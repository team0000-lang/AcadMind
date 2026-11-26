-- Run ONLY in the Supabase SQL Editor after the intended owner has signed up.
-- Replace the email below with the exact verified email of your account.
-- This grants owner role to one matching existing account; it does not expose owner promotion in the app.
update public.profiles p
set role = 'owner', status = 'active'
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('REPLACE_WITH_YOUR_SIGNUP_EMAIL')
  and p.role = 'student';

-- Verify the result:
select id, email, role, status
from public.profiles
where lower(email) = lower('REPLACE_WITH_YOUR_SIGNUP_EMAIL');
