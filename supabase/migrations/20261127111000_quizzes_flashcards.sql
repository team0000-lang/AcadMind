-- Owner-authored practice quizzes and flashcard decks, scoped by academic placement.
create table if not exists public.study_quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 2 and 180),
  description text,
  subject_id uuid references public.subjects(id) on delete set null,
  academic_year_id uuid not null references public.academic_years(id),
  group_id uuid references public.groups(id),
  section_id uuid references public.sections(id),
  is_published boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  constraint study_quizzes_scope check (section_id is null or group_id is not null)
);
create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.study_quizzes(id) on delete cascade,
  question text not null check (char_length(trim(question)) between 2 and 3000),
  question_type text not null check (question_type in ('multiple_choice','true_false','short_answer')),
  options jsonb not null default '[]'::jsonb,
  correct_answer text not null,
  explanation text,
  points numeric(7,2) not null default 1 check (points > 0),
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint quiz_question_options_array check (jsonb_typeof(options) = 'array')
);
create index if not exists quiz_questions_order_idx on public.quiz_questions(quiz_id, display_order);

create table if not exists public.flashcard_decks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 2 and 180),
  description text,
  subject_id uuid references public.subjects(id) on delete set null,
  academic_year_id uuid not null references public.academic_years(id),
  group_id uuid references public.groups(id),
  section_id uuid references public.sections(id),
  is_published boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  constraint flashcard_decks_scope check (section_id is null or group_id is not null)
);
create table if not exists public.flashcards (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid not null references public.flashcard_decks(id) on delete cascade,
  question text not null check (char_length(trim(question)) between 1 and 3000),
  answer text not null check (char_length(trim(answer)) between 1 and 5000),
  difficulty text not null default 'normal' check (difficulty in ('easy','normal','hard')),
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists flashcards_deck_order_idx on public.flashcards(deck_id, display_order);

alter table public.quiz_attempts add column if not exists quiz_id uuid references public.study_quizzes(id) on delete set null;

alter table public.study_quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.flashcard_decks enable row level security;
alter table public.flashcards enable row level security;

create policy study_quizzes_student_read on public.study_quizzes
  for select to authenticated using (public.is_owner() or (is_active and is_published and exists (
    select 1 from public.profiles p where p.id=(select auth.uid()) and p.status='active'
      and p.academic_year_id=study_quizzes.academic_year_id
      and (study_quizzes.group_id is null or p.group_id=study_quizzes.group_id)
      and (study_quizzes.section_id is null or p.section_id=study_quizzes.section_id)
  )));
create policy study_quizzes_owner_manage on public.study_quizzes
  for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy quiz_questions_owner_read on public.quiz_questions
  for select to authenticated using (public.is_owner());
create policy quiz_questions_owner_manage on public.quiz_questions
  for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy flashcard_decks_student_read on public.flashcard_decks
  for select to authenticated using (public.is_owner() or (is_active and is_published and exists (
    select 1 from public.profiles p where p.id=(select auth.uid()) and p.status='active'
      and p.academic_year_id=flashcard_decks.academic_year_id
      and (flashcard_decks.group_id is null or p.group_id=flashcard_decks.group_id)
      and (flashcard_decks.section_id is null or p.section_id=flashcard_decks.section_id)
  )));
create policy flashcard_decks_owner_manage on public.flashcard_decks
  for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy flashcards_student_read on public.flashcards
  for select to authenticated using (exists (
    select 1 from public.flashcard_decks d where d.id=deck_id and d.is_active and d.is_published
  ));
create policy flashcards_owner_read on public.flashcards
  for select to authenticated using (public.is_owner());
create policy flashcards_owner_manage on public.flashcards
  for all to authenticated using (public.is_owner()) with check (public.is_owner());

grant select, insert, update, delete on public.study_quizzes, public.quiz_questions, public.flashcard_decks, public.flashcards to authenticated;

-- Revoke direct answer/grade writes: owners author questions; learners read safe question payloads and submit answers via RPC.
drop policy if exists quiz_attempts_own_manage on public.quiz_attempts;
create policy quiz_attempts_own_select on public.quiz_attempts
  for select to authenticated using (user_id = (select auth.uid()));
grant select on public.quiz_attempts to authenticated;
revoke insert, update, delete on public.quiz_attempts from authenticated;

grant execute on function public.is_owner() to authenticated;
create or replace function public.get_practice_quiz_questions(p_quiz_id uuid)
returns table(id uuid, question text, question_type text, options jsonb, points numeric, display_order integer)
language plpgsql stable security definer set search_path = '' as $$
declare
  v_quiz public.study_quizzes%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into v_quiz from public.study_quizzes where study_quizzes.id=p_quiz_id and is_active and is_published;
  if not found then raise exception 'Quiz not available'; end if;
  if not public.is_owner() and not exists (
    select 1 from public.profiles p where p.id=auth.uid() and p.status='active'
      and p.academic_year_id=v_quiz.academic_year_id
      and (v_quiz.group_id is null or p.group_id=v_quiz.group_id)
      and (v_quiz.section_id is null or p.section_id=v_quiz.section_id)
  ) then raise exception 'Quiz not available'; end if;
  return query select q.id,q.question,q.question_type,q.options,q.points,q.display_order
    from public.quiz_questions q where q.quiz_id=p_quiz_id order by q.display_order,q.created_at;
end;
$$;
revoke all on function public.get_practice_quiz_questions(uuid) from public, anon;
grant execute on function public.get_practice_quiz_questions(uuid) to authenticated;

create or replace function public.submit_practice_quiz(p_quiz_id uuid, p_answers jsonb)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_quiz public.study_quizzes%rowtype;
  v_user uuid := auth.uid();
  v_score numeric(7,2);
  v_max numeric(7,2);
  v_result jsonb;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_answers is null or jsonb_typeof(p_answers) is distinct from 'array' then
    raise exception 'Answers must be an array';
  end if;
  if jsonb_array_length(p_answers) > 1000 then raise exception 'Too many answers'; end if;
  select * into v_quiz from public.study_quizzes where id=p_quiz_id and is_active and is_published;
  if not found then raise exception 'Quiz not available'; end if;
  if not public.is_owner() and not exists (
    select 1 from public.profiles p where p.id=v_user and p.status='active'
      and p.academic_year_id=v_quiz.academic_year_id
      and (v_quiz.group_id is null or p.group_id=v_quiz.group_id)
      and (v_quiz.section_id is null or p.section_id=v_quiz.section_id)
  ) then raise exception 'Quiz not available'; end if;
  select coalesce(sum(q.points),0) into v_max from public.quiz_questions q where q.quiz_id=p_quiz_id;
  if v_max <= 0 then raise exception 'Quiz has no questions'; end if;
  if exists (
    select 1 from (
      select a.value->>'questionId' as question_id, count(*) as answer_count
      from jsonb_array_elements(p_answers) a(value)
      group by a.value->>'questionId'
    ) submitted
    where submitted.answer_count > 1 or submitted.question_id is null or not exists (
      select 1 from public.quiz_questions q
      where q.quiz_id = p_quiz_id and q.id::text = submitted.question_id
    )
  ) then raise exception 'Invalid or duplicate question answers'; end if;
  select coalesce(sum(case when lower(btrim(coalesce(a.value->>'answer',''))) = lower(btrim(q.correct_answer)) then q.points else 0 end),0)
    into v_score
    from public.quiz_questions q
    left join lateral (
      select answer.value
      from jsonb_array_elements(p_answers) answer(value)
      where answer.value->>'questionId'=q.id::text
      limit 1
    ) a on true
    where q.quiz_id=p_quiz_id;
  select coalesce(jsonb_agg(jsonb_build_object(
    'questionId',q.id,'correct',lower(btrim(coalesce(a.value->>'answer',''))) = lower(btrim(q.correct_answer)),
    'correctAnswer',q.correct_answer,'explanation',q.explanation
  ) order by q.display_order), '[]'::jsonb)
    into v_result
    from public.quiz_questions q
    left join lateral (
      select answer.value
      from jsonb_array_elements(p_answers) answer(value)
      where answer.value->>'questionId'=q.id::text
      limit 1
    ) a on true
    where q.quiz_id=p_quiz_id;
  insert into public.quiz_attempts(user_id,subject_id,quiz_id,title,score,max_score,answers)
    values(v_user,v_quiz.subject_id,p_quiz_id,v_quiz.title,v_score,v_max,p_answers);
  return jsonb_build_object('score',v_score,'maxScore',v_max,'results',v_result);
end;
$$;
revoke all on function public.submit_practice_quiz(uuid,jsonb) from public, anon;
grant execute on function public.submit_practice_quiz(uuid,jsonb) to authenticated;
