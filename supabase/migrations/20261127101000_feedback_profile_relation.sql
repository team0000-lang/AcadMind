alter table public.feedback
  add constraint feedback_profile_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;
