# AIBS demo data and app logic

This is the dummy data and the rules the prototype runs on. Menus, prices, and records are **illustrative demo values**. The rules come from the PRD ("Detail Layar, Logic & Skrining"); where the hi-fi copy and the PRD differ, the note says which one wins.

The backend (FastAPI) owns all rules. The app only renders results and sends user input.

## Demo profiles (A1d)

| Field | Nadia, 21 · Mahasiswi | Raka, 24 · Karyawan |
|---|---|---|
| Diagnosis (self-reported) | Ya | Ya |
| Arahan | Low FODMAP · eliminasi | Rendah lemak |
| Dihindari | bawang putih, bawang bombay, susu sapi, gandum | gorengan, santan, kulit ayam |
| Batas porsi | nasi 1 porsi, buah 1 porsi | nasi 1 porsi |
| Alergi | udang | kacang tanah |
| Bikin nggak nyaman | santan, kopi | kopi |
| Budget | Rp25.000 | Rp35.000 |
| Pedas | sedikit | sedang |
| Lainnya | halal, masak ≤ 15 menit | halal |

The two profiles must get **different statuses for the same catalog** (PRD demo requirement). Raka's values beyond the chips shown on A1d are suggestions; align them with the seed data.

## Menu catalog (Nadia's view)

| Name | Type | Price | Status for Nadia | Reason line |
|---|---|---|---|---|
| Nasi ayam bakar kecap | Beli | Rp22.000 | Sesuai | tanpa bawang |
| Tumis tahu wortel | Masak | Rp15.000 | Sesuai | tanpa bawang |
| Sup ayam jahe | Beli | Rp18.000 | Sesuai | – |
| Nasi goreng telur | Beli | Rp18.000 | Perlu hati-hati | nasi 1½ porsi |
| Soto ayam santan | Beli | Rp20.000 | Tidak sesuai arahan | ada bawang putih |

M2 detail for "Nasi ayam bakar kecap": 1 porsi; Cara pesan "Minta tanpa sambal bawang", "Nasi cukup 1 porsi"; Bahan nasi putih 1 porsi, ayam paha 100 g, kecap manis 1 sdm, jahe 1 ruas, timun 3 iris.

**Ranking:** apply allergy and avoid-list constraints first, then budget, then the user's preferences (PRD: "Terapkan batasan sebelum mengurutkan menu"). H1 shows only Sesuai menus.

## Shopping list (M5)

ayam paha 200 g · 2 resep · kecap manis 2 sdm · jahe 2 ruas · 2 resep · tahu putih 2 potong · wortel 1 buah (checked). Amounts from several recipes are merged per ingredient.

## Journal demo (J1, R1, R2, R3)

Week 2–8 Nov 2026, today = Minggu 8 Nov.

| Day | Meal (time) | Symptom (time · scale) | Stress |
|---|---|---|---|
| Rab 4 | Nasi goreng (12.10), bawang putih | Kembung 15.00 · 3 | Tinggi · "Minggu UTS" |
| Kam 5 | Bakso (17.30) | Nyeri perut 20.00 · 2 | – |
| Jum 6 | Mie ayam (19.00), bawang putih | Kembung 21.30 · 2 | Tinggi |
| Min 8 | Roti gandum + telur (07.30) · Nasi ayam bakar kecap (12.15), nasi 1½ porsi | Kembung 16.30 · 2 | Sedang |

R1 7-day totals: 9 catatan makan, 4 gejala, pattern "Kembung 3x · 2x setelah bawang putih", 2 saus belum diketahui.

## Statuses (food check)

| Status | Token | Symbol | When |
|---|---|---|---|
| Sesuai | ok | ✓ | No confirmed ingredient conflicts with allergy, avoid list, or limits |
| Perlu hati-hati | warn | ! | Over a portion limit, or on the personal "bikin nggak nyaman" list |
| Tidak sesuai arahan | bad | × | Contains an allergen or an avoid-list ingredient |
| Belum bisa dinilai | unknown | ? | An ingredient that matters is still unknown |

- Rules run only on **confirmed** ingredients. Unknown sauce/spice/portion stays unknown, never guessed into a status (PRD).
- Allergy conflicts always show as a warning, even if other things are fine.
- **Never** label a food "aman" in absolute terms. "Sesuai" means "fits the advice you entered".

## Screening (B screens)

Answers are stored as **Ya / Tidak / Tidak tahu**, three distinct values.

### Profile questions (B1–B3)

1. Age (bucketed). **Under 18 → B1x**, flow stops.
2. "Apakah dokter pernah mendiagnosis kamu dengan IBS?" (self-reported diagnosis).
3. "Apakah kamu sedang mengikuti arahan makan dari dokter atau ahli gizi?"

### Red flags (B4, 5 questions)

PRD wording (wins over the shorter hi-fi example; the hi-fi B4 shows a simplified version of Q1):

1. "Apakah saat ini kamu mengalami nyeri perut sangat berat atau cepat memburuk, pingsan, atau sulit minum?" → **Ya = active complaint → B6b Bantuan.**
2. "Apakah ada darah saat BAB atau feses hitam seperti ter, dan apakah sedang terjadi?"
3. "Apakah berat badan turun tanpa disengaja?"
4. "Apakah dokter pernah menyebut anemia yang belum jelas penyebabnya?"
5. "Apakah keluarga dekat memiliki riwayat kanker usus, IBD (Inflammatory Bowel Disease), atau celiac?"

Ya on 2–5 → flag `perlu_konsultasi`: the flow continues, B6 and R3 point to a consultation summary. **Urgency rules and copy must be reviewed by a clinician** before real patients use it (NIDDK, BSG references in the PRD).

### Pattern questions (B5, Rome V C1 domains, team wording for demo)

| ID | Question | Answer type |
|---|---|---|
| Q1 | Dalam tiga bulan terakhir, apakah nyeri atau rasa tidak nyaman di perut muncul berulang dan tidak terus-menerus? | Ya / Tidak / Tidak tahu |
| Q2 | Dalam periode itu, rata-rata berapa hari per bulan keluhan terasa? | < 1 / 1–2 / 3–4 / 5+ / Tidak tahu |
| Q3 | Sudah berapa bulan sejak keluhan pertama muncul? | < 3 / 3–5 / 6–12 / > 12 bulan / Tidak tahu (bucket usulan) |
| Q4 | Apakah keluhan berkaitan dengan BAB, misalnya berubah saat atau setelah BAB? | Ya / Tidak / Tidak tahu |
| Q5 | Apakah frekuensi BAB berubah saat pola keluhan muncul? | Ya / Tidak / Tidak tahu |
| Q6 | Apakah bentuk atau konsistensi feses berubah saat pola keluhan muncul? | Ya / Tidak / Tidak tahu |

The hi-fi B5 example uses the shorter title "3 bulan terakhir, berapa hari per bulan perutmu sakit?" for Q2. Either is fine for the demo; keep the meaning.

### Result logic (backend, version `rome_v_c1_demo`)

1. **Routing first:** under 18 → B1x · active complaint → B6b · other red flags → set `perlu_konsultasi` · key answers "Tidak tahu" → result "Lengkapi jawaban".
2. **Pattern:** `cocok = Q1 == Ya && Q2 >= 3 hari/bulan && Q3 >= 6 bulan && count(Ya in Q4..Q6) >= 2`. Only "Ya" counts for Q4–Q6.
3. **UI:** show the status and which criteria were met (B6 checklist). **No risk percentage.**

Test cases:
- Q1 Ya, Q2 3–4, Q3 6–12, Q4 Ya, Q5 Ya, Q6 Tidak → cocok (PRD example: 4 days/month, 8 months, 2 BAB links).
- Q2 1–2, everything else Ya → **belum cocok** (frequency is mandatory).

**Diet access:** "Isi arahan diet" (B6 → C1) is for users who reported a diagnosis and/or clinician advice. Others get the logging path (H1p) and the consultation summary. Recalculate when the profile changes.

## Symptom scale (J4, J5)

| n | Label | Meaning |
|---|---|---|
| 1 | Sangat ringan | Terasa, tapi nggak ganggu |
| 2 | Ringan | Sedikit ganggu, aktivitas tetap normal |
| 3 | Sedang | Ganggu konsentrasi atau aktivitas |
| 4 | Berat | Harus berhenti atau istirahat |
| 5 | Sangat berat | Nggak bisa beraktivitas sama sekali |

Symptoms: Kembung, Nyeri perut, Diare, Sembelit, Mual, Lainnya. Stress: Rendah, Sedang, Tinggi.

- **Meal time and symptom time are stored separately** (FAST diary principle).
- Symptoms are stored separately from meals. "Hubungkan makanan" links to an earlier record; the link is shown as an order of events, never as a cause.

## Negation (J3 → J4)

The AI extracts food, time, symptoms, and context from the story. Negated symptoms are **not** symptoms:

| Story | Draft |
|---|---|
| "siang makan ayam kecap, sore kembung, tapi nggak muntah" | Makan: ayam kecap, siang · Gejala: kembung, sore · (muntah: tidak) |
| "nggak mual sama sekali" | mual = tidak (stored as a negative, not shown as a symptom) |

Times like "siang", "sore" are saved as **perkiraan** (approximate) and shown with that label.

## Ringkasan

- Backend counts records and completeness per period (7 / 30 days).
- **Not enough data → R1k.** Suggested threshold: at least 3 meal records and 1 symptom spread over ≥ 3 days in the period (R1k shows "3 dari 7 hari"). Tune with the team.
- Pattern copy is **factual counts**: "Kembung 3x · 2x setelah bawang putih" + "Belum tentu penyebab". The AI may summarize facts but never names a trigger.

## Consent and AI

- A3 / P4 "Bantuan AI" is stored separately from basic consent.
- AI off → no photo upload, no story parsing. F2 goes to manual input; J2 hides "Tulis cerita".
- "Simpan foto makanan" off → the photo is deleted after extraction.

## Plans vs records

- **Plan** (M6): menu + day + meal + time. Shown on H1 "Nanti malam". Not counted in Ringkasan.
- **Consumption record**: created only when the user says they ate it (F7 via "Tetap catat" / "Sudah dimakan" / journal). A plan becomes a record only through that action.

## State

Every data screen has these states. The four shared UI statuses from the PRD team contract are: **sedang diproses, perlu konfirmasi, tersimpan, gagal**. Plus **kosong**.

| State | Screens | Pattern |
|---|---|---|
| Kosong | H1k, J1k, R1k | Koala + one short line + one primary action |
| Sedang diproses | F3 (photo), J3 → J4 (story) | Koala mikir + "Lagi baca fotomu" + manual escape link |
| Perlu konfirmasi | F4 "Belum jelas", F5, R1 unknown card | Dashed unknown row → clarification |
| Gagal | F3x (+ same pattern for story parsing) | Koala mikir + short line + "Isi manual" + "Coba lagi" |
| Tersimpan | F7 (+ toast after J4/J5 save) | Koala senang + "Tersimpan" |
| Draft belum disimpan | J7 | Lanjut isi / Simpan draft / Buang draft |

- **Idempotent saves:** send a request ID so a double tap creates one record (PRD).
- After edit or delete, refresh Hari Ini and Ringkasan.

## Portion baseline

1 porsi nasi ≈ 100 g ≈ 1 centong (DBMP, Daftar Bahan Makanan Penukar, Kemenkes). The UI currently says "porsi". Showing "1½ centong (±150 g)" is a pending design decision; don't change the unit without the designer.
