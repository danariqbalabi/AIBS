# AIBS motion spec

**The hi-fi prototype is static.** It has no animations. Everything below is a small default set so the app feels consistent; it's a proposal, not something copied from the prototype. Keep motion quiet: the app is about trust, not delight. Durations and curves live in `AibsMotion` (`aibs_tokens.dart`).

**Curves:**

| Name | Flutter | Use |
|---|---|---|
| standard | `Curves.easeOutCubic` | Most enters and changes |
| emphasized | `Cubic(0.2, 0, 0, 1)` | Sheets, result cards |
| exit | `Curves.easeInCubic` | Things leaving |

No animation package is needed (no Lottie, no Rive).

## A. Everywhere

| # | Name | Trigger | Spec |
|---|---|---|---|
| A1 | Screen change | Push / pop | Fade + slide up 12 px, **240 ms**, standard. Tab switches: fade only, 160 ms. |
| A2 | Press | Pointer down on buttons, option cards, chips, rows | Scale to **0.97**, 90 ms; release back 120 ms. No Material ripple (theme sets `NoSplash`). |
| A3 | Selection | Chip / radio / scale dot selected | Fill color cross-fade **150 ms**. Scale dot grows 44 → 54, 180 ms emphasized. |
| A4 | Sheet | F0, M6, J7 | Slide up from bottom + scrim fade to 45%, **280 ms** emphasized. Close 200 ms exit. Drag down to dismiss. |
| A5 | Dialog | J6h, P3 | Fade + scale 0.96 → 1, 200 ms. |

## B. Onboarding

| # | Name | Spec |
|---|---|---|
| B1 | 1-tap advance | Tapped option card shows the pressed state (A2) and a primary 2 px border for **150 ms**, then the next question pushes (A1). This confirms the tap before the page changes. |
| B2 | Progress | `StepProgress` fill animates to the new width, 300 ms standard. |

## C. Results and states

| # | Name | Spec |
|---|---|---|
| C1 | Verdict card | On F6 / B6 enter: card fades + slides up 16 px, 320 ms emphasized; koala follows 80 ms later. |
| C2 | Processing | F3 koala: gentle bob, translateY 0 → −4 → 0, 1.6 s loop, easeInOut. Stops when the result arrives. |
| C3 | Saved | F7 koala scales 0.9 → 1, 260 ms emphasized. Toasts after J4/J5 save slide up 8 px + fade, show 2 s. |
| C4 | Koala prompt dismiss | H1 "Nggak ada": card fades + collapses height, 220 ms. |

## D. Reduced motion

When `MediaQuery.disableAnimationsOf(context)` is true:
- All transitions become a 120 ms fade, no slide or scale.
- C2 bob stops (static koala).
- B1 advances immediately.
