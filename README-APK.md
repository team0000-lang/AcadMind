# AcadMind APK

This repository contains the AcadMind Phase 1 interface wrapped with Capacitor for Android.

## Build APK on GitHub

1. Extract this ZIP and upload all files inside it to a new GitHub repository.
2. Open the repository's **Actions** tab.
3. Select **Build AcadMind APK**.
4. Click **Run workflow** or push to `main`.
5. When the workflow finishes, open the workflow run and download the artifact named `acadmind-debug-apk`.
6. Extract the artifact and install `app-debug.apk` on an Android phone.

This is a debug APK for testing. A signed release APK/AAB requires an Android signing key and GitHub Secrets.

## Local commands

```bash
pnpm install
pnpm build
pnpm exec cap sync android
cd android
./gradlew assembleDebug
```

The generated debug APK will be at:

`android/app/build/outputs/apk/debug/app-debug.apk`

## Important

The Phase 1 authentication is intentionally preview-only. Supabase authentication, real notifications, and backend data are planned for Phase 2.
