# Kesiapan demo AIBS

Perbaikan audit PRD dikumpulkan di `feat/hackathon-readiness`, PR #40. Dokumen ini membedakan implementasi, bukti tes dan tindakan tim yang belum tersedia. Tidak menjanjikan hasil penjurian.

## Pemetaan perbaikan

| Kebutuhan / temuan | Perubahan |
| --- | --- |
| Urutan makanan/gejala | Tautan dalam draft sama divalidasi; gagal membatalkan seluruh transaksi |
| Waktu makan manual | Review tanggal/jam/perkiraan dan konfirmasi sebelum konsumsi disimpan |
| Preferensi | Label FE menjadi kode server; ranking memakai preferensi, jenis menu dan tingkat pedas yang diketahui |
| Screening | Perdarahan aktif terpisah, perbaikan jawaban mengikuti missing fields, ringkasan memuat jawaban |
| Onboarding | Snapshot privat berversi di server, dipulihkan sebelum melanjutkan; migrasi `0003` |
| Profil ditunda | Pengecekan awal dapat dibuka kembali dari Profil |
| Menu | Editor bahan/porsi memakai cek backend; perubahan diteruskan ke rencana dan belanja |
| Belanja | Edit jumlah memakai ID/versi sama; satuan kompatibel digabung |
| Dashboard | Mode akses mengikuti server dan rencana hari ini ditampilkan |
| Ringkasan | Periode/jumlah server, label 30 hari, arah waktu, navigasi jurnal terfilter |
| Negasi | Tidak menjadi gejala positif; dapat ditinjau sebagai observasi tanpa gejala |
| Isian belum disimpan | Guard manual/gejala/review/edit, draft server dapat dilanjutkan |
| Fallback NLP | Editor manual terstruktur mempertahankan cerita tanpa memanggil AI |
| Foto sementara | Dihapus setelah ekstraksi; TTL/cron cadangan bila ditinggalkan/gagal cleanup |
| Dokumentasi | README mengacu integrasi dan deployment yang ada |

## Bukti

- Lokal: 98 tes backend lulus, 2 khusus PostgreSQL dilewati lokal; PostgreSQL berjalan di CI. 54 tes Flutter lulus, format/analyzer bersih pada tahap guard.
- Build web release berhasil. CI memeriksa web dan Android; gunakan run dari commit final, bukan run lama.
- [APK terhubung dan checksum](evidence/android-build-verification.json) sudah diunduh dari CI dan SHA-256 cocok dengan manifest artifact. Ini bukti kompilasi/configurasi, bukan tes instalasi perangkat. Ambil artifact terbaru setelah commit final.
- Migrasi `0003` diterapkan ke Supabase dan `alembic check` tidak menemukan drift pada pemeriksaan tersebut.
- [Gemini nyata](evidence/ai-nlp-evaluation.json): empat cerita sintetis lulus schema, negasi, pemisahan waktu dan porsi unknown. Latensi/token adalah pengamatan per panggilan.
- Production merespons health/readiness 200 dan CORS menerima frontend; perlu smoke ulang setelah deploy PR #40.
- [Smoke browser release](evidence/browser-smoke.json) pada viewport 390×844: demo anonymous, restore sesi, review waktu/commit manual dan catatan setelah reload. [Screenshot Jurnal](evidence/browser-journal.png). Backend lokal mengakses Supabase nyata; ini bukan pengujian seluruh flow production atau perangkat.

## Langkah release

1. Pastikan backend matrix, Flutter checks, web dan Android hijau. Review lalu merge PR #40; tidak perlu merge branch kecil satu per satu.
2. Tunggu backend/frontend Vercel Ready dari commit sama. Periksa readiness dan refresh frontend.
3. Download `aibs-android-demo`; periksa `connected=true`, commit dan SHA-256. Variabel repository berisi konfigurasi client publik; secret server tidak masuk APK.
4. Uji Android: instal, demo/login, kamera/galeri, koreksi, simpan, tutup/buka, edit/hapus, offline/fallback dan ekspor. Perangkat/emulator belum tersedia di sesi ini.
5. Pengguna menguji OTP sendiri: hubungkan anonymous ke email, logout/login email sama, lalu pastikan catatan sama. Jangan bagikan kode/app password.
6. Rekam 3–5 menit dari build sama dengan data sintetis. Unggah video Public/Unlisted dan sediakan APK yang dapat diakses juri tanpa akun developer.
7. Isi ketua/identitas, surat orisinalitas, atribusi dan tautan final. Cocokkan commit source/APK/video dan cutoff portal resmi.

## Batas

Belum ada bukti Android fisik, video final atau evaluasi foto makanan nyata yang beragam. Katalog/harga tetap ilustratif; screening/copy belum disahkan untuk penggunaan klinis. Hapus data bukan penghapusan identitas Auth. iOS belum dibangun. OCR, merchant, suara dan pengingat adalah pasca-MVP PRD.

## Mengulang smoke browser lokal

`scripts/browser_smoke.py` membutuhkan Python Playwright dan Chrome. Siapkan build web release yang mengarah ke API lokal (`API_BASE_URL=http://127.0.0.1:8011`), Supabase project/publishable key nyata, CORS origin `http://127.0.0.1:5180`, lalu serve `frontend/build/web` pada port 5180. Jalankan backend dengan schema/seed terbaru, kemudian `python scripts/browser_smoke.py` dari root repo. Script membuat akun anonymous sintetis dan membersihkan hanya UUID yang dibuat run itu melalui konfigurasi backend lokal. Tidak menggunakan sesi browser pengguna, OTP atau email nyata. Jangan menjalankan terhadap database tanpa izin pemilik.
