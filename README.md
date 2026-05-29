# BattiNala

An app built with Flutter for reporting and managing civic infrastructure issues.

## What This Project Does

- Lets users report infrastructure issues from a mobile app
- Uses Flutter for the UI and app logic
- Supports compile-time configuration for API keys and backend URL

## Prerequisites

- Flutter SDK 3.9.2+
- Android Studio or Xcode for device or emulator runs
- A valid `GEMINI_API_KEY`

## Use Locally

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key
```

If you need a custom backend URL, pass `BASE_URL` too:

```bash
flutter run --dart-define=BASE_URL=your_backend_url --dart-define=GEMINI_API_KEY=your_gemini_api_key
```

## Support

- Review the code for setup details if something is unclear

## Contribution

- For feature work, open a pull request
- Keep changes small and focused
- Include a clear description of the feature or fix
- Add screenshots or short notes when the change affects the UI

## Notes

- Keep API keys out of git.
- Pass `BASE_URL` or `GEMINI_API_KEY` with `--dart-define` when needed.
