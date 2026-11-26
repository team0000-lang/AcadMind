# AcadMind Phase 2 — Supabase Backend

This repository is the independent Supabase backend for AcadMind. Project ref: `skpjvgzxoholaapymvwd` (Frankfurt, `eu-central-1`). The pre-existing project named “سكينه” was not modified.

## Applied infrastructure

- PostgreSQL 17 schema, foreign keys, unique constraints and scoped indexes.
- Real Supabase Auth profile trigger and profile row security.
- Student/owner/summer-account role enum (summer-account has no invented behavior).
- Academic years → groups → sections → subjects → lectures.
- Schedules with weekday/time and a monotonically increasing `revision` plus `updated_at` for local notification refresh checks.
- YouTube/Drive resources, targeted announcements, app settings, app versions and update settings.
- Private Storage buckets: `profile-images`, `course-documents`, `subject-assets`.
- AI conversations/messages, daily quota counter, `vector(1536)` chunks, HNSW cosine index and scoped similarity RPC.
- RLS on every application table. Student data is scoped to the profile's academic year/group/section; students cannot update their placement or role. Only owners can write academic content. Conversations and messages are user-owned.

## Frontend configuration

Copy `.env.example` to `.env.local` (or the environment-specific Vite secret store) and retain the project URL and **publishable** key. Publishable/anon keys are designed for client use under RLS. Never add a service-role key, database password, or AI provider key to Vite variables, Android assets, or source control.

The repository contains `src/services/supabase.ts` and a real email/phone/OTP/password-reset facade in `src/services/auth.ts`. The Phase 1 UI is deliberately not rebuilt; Phase 3 should call these service methods and replace preview data with Supabase repositories.

## Auth provider setup required in Supabase Dashboard

1. Configure production Site URL and exact web/deep-link redirect URLs.
2. Configure a production SMTP provider and sender domain for verification and password-reset messages. Keep email confirmations enabled.
3. For phone OTP, choose an SMS provider, add its credentials in Supabase Auth settings, and configure Egyptian phone-number delivery. Do not tell users phone sign-in is live until test OTPs arrive.
4. Create the first account via normal signup. Promote only the intended trusted account to `owner` through a controlled admin SQL/dashboard operation; never expose that capability to clients. Example, after verifying the account ID:
   `update public.profiles set role='owner' where id='<verified-auth-user-uuid>';`
5. Enroll students and assign their academic year/group/section as owner. Do not allow self-service placement changes.

Email/password, phone OTP, session refresh/persistence, email verification and reset operations are implemented by Supabase Auth. Provider delivery/production redirects are project-level configuration and must be completed before release.

## AI and knowledge base secrets

The functions read `GEMINI_API_KEY` only from Edge Function runtime secrets. Optional `GEMINI_CHAT_MODEL` can override the default `gemini-3.8-flash`. Do not place these in `.env`, Flutter, GitHub source, or the app bundle. Set the key in Supabase Dashboard → Edge Function Secrets, or from a trusted workstation with the Supabase CLI:

```sh
supabase secrets set --project-ref skpjvgzxoholaapymvwd GEMINI_API_KEY='YOUR_GEMINI_KEY'
```

The chat function uses Gemini for responses and Gemini Embedding 2 with 1536 dimensions for retrieval. The ingestion function uses the same embedding model and dimension. Existing course chunks created with a different embedding provider/model must be re-ingested before semantic retrieval is reliable. Keep the secret server-side only.

## AI endpoints

- `POST /functions/v1/ai-chat`: requires authenticated Supabase JWT; validates account, scope and input; charges an atomic daily quota (default 30/day); optionally embeds and retrieves up to six chunks for a supplied subject; calls Gemini; saves the user's own messages and sources. Send JSON `{ "question": "...", "subjectId": "<uuid>", "lectureId": "<uuid-or-null>", "conversationId": "<uuid-or-null>", "retrieve": true, "task": "chat|explain|summarize|quiz|flashcards|planner|pdf|analytics" }`.
- `POST /functions/v1/ingest-knowledge`: owner-only; takes `{ "documentId": "<uuid>" }`, downloads the private object, extracts PDF/TXT/DOCX text, cleans/chunks it, computes Gemini Embedding 2 vectors (1536 dimensions), stores source/page metadata and marks the document ready. Upload the file to `course-documents` and create its `knowledge_documents` row first. Scanned PDFs with no text layer require OCR before ingestion; the function rejects empty extraction and files exceeding 1 MB of extracted text / 800 chunks.

Both functions require JWT verification. Retrieval only returns chunks visible under the signed-in user's RLS scope.

## Useful queries

- Notification resync: read matching active schedule rows with `revision` and `updated_at`; keep the last sync watermark and refetch rows updated since it (including inactive/deleted rows needed to remove old reminders).
- Current app update: for platform, read enabled `app_versions` ordered by descending `build_number`, and `update_settings`.
- Academic year UI: read `academic_years.status` (`active`, `coming_soon`, `disabled`). Students only see active academic-year rows and scoped active content.
- Owner setup and content writes: use an authenticated Owner session; never rely on UI hiding instead of RLS.

## Apply changes later

Migrations live under `supabase/migrations/`. After reviewing a migration, apply it to the matching project ref with Supabase CLI (`supabase link --project-ref skpjvgzxoholaapymvwd` then `supabase db push`) or the approved Supabase deployment workflow. Edge Function sources are under `supabase/functions/`.
