-- Trusted SQL/service-role administration may provision the first owner account.
create or replace function public.protect_profile_privileges() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user not in ('postgres', 'service_role', 'supabase_admin') and not public.is_owner() then
    if new.role is distinct from old.role
      or new.status is distinct from old.status
      or new.id is distinct from old.id
      or new.academic_year_id is distinct from old.academic_year_id
      or new.group_id is distinct from old.group_id
      or new.section_id is distinct from old.section_id then
      raise exception 'role, status, identity and academic placement are managed by an owner';
    end if;
  end if;
  return new;
end; $$;
