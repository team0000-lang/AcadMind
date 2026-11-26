-- Students can see all schedule rows in their own scope (including tombstones) to reconcile local reminders.
drop policy schedules_read on public.schedules;
create policy schedules_read on public.schedules for select to authenticated
using (public.is_owner() or public.can_access_academic_scope(academic_year_id, group_id, section_id));

-- Show coming-soon years to students, while keeping disabled years hidden.
drop policy academic_year_read on public.academic_years;
create policy academic_year_read on public.academic_years for select to authenticated
using ((status in ('active', 'coming_soon') and deleted_at is null) or public.is_owner());

-- Public announcements still require an active account; targeted ones also require an active matching year.
drop policy announcements_read on public.announcements;
create policy announcements_read on public.announcements for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and published_at <= now() and (expires_at is null or expires_at > now())
  and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.status='active' and p.deleted_at is null)
  and (target='everyone' or public.can_access_academic_scope(academic_year_id, group_id, section_id))));

-- Students may only edit ordinary contact/profile fields, not archival or security metadata.
create or replace function public.protect_profile_privileges() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user not in ('postgres', 'service_role', 'supabase_admin') and not public.is_owner() then
    if new.role is distinct from old.role or new.status is distinct from old.status or new.id is distinct from old.id
      or new.academic_year_id is distinct from old.academic_year_id or new.group_id is distinct from old.group_id
      or new.section_id is distinct from old.section_id or new.deleted_at is distinct from old.deleted_at
      or new.created_at is distinct from old.created_at then
      raise exception 'role, status, identity, academic placement and archival metadata are managed by an owner';
    end if;
  end if;
  return new;
end; $$;
