# Whelbeing

A women's wellbeing and health app built with Flutter, featuring a dark gold luxury aesthetic. Backed by Supabase with an AI-powered health assistant.

## Features

- **Learn**: Curated educational articles across mental health, physical wellness, reproductive health, and sleep — with read history tracked locally
- **Home**: Personalised welcome dashboard with streak tracking and AI health assistant (symptom navigator, appointment prep, lab interpreter, care gap analysis)
- **Track**: Log and review health visits, lab results, and symptoms

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend**: Supabase (Postgres, Auth, Edge Functions)
- **State management**: Riverpod
- **Authentication**: Google Sign-In and Sign in with Apple
- **AI**: OpenAI GPT-4o via Supabase Edge Function (`supabase/functions/ai-chat/`)
- **Local persistence**: SharedPreferences (read history)

## Getting Started

```sh
# Install dependencies
flutter pub get

# Run against production Supabase
flutter run

# Run against a local Supabase instance
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<key from `supabase status`>

# Run tests
flutter test

# Static analysis
flutter analyze

# Start local Supabase (requires Docker)
supabase start
```

## Color Palette

| Role            | Hex       |
|-----------------|-----------|
| Primary gold    | `#C9A96E` |
| Dark gold       | `#6B5220` |
| Warm text/cream | `#E8DCC8` |
| Surface         | `#1A1A1A` |
| Background      | `#0D0D0D` |
| Border/divider  | `#2A2520` |
