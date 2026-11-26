-- AcadMind Phase 1-3 completion: schedule lecturer metadata and student feedback.
alter table public.schedules add column if not exists instructor text;

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null default 'suggestion' check (category in ('suggestion','bug','content','other')),
  subject text not null check (char_length(trim(subject)) between 3 and 120),
  message text not null check (char_length(trim(message)) between 10 and 5000),
  status text not null default 'new' check (status in ('new','in_progress','resolved','closed')),
  admin_reply text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists feedback_created_at_idx on public.feedback(created_at desc);
create index if not exists feedback_status_idx on public.feedback(status);

alter table public.feedback enable row level security;
drop policy if exists feedback_insert_own on public.feedback;
create policy feedback_insert_own on public.feedback
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists feedback_read_own_or_owner on public.feedback;
create policy feedback_read_own_or_owner on public.feedback
  for select to authenticated using ((select auth.uid()) = user_id or public.is_owner());
drop policy if exists feedback_update_owner on public.feedback;
create policy feedback_update_owner on public.feedback
  for update to authenticated using (public.is_owner()) with check (public.is_owner());

grant select, insert on public.feedback to authenticated;
grant update on public.feedback to authenticated;
