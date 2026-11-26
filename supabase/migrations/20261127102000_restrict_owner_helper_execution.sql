-- Restrict privileged helper RPC execution while preserving policy and trigger behavior.
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.is_owner() from public, anon;
grant execute on function public.is_owner() to authenticated;
