create table if not exists public.academic_year_interest (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  academic_year_id uuid not null references public.academic_years(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint academic_year_interest_user_year_key unique (user_id, academic_year_id)
);

alter table public.academic_year_interest enable row level security;
revoke all on public.academic_year_interest from anon;
grant select, insert, delete on public.academic_year_interest to authenticated;

create policy "academic_year_interest_read_own_or_owner"
on public.academic_year_interest for select to authenticated
using (user_id = (select auth.uid()) or public.is_owner());

create policy "academic_year_interest_insert_own_coming_year"
on public.academic_year_interest for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid())
      and p.status = 'active'
      and p.role <> 'owner'
  )
  and exists (
    select 1 from public.academic_years ay
    where ay.id = academic_year_id
      and ay.status = 'coming_soon'
      and ay.deleted_at is null
  )
);

create policy "academic_year_interest_delete_own_or_owner"
on public.academic_year_interest for delete to authenticated
using (user_id = (select auth.uid()) or public.is_owner());