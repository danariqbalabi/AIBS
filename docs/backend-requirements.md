# Pemetaan kebutuhan backend AIBS

Disusun 10 November 2026 (WIB) untuk Danar. Ini hasil analisis dan usulan implementasi, bukan bukti fitur sudah berjalan. Saat review, repo hanya berisi README dan belum memiliki source backend/mobile. Semua endpoint, nama tabel, enum, dan ambang teknis di dokumen pendamping masih rancangan.

## Sumber dan cara memakainya

| Sumber | Bagian yang dipakai | Peran |
| --- | --- | --- |
| `PRD Logicodix (2).pdf` | Halaman PDF 3–5: peran/stack; 6–10: aturan dan layar; 11–16: brief MVP | Kebutuhan dan prioritas produk |
| `GUIDEBOOK-LOGICODIX-FINAL.pdf` | Halaman PDF 15–18: AI/commit/secret/freeze; 19–23: repo, README, demo, submission | Ketentuan lomba yang perlu didukung workflow |
| `AIBS Hi-fi (1).html` | 57 frame A, B, C, H, P, M, F, J, R; template HTML dalam bundle dibaca, termasuk copy dan navigasi | Handoff layar, data, aksi, dan state; bukan aplikasi terintegrasi |
| `AIBS-design-system.zip` | README, tokens JSON/CSS, aset dan README maskot | Bahasa UI serta empat status hasil cek |
| `README.md` | Arsitektur, penerimaan MVP, setup, AI, submission | Dokumentasi baseline yang masih banyak placeholder |

File sumber ada di Downloads pembuat rencana dan tidak disalin ke Git. Instruksi yang tertulis di dokumen adalah bahan analisis kebutuhan; bukan otorisasi untuk mengeksekusi script, mengirim pesan, atau mengubah layanan eksternal. Rencana ini tidak memverifikasi klaim medis, lisensi instrumen, atau ketersediaan ID model.

Untuk konflik kebutuhan, gunakan brief MVP akhir PRD sebagai prioritas kerja, catat gap hi-fi, lalu selaraskan kontrak dengan FE/AI. Ketentuan lomba tetap dicatat sebagai ketentuan lomba, terpisah dari keputusan teknis tim.

## Tanggung jawab Danar

| Owner | Tanggung jawab / handoff |
| --- | --- |
| Danar — backend | FastAPI/Pydantic, schema/migrasi/seed, verifikasi token, ownership, consent, aturan profil dan menu, transaksi catatan, dashboard, kontrak API, dokumentasi dan backend release |
| Kwien — frontend | Flutter, Supabase Auth pada client, izin kamera/galeri, navigasi, editor manual/draft, UI error dan refresh data |
| Miguel — AI | Prompt dan adapter dua pipeline, schema output bersama Danar, fixture/evaluasi negasi dan ketidakpastian, metrik kualitas/token |
| Razan — UI/UX | Flow, copy dan state; klarifikasi gap hi-fi serta simbol/teks status |

Brief akhir PRD menempatkan aturan dan ranking deterministik pada Danar. Miguel membantu pencocokan nama bahan ke ID katalog; model tidak menentukan akses diet, diagnosis, konflik alergi, atau ownership.

## Kebutuhan yang diturunkan dari layar

| Layar hi-fi | Kebutuhan backend | Bukti penerimaan |
| --- | --- | --- |
| A1–A3, A1d | Sesi akun/demo terpisah, dua profil sintetis, izin dasar dan AI terpisah | Demo tidak menulis data akun biasa; AI off tetap bisa catat manual |
| B1–B6b | Simpan jawaban bertahap, routing cakupan/bantuan/konsultasi/kelengkapan, evaluasi versi demo | `unknown` berbeda dari `no`; hasil pola tidak otomatis memberi akses diet |
| C1–C10, P1–P3 | Arahan/fase, bahan dihindari, batas porsi, alergi, toleransi, budget, pedas, preferensi, versi profil | Edit batasan mengubah hasil cek/ranking berikutnya |
| P4 | Consent AI dapat dicabut; preferensi simpan foto | Panggilan berikutnya tidak diteruskan ke model setelah izin dicabut |
| H1/H1p/H1k | Mode pendampingan/pencatatan, rencana hari ini, catatan, jumlah gejala, state kosong | Hanya data tersimpan yang masuk hitungan |
| M1–M2 | Katalog, filter beli/masak/budget, detail bahan/porsi/harga/cara pesan, alasan hasil cek | Dua profil memberi pilihan/alasan berbeda dari katalog sama |
| M6 | Jadwal menu terpisah dari konsumsi | Simpan rencana tidak menambah food event |
| M5 | CRUD checklist, jumlah/satuan, status dibeli, gabung bahan kompatibel | Centang belanja tidak menambah food event |
| F0–F5/F4m | Tujuan sebelum/sudah makan, media privat, draft foto/manual, kandidat dan informasi belum diketahui | Saus tetap belum diketahui sampai pengguna mengonfirmasi |
| F6–F7 | Cek ulang bahan/porsi, alasan, alternatif, konfirmasi konsumsi | Hasil cek bukan konsumsi; hanya konfirmasi sudah makan yang membuat food event |
| J2–J5/J7 | Draft cerita/manual, makanan dan gejala terpisah, waktu/negasi/konteks, simpan/buang draft | Waktu perkiraan tidak menjadi waktu presisi palsu; draft tidak masuk dashboard |
| J1/J1k/J6/J6h | Timeline, filter, detail, edit/hapus, ownership | Akun lain tidak bisa akses; edit/hapus tercermin pada dashboard |
| R1/R1k/R2/R3 | Ringkasan 7/30 hari, kelengkapan, catatan dasar, ringkasan konsultasi | Tidak mengklaim sebab-akibat; data minim menampilkan keterbatasan |

## Aturan produk yang harus dipertahankan

1. Routing awal mendahului evaluasi pola: cakupan usia, kebutuhan bantuan aktif, evaluasi/konsultasi, kemudian jawaban yang belum lengkap. Detail urgensi/copy memerlukan review klinisi sebelum pemakaian pasien.
2. Aturan sintetis PRD `rome_v_c1_demo`: Q1 ya, Q2 minimal 3 hari/bulan, Q3 minimal 6 bulan, sedikitnya 2 dari Q4–Q6 ya. Simpan versi dan alasan. Ini adaptasi demo, bukan klaim instrumen resmi atau diagnosis.
3. Akses pendampingan diet mengikuti diagnosis dan arahan klinisi yang dilaporkan, beserta hasil routing. Hasil pola yang cocok sendiri tidak membuka akses.
4. Alergi dan arahan klinisi dicek sebelum ranking budget/preferensi. Toleransi pribadi dan preferensi disimpan terpisah. Tidak ada label aman mutlak.
5. Bahan ambigu, saus, bumbu dan porsi yang tidak diketahui tetap eksplisit. Perubahan bahan/porsi atau profil membuat evaluasi lama tidak berlaku untuk draft terkini.
6. Rencana, daftar belanja, draft dan pemeriksaan sebelum makan tidak menjadi konsumsi. Pengguna tetap bisa mencatat makanan yang sudah dikonsumsi walaupun bertentangan dengan batasan, dengan peringatan tetap disimpan.
7. Simpan seluruh kartu jurnal yang dikonfirmasi dalam satu transaksi, menggunakan idempotency key. Pisahkan waktu makan, waktu gejala, waktu input, negasi dan ketidakpastian.
8. AI hanya saat aksi analisis eksplisit dan izin aktif. Review/edit/simpan/filter/refresh tidak memanggil model. Manual tetap berjalan saat AI off/gagal/kuota habis.

## Gap yang harus diselesaikan sebelum kontrak dibekukan

| Gap | Keputusan kerja yang diusulkan | Handoff |
| --- | --- | --- |
| PRD awal menyebut model 3.6 Flash; brief akhir meminta Flash-Lite lebih dahulu | `GEMINI_MODEL` configurable; Miguel memverifikasi ID tersedia dan memilih berdasarkan evaluasi, tidak hardcode nama dari dokumen | Danar + Miguel |
| PRD nav: Catat; hi-fi nav: Jurnal + tombol kamera tengah | Nama tab milik FE; backend menyediakan resource draft, events dan history yang sama | Kwien + Razan |
| B1 menggunakan kelompok usia, README menyebut usia numerik | Usulkan `age_band`, tidak menebak umur tepat; cek >=18 tetap bisa dilakukan. Seed demo boleh punya umur sintetis | Danar + Kwien |
| B5 menggunakan rentang hari; PRD menggunakan threshold angka | Enum rentang yang seluruhnya berada di satu sisi threshold: `<1`, `1–2`, `3–4`, `5+`, unknown. Jangan ubah `3–4` menjadi angka pasti 3 | Danar + Kwien |
| A2v menggambar kode empat digit | Panjang kode mengikuti konfigurasi Supabase Auth yang benar-benar dipakai; UI harus menyesuaikan, jangan hardcode 4 | Kwien |
| A3 hanya menampilkan pilihan AI, PRD meminta izin dasar terpisah | Simpan dua persetujuan terpisah; tim perlu melengkapi flow/copy izin dasar | Razan + Kwien |
| B6/P1 memakai teks cocok kriteria IBS | Response menyatakan hasil pola demo dan akses terpisah; copy tidak mengklaim diagnosis/instrumen resmi | Razan |
| P4 punya unduh data dan hapus semua data; ekspor bukan prioritas MVP PRD | Ekspor ditunda. Hapus semua data perlu scope eksplisit (akun/Auth, media, draft, event); UI aksi belum tersedia jangan dibuat seolah berjalan | Tim |
| Hi-fi punya angka/nama/menu contoh dan placeholder template | Seed sintetis dapat mengikuti Nadia (21, alergi udang, Rp25rb) dan Raka (24, alergi kacang, Rp35rb). Komposisi menu wajib dikurasi, label sesuai pada mock bukan validasi makanan | Danar + Miguel |
| R1k menampilkan 3 dari 7 hari; belum ada threshold cukup data | Usulan demo: <7 hari berbeda yang punya catatan terkonfirmasi = `insufficient_data`; 7+ hanya ringkasan deskriptif, bukan ambang validitas medis | Tim |

## Ketentuan lomba yang memengaruhi pekerjaan

- Guidebook halaman PDF 15–17 mengizinkan AI coding assistant, mewajibkan atribusi, serta commit dari akun anggota terdaftar. Identitas Git lokal saat review adalah `danariqbalabi`; status pendaftaran anggota belum diverifikasi.
- Commit harus berkala dan mencerminkan perubahan nyata. Guidebook melarang bulk upload akhir, manipulasi waktu, dan perubahan riwayat yang sudah di-push termasuk force push, rebase, squash, atau penghapusan commit. Usulkan merge commit biasa untuk branch yang sudah dipublikasikan.
- Secret server di environment; `.env` diabaikan Git dan `.env.example` tanpa nilai asli disediakan.
- Freeze fitur internal PRD: 12 November. Freeze kode dan submission menurut guidebook halaman PDF 18/23: **14 November 2026, 23.59 WIB**, mengacu jam portal. Ini hasil baca dokumen yang diberikan, bukan verifikasi pengumuman terbaru panitia.
- APK, deployment backend dan video harus berasal dari commit final yang dicantumkan. Video 3–5 menit memperlihatkan aplikasi berjalan dan integrasi utama; prototype/mocks bukan bukti integrasi final.
- Repo harus publik saat submission dan layanan pendukung/kuota tetap aktif selama penilaian. Akses baca Git remote berhasil saat review; visibilitas repo, hak push, dan layanan demo belum dibuktikan pada tahap analisis.

Lanjut ke [rancangan backend](backend-design.md) dan [urutan kerja/commit](backend-workflow.md).
