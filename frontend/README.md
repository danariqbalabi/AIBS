# AIBS Flutter frontend

Flutter app prototype for the AIBS mobile experience. It includes onboarding,
home/profile, menu and shopping checklist, food-check flow, and symptom journal
screens. Data is sample/in-memory only; authentication, device camera, and
backend persistence are not connected yet.

## Design source of truth

Use [`AGENTS.md`](AGENTS.md) and [`docs/design/`](docs/design/) for all mobile
UI work. The current handoff lives in this `frontend/` project: design docs are
under `docs/design/`, tokens and theme under `lib/core/theme/`, reusable
widgets under `lib/shared/widgets/`, and SVG assets under `assets/`.

The screens are still a prototype and should be updated screen by screen to
match `docs/design/SCREENS.md`.

Nunito is bundled locally as a variable font and licensed under the SIL Open
Font License in `assets/fonts/OFL.txt`. The theme maps its 600, 700, and 800
styles to the variable font's `wght` axis, so rendering does not require a
network connection.

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
