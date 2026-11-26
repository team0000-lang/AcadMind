drop policy if exists "subjects_read_during_student_setup" on public.subjects;
create policy "subjects_read_during_student_setup"
on public.subjects
for select
to authenticated
using (
  is_active
  and deleted_at is null
  and group_id is null
  and section_id is null
  and exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.status = 'active'
      and p.deleted_at is null
      and p.role <> 'owner'
  )
  and exists (
    select 1
    from public.academic_years ay
    where ay.id = subjects.academic_year_id
      and ay.status = 'active'
      and ay.deleted_at is null
  )
);