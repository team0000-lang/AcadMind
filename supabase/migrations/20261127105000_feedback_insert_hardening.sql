-- Prevent student-submitted feedback from impersonating owner workflow state.
-- Keep the policy additive and compatible with the existing feedback table.
drop policy if exists feedback_insert_own on public.feedback;
create policy feedback_insert_own on public.feedback
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'new'
    and admin_reply is null
  );

-- Defaults are server-side; reject clients attempting to backdate or forge metadata.
create or replace function public.enforce_feedback_submission_defaults()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_owner() then
    new.status := 'new';
    new.admin_reply := null;
    new.created_at := now();
    new.updated_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists feedback_submission_defaults on public.feedback;
create trigger feedback_submission_defaults
  before insert on public.feedback
  for each row execute function public.enforce_feedback_submission_defaults();
