# Alur kerja Danar dan rencana commit backend

**Mulai dari kontrak + profil/menu, tuntaskan catat manual, lalu integrasikan AI.** Rencana awal dibuat 10 November 2026 WIB berdasarkan [kebutuhan](backend-requirements.md) dan [rancangan API/data](backend-design.md). Daftar di bawah adalah baseline rencana; implementasi/branch/PR serta batas verifikasi aktual ada di [status backend](backend-progress.md).

## Cara menjalankan pekerjaan sehari-hari

1. Pilih satu tahap kecil dari tabel. Pastikan endpoint, payload, fixture, dan kriteria selesainya jelas sebelum coding.
2. Mulai dari branch terbaru tanpa menghapus perubahan rekan. Bagi tugas berdasarkan folder: Danar `backend/`, Kwien `mobile/`, Miguel adapter/prompt yang disepakati, Razan handoff desain.
3. Kerjakan schema -> service/aturan -> route -> skenario verifikasi yang relevan -> dokumentasi kontrak. Route tidak memuat seluruh logika bisnis.
4. Uji dengan token demo dan database dev terisolasi. Uji akses akun B terhadap data A untuk endpoint privat baru, bukan hanya happy path.
5. Review diff, pastikan secret/data nyata tidak ikut, lalu commit hanya file tahap itu dengan pesan spesifik. Sertakan hasil tes aktual pada PR/handoff.
6. Push branch secara berkala dan beri Kwien payload/base URL yang sudah dapat dicoba. Jangan menyebut fixture sebagai endpoint yang sudah berjalan.
7. Integrasikan dengan merge commit biasa. Branch yang sudah di-push tidak di-rebase, squash, amend atau force-push menurut ketentuan riwayat guidebook. Perbaikan dibuat sebagai commit baru.

Satu tahap boleh membutuhkan lebih dari satu commit bila perubahan nyata memang terpisah. Tidak perlu memecah kode setengah jalan hanya untuk memperbanyak commit. Waktu commit adalah waktu kerja sebenarnya.

## Urutan commit implementasi

Nama path pada tabel mengikuti struktur usulan; sesuaikan ketika source code benar-benar dibuat. Setiap tahap berikut membawa pemeriksaan yang relevan bersama fiturnya, bukan menunda semua testing ke tahap terakhir.

| No. | Pesan commit yang dituju | Isi konkret | Syarat selesai / bukti | Dependensi |
| --- | --- | --- | --- | --- |
| 01 | `chore(backend): bootstrap FastAPI settings and tooling` | `backend/pyproject.toml`, lockfile, app factory, config, health, `.env.example`, root `.gitignore`, lint/test CI | Install dari environment bersih; health 200; missing config gagal jelas; secret tidak terlacak | Rencana ini |
| 02 | `docs(api): define v1 schemas and frontend fixtures` | Pydantic request/response/enum, bentuk error, OpenAPI awal, contoh photo/journal/check/profile untuk FE | Fixture tervalidasi oleh schema; sepakat field wajib, null/unknown, waktu, severity dan versioning dengan FE/AI | 01 |
| 03 | `feat(db): add owned schema migrations and curated catalog seed` | Model, Alembic, constraint/index owner, katalog/bahan/sumber, seed sintetis deterministik | DB kosong -> upgrade -> seed dua kali tanpa duplikasi; rollback hanya diuji pada DB dev sekali pakai | 02 |
| 04 | `feat(auth): verify Supabase sessions and isolate demo data` | Auth dependency, issuer/audience, ownership query, bootstrap sesi demo privat, rate limit | Token invalid/expired ditolak; demo A/B terisolasi; akses silang 404; tanpa bypass owner | 03 |
| 05 | `feat(profile): persist consent assessment and diet profile` | Consent dasar/AI, autosave assessment, profil diet terpisah, profile_version | Bisa lanjut draft onboarding; unknown != no; perubahan profil tersimpan dan version conflict 409 | 04 |
| 06 | `feat(rules): add versioned demo routing and assessment` | Routing cakupan/bantuan/konsultasi/lengkapi, aturan sintetis, reasons/allowed_actions | Contoh Q2=2 gagal pola; Q2=4/Q3=8 dan 2 kaitan memenuhi; red flag mendahului pola; hasil pola tidak membuka diet sendiri | 05 |
| 07 | `feat(menu): evaluate constraints and rank curated menus` | Search/detail katalog, food-check, konflik, ketidakpastian, ranking deterministik dan gate akses | Dua profil berbeda hasil/alasan; alergi tidak lolos karena murah; porsi/substitusi/profil berubah -> cek ulang | 06 |
| 08 | `feat(drafts): support manual food and symptom review` | CRUD draft, intent, optimistic version, unknown ingredients, waktu perkiraan, negasi, save/discard | Manual selesai tanpa AI; before_meal belum jadi event; draft yang disimpan bisa dilanjutkan setelah reopen | 07 |
| 09 | `feat(records): commit reviewed journal batches idempotently` | Transaksi food/symptom/link, snapshot evaluasi, Idempotency-Key, unique committed draft | Dua request bersamaan -> satu batch; key sama payload beda -> 409; key berbeda draft sama tidak duplikat; invalid satu kartu -> rollback semua | 08 |
| 10 | `feat(history): add owned timeline edit and delete` | List/detail/filter/cursor, edit event berversi, hapus/link cleanup | Reopen tetap ada; akses silang gagal; hapus makanan tidak diam-diam menghapus gejala terpisah | 09 |
| 11 | `feat(planning): add meal plans and shopping checklist` | CRUD jadwal, checklist dari menu/manual, unit/qty merge | Jadwal/centang belanja tidak membuat konsumsi; unit berbeda tidak dijumlahkan sembarang; owner diuji | 07, 10 |
| 12 | `feat(media): store private food photos with owned access` | Upload tervalidasi, size/type limit, private path, retention option | Akun lain tidak bisa baca/hapus media; tidak memakai URL publik; invalid image ditolak | 04, 08 |
| 13 | `feat(ai): integrate consented photo and journal draft adapters` | Adapter Miguel, schema validation, timeout/retry dedup, consent saat dispatch, kuota, metrik token | Foto minta konfirmasi saus; jurnal mempertahankan negasi; invalid JSON/timeouts/AI off -> manual; dua aksi inti = dua panggilan normal | 02, 08–10, 12 |
| 14 | `feat(dashboard): derive today and descriptive summaries` | Rencana/catatan/count/hari lengkap, 7/30 hari, basis catatan dan konsultasi | Draft/negasi tidak dihitung sebagai gejala; minim data ditandai; edit/hapus/ref profil direfleksikan; timezone batas hari benar | 10, 11 |
| 15 | `test(backend): verify end-to-end demo and failure paths` | Tes integrasi lintas modul, regresi concurrency/owner/consent, smoke dengan Flutter dan provider nyata | Semua skenario tabel penerimaan di bawah punya hasil aktual; kegagalan diperbaiki dalam commit `fix(...)` spesifik | 13, 14 |
| 16 | `docs(release): publish verified setup demo access and attribution` | README dari source nyata, env/migrasi/seed/run, deployment guide, atribusi, model/version, bukti tes/demo | Clone bersih bisa dijalankan; backend HTTPS aktif; APK/video/commit final konsisten; tidak mengisi klaim yang belum diuji | 15 |

Tahap 11/12 bisa dikerjakan setelah dependensinya siap tanpa menunggu semua baris sebelumnya. Dashboard tidak perlu menunggu integrasi AI karena inputnya event tersimpan. Setiap commit fitur sebaiknya tetap dapat dijalankan; endpoint belum tersedia jangan diiklankan sebagai sudah selesai.

## Target waktu yang realistis dari 10 November

Ini rencana padat; waktunya tergantung progres tim yang belum ada di repo. Tutup satu alur end-to-end lebih dahulu dan laporkan hambatan, bukan menyamarkan fitur yang belum jalan.

| Waktu WIB | Target Danar | Output untuk rekan |
| --- | --- | --- |
| 10 Nov, sesi 1 | Tahap 01–04: bootstrap, schema/fixture, DB/Auth | Kwien mendapat kontrak/mock; Miguel mendapat schema adapter; database dev bisa diakses backend |
| 10 Nov, sesi 2 | Tahap 05–07: profil, routing dan katalog | Dua profil sintetis dengan alasan berbeda; Kwien integrasi onboarding/menu |
| 11 Nov, sesi 1 | Tahap 08–10: manual -> commit -> history; mulai dashboard | Alur manual tersimpan/reopen; uji klik ganda dan ownership |
| 11 Nov, sesi 2 | Tahap 11–14: rencana/belanja/media, sambung AI dan selesaikan dashboard | Satu build MVP lengkap; foto dan jurnal nyata, bukan fixture |
| 12 Nov | Freeze fitur internal; tahap 15 dan perbaikan | Uji silang FE/backend/AI, red flags sintetis, failure cases dan akses data |
| 13 Nov | Release candidate dan tahap 16 | Clone bersih, deploy backend, build APK, rekam video, audit README/link |
| 14 Nov | Smoke akses/kuota/link dan submission | Final commit/hash serta APK/backend/video cocok; batas dokumen resmi 23.59 WIB |

Jika tertinggal: tunda OCR, merchant, ekspor, suara, pengingat, dan penjelasan AI tambahan. Pertahankan profil/menu, input manual, ownership, transaksi/idempotency, dua pipeline utama, dan dashboard faktual. Negosiasikan scope dengan tim untuk rencana/belanja bila perlu; jangan diam-diam mengklaim semua MVP sudah selesai.

## Handoff minimum supaya tim tidak saling menunggu

**Ke Kwien:** kontrak JSON dan enum, contoh error/empty/needs_confirmation/saved, base URL dev dan cara auth demo, cara mengirim Idempotency-Key serta versi draft. Android emulator dan perangkat fisik punya base URL berbeda; URL aktual dicatat setelah server ada. Untuk retry simpan gunakan key yang sama selama payload tidak berubah. Setelah mutation berhasil refresh endpoint terkait.

**Ke Miguel:** schema `photo_to_draft`/`journal_to_draft`, input reference date/timezone, daftar ID bahan, aturan unknown dan negasi, timeout dan batas payload. Miguel menyerahkan prompt/schema version, fixture, evaluasi, model ID yang diverifikasi dan token usage; Danar memvalidasi output dan memegang persistensi/ownership.

**Ke Razan:** selesaikan gap izin dasar/AI, umur rentang, istilah tab, OTP, copy hasil demo, serta fitur P4. Status cek empat warna berbeda dari status proses. Alasan dari server singkat dan tidak memberi jaminan aman.

## Checklist penerimaan sebelum release

| Skenario | Hasil yang wajib terlihat |
| --- | --- |
| Dua profil, katalog sama | Pilihan/alasan berbeda dan deterministik dari seed yang jelas |
| Alergi vs budget | Konflik tetap diperingatkan dan tidak masuk rekomendasi hanya karena murah |
| Saus/bahan ambigu | `missing_information`; tidak dianggap bebas alergen |
| Ganti porsi/bahan/profil | Cek memakai nilai/versi terbaru tanpa panggilan AI baru |
| Before meal / rencana / belanja | Tidak menambah food event |
| Sudah dimakan | Waktu dan isi dikonfirmasi sebelum commit; makanan berkonflik tetap bisa dicatat sebagai fakta |
| Jurnal negasi | Uji PRD “nggak mual” dan variasi hi-fi “nggak muntah”; keduanya tidak berubah menjadi gejala hadir |
| Simpan berulang/concurrent | Satu batch, hasil response konsisten; conflict dan rollback teruji |
| AI off/izin dicabut/error/kuota | Tidak ada panggilan tanpa izin; manual tetap tersimpan |
| Tutup/buka app | Data persisten terambil ulang, bukan hanya state lokal |
| Edit/hapus catatan | Riwayat, Hari Ini dan ringkasan diperbarui; negasi tidak masuk count gejala |
| Akun lain dan media | Baca/edit/hapus silang ditolak pada semua resource privat |
| Minim data dan timezone | Keterbatasan jelas; batas hari WIB benar; tidak ada klaim pemicu/diagnosis |
| Submission | README akurat, repo publik, akses demo bisa dipakai, kuota aktif, video 3–5 menit, hash/build sama |

Pada implementasi gunakan lint + unit test aturan/schema, lalu integration test DB nyata untuk transaksi, constraint, ownership, serta concurrency. In-memory mock saja tidak membuktikan unique constraint/rollback. Smoke Flutter dan AI nyata diperlukan untuk klaim demo; fixture membantu pengembangan tetapi bukan pengganti.

## Workflow Git dan koneksi repository

Workspace ini sudah memiliki remote `origin` ke `https://github.com/danariqbalabi/AIBS.git`. Saat mulai analisis, branch `main` lokal dan remote sama-sama menunjuk `05c1863` dan working tree bersih. Dokumentasi ini dibuat di `docs/backend-plan`.

Contoh memulai fitur setelah branch dokumentasi diintegrasikan; jalankan sebagai perintah terpisah:

```powershell
git switch main
git pull --ff-only origin main
git switch -c feat/backend-bootstrap
```

Setelah perubahan dan verifikasi aktual, pilih file secara eksplisit (jangan menambahkan file rahasia):

```powershell
git status --short
git diff --check
git diff
git add -- backend/pyproject.toml backend/app/main.py backend/.env.example .gitignore
git diff --cached
git commit -m "chore(backend): bootstrap FastAPI settings and tooling"
git push -u origin feat/backend-bootstrap
```

Daftar `git add` di atas hanya contoh untuk file yang akan ada pada tahap 01; tambahkan lockfile/test/config terkait yang benar-benar dibuat. Buka PR ke `main`, catat apa yang berubah dan hasil verifikasinya, lalu merge biasa setelah review tim. Bila main berubah, integrasikan dengan `git merge origin/main` setelah fetch dan selesaikan konflik, tanpa menulis ulang commit yang sudah dipublikasikan.

Jangan menambahkan remote duplikat, mengubah user Git tanpa alasan, menaruh PAT dalam URL, atau force-push. Jika push ditolak, perbaiki login/hak akses akun yang benar; jangan mengganti identitas author agar terlihat sebagai anggota lain.

## Definition of done satu fitur

- [ ] Perilaku dan batasan cocok dengan PRD serta kontrak yang disepakati.
- [ ] Endpoint bisa dipanggil FE dengan data persisten dan ownership benar.
- [ ] Skenario gagal yang relevan teruji; error cukup jelas untuk UI.
- [ ] Migrasi/seed dan env example diperbarui bila diperlukan.
- [ ] Tes relevan lulus; hasil aktual dicatat pada PR, tidak diasumsikan.
- [ ] Tidak ada secret, data pasien nyata, atau log payload sensitif.
- [ ] Dokumentasi/mock/schema sesuai implementasi terbaru.
- [ ] Commit berisi perubahan nyata, sudah di-push, dan integrasi FE diverifikasi.
