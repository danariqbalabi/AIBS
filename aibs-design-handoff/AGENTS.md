# AGENTS.md: AIBS (Flutter)

Instructions for AI coding assistants (Codex, Claude, Cursor) working in this repo.

## Before any UI work

Read these first. They are the source of truth for the UI and come from the final hi-fi prototype:

1. `docs/design/DESIGN.md`: principles, tokens, components, copy.
2. `docs/design/SCREENS.md`: every screen's layout and the navigation map.
3. `docs/design/MOTION.md`: transitions and press feedback.
4. `docs/design/DATA.md`: demo data and app rules (screening, red flags, check status, UI states).

**Visual reference:**

- The hi-fi canvas: https://claude.ai/artifact/EYzZH9vbkSWH2iHhCkrcKr (each artboard is a 390 × 844 screen, named by its ID, e.g. `H1 · Hari Ini`).
- Screenshots the team attaches to the prompt.

When existing UI code disagrees with these docs, **the docs win**.

## Rules

- **Tokens only.** Colors, sizes, radii, shadows, and durations come from `lib/core/theme/aibs_tokens.dart` (`AibsColors`, `AibsSpace`, `AibsRadius`, `AibsShadows`, `AibsType`, `AibsMotion`). No hex literals or magic numbers in widgets.
- **Theme:** `lib/core/theme/aibs_theme.dart` (`AibsTheme.light`).
- **Font:** Nunito, bundled as an asset (600/700/800).
- **Reuse the provided elements:**
  - `StatusBadge` for every food-check status. Never invent a new status color.
  - `Koala` and `KoalaBubble` for the mascot.
  - `StepProgress` for the onboarding progress bar.
  - SVGs in `assets/brand/`, `assets/icons/`, `assets/illustrations/` (render with `flutter_svg`).
- **Blue is the brand, green only means "Sesuai".** Status colors (ok / warn / bad / unknown) are only for check results, always with their symbol (✓ ! × ?).
- **Don't build** the phone frame from the prototype. Use `SafeArea`.
- **Overlays are not routes.** The camera choice sheet (F0), Jadwalkan (M6), delete dialog (J6h), and draft dialog (J7) are bottom sheets / dialogs over their parent screen.
- **AI calls go through the backend** (FastAPI). The app never calls Gemini directly and never sends a photo or story when the user picked "Tanpa AI" (A3 / P4).
- **Health copy:** never diagnose, never say a food "caused" a symptom, never label food as absolutely "aman". Patterns always carry "Belum tentu penyebab". Use the exact strings from DESIGN.md §5.
- **Minimal text.** No helper subtitles, no notes about how the system works. If a screen needs explaining, fix the layout.
- **Every state exists.** Each data screen needs its empty, loading, needs-confirmation, failed, and saved states (DATA.md §State).

## Quality

```
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Commit only after these pass. Work on one branch per feature.
