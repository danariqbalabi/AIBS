# AIBS Flutter frontend

Flutter prototype for the AIBS mobile experience. The handoff's primary
onboarding, Today, menu/shopping, food check, journal, summary, and profile
flows are represented with demo UI and in-memory state. Restarting the app
clears session data.

## Design source of truth

Use [`AGENTS.md`](AGENTS.md) and [`docs/design/`](docs/design/) for all mobile
UI work. The current handoff lives in this `frontend/` project: design docs are
under `docs/design/`, tokens and theme under `lib/core/theme/`, reusable
widgets under `lib/shared/widgets/`, and SVG assets under `assets/`.

`docs/design/SCREENS.md` and `docs/design/DATA.md` describe the screen and
data-behavior source of truth. Nunito is bundled locally for offline rendering.

## Prototype boundaries

- Sign-in/code entry and profile data are local-only; there is no authentication
  or backend persistence.
- Food assessment and screening require backend-owned logic. The prototype does
  not calculate diagnoses or claim food is absolutely safe.
- Camera/gallery capture, AI photo analysis, and AI story extraction are not
  connected. Photo and story flows are demonstrations; story text is saved as
  entered.
- Privacy export copies the available profile fields to the clipboard.
  Photo-retention preferences are UI state only because photo storage is not
  implemented.
- Demo menu/catalog and summary data are illustrative, not medical guidance.

## Run

```powershell
flutter pub get
flutter run
```

## Verify

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
