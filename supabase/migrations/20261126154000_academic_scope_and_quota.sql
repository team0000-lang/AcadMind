-- Security-definer helper centralizes active-year and profile scope checks for RLS policies.
create or replace function public.can_access_academic_scope(p_year uuid, p_group uuid default null, p_section uuid default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
    join public.academic_years y on y.id = p.academic_year_id
    where p.id = (select auth.uid()) and p.status = 'active' and p.deleted_at is null
      and p.academic_year_id = p_year and y.status = 'active' and y.deleted_at is null
      and (p_group is null or p.group_id is null or p.group_id = p_group)
      and (p_section is null or p.section_id is null or p.section_id = p_section)
  );
$$;
revoke all on function public.can_access_academic_scope(uuid, uuid, uuid) from public, anon;
grant execute on function public.can_access_academic_scope(uuid, uuid, uuid) to authenticated;

drop policy groups_read on public.groups;
create policy groups_read on public.groups for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and public.can_access_academic_scope(academic_year_id, id, null)));
drop policy sections_read on public.sections;
create policy sections_read on public.sections for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and public.can_access_academic_scope(academic_year_id, group_id, id)));
drop policy subjects_read on public.subjects;
create policy subjects_read on public.subjects for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and public.can_access_academic_scope(academic_year_id, group_id, section_id)));
drop policy lectures_read on public.lectures;
create policy lectures_read on public.lectures for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and exists (
  select 1 from public.subjects s where s.id = lectures.subject_id and s.is_active and s.deleted_at is null
    and public.can_access_academic_scope(s.academic_year_id, s.group_id, s.section_id)
)));
drop policy schedules_read on public.schedules;
create policy schedules_read on public.schedules for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and public.can_access_academic_scope(academic_year_id, group_id, section_id)));
drop policy youtube_read on public.youtube_resources;
create policy youtube_read on public.youtube_resources for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and exists (
  select 1 from public.subjects s where s.id = youtube_resources.subject_id and s.is_active and s.deleted_at is null
    and public.can_access_academic_scope(s.academic_year_id, s.group_id, s.section_id)
)));
drop policy drive_read on public.drive_folders;
create policy drive_read on public.drive_folders for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and public.can_access_academic_scope(academic_year_id, group_id, section_id)));
drop policy docs_read_scope on public.knowledge_documents;
create policy docs_read_scope on public.knowledge_documents for select to authenticated
using (public.is_owner() or exists (
  select 1 from public.subjects s where s.id = knowledge_documents.subject_id and s.is_active and s.deleted_at is null
    and public.can_access_academic_scope(s.academic_year_id, s.group_id, s.section_id)
));
drop policy chunks_read_scope on public.knowledge_chunks;
create policy chunks_read_scope on public.knowledge_chunks for select to authenticated
using (public.is_owner() or exists (
  select 1 from public.subjects s where s.id = knowledge_chunks.subject_id and s.is_active and s.deleted_at is null
    and public.can_access_academic_scope(s.academic_year_id, s.group_id, s.section_id)
));
drop policy course_docs_student_read on storage.objects;
create policy course_docs_student_read on storage.objects for select to authenticated
using (bucket_id = 'course-documents' and exists (
  select 1 from public.knowledge_documents d join public.subjects s on s.id = d.subject_id
  where d.storage_path = name and d.status = 'ready' and s.is_active and s.deleted_at is null
    and public.can_access_academic_scope(s.academic_year_id, s.group_id, s.section_id)
));
drop policy subject_assets_read_scope on storage.objects;
create policy subject_assets_read_scope on storage.objects for select to authenticated
using (bucket_id = 'subject-assets' and (public.is_owner() or exists (
  select 1 from public.subjects s where s.icon_path = name and s.is_active and s.deleted_at is null
    and public.can_access_academic_scope(s.academic_year_id, s.group_id, s.section_id)
)));

alter table public.announcements add constraint announcements_year_fk foreign key (academic_year_id) references public.academic_years(id);
alter table public.announcements add constraint announcements_target_scope_complete check (
 (target = 'everyone' and academic_year_id is null and group_id is null and section_id is null)
 or (target = 'academic_year' and academic_year_id is not null and group_id is null and section_id is null)
 or (target = 'group' and academic_year_id is not null and group_id is not null and section_id is null)
 or (target = 'section' and academic_year_id is not null and group_id is not null and section_id is not null)
);
drop policy announcements_read on public.announcements;
create policy announcements_read on public.announcements for select to authenticated
using (public.is_owner() or (is_active and deleted_at is null and published_at <= now() and (expires_at is null or expires_at > now()) and (
  target = 'everyone' or public.can_access_academic_scope(academic_year_id, group_id, section_id)
)));

-- Fixed quota; clients cannot raise the cap by calling the RPC with a larger parameter.
revoke all on function public.consume_ai_quota(integer) from public, anon, authenticated;
drop function public.consume_ai_quota(integer);
create or replace function public.consume_ai_quota() returns boolean language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
  if auth.uid() is null then return false; end if;
  insert into public.ai_usage(user_id, usage_day, request_count)
  values (auth.uid(), (now() at time zone 'utc')::date, 1)
  on conflict(user_id, usage_day) do update set request_count = public.ai_usage.request_count + 1
  returning request_count into n;
  return n <= 30;
end; $$;
revoke all on function public.consume_ai_quota() from public, anon;
grant execute on function public.consume_ai_quota() to authenticated;
