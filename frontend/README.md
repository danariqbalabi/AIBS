# AIBS Flutter frontend

Flutter app prototype for the AIBS mobile experience. It includes onboarding,
home/profile, menu and shopping checklist, food-check flow, and symptom journal
screens. Data is sample/in-memory only; authentication, device camera, and
backend persistence are not connected yet.

## Design source of truth

Use [`AGENTS.md`](AGENTS.md) and [`docs/design/`](docs/design/) for all mobile
UI work. The Flutter tokens, reusable components, and SVG assets from the
`aibs-design-handoff` package are installed here under `lib/core/theme/`,
`lib/shared/widgets/`, and `assets/`.

The older `AIBS-design-system` package is not the current mobile design spec.
The existing screens are still a prototype and should be updated screen by
screen to match `docs/design/SCREENS.md`; the handoff does not include screen
implementations.

Nunito currently uses the existing `google_fonts` runtime loader. The handoff
specifies bundled static weights (600/700/800), which should be added before
offline or release use.

## Run

```powershell
flutter pub get
flutter run
```

## Verify

```powershell
flutter analyze
flutter test
```
