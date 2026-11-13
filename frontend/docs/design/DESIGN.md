# AIBS design system

This is the single source of truth for how AIBS looks. Every value here comes from the final hi-fi canvas (https://claude.ai/artifact/EYzZH9vbkSWH2iHhCkrcKr). Read it next to:

- `SCREENS.md`: layout of every screen.
- `MOTION.md`: transitions and press feedback.
- `DATA.md`: demo data and app logic.

Tokens live in `lib/core/theme/aibs_tokens.dart`. Widgets read from there and never hardcode hex values or sizes.

## 1. Product in one paragraph

AIBS (AI for IBS, Irritable Bowel Syndrome) helps adults with IBS pick food that fits **their doctor's diet advice** and log symptoms with as little effort as possible. The main question the app answers is **"mau makan apa?"**. The core loops:

1. **Pick:** Hari Ini shows menus that fit the user's diet profile → detail → Jadwalkan or Sudah dimakan.
2. **Check:** camera → "Cek sebelum makan" or "Sudah dimakan" → AI reads the photo → user confirms ingredients → result status → log.
3. **Log symptoms:** a koala prompt on Hari Ini, or the Jurnal tab → symptom, scale 1–5, time, stress → linked to the food before it.
4. **See patterns:** factual counts over 7 or 30 days ("Kembung 3x · 2x setelah bawang putih") plus a summary for the doctor.

The app **never diagnoses** and **never decides a trigger**. It only says whether a food fits the advice the user entered.

## 2. Design principles

1. **Every element has a purpose.** No header card that only holds a greeting, no decorative card. The screen's main question sits at the top.
2. **Minimal text.** No helper subtitles, no notes about how the system works. If a screen needs explaining, fix the layout. A small disclaimer and the small "Belum tentu penyebab" stay.
3. **Group related things.** A "Lihat semua" link is the **last card inside the slider**, not on the title line and not under the slider.
4. **The user's choice is bolder than its category.** Category = small `caption` in ink-muted; the chosen value = bold, bigger.
5. **One question per page in onboarding, 1 tap when possible.** A single-answer question is a list of big option cards; tapping one goes straight to the next page. Multi-select uses chips + a "Lanjut" button.
6. **Blue is the brand and means safe.** Green only means the "Sesuai" status. Status colors are never decoration.
7. **The mascot has a role or it's not there.** The koala asks a question (speech bubble), shows a mood on a result, or fills an empty state. At most one koala per screen. Text next to it never rises above the tips of its ears.
8. **Iconic actions get no label.** The camera button in the middle of the tab bar has no text.
9. **Soft gradients, bold color, whitespace.** Gradients only on primary buttons, the camera button, and hero cards, always one direction (sky → primary).

## 3. Foundations

### Color

| Token | Hex | Use |
|---|---|---|
| primary | #2F6FED | Brand. Selected chips, progress fill, active states |
| primaryStrong | #1F55C8 | Links, end of the button gradient, text on primarySoft |
| primaryLight | #3B7BF5 | Start of the button gradient |
| sky | #78AAFF | Light end of brand gradients, focus ring. Never text |
| primarySoft | #E8F0FE | Soft button, active nav pill, koala prompt card, info cards |
| primaryTint | #DCE8FF | Text on gradient buttons (secondary line), background glow |
| surface | #F5F8FF | Page background |
| card | #FFFFFF | Cards, sheets, inputs, option cards |
| ink | #14233F | Main text |
| inkMuted | #5B6A85 | Secondary text, category labels, inactive nav |
| line | #E1E8F4 | Dividers, ghost-button and chip borders, empty progress |
| ok / okInk / okSoft | #22A06B / #11774A / #E3F6EC | Status **Sesuai** only |
| warn / warnInk / warnSoft | #F5A524 / #8A5300 / #FFF3DC | Status **Perlu hati-hati** |
| bad / badInk / badSoft | #E5534B / #B02B24 / #FDE8E6 | Status **Tidak sesuai arahan**, destructive actions (Hapus, Telepon 119) |
| unknown / unknownSoft | #9AA5B8 / #EEF1F6 | Status **Belum bisa dinilai**, "Belum jelas" items, empty day dots |
| scrim | #14233F @45% | Behind sheets and dialogs |

Status text uses the `-Ink` variant on its `-Soft` background or on white. Status always comes with its symbol: ✓ Sesuai, ! Perlu hati-hati, × Tidak sesuai, ? Belum bisa dinilai.

**Symptom day dots** (Hari Ini strip, Ringkasan): no symptom = unknownSoft, scale 1–2 = sky with ink number, scale 3+ = primary with white number. Today has a 3 px white ring + 2 px primary ring.

### Type

The font is **Nunito**, weights 600, 700, 800. Counts and times use tabular figures.

| Style | Size / line | Weight | Where |
|---|---|---|---|
| display | 32/38 | 800 | Welcome title "Makan tenang, perut senang" |
| title | 28/34 | 800 | Every screen's main question/heading (h1) |
| titleDetail | 26/32 | 800 | Detail screen names (menu, record), Bantuan heading |
| sheetTitle | 22/28 | 800 | Sheet and dialog titles |
| verdict | 20/26 | 800 | Result headline next to the koala, top-bar title |
| option | 17/22 | 800 | Option cards, primary button label, bubble text (16) |
| button | 16/22 | 800 | Buttons, row values |
| body | 15/22 | 600–800 | Body, list item names (800) |
| sectionTitle | 16/22 | 800 | Section headings ("Bahan", "Hari ini") |
| label | 14/20 | 800 | Chips, links, step counter "1 dari 5" (primaryStrong) |
| caption | 13/18 | 700 | Secondary lines, field labels, group headers |
| small | 12/16 | 700–800 | Category labels above values, status badges, day letters |
| micro | 11/14 | 700 | Tab labels, "Belum tentu penyebab", disclaimer |

The greeting "Hai, Nadia" is 15/800 in primaryStrong, sitting 2 px above the title.

### Spacing and radius

- **Spacing scale:** 2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28.
- **Screen side padding:** 20.
- **Top bar:** padding 16 / 20 / 8. Content below it starts at padding-top 24.
- **Gap between sections:** 20–24. Gap between option cards: 10. Gap between cards in a list: 10–12.
- **Bottom action area:** padding 12 / 20 / 24, pinned.

| Radius | Value | Where |
|---|---|---|
| xs | 12 | Stepper buttons, koala prompt buttons, icon squares |
| sm | 14 | Back button, small inner buttons |
| md | 16 | Thumbnails (72), OTP boxes, Jadwalkan chips, stat tiles |
| bubble | 18 | Input, koala bubble (`18 18 18 6`, tail bottom-left) |
| lg | 20 | Cards, option cards, buttons |
| xl | 24 | Big choice cards (A3, A1d, F0), result hero cards |
| xxl | 28 | Sheets (top corners), tab bar (top corners), verdict card |
| pill | 999 | Chips, badges, progress |

### Elevation

There is basically **one shadow**.

| Name | Value | Where |
|---|---|---|
| card | `0 8 24 primary@10%` | Every white card, option card, back button |
| glow | `0 10 24 primary@30%` | Primary gradient buttons, gradient choice cards |
| camera | `0 10 24 primary@35%` + 6 px surface ring | Camera button |
| bar | `0 -6 24 primary@8%` | Tab bar and pinned bottom action areas on white |
| danger | `0 10 24 bad@25%` | Red buttons |

### Gradients

| Name | Value | Where |
|---|---|---|
| brand | 135°, #3B7BF5 → #1F55C8 | Primary buttons, camera button, selected scale dot |
| brandCard | 140°, #3B7BF5 → #1F55C8 | "Pakai AI" choice card, F0 primary option |
| hero | 140°, #E8F0FE → #C9DCFF | B6 result card |
| glow | radial, #DCE8FF → #E8F0FE → transparent | Top of Hari Ini and Welcome, behind content |
| food | 140°, light → mid (blue #E8F0FE→#B9D2FF, pink #FFEFF3→#FFC9D7, grey #EEF1F6→#CDD5E3) | Food photo placeholders |

## 4. Components

All measurements are logical px at a 390-wide screen.

### Top bar
- Row: back button 44 | flex middle | optional right link. Gap 14, padding 16 / 20 / 8.
- **Middle:** either `StepProgress` (onboarding), a title (20/800), or empty.
- **Right link:** "Nanti" or "Lewati", label 14/800, primaryStrong, min height 44.

### Back button
- 44 × 44, radius 14, white, shadow card, ink chevron 22 (stroke 2.2). On photo screens (F1–F2) it's a close/back icon in white on a translucent dark circle.

### Step progress (`lib/shared/widgets/step_progress.dart`)
- One bar, height 8, radius 4, track line, fill primary. Width = step / total. Total is 14 (B1–B5 = 1–5, C1–C9 = 6–14).
- Semantics: "Langkah X dari 14".

### Option card (1 tap)
- Full-width white card, min height 60, radius 20, padding 12 / 20, shadow card.
- Label option 17/800. Optional second line 13/700 inkMuted. Optional leading icon (e.g. chili row on C8).
- Tapping saves the answer and goes to the next page. No radio, no "Lanjut".

### Choice card (big)
- Used on A3 (AI or not), A1d (demo profile), F0 (camera purpose).
- Radius 24, padding 16–18, icon square 52 radius 16, title 18/800, sub 13/700.
- Primary choice = brandCard gradient, white text, sub in primaryTint, icon square white@20%. Other = white or surface.

### Chips (multi-select)
- Pill, min height 44, padding 0 16, label 15.
- Off: white, 2 px line border, ink 700.
- On: primary fill, white 800, prefixed with "✓".
- "Tambah" / "Lainnya" chip: dashed 2 px sky border, primaryStrong 800, "+" prefix.
- Filter chips in Menu are 38 high, label 14/800; the active budget filter is primarySoft + primaryStrong.

### Buttons

| Variant | Fill | Text | Height | Use |
|---|---|---|---|---|
| primary | brand gradient + glow | white | 56 | Main action of the screen, always one |
| soft | primarySoft | primaryStrong | 56 (44 inside cards) | Second action next to primary (Jadwalkan, Edit), actions inside the koala card |
| ghost | white + 2 px line | ink | 56 | Secondary ("Mulai catat aja", "Batal") |
| danger | bad + danger shadow | white | 56 | "Hapus", "Telepon 119" |
| link | none | primaryStrong 14–15/800 | ≥ 44 | Tertiary ("Ubah jawaban", "Isi manual", "Nggak ada alergi"); destructive links in badInk |

- Radius 20, label 16–17/800. Two buttons side by side use a 10 gap; when one is primary, it gets the wider column (1 : 1.3–1.4).
- Press: see MOTION.md §A2. No Material ripple.

### Tab bar
- Height 84, white, top radius 28, shadow bar. 5 equal columns: **Hari Ini · Menu · (camera) · Jurnal · Profil**.
- Tab: icon 22 (stroke 2) over micro label. Active = primaryStrong 800 on a primarySoft pill (radius 16, padding 8 / 10). Inactive = inkMuted 700.
- **Camera button:** 60 circle, brand gradient, white camera icon 26, camera shadow with 6 px surface ring, sticks up 34 above the bar. No label (semantics label "Foto makanan"). Opens the F0 sheet from any tab.

### Koala (`lib/shared/widgets/koala.dart`)
- **Moods:**
  - `senang`: Welcome, Hari Ini prompt, B6 result, Tersimpan, empty Hari Ini.
  - `mikir`: photo processing, B1x, empty Jurnal, not enough data, H1p diet prompt.
  - `khawatir`: result "Tidak sesuai arahan", B6b Bantuan. Calm, never dramatic.
- **Sizes:** bubble 84–96, verdict card 140–150, hero/empty 170–200, welcome 230.
- Never add shadows or recolor it.

### Koala bubble
- Row aligned to the bottom: koala (84–96, margin-left −6) + bubble.
- Bubble: white, radius `18 18 18 6`, padding 12 / 14, shadow `0 6 16 primary@10%`, margin-bottom 14–16 so the text stays below the ear tips. Text 15–16/800.
- Usually inside a primarySoft card (radius 20, padding 12 / 16 / 16) with its actions under it (2 equal buttons 44 high, radius 14: white "Nggak ada" + gradient "Catat").

### Verdict card (hero result)
- Radius 24–28, min height 140–150, padding-left 144–150, text bottom-aligned (`justify-content: flex-end`), overflow hidden.
- Koala absolute bottom-left (left −4…4, bottom −6…−8), size 140–150.
- Text: small label above (13/800) + headline 20/800 on one or two short lines. The headline must not rise above the koala's ears; shorten the copy rather than shrink the koala.
- Background by status: badSoft (F6), hero gradient (B6), okSoft / warnSoft as needed.

### Status badge (`lib/shared/widgets/status_badge.dart`)
- Pill, padding 3 / 10, 12/800, `-Ink` text on `-Soft` fill, symbol first ("✓ Sesuai").
- **Group header instead of badges:** in a list grouped by status (Menu M1), the group header carries the status (10 px dot + 13/800 in the status ink) and the rows don't repeat the badge.

### Menu card
- **Slider card (Hari Ini):** width 176, radius 20, image 104 high (food gradient + bowl illustration 56), body padding 12 / 14 / 14: name 15/800, "Beli · Rp22.000" 12/700 muted, status badge.
- **"Lihat semua" card:** last item of the slider, width 120, primarySoft, white 48 circle with arrow, label 14/800 primaryStrong.
- **List row (Menu):** white, radius 20, padding 10, thumb 72 radius 16, name 15/800, meta 12/700 muted ("Beli · Rp22.000 · tanpa bawang").

### Rows
- **Setting/summary row:** min height 64–68, divider line, category 12/700 muted above value 16/800, chevron 18 muted. Used on P1, C10, P4.
- **Ingredient row:** min height 48, name 15/800, amount 13/700 muted on the right. On check screens a 24 status circle leads the row (✓ ok / × bad / ? unknown).
- **Log row:** time 13/800 muted (48 wide) | name 15/800 + optional sub.
- **"Belum jelas" row:** 2 px dashed unknown border, unknownSoft fill, radius 20, "?" circle 28–32, opens clarification.

### Scale 1–5 (symptom)
- 5 circles on a 4 px line track. Off = 44 white with 2 px line border, number 16/800 muted. On = 54 brand gradient, white 20/800, 5 px surface ring + glow.
- Under it a primarySoft card shows "2 · Ringan" (16/800) + the meaning (13/700).

### Stepper
- Row: name 16/800 | "−" 40 square radius 12 primarySoft | value 15/800 (min width 72, centered) | "+". Used for porsi limits (C4, P2).

### Sheet
- White, top radius 28, padding 12 / 20 / 28, gap 14, grab handle 40 × 5 line. Title 22/800 with a close button on the right.
- Over a scrim (ink 45%). The parent screen stays visible behind.

### Dialog
- White, radius 28, inset 24 from the sides, vertically centered, padding 24 / 20 / 20. Title 22/800 centered, context line 15/700 muted, then stacked buttons (danger/primary first).

### Inputs
- Min height 56, white, 2 px border (line at rest, primary on focus), radius 18, padding 0 18, value 17/800.
- Field label 13/800 muted, 8 above. OTP: 6 boxes, 60 high, radius 16, value 26/800, active box has a 2 px primary border and caret.

## 5. Copy and voice

Casual Indonesian ("kamu"), short. Buttons are verbs. Never diagnose, never blame a food.

| Where | Copy |
|---|---|
| Welcome | "AIBS" · "Makan tenang, perut senang" · "Pilih makan sesuai arahan dokter, catat gejala dengan mudah." · "Coba Demo" · "Masuk" · "Bukan pengganti saran dokter." |
| Masuk | "Masuk ke AIBS" · "Email" · "Kirim kode" · "Masukkan kode" · "Kirim ulang kode" |
| Izin AI | "Pakai bantuan AI?" · "Pakai AI" / "Foto dan cerita dirapikan otomatis" · "Tanpa AI" / "Semua diisi manual" · "Bisa diubah kapan saja di Profil › Privasi." |
| Riwayat keluhan | "Berapa usia kamu?" · "Pernah didiagnosis IBS oleh dokter?" · "Punya arahan makan dari dokter atau ahli gizi?" · "Sekarang lagi sakit perut hebat yang nggak reda?" · "3 bulan terakhir, berapa hari per bulan perutmu sakit?" · answers "Ya" / "Tidak" / "Tidak tahu" · top link "Nanti" |
| Hasil | "Hasil pengecekan awal" · "Polanya cocok dengan kriteria IBS" · "Bukan diagnosis. Pastikan ke dokter." · "Ubah jawaban" · "Isi arahan diet" · "Mulai catat aja" |
| Bantuan | "Periksa ke dokter dulu, ya" · "Sakit hebat atau nggak reda?" / "Langsung ke IGD terdekat" · "Hubungi dokter atau faskes" · "Bawa ringkasan keluhanmu" · "Telepon 119" · "Lihat ringkasan keluhan" |
| Profil diet | "Arahan makan apa yang kamu ikuti?" · "Low FODMAP fase apa?" · "Bahan apa yang dihindari?" · "Ada batas porsi?" · "Punya alergi makanan?" / "Nggak ada alergi" · "Ada yang bikin perutmu nggak nyaman?" · "Budget sekali makan?" · "Suka pedas?" · "Ada preferensi lain?" · "Udah bener?" · "Simpan profil" · "Lanjut" · "Lewati" |
| Hari Ini | "Hai, Nadia" · "Mau makan siang apa?" (meal follows the time of day) · "Lihat semua" · "Nanti malam" · "Ada keluhan setelah makan pagi tadi?" · "Nggak ada" / "Catat" · "7 hari terakhir" · "4 hari ada gejala" · "Baca pola" / "Lihat riwayat" |
| Hari Ini (no diet profile) | "Mau catat apa hari ini?" · "Isi arahan dietmu biar aku bisa kasih rekomendasi menu." · "Isi arahan diet" |
| Menu | "Menu" · "Semua" / "Beli" / "Masak" · "Sesuai arahanmu" / "Perlu hati-hati" / "Tidak sesuai arahan" · "Cara pesan" · "Bahan" · "Masukkan ke checklist belanja" · "Jadwalkan" · "Sudah dimakan" · "Simpan rencana" · "Checklist belanja" |
| Foto | "Foto buat apa?" · "Cek sebelum makan" / "Sesuai arahanku nggak?" · "Sudah dimakan" / "Langsung catat" · "Isi manual" · "Foto dari atas, semua lauk kelihatan" · "Foto ulang" · "Analisis" · "Lagi baca fotomu" · "Fotonya belum bisa dibaca" · "Coba lagi" |
| Review & hasil | "Cek hasil foto" · "Bahan yang kelihatan" · "Tambah bahan" · "Belum jelas" · "Saus ini kira-kira apa?" · "Nggak tahu" · "Cek makanan" · "Hasil cek" · "Coba ganti" · "Nggak jadi" · "Tetap catat" · "Tersimpan" · "Ada keluhan" · "Selesai" |
| Jurnal | "Jurnal" · "Mau catat apa?" · "Tulis cerita" / "Catat gejala" / "Catat makan" · "Ceritain hari ini" · "Bantu Rapikan" · "Isi manual aja" · "Cek sebelum simpan" · "Simpan semua" · "Catat gejala" · "Apa yang kamu rasain?" · "Seberapa ganggu?" · "Mulai jam" · "Stres" · "Gejala setelahnya" · "Hapus catatan ini?" · "Ceritamu belum disimpan" · "Lanjut isi" / "Simpan draft" / "Buang draft" · "Belum ada catatan" · "Catat sekarang" |
| Ringkasan | "Ringkasan" · "7 hari" / "30 hari" · "catatan makan" · "gejala" · "Belum tentu penyebab" · "Lihat catatan ›" · "Ringkasan buat konsultasi" · "Buat konsultasi" · "Pertanyaan buat dokter" · "Catatannya belum cukup" · "3 dari 7 hari" |
| Profil | "Profil" · "Pengecekan awal" · "Arahan diet" · "Alergi" · "Budget & preferensi" · "Checklist belanja" · "Privasi & AI" · "Keluar" · "Bantuan AI" · "Simpan foto makanan" · "Unduh data saya" · "Hapus semua data" |

**Words to avoid:** "penyebab" without "belum tentu", "aman" as an absolute label, "pemicu" as a verdict, "sembuh", diagnosis words ("kamu mengidap IBS"), shaming ("salah makan").

## 6. Accessibility

- **Touch targets:** at least 44 × 44 (chips 44, links 44, back 44).
- **Contrast:** status text always uses the `-Ink` variant. Never put sky on white as text.
- **Status is never color only:** always symbol + word.
- **Semantics:**
  - Progress: "Langkah X dari 14".
  - Scale dots: "Skala 3, Sedang", selected state announced.
  - Day strip: one label, e.g. "7 hari terakhir: Rabu gejala skala 3, Kamis 2, Jumat 2, Minggu 2."
  - Camera button: "Foto makanan".
  - Koala images: decorative when a bubble carries the text; otherwise "Koala AIBS {mood}".
- **Reduced motion:** see MOTION.md §C.
- **Health copy:** red-flag and Bantuan copy must be reviewed by a clinician before release.

## 7. Prototype → Flutter notes

- **Device frame:** the canvas boards are 390 × 844 with no status bar. Use `SafeArea`; content scrolls, top bar and bottom actions/tab bar stay pinned.
- **Absolute positions:** only the verdict-card koala and the welcome decorations are absolutely placed. Use `Stack` for those, `Column` + padding for the rest.
- **Overlays:** F0, M6, J7 are `showModalBottomSheet`; J6h is `showDialog`. Not routes.
- **SVGs:** `flutter_svg` for the koala, icons, and illustrations.
- **Food photos:** the prototype uses gradient + bowl placeholders. In the app, real photos go in the same slot (cover) with the gradient as the loading/fallback background.
- **Font:** bundle Nunito static TTFs 600/700/800 under `fonts:` with family `Nunito`. `google_fonts` also works but needs network on first load.
