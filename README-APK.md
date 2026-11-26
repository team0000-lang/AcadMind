# AcadMind — Phase 1 app + Phase 2 backend

This repository contains the existing AcadMind interface wrapped with Capacitor for Android, plus its Phase 2 Supabase backend. The interface has not been unnecessarily rebuilt. The backend project is an independent Supabase project in Frankfurt.

## Configure frontend Supabase client

```bash
cp .env.example .env.local
pnpm install
pnpm build
```

`.env.example` contains only the Supabase URL and a publishable client key. Never place an AI provider key, service-role key, or database password in Vite variables or Android assets.

## Backend files

- Database migrations: `supabase/migrations/`
- Edge Functions: `supabase/functions/ai-chat` and `supabase/functions/ingest-knowledge`
- Backend setup, Auth provider steps, RLS model, AI secrets and Phase 3 integration notes: [`supabase/README.md`](supabase/README.md)

Real Supabase Auth methods are exposed in `src/services/auth.ts`; Phase 3 should connect them to the existing login/register/phone UI and replace the preview repositories with scoped Supabase queries. Configure production SMTP and an SMS provider in Supabase Auth before production sign-in.

## Android debug APK

```bash
pnpm exec cap sync android
cd android
./gradlew assembleDebug
```

The generated debug APK will be at `android/app/build/outputs/apk/debug/app-debug.apk`. A signed release APK/AAB requires an Android signing key and CI secrets.
