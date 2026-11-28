-- Personal Smart Study Library: saved AI outputs remain private to each student.
create table if not exists public.study_library_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  item_type text not null check (item_type in ('summary','analysis','quiz','flashcards','explanation','plan','chat','note')),
  title text not null check (char_length(trim(title)) between 1 and 180),
  content text not null check (char_length(content) between 1 and 50000),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists study_library_user_created_idx on public.study_library_items(user_id, created_at desc);
create index if not exists study_library_subject_type_idx on public.study_library_items(user_id, subject_id, item_type);
alter table public.study_library_items enable row level security;
drop policy if exists study_library_own_manage on public.study_library_items;
create policy study_library_own_manage on public.study_library_items
  for all to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.study_library_items to authenticated;
