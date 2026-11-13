# AIBS: design handoff buat developer

Paket ini isinya semua yang dibutuhin buat ngebangun UI AIBS (AI for IBS) di repo Flutter sesuai prototype hi-fi final di canvas Claude Design "AIBS Hi-fi": https://claude.ai/artifact/EYzZH9vbkSWH2iHhCkrcKr

## Isi paket

| File | Buat apa |
|---|---|
| `AGENTS.md` | Aturan buat AI coding assistant (Codex otomatis baca file ini di root repo). |
| `docs/design/DESIGN.md` | Prinsip desain, warna, font, spacing, komponen, copy. |
| `docs/design/SCREENS.md` | Layout tiap layar (60 layar dalam 8 bagian) + peta navigasi. |
| `docs/design/MOTION.md` | Transisi dan feedback tekan. Prototype-nya statis, jadi isinya default yang disaranin. |
| `docs/design/DATA.md` | Data demo, aturan pengecekan awal (Rome V), red flag, status cek makanan, state UI. |
| `lib/core/theme/aibs_tokens.dart` | Token desain dalam bentuk Dart (warna, font, ukuran, radius, bayangan, durasi). |
| `lib/core/theme/aibs_theme.dart` | `ThemeData` AIBS. |
| `lib/shared/widgets/status_badge.dart` | Badge status hasil cek (Sesuai / Perlu hati-hati / Tidak sesuai / Belum bisa dinilai). |
| `lib/shared/widgets/koala.dart` | Maskot koala + gelembung chat koala. |
| `lib/shared/widgets/step_progress.dart` | Progress bar onboarding. |
| `assets/brand/` | Maskot koala (senang, mikir, khawatir) dalam SVG. |
| `assets/icons/` | Ikon garis: nav, back, chevron, close, plus, check, search, cart, pencil, sparkle, chili. |
| `assets/illustrations/` | Ilustrasi kecil berwarna (mangkuk, jurnal, kamera, keranjang). |

Paket ini cuma dokumen dan elemen dasar. Kode layar sengaja nggak dibikinin.

## Cara pakai

1. **Copy isinya ke root repo Flutter AIBS.** Struktur foldernya `lib/` + `assets/` + `docs/`, tinggal timpa/gabung.
2. **Tambahin ke `pubspec.yaml`:**
   - Package `flutter_svg`.
   - Folder `assets/brand/`, `assets/icons/`, `assets/illustrations/`.
   - Font Nunito: download dari fonts.google.com, ambil file static SemiBold (600), Bold (700), ExtraBold (800).
3. **Pasang theme** di `MaterialApp`: `theme: AibsTheme.light`.
4. **Kerjain per layar, satu prompt satu layar.** Contoh prompt:

   > Baca AGENTS.md dan docs/design/*. Bangun layar Hari Ini sesuai SCREENS.md §4 (H1). Pakai token, KoalaBubble, dan StatusBadge yang udah ada. Screenshot terlampir.

   Urutan yang disaranin:
   1. Theme + font + assets.
   2. Shell tab bar (5 slot, tombol kamera di tengah).
   3. Hari Ini (H1, H1p, H1k).
   4. Menu: daftar, detail, Jadwalkan, belanja.
   5. Foto: pilih tujuan, kamera, proses, review, klarifikasi, hasil cek, tersimpan.
   6. Jurnal: riwayat, detail, catat gejala, cerita + review.
   7. Onboarding: masuk, izin AI, riwayat keluhan, profil diet.
   8. Ringkasan + ringkasan konsultasi.
   9. Profil + privasi.
   10. Cek semua state (kosong, diproses, gagal, perlu konfirmasi, tersimpan).
5. **Screenshot:** buka canvas di link atas, klik artboard, screenshot per layar/state, terus lampirin ke prompt. Kebanyakan coding assistant lebih akurat dari screenshot daripada dari deskripsi aja.

## Catatan

- Data demo (menu, harga, catatan) cuma ilustrasi.
- Teks red flag dan layar Bantuan (B4, B6b) **wajib ditinjau tenaga medis** sebelum rilis.
- Satuan porsi masih "porsi" (1 porsi nasi ≈ 100 g, DBMP (Daftar Bahan Makanan Penukar) Kemenkes). Usulan "1½ centong (±150 g)" belum diputusin.
- File Dart di paket ini belum dicek pakai Flutter. Setelah di-copy, jalanin `dart format lib` lalu `flutter analyze` dulu.
