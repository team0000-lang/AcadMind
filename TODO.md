# AcadMind Phase 1 — Outcome TODO

- [ ] **Brand startup and app shell**
  - Display `AcadMind` centered, animate it into `AM`, keep the splash short, then route preview users to Login and existing authenticated users to Home when real auth is connected.
  - Use the AM identity consistently in app chrome, logo, and navigation.

- [ ] **Scalable frontend architecture**
  - Separate presentation, screens, widgets/render helpers, models/mock data, services, repositories, state, navigation, authentication contracts, notification contracts, local settings, and configuration.
  - Do not put the whole application in one Dart/HTML file and keep mock data outside production repository interfaces.

- [ ] **Bilingual and theme-ready experience**
  - Support Arabic RTL and English LTR across navigation, buttons, errors, settings, notifications, academic labels, authentication, profile, and empty states.
  - Support Light, Dark, and System theme choices and persist the selected choice locally.

- [ ] **Authentication and onboarding UI**
  - Provide Login, Register, phone number, OTP with timer/resend state, email verification, forgot password, reset password, password visibility, remember session, terms confirmation, and create-account navigation.
  - Do not pretend that a user is authenticated before Phase 2; preview mode must be visibly distinct.
  - Provide Academic Year, Group G1/G2, and Section Sec 1–Sec 6 selection. Only First Year is selectable initially; other years show Coming Soon.

- [ ] **Student home experience**
  - Show greeting, academic year, group, section, current date, next lecture, live countdown, today schedule, upcoming class, subjects/schedule/AI shortcuts, announcements, and academic motivation card without overloading the screen.

- [ ] **Subjects and lectures**
  - Show subject cards with subject name, icon, description, year, and status.
  - Show subject details with lectures, topics, notes, YouTube, Google Drive, and AI Assistant action.
  - Show lecture list/details with lecture title, number, topic, description, notes, resources, and videos.

- [ ] **Schedule and countdown**
  - Provide Today, Tomorrow, Weekly, and Upcoming views.
  - Schedule cards show subject, class type (Lecture/Section/Practical/Lab), start/end, location, and duration.
  - Countdown must advance to the next upcoming class after the current one ends.

- [ ] **Notification architecture**
  - Provide notification permission state, reminder settings, custom reminder time, duplicate prevention, rescheduling, and cancellation contracts.
  - Default reminder is 10 minutes before lecture and the architecture accepts future Supabase schedule data.

- [ ] **Profile, settings, and updates**
  - Profile shows name, email, phone, academic context, image placeholder, account information, edit profile, change password, and logout.
  - Settings includes language, theme, notification settings, reminder time, account, privacy, about, and app version.
  - Optional update offers Update Now/Later. Mandatory update blocks continuation and exposes version/release notes/Update Now.

- [ ] **Owner Panel UI**
  - Provide admin navigation and screens for dashboard, students, subjects, lectures, schedules, resources, announcements, app version, academic management, schedule management, resource management, AI management, announcements, and update management.
  - Do not implement backend authorization in Phase 1; preserve role-ready UI for Student, Owner, and future account types such as `حساب صيف` without inventing its functionality.

- [ ] **Resilience and offline preparation**
  - Major screens must have explicit loading, empty, error, and retry-ready render paths rather than blank screens.
  - Prepare cached/offline indicators for profile, schedule, subjects, and settings and distinguish cached data from live data.

- [ ] **Build and delivery**
  - The application must compile and run through the managed preview runtime.
  - Add a route manifest and keep the project ready for Phase 2 backend integration.
