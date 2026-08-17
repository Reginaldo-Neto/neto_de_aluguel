# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Neto de Aluguel** — A Flutter app connecting elderly users ("elders") with helpers for companionship, errands, and other services. Two-role system: `elder` and `helper`. UI and copy are in Brazilian Portuguese.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint
flutter test             # Run tests
flutter run              # Run app (requires device/emulator)
flutter build apk        # Android release build
flutter build ios        # iOS release build
```

## Supabase Configuration

The file `lib/config/supabase_config.dart` is gitignored. Copy the example file and fill in credentials:

```bash
cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart
```

The Supabase project has two main tables: `profiles` and `sessions`. Row Level Security is enforced. A `handle_new_user()` trigger auto-creates a profile row on signup.

## Architecture

**Pattern:** MVVM-like with Riverpod + Hooks.

**Layer responsibilities:**

| Layer | Location | Role |
|-------|----------|------|
| Services | `lib/services/` | Supabase auth/db calls, external integrations |
| Presenters | `lib/presenters/` | Riverpod Notifiers; business logic & state |
| Views | `lib/views/` | `HookConsumerWidget` screens; no business logic |
| Widgets | `lib/widgets/` | Reusable UI components |
| Models | `lib/models/` | Data classes + enums + mock helpers |

**State management:**
- `Notifier` / `NotifierProvider` for persistent app state (auth, home list, login form)
- `FutureProvider` for async data (sessions)
- `flutter_hooks` (`HookConsumerWidget`) for local widget state (controllers, form keys)

**Navigation:** GoRouter (`lib/app.dart`). Auth redirect: unauthenticated → `/login`; authenticated trying `/login` → `/home`. Routes: `/login`, `/home`, `/session/:helperId`, `/video-call/:sessionId`.

**Dual-role UI:** `home_view.dart` renders `_ElderHome` or `_HelperHome` based on `user.role`. Role is determined at login and stored in the presenter.

**Incomplete integrations (mocked):**
- Video calls: Daily.co (`lib/services/video_service.dart`)
- Notifications: OneSignal + SMTP (`lib/services/notification_service.dart`)
