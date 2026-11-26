-- AcadMind Phase 2 — PostgreSQL schema and security baseline
create extension if not exists pgcrypto with schema extensions;
create extension if not exists vector with schema extensions;

create type public.app_role as enum ('student', 'owner', 'summer_account');
create type public.academic_year_status as enum ('active', 'coming_soon', 'disabled');
create type public.announcement_target as enum ('everyone', 'academic_year', 'group', 'section');
create type public.class_type as enum ('lecture', 'section', 'practical', 'lab');

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;

create table public.academic_years (
 id uuid primary key default gen_random_uuid(), name_ar text not null, name_en text not null,
 code text not null unique, status public.academic_year_status not null default 'disabled',
 display_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create table public.groups (
 id uuid primary key default gen_random_uuid(), academic_year_id uuid not null references public.academic_years(id),
 name text not null, code text not null, display_order integer not null default 0, is_active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 unique(academic_year_id, code), unique(id, academic_year_id)
);
create table public.sections (
 id uuid primary key default gen_random_uuid(), academic_year_id uuid not null references public.academic_years(id),
 group_id uuid not null, name text not null, code text not null, display_order integer not null default 0, is_active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(group_id, academic_year_id) references public.groups(id, academic_year_id), unique(group_id, code), unique(id, academic_year_id, group_id)
);
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade, full_name text not null default '', email text, phone text,
 avatar_path text, academic_year_id uuid references public.academic_years(id), group_id uuid, section_id uuid,
 role public.app_role not null default 'student', status text not null default 'active' check(status in ('active','suspended','pending')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(group_id, academic_year_id) references public.groups(id, academic_year_id),
 foreign key(section_id, academic_year_id, group_id) references public.sections(id, academic_year_id, group_id)
);
create index profiles_academic_idx on public.profiles(academic_year_id, group_id, section_id) where deleted_at is null;
create index profiles_role_idx on public.profiles(role) where deleted_at is null;
create or replace function public.is_owner() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'owner' and p.status = 'active' and p.deleted_at is null)
$$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id, full_name, email, phone)
 values(new.id, coalesce(new.raw_user_meta_data->>'full_name',''), new.email, new.phone)
 on conflict(id) do nothing;
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
create or replace function public.protect_profile_privileges() returns trigger language plpgsql set search_path = '' as $$
begin
 if not public.is_owner() then
   if new.role is distinct from old.role or new.status is distinct from old.status or new.id is distinct from old.id then
     raise exception 'role, status and identity are managed by an owner';
   end if;
 end if;
 return new;
end; $$;
create trigger protect_profile_privileges before update on public.profiles for each row execute function public.protect_profile_privileges();

create table public.subjects (
 id uuid primary key default gen_random_uuid(), academic_year_id uuid not null references public.academic_years(id), group_id uuid, section_id uuid,
 code text, name_ar text not null default '', name_en text not null default '', description text, icon_path text,
 is_active boolean not null default true, display_order integer not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(group_id, academic_year_id) references public.groups(id, academic_year_id),
 foreign key(section_id, academic_year_id, group_id) references public.sections(id, academic_year_id, group_id),
 unique nulls not distinct(academic_year_id, group_id, section_id, code)
);
create index subjects_scope_idx on public.subjects(academic_year_id, group_id, section_id, display_order) where is_active and deleted_at is null;
create table public.lectures (
 id uuid primary key default gen_random_uuid(), subject_id uuid not null references public.subjects(id), lecture_number integer,
 title text not null, topic text, description text, notes text, is_active boolean not null default true,
 display_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 unique(subject_id, lecture_number)
);
create index lectures_subject_order_idx on public.lectures(subject_id, display_order) where is_active and deleted_at is null;
create table public.schedules (
 id uuid primary key default gen_random_uuid(), academic_year_id uuid not null references public.academic_years(id), group_id uuid, section_id uuid, subject_id uuid references public.subjects(id),
 class_type public.class_type not null, day_of_week smallint not null check(day_of_week between 0 and 6), starts_at time not null, ends_at time not null check(ends_at > starts_at),
 location text, description text, valid_from date, valid_until date, is_active boolean not null default true, revision bigint not null default 1,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(group_id, academic_year_id) references public.groups(id, academic_year_id),
 foreign key(section_id, academic_year_id, group_id) references public.sections(id, academic_year_id, group_id)
);
create index schedules_scope_idx on public.schedules(academic_year_id, group_id, section_id, day_of_week, starts_at) where is_active and deleted_at is null;
create or replace function public.bump_schedule_revision() returns trigger language plpgsql set search_path = '' as $$
begin new.revision = old.revision + 1; return new; end; $$;
create trigger schedule_revision before update on public.schedules for each row execute function public.bump_schedule_revision();

create table public.youtube_resources (
 id uuid primary key default gen_random_uuid(), subject_id uuid not null references public.subjects(id), lecture_id uuid references public.lectures(id),
 title text not null, youtube_url text not null check(youtube_url ~ '^https://(www\\.)?(youtube\\.com|youtu\\.be)/'), description text, channel text,
 display_order integer not null default 0, is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create index youtube_subject_idx on public.youtube_resources(subject_id, lecture_id, display_order) where is_active and deleted_at is null;
create table public.drive_folders (
 id uuid primary key default gen_random_uuid(), subject_id uuid not null references public.subjects(id), academic_year_id uuid not null references public.academic_years(id), group_id uuid, section_id uuid,
 folder_name text not null, folder_url text not null check(folder_url ~ '^https://drive\\.google\\.com/'), description text,
 is_active boolean not null default true, display_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(group_id, academic_year_id) references public.groups(id, academic_year_id), foreign key(section_id, academic_year_id, group_id) references public.sections(id, academic_year_id, group_id)
);
create index drive_scope_idx on public.drive_folders(academic_year_id, group_id, section_id, subject_id, display_order) where is_active and deleted_at is null;
create table public.announcements (
 id uuid primary key default gen_random_uuid(), title text not null, content text not null, priority smallint not null default 0 check(priority between 0 and 5),
 target public.announcement_target not null default 'everyone', academic_year_id uuid, group_id uuid, section_id uuid,
 published_at timestamptz not null default now(), expires_at timestamptz, is_active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz,
 foreign key(group_id, academic_year_id) references public.groups(id, academic_year_id), foreign key(section_id, academic_year_id, group_id) references public.sections(id, academic_year_id, group_id),
 check((target='everyone' and academic_year_id is null and group_id is null and section_id is null) or (target='academic_year' and academic_year_id is not null and group_id is null and section_id is null) or (target='group' and group_id is not null and section_id is null) or (target='section' and section_id is not null))
);
create index announcements_feed_idx on public.announcements(published_at desc, priority desc) where is_active and deleted_at is null;

create table public.ai_conversations (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 subject_id uuid references public.subjects(id), lecture_id uuid references public.lectures(id), title text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create index ai_conversations_user_idx on public.ai_conversations(user_id, updated_at desc) where deleted_at is null;
create table public.ai_messages (
 id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, role text not null check(role in ('user','assistant','system')),
 content text not null check(length(content) <= 20000), sources jsonb not null default '[]'::jsonb, token_count integer, created_at timestamptz not null default now()
);
create index ai_messages_conversation_idx on public.ai_messages(conversation_id, created_at);
create table public.ai_usage (
 user_id uuid not null references auth.users(id) on delete cascade, usage_day date not null default (now() at time zone 'utc')::date,
 request_count integer not null default 0, primary key(user_id, usage_day)
);
create or replace function public.consume_ai_quota(p_daily_limit integer default 30) returns boolean language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
 if auth.uid() is null then return false; end if;
 insert into public.ai_usage(user_id, usage_day, request_count) values(auth.uid(), (now() at time zone 'utc')::date, 1)
 on conflict(user_id, usage_day) do update set request_count = public.ai_usage.request_count + 1
 returning request_count into n;
 return n <= greatest(1, least(p_daily_limit, 500));
end; $$;
revoke all on function public.consume_ai_quota(integer) from public, anon;
grant execute on function public.consume_ai_quota(integer) to authenticated;

create table public.knowledge_documents (
 id uuid primary key default gen_random_uuid(), subject_id uuid not null references public.subjects(id), lecture_id uuid references public.lectures(id),
 document_name text not null, mime_type text not null, storage_path text not null unique, status text not null default 'uploaded' check(status in ('uploaded','processing','ready','failed','archived')),
 page_count integer, metadata jsonb not null default '{}'::jsonb, uploaded_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create index knowledge_docs_scope_idx on public.knowledge_documents(subject_id, lecture_id) where status='ready' and deleted_at is null;
create table public.knowledge_chunks (
 id bigserial primary key, document_id uuid not null references public.knowledge_documents(id) on delete cascade,
 subject_id uuid not null references public.subjects(id), lecture_id uuid references public.lectures(id), chunk_index integer not null,
 page_number integer, content text not null, embedding extensions.vector(1536), metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), unique(document_id, chunk_index)
);
create index knowledge_chunks_subject_idx on public.knowledge_chunks(subject_id, lecture_id);
create index knowledge_chunks_embedding_idx on public.knowledge_chunks using hnsw (embedding extensions.vector_cosine_ops) with (m=16, ef_construction=64);
create or replace function public.match_knowledge_chunks(query_embedding extensions.vector(1536), match_count integer default 6, filter_subject uuid default null, filter_lecture uuid default null)
returns table(chunk_id bigint, document_id uuid, document_name text, subject_id uuid, lecture_id uuid, page_number integer, content text, similarity double precision)
language sql stable security invoker set search_path = '' as $$
 select c.id, c.document_id, d.document_name, c.subject_id, c.lecture_id, c.page_number, c.content, 1-(c.embedding OPERATOR(extensions.<=>) query_embedding)::double precision
 from public.knowledge_chunks c join public.knowledge_documents d on d.id=c.document_id
 join public.subjects s on s.id=c.subject_id
 where c.embedding is not null and d.status='ready' and d.deleted_at is null and s.is_active and s.deleted_at is null
 and (filter_subject is null or c.subject_id=filter_subject) and (filter_lecture is null or c.lecture_id=filter_lecture)
 order by c.embedding OPERATOR(extensions.<=>) query_embedding limit greatest(1, least(match_count, 20));
$$;
grant execute on function public.match_knowledge_chunks(extensions.vector, integer, uuid, uuid) to authenticated;

create table public.app_settings (
 key text primary key, value jsonb not null default '{}'::jsonb, description text, is_public boolean not null default false,
 updated_by uuid references auth.users(id), updated_at timestamptz not null default now()
);
create table public.app_versions (
 id uuid primary key default gen_random_uuid(), platform text not null check(platform in ('android','ios','web')), version_name text not null,
 build_number integer not null, update_url text, release_notes text, minimum_supported_version text, force_update boolean not null default false,
 optional_update boolean not null default true, enabled boolean not null default true, released_at timestamptz, created_at timestamptz not null default now(), unique(platform, build_number)
);
create index app_versions_current_idx on public.app_versions(platform, build_number desc) where enabled;
create table public.update_settings (
 platform text primary key check(platform in ('android','ios','web')), minimum_supported_version text, force_update boolean not null default false,
 update_url text, message text, enabled boolean not null default true, updated_at timestamptz not null default now()
);

-- Timestamp triggers
DO $$ declare t text; begin
 foreach t in array array['academic_years','groups','sections','profiles','subjects','lectures','schedules','youtube_resources','drive_folders','announcements','ai_conversations','knowledge_documents'] loop
  execute format('create trigger %I before update on public.%I for each row execute function public.set_updated_at()', 'set_updated_at_'||t, t);
 end loop;
end $$;

-- Row-level security
alter table public.profiles enable row level security;
alter table public.academic_years enable row level security;
alter table public.groups enable row level security;
alter table public.sections enable row level security;
alter table public.subjects enable row level security;
alter table public.lectures enable row level security;
alter table public.schedules enable row level security;
alter table public.youtube_resources enable row level security;
alter table public.drive_folders enable row level security;
alter table public.announcements enable row level security;
alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_usage enable row level security;
alter table public.knowledge_documents enable row level security;
alter table public.knowledge_chunks enable row level security;
alter table public.app_settings enable row level security;
alter table public.app_versions enable row level security;
alter table public.update_settings enable row level security;

create policy profile_read_self_or_owner on public.profiles for select to authenticated using(id=(select auth.uid()) or public.is_owner());
create policy profile_update_self_or_owner on public.profiles for update to authenticated using(id=(select auth.uid()) or public.is_owner()) with check(id=(select auth.uid()) or public.is_owner());
create policy academic_year_read on public.academic_years for select to authenticated using((status='active' and deleted_at is null) or public.is_owner());
create policy academic_year_owner on public.academic_years for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy groups_read on public.groups for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.academic_year_id=groups.academic_year_id)));
create policy groups_owner on public.groups for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy sections_read on public.sections for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.academic_year_id=sections.academic_year_id and (p.group_id is null or p.group_id=sections.group_id) and (p.section_id is null or p.section_id=sections.id))));
create policy sections_owner on public.sections for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy subjects_read on public.subjects for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.academic_year_id=subjects.academic_year_id and (subjects.group_id is null or p.group_id=subjects.group_id) and (subjects.section_id is null or p.section_id=subjects.section_id) and p.status='active')));
create policy subjects_owner on public.subjects for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy lectures_read on public.lectures for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and exists(select 1 from public.subjects s join public.profiles p on p.id=(select auth.uid()) where s.id=lectures.subject_id and s.is_active and s.deleted_at is null and p.status='active' and p.academic_year_id=s.academic_year_id and (s.group_id is null or p.group_id=s.group_id) and (s.section_id is null or p.section_id=s.section_id))));
create policy lectures_owner on public.lectures for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy schedules_read on public.schedules for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.status='active' and p.academic_year_id=schedules.academic_year_id and (schedules.group_id is null or p.group_id=schedules.group_id) and (schedules.section_id is null or p.section_id=schedules.section_id))));
create policy schedules_owner on public.schedules for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy youtube_read on public.youtube_resources for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and exists(select 1 from public.subjects s join public.profiles p on p.id=(select auth.uid()) where s.id=youtube_resources.subject_id and s.is_active and s.deleted_at is null and p.status='active' and p.academic_year_id=s.academic_year_id and (s.group_id is null or p.group_id=s.group_id) and (s.section_id is null or p.section_id=s.section_id))));
create policy youtube_owner on public.youtube_resources for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy drive_read on public.drive_folders for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.status='active' and p.academic_year_id=drive_folders.academic_year_id and (drive_folders.group_id is null or p.group_id=drive_folders.group_id) and (drive_folders.section_id is null or p.section_id=drive_folders.section_id))));
create policy drive_owner on public.drive_folders for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy announcements_read on public.announcements for select to authenticated using(public.is_owner() or (is_active and deleted_at is null and published_at<=now() and (expires_at is null or expires_at>now()) and (target='everyone' or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.status='active' and (target='academic_year' and p.academic_year_id=announcements.academic_year_id or target='group' and p.group_id=announcements.group_id or target='section' and p.section_id=announcements.section_id)))));
create policy announcements_owner on public.announcements for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy conversations_read_own on public.ai_conversations for select to authenticated using(user_id=(select auth.uid()) or public.is_owner());
create policy conversations_insert_own on public.ai_conversations for insert to authenticated with check(user_id=(select auth.uid()));
create policy conversations_update_own on public.ai_conversations for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy conversations_delete_own on public.ai_conversations for delete to authenticated using(user_id=(select auth.uid()));
create policy messages_read_own on public.ai_messages for select to authenticated using(user_id=(select auth.uid()) or public.is_owner());
create policy messages_insert_own on public.ai_messages for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.ai_conversations c where c.id=conversation_id and c.user_id=(select auth.uid())));
create policy messages_owner on public.ai_messages for delete to authenticated using(public.is_owner());
create policy usage_read_own on public.ai_usage for select to authenticated using(user_id=(select auth.uid()));
create policy docs_read_scope on public.knowledge_documents for select to authenticated using(public.is_owner() or exists(select 1 from public.subjects s join public.profiles p on p.id=(select auth.uid()) where s.id=knowledge_documents.subject_id and s.is_active and s.deleted_at is null and p.status='active' and p.academic_year_id=s.academic_year_id and (s.group_id is null or p.group_id=s.group_id) and (s.section_id is null or p.section_id=s.section_id)));
create policy docs_owner on public.knowledge_documents for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy chunks_read_scope on public.knowledge_chunks for select to authenticated using(public.is_owner() or exists(select 1 from public.subjects s join public.profiles p on p.id=(select auth.uid()) where s.id=knowledge_chunks.subject_id and s.is_active and s.deleted_at is null and p.status='active' and p.academic_year_id=s.academic_year_id and (s.group_id is null or p.group_id=s.group_id) and (s.section_id is null or p.section_id=s.section_id)));
create policy chunks_owner on public.knowledge_chunks for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy settings_read_public on public.app_settings for select to anon, authenticated using(is_public or public.is_owner());
create policy settings_owner on public.app_settings for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy app_versions_read on public.app_versions for select to anon, authenticated using(enabled or public.is_owner());
create policy app_versions_owner on public.app_versions for all to authenticated using(public.is_owner()) with check(public.is_owner());
create policy update_settings_read on public.update_settings for select to anon, authenticated using(enabled or public.is_owner());
create policy update_settings_owner on public.update_settings for all to authenticated using(public.is_owner()) with check(public.is_owner());

-- Explicit grants: RLS remains authoritative; no direct client writes for academic content.
grant usage on schema public to anon, authenticated;
grant select on public.academic_years, public.groups, public.sections, public.subjects, public.lectures, public.schedules, public.youtube_resources, public.drive_folders, public.announcements, public.knowledge_documents, public.knowledge_chunks, public.app_settings, public.app_versions, public.update_settings to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.ai_conversations to authenticated;
grant select, insert, delete on public.ai_messages to authenticated;
grant select on public.ai_usage to authenticated;
grant usage, select on sequence public.knowledge_chunks_id_seq to authenticated;

-- Private storage buckets; owners upload/administer; students only read authorized document objects (path: subject_id/...).
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
 ('profile-images','profile-images',false,5242880,array['image/jpeg','image/png','image/webp']),
 ('course-documents','course-documents',false,52428800,array['application/pdf','text/plain','application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
 ('subject-assets','subject-assets',false,10485760,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false, file_size_limit=excluded.file_size_limit, allowed_mime_types=excluded.allowed_mime_types;
create policy profile_image_owner_path on storage.objects for select to authenticated using(bucket_id='profile-images' and (owner_id=(select auth.uid())::text or public.is_owner()));
create policy profile_image_self_upload on storage.objects for insert to authenticated with check(bucket_id='profile-images' and owner_id=(select auth.uid())::text);
create policy profile_image_self_update on storage.objects for update to authenticated using(bucket_id='profile-images' and (owner_id=(select auth.uid())::text or public.is_owner())) with check(bucket_id='profile-images' and (owner_id=(select auth.uid())::text or public.is_owner()));
create policy course_docs_owner_all on storage.objects for all to authenticated using(bucket_id='course-documents' and public.is_owner()) with check(bucket_id='course-documents' and public.is_owner());
create policy course_docs_student_read on storage.objects for select to authenticated using(bucket_id='course-documents' and exists(select 1 from public.knowledge_documents d join public.subjects s on s.id=d.subject_id join public.profiles p on p.id=(select auth.uid()) where d.storage_path=name and d.status='ready' and s.is_active and s.deleted_at is null and p.status='active' and p.academic_year_id=s.academic_year_id and (s.group_id is null or p.group_id=s.group_id) and (s.section_id is null or p.section_id=s.section_id)));
create policy subject_assets_read_scope on storage.objects for select to authenticated using(bucket_id='subject-assets' and (public.is_owner() or exists(select 1 from public.subjects s join public.profiles p on p.id=(select auth.uid()) where s.icon_path=name and s.is_active and s.deleted_at is null and p.status='active' and p.academic_year_id=s.academic_year_id and (s.group_id is null or p.group_id=s.group_id) and (s.section_id is null or p.section_id=s.section_id))));
create policy subject_assets_owner_write on storage.objects for all to authenticated using(bucket_id='subject-assets' and public.is_owner()) with check(bucket_id='subject-assets' and public.is_owner());
