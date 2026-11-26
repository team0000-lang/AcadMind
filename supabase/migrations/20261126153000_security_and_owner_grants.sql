-- Lock student academic placement fields and allow owner-managed DML (still protected by RLS).
create or replace function public.protect_profile_privileges() returns trigger
language plpgsql set search_path = '' as $$
begin
  if not public.is_owner() then
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

grant insert, update, delete on public.academic_years, public.groups, public.sections,
  public.subjects, public.lectures, public.schedules, public.youtube_resources,
  public.drive_folders, public.announcements, public.knowledge_documents,
  public.knowledge_chunks, public.app_settings, public.app_versions,
  public.update_settings to authenticated;
grant usage, select on sequence public.knowledge_chunks_id_seq to authenticated;
