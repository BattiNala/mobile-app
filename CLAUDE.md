# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on a connected device or emulator
flutter run --dart-define=GEMINI_API_KEY=<key>

# Override the backend URL (useful for local dev)
flutter run --dart-define=BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=GEMINI_API_KEY=<key>

# Analyze for lint issues
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/file_test.dart

# Regenerate launcher icons and splash screen
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Architecture

The app is a civic-issue reporting platform with two user roles: **citizen** (reports hazards) and **staff** (resolves them). It follows a **feature-first** structure under `lib/`, with two top-level namespaces:

- `lib/core/` — shared infrastructure used by all features
- `lib/features/` — self-contained feature modules

### State management

Riverpod `StateNotifier` + `Provider` throughout. Each feature exposes a `*NotifierProvider` that wraps a `*State` class. Widgets are `ConsumerWidget` or `ConsumerStatefulWidget`.

### Data flow

```
Consumer Widget → StateNotifier → Repository → DioClient → Backend API
                    ↑____________________________|
```

### Routing (`lib/core/router/app_router.dart`)

GoRouter with a `redirect` guard that enforces a three-step gate:
1. Onboarding (seen once, persisted via `shared_preferences`)
2. Authentication (JWT stored in `FlutterSecureStorage`)
3. Email verification (`/verify-otp`)

After all gates pass, the router redirects to `/citizen-dashboard` or `/staff-dashboard` based on `user.role`.

### Networking (`lib/core/networks/`)

- `DioClient` configures a single `Dio` instance with the base URL and headers.
- `AuthInterceptor` automatically attaches the Bearer token and handles silent token refresh on 401 responses, queuing concurrent requests during the refresh.
- Base URL priority: `--dart-define BASE_URL` → platform default → production (`https://backend.parakramk.com.np/api/v1`).

### AI image analysis (`lib/core/services/gemini_analyzer.dart`)

`GeminiAnalyzer.analyzeImage()` sends an infrastructure photo to `gemini-2.5-flash` with a fixed prompt from `lib/core/constants/prompt.dart`. It returns a `GeminiAnalyzerResult` with `issueType`, `priority`, `confidence`, and `description`. The API key is injected via `--dart-define GEMINI_API_KEY`.

### Token storage (`lib/core/services/storage_services.dart`)

`FlutterSecureStorage` holds `access_token`, `refresh_token`, `user_role`, and `is_verified`. On app start `AuthNotifier._loadUserFromStorage()` restores session state.

### Maps (`lib/features/staff-issue/`)

`MissionMapView` uses `flutter_map` (OpenStreetMap tiles) + `geolocator` for live GPS. Routing is fetched from the backend (`ApiUrl.shortestRoute`).

## Key conventions

- **Colors**: always use `AppColors` from `lib/core/constants/colors.dart`.
- **Models**: use `fromJson` factory constructors for all API-mapped entities.
- **Imports**: `always_use_package_imports` is enforced — use `package:batti_nala/…` not relative paths.
- **Quotes**: `prefer_single_quotes` is enforced.
- **`avoid_print`** is enforced — use `debugPrint` for development logging.
- Issue identification across the app uses `issueLabel` (a string slug), not a numeric ID.
- The `shared/issue/` sub-module holds `IssueModel`, `IssueTypeModel`, and `IssueRepository` — both `user-issue` and `staff-issue` depend on these; avoid duplicating them in feature-specific folders.
