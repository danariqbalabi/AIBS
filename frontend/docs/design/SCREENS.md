# AIBS screens

The reference frame is a 390 × 844 phone. Every screen ID below matches an artboard on the hi-fi canvas (e.g. `H1 · Hari Ini`). Numbers are logical px from the prototype. Build with normal Flutter layout (padding, Column, Stack), not absolute coordinates. Content scrolls; top bars, bottom actions, and the tab bar stay pinned.

Components (top bar, option card, chips, koala bubble, verdict card, …) are specified in DESIGN.md §4. This file only says which ones each screen uses, in what order, and where each tap goes.

Items marked *(flow v2, belum digambar di canvas)* are in the agreed user flow but have no artboard yet. Build them with the same components; ask the designer if the layout is unclear.

## 0. Shared patterns

### Screen types

| Type | Structure | Screens |
|---|---|---|
| **Tab screen** | content (scroll, padding 28 / 20 / 16) + tab bar | H1, H1p, H1k, M1, J1, J1k, P1 |
| **Question screen** | top bar (back + progress + "Nanti"/"Lewati") → title 28/34 → options (gap 10), padding 24 / 20 | B1–B5, C1–C9 |
| **Inner screen** | top bar (back + optional title) → content scroll → pinned bottom actions (padding 12 / 20 / 24) | most others |
| **Photo screen** | full-bleed dark camera/photo, white controls | F1, F2 |
| **Overlay** | parent screen + scrim + sheet/dialog. **Not a route.** | F0, M6, J6h, J7 |

### Onboarding rules (B and C)

- **1 tap:** single-answer questions are option cards. Tapping saves and moves on. No "Lanjut".
- **Multi-select** (C3, C5, C6, C9): chips + a pinned primary "Lanjut".
- **Progress:** `StepProgress` out of 14. B1 = 1 … B5 = 5, C1 = 6 … C9 = 14. B1x, B6, B6b, C10 have no bar.
- **Top-right link:**
  - "Nanti" on required questions: saves the answers so far and goes to **H1p** (logging mode). The user can come back from Profil.
  - "Lewati" on optional questions (C4, C6, C9): skips just that question.
- Back always returns to the previous question with the answer kept.

### Tab bar

Hari Ini (H1) · Menu (M1) · camera (opens F0 sheet over the current tab) · Jurnal (J1) · Profil (P1).

---

## 1. Mulai

### Main · Selamat datang
1. Background: radial glow top-left.
2. Hero (470 high): white→primarySoft circle 250, koala **senang** 230 in front of it, three tilted white tiles (64, radius 18) with the bowl, journal, and camera illustrations.
3. Text block (centered, padding 8 / 24, gap 12): "AIBS" pill (13/800, letter-spacing 0.08em, primarySoft), display "Makan tenang, / perut senang", body 15/600 muted (max width 290).
4. Bottom (padding 16 / 24 / 24): primary "Coba Demo" → **A1d**; link "Masuk" → **A2**; micro disclaimer "Bukan pengganti saran dokter."

### A1d · Pilih profil demo
- Title "Pilih profil demo". Two profile cards (radius 24, padding 18, gap 14):
  - Row: avatar 56 circle (gradient + initial 24/800) | name 20/800 + role 13/700 | chevron.
  - Chips (primarySoft, 13/800): profile highlights.
- **Nadia, 21 · Mahasiswi:** Low FODMAP · Alergi udang · Rp25rb → **H1**.
- **Raka, 24 · Karyawan:** Rendah lemak · Alergi kacang · Rp35rb → **H1**.

### A2 · Masuk
- Title "Masuk ke AIBS". Field "Email". Pinned primary "Kirim kode" → **A2v**.

### A2v · Verifikasi kode
- Title "Masukkan kode" + the email in 15/800 primaryStrong under it.
- OTP boxes follow `EMAIL_OTP_LENGTH` (default 8 to match the deployed Supabase project; configurable 6–10). Grid gap 8; pasting distributes the complete code across boxes. "Lanjut" verifies the full code before **A3**.
- Link "Kirim ulang kode".

### A3 · Izin data
- Title "Pakai bantuan AI?". Two choice cards (1 tap, both → **B1**):
  - **"Pakai AI"** (brandCard, sparkle icon): "Foto dan cerita dirapikan otomatis".
  - **"Tanpa AI"** (white, pencil icon): "Semua diisi manual".
- Footer micro: "Bisa diubah kapan saja di Profil › Privasi."
- The choice is stored as the AI consent flag (DATA.md §Consent).

## 2. Riwayat keluhan (screening)

All question screens follow §0. Answers feed the rules in DATA.md §Screening.

| ID | Title | Options → next |
|---|---|---|
| B1 · Usia | "Berapa usia kamu?" | "Di bawah 18" → **B1x** · "18–29" / "30–39" / "40–49" / "50 ke atas" → B2 |
| B2 · Diagnosis | "Pernah didiagnosis IBS oleh dokter?" | Ya / Tidak / Tidak tahu → B3 |
| B3 · Arahan makan | "Punya arahan makan dari dokter atau ahli gizi?" | Ya / Tidak → B4 |
| B4 · Pengecekan awal | counter "1 dari 5" (14/800 primaryStrong) + red-flag question | **Ya → B6b** (active severe complaint) · Tidak / Tidak tahu → next flag … then B5 |
| B5 · Pola keluhan | counter "2 dari 6" + Rome question | e.g. Q2: "Kurang dari 1 hari" / "1–2 hari" / "3–4 hari" / "5 hari atau lebih" / "Tidak tahu" → next … then B6 |

- **B4** is one template shown 5 times (one flag each). **B5** is one template shown 6 times (Q1–Q6). The canvas shows one example of each.
- A "Ya" on a non-severe flag doesn't stop the flow. It sets the "perlu konsultasi" flag shown on B6 and R3 (DATA.md §Red flags).

### B1x · Info cakupan (< 18)
- No progress. Koala **mikir** 200 centered (24 below the top bar), heading 26/32 "AIBS dibuat untuk usia 18+", body 16/23 muted "Ajak orang tua atau dokter buat bantu atur makanmu."
- Pinned ghost "Ubah usia" → B1.

### B6 · Hasil
1. **Verdict card** (hero gradient, radius 24, min height 150, padding-left 150): koala **senang** 150 bottom-left, label "Hasil pengecekan awal" (13/800 primaryStrong), headline "Polanya cocok dengan kriteria IBS".
2. **Criteria card** (white, padding 8 / 16): 4 rows, each a 26 circle (✓ primary when met, "–" unknownSoft when not) + 15/800 text:
   "Sakit perut berulang" · "3+ hari per bulan" · "Sudah 6 bulan lebih" · "Berhubungan dengan BAB · 2 dari 3".
3. Micro disclaimer "Bukan diagnosis. Pastikan ke dokter."
4. Link "Ubah jawaban" → B5.
5. Pinned: primary "Isi arahan diet" → C1; ghost "Mulai catat aja" → H1p.

- **No percentage and no score.** Only which criteria were met.
- Other headlines (same card): "Belum cocok dengan kriteria IBS" or "Jawabannya belum cukup" when there are many "Tidak tahu" answers (then the primary becomes "Lengkapi jawaban" → B5). Copy for these needs review (DATA.md). *(flow v2, belum digambar di canvas)*

### B6b · Bantuan
- Koala **khawatir** 170 centered, heading 26/32 "Periksa ke dokter dulu, ya" (centered).
- White card, 3 numbered steps (28 circle badSoft/badInk + 16/800 title, optional 13/700 sub):
  1. "Sakit hebat atau nggak reda?" / "Langsung ke IGD terdekat"
  2. "Hubungi dokter atau faskes"
  3. "Bawa ringkasan keluhanmu"
- Micro "Teks ini perlu ditinjau tenaga medis." (remove after review).
- Pinned: danger "Telepon 119" (`tel:119`); ghost "Lihat ringkasan keluhan" → R3.

## 3. Profil diet

| ID | Title | Input | Next |
|---|---|---|---|
| C1 · Jenis arahan | "Arahan makan apa yang kamu ikuti?" | 1 tap: Low FODMAP / Rendah lemak / Tinggi serat / Belum ada arahan / Lainnya | Low FODMAP → **C2**, others → C3 |
| C2 · Fase | "Low FODMAP fase apa?" | 1 tap with sub-line: Eliminasi ("Menghindari semua FODMAP tinggi") / Reintroduksi ("Mencoba lagi satu per satu") / Personalisasi ("Sudah tahu yang cocok") / Belum tahu | C3 |
| C3 · Bahan dihindari | "Bahan apa yang dihindari?" | chips; pre-selected from the diet type (Low FODMAP → bawang putih, bawang bombay, susu sapi, gandum) + "Tambah" | Lanjut → C4 |
| C4 · Batas porsi | "Ada batas porsi?" | white card with stepper rows: Nasi "1 porsi", Buah "1 porsi", Roti "Tidak ada" · top link "Lewati" | Lanjut → C5 |
| C5 · Alergi | "Punya alergi makanan?" | chips (Udang, Kacang tanah, Telur, Susu, Ikan, Kedelai, Kerang, + Lainnya) + link "Nggak ada alergi" (1 tap → C6) | Lanjut → C6 |
| C6 · Toleransi pribadi | "Ada yang bikin perutmu nggak nyaman?" | chips (Santan, Gorengan, Kopi, Soda, Makanan berminyak, + Tambah) · "Lewati" | Lanjut → C7 |
| C7 · Budget | "Budget sekali makan?" | 1 tap: Rp15.000 / Rp25.000 / Rp35.000 / Rp50.000+ / "Ketik sendiri" (opens a number field) | C8 |
| C8 · Level pedas | "Suka pedas?" | 1 tap with 3 chili icons (filled bad / empty line): Nggak pedas 0 / Sedikit 1 / Sedang 2 / Pedas banget 3 | C9 |
| C9 · Preferensi lain | "Ada preferensi lain?" | chips (Halal, Vegetarian, Tanpa daging merah, Masak ≤ 15 menit, Lebih suka beli, Lebih suka masak) · "Lewati" | Lanjut → C10 |

- Chips on C3/C6 are personal avoid/tolerance lists. The app never adds an item on its own; pre-selection on C3 comes only from the diet type the user picked.

### C10 · Cek ulang profil
- Title "Udah bener?". White card of summary rows (category 12/700 muted above value 16/800, chevron). Each row → its question, and returning there comes back to C10:
  Arahan → C1 · Dihindari → C3 · Batas porsi → C4 · Alergi → C5 · Bikin nggak nyaman → C6 · Budget → C7 · Pedas → C8 · Lainnya → C9.
- Pinned primary "Simpan profil" → H1.

## 4. Hari Ini

### H1 · Hari Ini (profile complete)
Content, top to bottom (gap 24), radial glow behind the top:
1. **Greeting + question** (padding 0 20): "Hai, Nadia" + title "Mau makan siang apa?". The meal word follows the time of day (sarapan / makan siang / makan malam / camilan).
2. **Recommendation slider** (horizontal scroll, padding 4 / 20 / 12, gap 12): 3 menu slider cards → M2, then the **"Lihat semua" card** → M1. Recommendations only include menus with status Sesuai, sorted by fit then budget.
3. **Next plan card** (only when a plan exists): white row, 52 time tile ("19.00"), label "Nanti malam" (12/800 primaryStrong) + menu name 16/800, chevron → M2 of that menu.
4. **Koala prompt card** (primarySoft): KoalaBubble **senang** 84 "Ada keluhan setelah makan pagi tadi?" + two buttons: "Nggak ada" (white, saves a "no symptom" check-in and hides the card) and "Catat" (gradient) → J5. Shows only after a logged meal without a symptom check-in.
5. **7-day card** (white, padding 16, gap 14): header "7 hari terakhir" 15/800 + "4 hari ada gejala" 13/700 muted on the right; 7 day dots (32, day letter 12/700 under); then two soft buttons "Baca pola" → R1 and "Lihat riwayat" → J1.
6. Tab bar (Hari Ini active).

### H1p · Hari Ini mode pencatatan (no diet profile yet)
- Greeting + "Mau catat apa hari ini?".
- Koala prompt card: KoalaBubble **mikir** 96 "Isi arahan dietmu biar aku bisa kasih rekomendasi menu." + primary "Isi arahan diet" → C1.
- Section "Hari ini": white card of log rows (time | name) → J6.
- No recommendations (they need the profile). Logging works fully.

### H1k · Hari Ini kosong (profile done, no records yet)
- Greeting + "Mau makan siang apa?".
- Row card "Lihat 12 menu yang sesuai" → M1.
- White card: koala **senang** 120 + "Belum ada catatan" 18/800 + soft "Catat makan pertama" → F0.

## 5. Menu

### M1 · Daftar menu
1. Header: title "Menu" + cart button (white 44, cart icon, count badge "4") → M5. Search field below.
2. Filter row (horizontal scroll, 38 chips): Semua / Beli / Masak (one selected) + budget chip "≤ Rp25.000" (from profile, primarySoft).
3. List grouped by status, in this order: **Sesuai arahanmu**, **Perlu hati-hati**, **Tidak sesuai arahan**. Each group has a header (10 dot + 13/800 in the status ink). Rows don't repeat the status badge.
   - Row meta says why in a few words: "Beli · Rp22.000 · tanpa bawang", "nasi 1½ porsi", "ada bawang putih".
4. Row → M2. Tab bar (Menu active).

### M2 · Detail menu
1. Hero 260 high (food gradient + big illustration), back button top-left (16 / 20). The content sheet overlaps it by 28 (top radius 28, surface).
2. Name (titleDetail) + meta "Beli · Rp22.000 · 1 porsi" (14/800 muted) + status badge.
3. Status note card in the status soft color (14/700 in status ink): "Tanpa bawang putih dan bawang bombay. Nasi 1 porsi."
4. **Cara pesan** (Beli) or **Cara masak** (Masak, numbered steps + time) *(flow v2, belum digambar di canvas)*: white card rows, e.g. "Minta tanpa sambal bawang", "Nasi cukup 1 porsi".
5. **Bahan:** ingredient rows with status circles. For Masak menus each row can open an inline porsi change or a swap. *(flow v2, belum digambar di canvas)*
6. Link "Masukkan ke checklist belanja" → M5 (adds the ingredients).
7. Pinned bar (white, top radius 28): soft "Jadwalkan" → **M6** · primary "Sudah dimakan" → **F4** (prefilled with this menu, intent = sudah dimakan).

### M6 · Jadwalkan (sheet over M2)
- Title "Jadwalkan" + close.
- "Hari": 4 radio chips (48 high, radius 16) Hari ini / Besok / next two weekdays.
- "Waktu": Pagi / Siang / Malam / Camilan.
- "Jam" row (surface, radius 16): value 17/800, opens a time picker. Default from the meal time.
- Primary "Simpan rencana" → closes, saves a **plan** (not a consumption record) and returns to H1 with the plan card.

### M5 · Checklist belanja
- Title "Checklist belanja". Rows: check circle + name + "200 g · 2 resep". Tap toggles bought (checked rows go muted). Swipe or × removes a row; tap the amount to edit it. *(flow v2, belum digambar di canvas)*

## 6. Foto

### F0 · Foto buat apa? (sheet over the current tab)
- Title + close. Two choice cards:
  - **"Cek sebelum makan"** / "Sesuai arahanku nggak?" (brandCard, camera icon) → F1, intent = **cek**.
  - **"Sudah dimakan"** / "Langsung catat" (surface, check icon) → F1, intent = **sudah dimakan**.
- Link "Isi manual" → F4m.

### F1 · Kamera
- Full-bleed camera preview, white close (→ back to the tab), framing hint "Foto dari atas, semua lauk kelihatan", shutter → F2, gallery button → F2, link "Isi manual" → F4m.

### F2 · Preview foto
- The photo, back, ghost "Foto ulang" → F1, primary "Analisis" (sparkle icon) → F3.
- When AI consent is off, "Analisis" is replaced by "Isi manual" → F4m and the photo is never uploaded. *(flow v2, belum digambar di canvas)*

### F3 · Sedang diproses
- Koala **mikir** + heading "Lagi baca fotomu" + link "Isi manual aja" → F4m. Cancel returns to F2.
- Success → F4, failure or timeout → F3x. (The canvas has two prototype-only links "berhasil"/"gagal"; don't build them.)

### F3x · Gagal
- Koala **mikir**, heading "Fotonya belum bisa dibaca", one short line, ghost "Isi manual" → F4m, primary "Coba lagi" → F1.

### F4m · Isi manual
- Title "Isi manual". Field "Nama makanan". Section "Bahan": ingredient rows with amount and × ; a "?" row for something unknown ("Saus"); "Tambah bahan". Primary "Lanjut" → F5 if any "?" row, else → result step (see F4).

### F4 · Review makanan
1. Title "Cek hasil foto".
2. Dish guess: chips for the top guesses (selected = "✓ Nasi + ayam goreng") + "Lainnya".
3. "Bahan yang kelihatan": ingredient rows (name + "±1 porsi" + ×), "Tambah bahan".
4. "Belum jelas": dashed unknown row(s), e.g. "Saus coklat di atas ayam" → F5.
5. Meal time row (defaults to now; editable) — needed for linking symptoms. *(flow v2, belum digambar di canvas)*
6. Pinned primary, depends on intent and state:
   - Unknown items left → "Lanjut" → F5.
   - Intent **cek** → "Cek makanan" → F6.
   - Intent **sudah dimakan** → "Simpan" → F7.

### F5 · Perlu konfirmasi (klarifikasi)
- Title "Saus ini kira-kira apa?". Radio list: Kecap manis / Sambal / Saus tiram / Saus tomat / "? Nggak tahu".
- "Bumbu lain di saus": chips with × (e.g. Bawang putih) + "Atau tulis sendiri".
- Primary "Cek makanan" → F6 (or "Simpan" → F7 for intent sudah dimakan).
- "Nggak tahu" is allowed: that item is saved as unknown and the result becomes "Belum bisa dinilai" if it matters.

### F6 · Hasil cek
1. Dish header: thumb + name 17/800 + "Dari foto · 12.20".
2. **Verdict card** in the status soft color, koala by status (khawatir for Tidak sesuai, senang for Sesuai, mikir for Belum bisa dinilai): headline "Ada bawang putih" (20/800 status ink) + one short reason line "Di sausnya. Masuk daftar hindari." + status badge.
3. Ingredient rows with status circles; the problem items first.
4. **"Coba ganti":** 1–2 alternative menus that are Sesuai → M2.
5. Pinned: ghost "Nggak jadi" → H1 (nothing saved); primary "Tetap catat" → F7. When the status is Sesuai the primary reads "Catat sudah dimakan". *(flow v2, belum digambar di canvas)*
- When there are unknown items, a soft "Lengkapi bahan" → F5 appears above the actions. *(flow v2, belum digambar di canvas)*

### F7 · Tersimpan
- Koala **senang** 190, title "Tersimpan", log row (time | name | meal) → J6.
- Pinned: ghost "Ada keluhan" → J5 (linked to this meal); primary "Selesai" → H1.

## 7. Jurnal

### J1 · Riwayat (Jurnal tab)
- Header "Jurnal" + Ringkasan button → R1. Day switcher "Hari ini · Minggu, 8 Nov" with ‹ › arrows. Filter (Semua / Makan / Gejala). *(flow v2, belum digambar di canvas)*
- Timeline rows by time: meal rows (name + status badge) → J6; symptom rows (scale dot + "Kembung" + "Ringan · stres sedang") → J5 in edit mode.
- Pinned primary "Catat" → J2. Tab bar (Jurnal active).

### J1k · Riwayat kosong
- "Jurnal" title, koala **mikir** 170 + "Belum ada catatan" + primary "Catat sekarang" → J2.

### J6 · Detail catatan
- Label "Makan siang · Min 12.15" (14/800 primaryStrong), name (titleDetail), status badge.
- Ingredient card (name | amount).
- "Gejala setelahnya": symptom card (scale tile 40 + "Kembung · 16.30" + micro "Belum tentu penyebab") → J5.
- Bottom: ghost "Hapus" (badInk text) → J6h; soft "Edit" → F4 (edit mode).

### J6h · Hapus catatan (dialog over J6)
- "Hapus catatan ini?" + "Nasi ayam bakar kecap · 12.15" + danger "Hapus" → J1 (toast) + ghost "Batal".

### J2 · Mau catat apa?
- Sheet-like screen: "Mau catat apa?" + 3 rows: "Tulis cerita" (primary row, AI) → J3 · "Catat gejala" → J5 · "Catat makan" → F4m. Link "Batal".
- When AI consent is off, "Tulis cerita" is hidden.

### J3 · Tulis cerita
- Title "Ceritain hari ini" + big text area (example: "siang makan ayam kecap, sore kembung, tapi nggak muntah").
- Primary "Bantu Rapikan" → J4; link "Isi manual aja" → J5.
- Back with unsaved text → **J7**. (The "berhasil/gagal" links on the canvas are prototype-only.)

### J7 · Draft belum disimpan (sheet over J3)
- "Ceritamu belum disimpan" + primary "Lanjut isi" (close sheet) + ghost "Simpan draft" → J2 + red link "Buang draft" → J2.

### J4 · Review jurnal
- Title "Cek sebelum simpan", the original quote in a soft card.
- Extracted items, each editable with ×:
  - **Makan:** food name, "Jam · perkiraan".
  - **Gejala:** name, "Mulai · perkiraan", scale 1–5 ("Seberapa ganggu?"), notes.
- **Negation:** "nggak muntah" never becomes a symptom item (DATA.md §Negation).
- Primary "Simpan semua" → J1.

### J5 · Gejala & BAB
- Title "Catat gejala".
- "Apa yang kamu rasain?": chips Kembung / Nyeri perut / Diare / Sembelit / Mual / Lainnya (multi).
- "Seberapa ganggu?": scale 1–5 + meaning card.
- "Mulai jam" time row · "Stres" Rendah / Sedang / Tinggi · "Catatan" field.
- "Hubungkan makanan": the meal right before (pre-selected) with option to change. *(flow v2, belum digambar di canvas)*
- Primary "Simpan" → J1.

## 8. Ringkasan

### R1 · Ringkasan pola
1. Header back + "Ringkasan". Segmented 7 hari / 30 hari.
2. Day strip with symptom dots + 2 stat tiles (surface, radius 16): "9 catatan makan", "4 gejala" (26/800 tabular).
3. **Pattern card** (white, 2 px primary border, radius 24): "Kembung 3x · 2x setelah bawang putih" (17/800) + micro "Belum tentu penyebab" + "Lihat catatan ›" → R2.
4. Unknown card (dashed): "? 2 saus belum diketahui" → F5.
5. Pinned primary "Ringkasan buat konsultasi" → R3.
- Copy is **counts only**. No "kamu sensitif terhadap…", no ranking of triggers.

### R1k · Belum cukup catatan
- Back + "Ringkasan". Koala **mikir** 180, heading "Catatannya belum cukup", 7-segment bar (3 filled) + "3 dari 7 hari".
- Primary "Catat hari ini" → F0; ghost "Lihat catatan yang ada" → J1.
- Threshold: DATA.md §Ringkasan.

### R2 · Catatan dasar
- Title "Kembung · 7 hari". Per day: date header, meal row (time + name + highlighted matched ingredient), symptom row (time + "Kembung · 3"), stress chip + note ("Minggu UTS"). Rows → J1 at that day.

### R3 · Ringkasan konsultasi
- Title "Buat konsultasi". Summary rows: Periode / Arahan / Alergi.
- "Hasil pengecekan awal": criteria met + any red flags answered "Ya". *(flow v2, belum digambar di canvas)*
- "Gejala & makanan sebelumnya": list of scale tile + "Kembung · Rab 15.00" + "Setelah nasi goreng, 12.10".
- "Pertanyaan buat dokter": editable list.
- Actions: share / download PDF (system share sheet). *(flow v2, belum digambar di canvas)*

## 9. Profil

### P1 · Profil
- Title "Profil". User card (avatar 56 + name 18/800 + email 13/700).
- Settings card rows: "Pengecekan awal · Cocok kriteria IBS" → B6 · "Arahan diet · Low FODMAP · eliminasi" → P2 · "Alergi · Udang" → P2 · "Budget & preferensi · Rp25.000 · pedas sedang · halal" → C10.
- "Checklist belanja · 4 bahan belum dibeli" (primarySoft card, cart illustration) → M5.
- "Privasi & AI" → P4. Red link "Keluar" → Main. Tab bar (Profil active).

### P2 · Ubah arahan diet (one page on purpose)
- Title "Arahan diet". "Jenis arahan" radio list. "Bahan yang dihindari" chips with × (a removed chip stays as a struck-through "undo" chip). "Batas porsi" stepper rows + "Tambah batas porsi". Pinned primary "Simpan perubahan" → P3.

### P3 · Konfirmasi perubahan (dialog)
- Koala + "Hapus bawang bombay dari daftar hindari?" + "Pastikan sesuai arahan dokter atau ahli gizimu." + ghost "Batal" + primary "Ya, ubah" → P1.
- Shown only when an item is **removed** from the avoid list or a limit is loosened.

### P4 · Privasi
- Back + title "Privasi". Toggle card: "Bantuan AI" (sub "Foto dan cerita dirapikan otomatis") · "Simpan foto makanan". Row card: "Unduh data saya" · "Hapus semua data" (badInk, confirm dialog like J6h). *(flow v2, belum digambar di canvas)*

---

## Navigation map

```
Main ─ Coba Demo ─► A1d ─ profil ─► H1 (demo data)
     └ Masuk ─► A2 ─► A2v ─► A3 ─► B1 … B5 ─► B6 ─ Isi arahan diet ─► C1 … C10 ─ Simpan ─► H1
                                   │ <18 ─► B1x        └ Mulai catat aja ─► H1p
                                   │ B4 "Ya" (severe) ─► B6b ─► R3
                                   └ "Nanti" anywhere ─► H1p

Tabs:  H1 ◄─► M1 ◄─► J1 ◄─► P1          camera (any tab) ─► F0 sheet

H1 ─ menu card ─► M2 ─ Jadwalkan ─► M6 ─► H1 (plan card)
   │               └ Sudah dimakan ─► F4 ─► F7
   ├ Lihat semua ─► M1 ─► M2
   ├ koala "Catat" ─► J5
   └ Baca pola ─► R1 (or R1k) ─► R2 / R3   ·   Lihat riwayat ─► J1

F0 ─ Cek / Sudah dimakan ─► F1 ─► F2 ─► F3 ─┬► F4 ─(?)─► F5 ─┬► F6 ─ Tetap catat ─► F7
   └ Isi manual ─► F4m ──────────────────────┘ └► F3x         └► F7 (sudah dimakan)

J1 ─ Catat ─► J2 ─┬ Tulis cerita ─► J3 ─► J4 ─► J1   (back with text ─► J7)
                  ├ Catat gejala ─► J5 ─► J1
                  └ Catat makan ─► F4m
J1 ─ row ─► J6 ─ Edit ─► F4 · Hapus ─► J6h ─► J1

P1 ─► B6 · P2 ─► P3 · C10 · M5 · P4 · Keluar ─► Main
```

Suggested go_router paths: `/welcome`, `/demo`, `/login`, `/login/code`, `/consent`, `/screening/:step`, `/screening/result`, `/screening/help`, `/diet/:step`, `/diet/review`, `/today`, `/menu`, `/menu/:id`, `/shopping`, `/camera`, `/camera/preview`, `/check/processing`, `/check/review`, `/check/clarify`, `/check/result`, `/check/saved`, `/journal`, `/journal/:id`, `/journal/new`, `/journal/story`, `/journal/story/review`, `/journal/symptom`, `/summary`, `/summary/pattern/:id`, `/summary/consult`, `/profile`, `/profile/diet`, `/profile/privacy`. Overlays (F0, M6, J6h, J7, P3) are sheets/dialogs, not routes. Back = `context.pop()`.
