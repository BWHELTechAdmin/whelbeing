# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Commands

```sh
# Install dependencies
flutter pub get

# Run the app (production Supabase — values in supabase_config.dart defaults)
flutter run

# Run the app against a local Supabase instance
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<key from `supabase status`>

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Static analysis / lint
flutter analyze

# Start local Supabase (Docker required)
supabase start

# Push migrations to the linked remote project
supabase db push
```

## Architecture

Whelbeing is a Flutter women's wellbeing app with a dark gold luxury theme (`#C9A96E` gold on `#0D0D0D` near-black). The README mentions a lavender theme but the actual implementation uses the dark gold palette.

### Navigation

`lib/main.dart` hosts `MainNavigation`, a `StatefulWidget` with a `BottomNavigationBar` and a fixed list of **three** screen widgets at indices 0–2:

| Index | Label | Screen        |
|-------|-------|---------------|
| 0     | Learn | `LearnScreen` |
| 1     | Home  | `HomeScreen`  |
| 2     | Track | `TrackScreen` |

The app starts on index 1 (Home). Before `MainNavigation` is shown, `_AppEntry` routes unauthenticated or un-onboarded users to `HealthProfileOnboarding`. Sub-screens are pushed imperatively via `Navigator.of(context).push(MaterialPageRoute(...))` — there is no named-route or go_router setup.

### Authentication & Onboarding

Auth is handled by Supabase (`supabase_flutter`). Supported sign-in methods: Google and Apple (see `lib/screens/sign_in_screen.dart`). Credentials are passed at build time via `--dart-define`; defaults live in `lib/config/supabase_config.dart`.

`_AppEntry` (in `main.dart`) watches `isAuthenticatedProvider` and `hasCompletedOnboardingProvider` (Riverpod) to decide whether to show `HealthProfileOnboarding` or `MainNavigation`. The onboarding-complete flag is stored in Supabase user metadata.

### State Management — Riverpod

The app uses `flutter_riverpod`. The entry point is wrapped in `ProviderScope`. Providers live in `lib/providers/`:

- `auth_provider.dart` — `supabaseClientProvider`, `authStateChangesProvider`, `currentSessionProvider`, `isAuthenticatedProvider`, `currentUserProvider`, `hasCompletedOnboardingProvider`
- `user_provider.dart` — `currentUserModelProvider` (fetches `public.users` row)
- `health_record_provider.dart` — `healthRecordsProvider` (AsyncNotifier), `healthRecordCountProvider`, `streakProvider`
- `ai_conversation_provider.dart` — `aiConversationsProvider` (paginated AsyncNotifier with `loadMore()`)
- `onboarding_provider.dart` — local session flag `onboardingCompleteProvider`
- `sign_in_provider.dart` — sign-in state

### Backend — Supabase

Migrations live in `supabase/migrations/`. Current tables:

- `public.users` — profile data (first/last name, date of birth)
- `public.health_records` — user health visits, labs, symptom logs
- `public.profiles` — extended profile / onboarding answers
- `public.user_activity_streak` — daily app-open tracking; `get_streak()` RPC computes consecutive-day streaks
- `public.ai_conversations` — persisted AI chat sessions (JSONB messages column)

Edge Functions live in `supabase/functions/ai-chat/`. `AiService` (`lib/services/ai_service.dart`) calls this function, which proxies to **OpenAI GPT-4o**. The `OPENAI_API_KEY` secret is read from `supabase/functions/.env` locally and must be set via `supabase secrets set OPENAI_API_KEY=...` for remote deployment. The four AI modes are `symptom_navigator`, `appointment_prep`, `lab_interpreter`, and `care_gap`.

### Repositories

Repositories in `lib/repositories/` encapsulate all data access:

- `auth_repository.dart` — sign-in/out, `recordAppOpen`, `markOnboardingComplete`
- `user_repository.dart` — fetch/upsert `public.users`
- `profile_repository.dart` — fetch/upsert `public.profiles`
- `health_record_repository.dart` — CRUD on `public.health_records`
- `ai_conversation_repository.dart` — paginated fetch + upsert of `public.ai_conversations`
- `reads_repository.dart` — **local** read history via SharedPreferences; exposes `previousReadsNotifier` (global `ValueNotifier<List<Article>>`), `init()` (idempotent load), and `recordRead(article)` (deduplicates by UUID, updates notifier synchronously then persists)

### Data Models

- `lib/models/article.dart` — `Article` (id: UUID, title, description, readTime, category, icon, color). All 12 static learn articles are defined in `lib/data/articles_data.dart` with hardcoded UUIDs; `articlesById` map and `articlesForCategory()` helper are the single source of truth used by both `LearnScreen` and `CategoryDetailScreen`.
- `lib/models/user_model.dart` — `UserModel` (mirrors `public.users` + auth email; helpers: `displayFirstName`, `displayName`, `memberSince`)
- `lib/models/health_record_model.dart` — `HealthRecordModel` with `HealthRecordType` and `HealthRecordStatus` enums
- `lib/models/ai_conversation.dart` — `AiConversation` + `ChatMessage`
- `lib/models/thread.dart` — `CommunityThread` + `Reply` (in-memory only; no backend)

### Responsive Sizing — `SizeConfig`

`lib/utils/size_config.dart` exposes `SizeConfig.vh` (1% of screen height) and `SizeConfig.vw` (1% of screen width). **Every `build` method that uses these must call `SizeConfig.init(context)` at the top.** Dimensions throughout the codebase are expressed as multiples of `vh`/`vw` (e.g. `EdgeInsets.all(4.0 * vw)`) rather than fixed pixel values.

### Shared Widgets

`lib/widgets/gold_shimmer.dart` provides two reusable components used on hero sections across screens:
- `GoldShimmer` — wraps any widget in an animated gold shimmer via `ShaderMask`.
- `GoldShimmerContainer` — a self-contained container with a warm gold-to-black gradient background and a subtle shimmer sweep painted via `CustomPainter`. Used for profile headers, community stats, and the home welcome card.

### Key Color Constants

These are used inline (not in a centralized theme file) throughout the codebase:

| Role            | Hex       |
|-----------------|-----------|
| Primary gold    | `#C9A96E` |
| Dark gold       | `#6B5220` |
| Warm text/cream | `#E8DCC8` |
| Surface         | `#1A1A1A` |
| Background      | `#0D0D0D` |
| Border/divider  | `#2A2520` |
