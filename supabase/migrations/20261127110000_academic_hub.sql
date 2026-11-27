-- AcadMind academic hub: dated events, personal completion/progress records.
-- Reuses profiles, subjects and the existing academic hierarchy.
create table if not exists public.academic_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null check (event_type in ('lecture','exam','quiz','assignment','deadline','event')),
  title text not null check (char_length(trim(title)) between 2 and 180),
  subject_id uuid references public.subjects(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  description text,
  location text,
  external_url text,
  reminder_minutes integer not null default 0 check (reminder_minutes between 0 and 10080),
  academic_year_id uuid not null references public.academic_years(id),
  group_id uuid references public.groups(id),
  section_id uuid references public.sections(id),
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint academic_events_valid_time check (ends_at is null or ends_at > starts_at),
  constraint academic_events_section_scope check (section_id is null or group_id is not null)
);
create index if not exists academic_events_scope_time_idx
  on public.academic_events(academic_year_id, group_id, section_id, starts_at)
  where is_active;
create index if not exists academic_events_type_time_idx
  on public.academic_events(event_type, starts_at)
  where is_active;

create table if not exists public.assignment_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id uuid not null references public.academic_events(id) on delete cascade,
  status text not null default 'not_started' check (status in ('not_started','in_progress','completed')),
  updated_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  title text not null check (char_length(trim(title)) between 2 and 180),
  started_at timestamptz not null default now(),
  duration_minutes integer not null check (duration_minutes between 1 and 1440),
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists study_sessions_user_started_idx on public.study_sessions(user_id, started_at desc);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  title text not null check (char_length(trim(title)) between 2 and 180),
  score numeric(7,2) not null check (score >= 0),
  max_score numeric(7,2) not null check (max_score > 0 and score <= max_score),
  answers jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists quiz_attempts_user_created_idx on public.quiz_attempts(user_id, created_at desc);

create table if not exists public.flashcard_reviews (
  user_id uuid not null references auth.users(id) on delete cascade,
  card_key text not null check (char_length(card_key) between 1 and 240),
  difficulty text not null default 'normal' check (difficulty in ('known','normal','difficult')),
  reviewed_at timestamptz not null default now(),
  primary key (user_id, card_key)
);

alter table public.academic_events enable row level security;
alter table public.assignment_progress enable row level security;
alter table public.study_sessions enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.flashcard_reviews enable row level security;

drop policy if exists academic_events_student_read on public.academic_events;
create policy academic_events_student_read on public.academic_events
  for select to authenticated using (
    public.is_owner() or (
      is_active and exists (
        select 1 from public.profiles p
        where p.id = (select auth.uid()) and p.status = 'active'
          and p.academic_year_id = academic_events.academic_year_id
          and (academic_events.group_id is null or p.group_id = academic_events.group_id)
          and (academic_events.section_id is null or p.section_id = academic_events.section_id)
      )
    )
  );
drop policy if exists academic_events_owner_manage on public.academic_events;
create policy academic_events_owner_manage on public.academic_events
  for all to authenticated using (public.is_owner()) with check (public.is_owner());
grant select, insert, update, delete on public.academic_events to authenticated;

create policy assignment_progress_own_select on public.assignment_progress
  for select to authenticated using (user_id = (select auth.uid()));
create policy assignment_progress_own_write on public.assignment_progress
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.academic_events e
    join public.profiles p on p.id = (select auth.uid())
    where e.id = event_id and e.event_type = 'assignment' and e.is_active
      and p.status = 'active' and p.academic_year_id = e.academic_year_id
      and (e.group_id is null or p.group_id = e.group_id)
      and (e.section_id is null or p.section_id = e.section_id)
  ));
grant select, insert, update, delete on public.assignment_progress to authenticated;

create policy study_sessions_own_manage on public.study_sessions
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.study_sessions to authenticated;
create policy quiz_attempts_own_manage on public.quiz_attempts
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.quiz_attempts to authenticated;
create policy flashcard_reviews_own_manage on public.flashcard_reviews
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.flashcard_reviews to authenticated;
