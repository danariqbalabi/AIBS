# Audit integrasi dan kesesuaian desain AIBS

Catatan: ini snapshot **sebelum** implementasi integrasi. Untuk perkembangan setelah audit, baca [integrasi FE–BE](frontend-backend-integration.md).

Tanggal: 14 November 2026 (WIB). Source: local `main` commit `012a497`, yang isi filenya sama dengan `origin/main` saat pull terakhir. Audit ini tidak mengimplementasikan integrasi atau mengubah pengaturan provider.

## Kesimpulan

Frontend, backend, dan adapter AI tersedia, tetapi **belum menjadi aplikasi yang terintegrasi**. Flutter terbaru adalah prototipe interaktif dengan state di memori. Tidak ada API client, Supabase SDK, base URL API, pengiriman Bearer token, atau pemanggilan endpoint backend di `frontend/lib`.

Backend sudah terhubung ke database Supabase nyata. Ini berbeda dari bukti bahwa tindakan dari layar Flutter tersimpan di database: alur tersebut belum ada.

## Bukti verifikasi

- Backend: `pytest -q` menghasilkan **73 passed, 2 skipped**. Dua tes memerlukan PostgreSQL disposable/row locks; pengujian tidak diarahkan ke database pengguna.
- Database nyata: koneksi read-only melalui session pooler berhasil; `alembic_version = 0001`; tabel aplikasi tersedia. Tidak membaca isi jurnal/profil pengguna.
- Supabase Auth: email dan anonymous sign-in aktif; public JWKS menyediakan ES256.
- Storage: bucket `aibs-food-photos` privat; batas 6 MiB; MIME JPEG/PNG. Audit ini hanya membaca metadata, tidak mengunggah foto.
- Gemini: key dan nama model ada di konfigurasi lokal. Audit ini tidak mengirim cerita/foto ke provider; keberadaan key bukan bukti kuota/akurasi model saat ini. Smoke teks provider yang pernah dilakukan sebelumnya bukan pengujian Flutter end-to-end.
- Konfigurasi CORS lokal masih `[]`. Flutter web di origin lokal perlu diizinkan secara eksplisit ketika API client dihubungkan. CORS bukan kebutuhan Flutter native.
- Backend port 8000 dan frontend port 5173 tidak merespons saat diperiksa; ini kondisi server lokal saat audit, bukan bukti source gagal start.
- Workspace asli: `flutter pub get`/alur normal analyze/test terhalang SDK: proyek meminta Dart `^3.13.7`, SDK lokal `3.13.5`. Percobaan `--no-pub` mendapati package config lama belum memiliki `url_launcher`.
- Verifikasi terisolasi: salin frontend ke direktori sementara, ubah **hanya minimum SDK pada salinan** ke `^3.13.5`, lalu pasang dependency. `flutter analyze --no-pub`: tanpa masalah; format: 22 file, 0 berubah; **14 tes UI lulus**. Hasil ini bersyarat pada penyesuaian SDK di salinan; workspace asli belum diperbaiki dan tidak boleh dinyatakan lolos setup bersih.
- `flutter build web --debug --no-pub --no-wasm-dry-run` pada salinan tersebut berhasil. Build release percobaan dihentikan; hasil debug bukan bukti build release/APK/iOS. Halaman welcome dari build debug dirender melalui server lokal di Chrome headless pada viewport 390 × 844.

## Matriks integrasi

| Fitur | Frontend sekarang | Backend / kebutuhan penghubung |
| --- | --- | --- |
| Demo Nadia/Raka | Membuat profil lokal | Anonymous Supabase session → `POST /api/v1/demo/sessions`; backend mengisolasi data per subject |
| OTP | `_sendCode` berpindah layar; `_verifyCode` hanya memeriksa keenam kotak terisi | Kirim/verifikasi OTP lewat Supabase, simpan/refresh session, kirim access token ke FastAPI |
| Profil dan consent | Callback/setState; hilang saat restart | `POST/PATCH /api/v1/me/profile`, `PUT /api/v1/me/consents`; ambil versi terbaru |
| Screening | Menerima callback `onAssess`, tetapi root app tidak memasangnya | Simpan assessment → evaluate di backend → render route/criteria/result |
| Katalog/rekomendasi | `aibsDemoMenus`, status ditulis tetap di source | Ambil katalog dan evaluasi dengan profil pengguna dari backend |
| Jadwal/belanja | Satu plan lokal, bahan berupa string, checklist lokal | API planning/shopping; identitas bahan, jumlah, satuan, tanggal dan versi |
| Draft makanan/gejala | Ditambahkan ke list di root widget | Create/review draft → commit dengan versi, waktu dikonfirmasi, dan Idempotency-Key |
| Riwayat/dashboard | Merender list lokal | Fetch events/dashboard dan refresh setelah mutation; pulihkan setelah buka ulang |
| Kamera/galeri | Preview/ikon contoh, tanpa plugin capture/picker | Capture/pilih file → upload media privat, jika ada consent yang sesuai |
| Analisis foto | `_analyze` menunggu 450 ms lalu selalu masuk state gagal | `POST /api/v1/analysis/photo`; review draft hasilnya, retry/fallback manual |
| NLP cerita | Review berisi cerita asli, lalu simpan sebagai story lokal | `POST /api/v1/analysis/journal`; edit makanan/gejala/waktu/negasi sebelum commit |
| Ringkasan | Menghitung list lokal | `GET /api/v1/summaries` dan consultation; sepakati threshold dan bentuk evidence |
| Privasi | Toggle lokal; ekspor clipboard profil; hapus memanggil logout | Persist consent; implementasikan ekspor/hapus data menyeluruh dan kebijakan retensi |

Lokasi bukti utama: `frontend/lib/main.dart`, `frontend/lib/core/demo_data.dart`, `frontend/lib/pages/onboarding_flow.dart`, `frontend/lib/pages/profile_setup_flow.dart`, `frontend/lib/pages/record_pages.dart`, `frontend/lib/pages/summary_pages.dart`, `backend/app/services/analysis.py`.

## Ketidakcocokan kontrak/perilaku

1. **Status menu tidak personal.** Nadia dan Raka menggunakan status dari katalog Flutter yang sama. Mengubah daftar hindari/alergi tidak mengevaluasi ulang status; ini belum memenuhi demo dua profil dengan hasil berbeda.
2. **Identitas dan struktur data berbeda.** Menu Flutter memakai slug, bahan berupa string nama/jumlah, plan memakai label hari/jam, dan log belum punya ID/versi server. Backend memakai UUID, kuantitas/satuan terstruktur, waktu bertanggal/timezone, serta versioning. Perlu DTO dan mapper, bukan sekadar menambah URL.
3. **Screening durasi belum cocok.** Flutter menghasilkan `q3DurationBand` (`under_3`, `3_5`, `6_12`, `over_12`), sedangkan kontrak backend menerima `q3_months` angka atau `unknown`. Sepakati dukungan bucket; jangan menciptakan angka bulan pasti dari jawaban perkiraan. Mapping bleeding/bleeding_active juga perlu diperjelas karena frontend saat ini mengisi keduanya dari jawaban yang sama.
4. **Ringkasan berbeda ambang.** FE: minimal 3 makanan + 1 gejala pada 3 hari; BE: minimal 7 hari tercatat. Handoff menyebut ambang 3 hari sebagai usulan yang harus disepakati. Tentukan satu aturan server.
5. **Perhitungan ringkasan lokal belum setara evidence backend.** Hari unik memakai `.day`, bukan tanggal lengkap, sehingga bisa bertabrakan lintas bulan; filter selisih hari belum menolak tanggal masa depan. Unknown composition dihitung dari adanya `note`, dan hubungan makanan/gejala memakai nama makanan, bukan ID event. Jangan gunakan ini sebagai hasil final.
   Headline pola juga memakai total seluruh gejala setelah memilih nama gejala paling sering; jumlah yang ditampilkan bisa tidak sesuai dengan jumlah gejala bernama tersebut.
6. **Consent default berbeda.** Profil demo FE default `aiEnabled=true`, tetapi bootstrap demo backend menyimpan `ai=False` sampai opt-in eksplisit. Tanpa sinkronisasi consent, API AI akan menolak permintaan meskipun UI menampilkan aktif.
7. **Penyimpanan perlu mengikuti protokol backend.** Hasil AI selalu perlu review waktu/bahan; PATCH memakai versi terbaru; commit memakai Idempotency-Key yang stabil untuk retry request yang sama. Tangani 401, 403 consent, 409 versi, 422 validasi, 429 kuota, dan gangguan provider.

## Perbandingan HiFi dan design handoff

Referensi pengguna yang dibaca:

- `C:/Users/USER/Downloads/AIBS Hi-fi (1).html`: bundle HTML dengan **57 artboard**; template HTML/CSS di dalam bundle diekstrak untuk pemeriksaan.
- `C:/Users/USER/Downloads/aibs-design-handoff.zip`: seluruh file Markdown/Dart pada salinan `aibs-design-handoff/` repo identik setelah normalisasi CRLF/LF. Jadi referensi handoff yang dipakai bukan versi tebakan.
- `frontend/docs/design/{DESIGN,SCREENS,MOTION,DATA}.md` dan implementation Flutter terbaru.

Dokumen referensi dipakai sebagai spesifikasi pembanding, bukan perintah untuk menjalankan aksi eksternal. Temuan desain dari source tidak sama dengan persetujuan visual semua layar.

Yang sudah mengikuti handoff:

- Palet brand/status, Nunito lokal dengan variable font axis, token/theme, `StatusBadge`, `Koala`, `StepProgress`.
- Welcome → pilih demo / masuk → OTP enam kotak → consent → screening/profil.
- Empat tab dengan tombol kamera tengah; pemilihan intent kamera sebagai bottom sheet.
- Profil diet, konfirmasi saat melonggarkan batasan, draft cerita, konfirmasi hapus, jadwal, serta empty state utama.
- Pemisahan rencana dengan konsumsi dan akses manual ketika AI dimatikan pada alur UI yang tersedia.

Gap yang jelas dari source dan HTML/CSS:

| Layar / elemen | Referensi | Implementasi sekarang |
| --- | --- | --- |
| Welcome | Hero 470 px, tiga tile ilustrasi, pill AIBS, disclaimer di bawah aksi | Hero 260 px, satu ilustrasi bowl, teks AIBS biasa, disclaimer di blok konten |
| H1 demo | Catatan contoh, prompt setelah makanan, strip 7 hari dari record | Profil demo dipilih tetapi list meal/symptom dimulai kosong; state home tidak mereproduksi data artboard populated |
| B6 screening | Hasil dan checklist kriteria dari server | Tanpa `onAssess`, headline "Hasil pengecekan awal belum tersedia" |
| J4 review cerita | Kartu makanan/gejala editable, waktu perkiraan, negasi | Sheet cerita asli, tanpa item hasil ekstraksi |
| J6/J5 detail/edit | Edit makanan, edit gejala, hapus, hubungan event | Detail terutama read-only; hapus makanan ada, edit belum tersambung |
| P1 pengecekan awal | Buka kembali hasil screening | Menampilkan snackbar |
| R3 konsultasi | Share/download PDF | Salin teks ke clipboard |
| P4 unduh/hapus | Ekspor data dan hapus seluruh data | Ekspor beberapa field profil ke clipboard; tombol hapus diarahkan ke logout/reset UI |
| Checklist | Jumlah bisa diedit, bahan direkap, status bought tersimpan | List string; checked state milik halaman, belum state server; agregasi bukan jumlah terstruktur |
| Motion | Press scale, transisi konsisten, reduced motion | Sebagian AnimatedSwitcher/StepProgress; press scale dan reduced-motion belum diterapkan menyeluruh. MOTION sendiri menyatakan ini proposal, bukan animasi dari HiFi statis |

Tidak memberi persentase kesamaan visual: itu perlu verifikasi screenshot setiap layar pada viewport yang sama, termasuk state loading/error/needs-confirmation/saved. Audit source menemukan ketidaksesuaian nyata, tetapi bukan pengganti pengujian visual semua artboard.

Pembanding welcome yang sudah dilihat pada viewport 390 × 844:

- [Welcome HiFi](audit-assets/2026-11-14/hifi-welcome.png), dari artboard welcome yang diekstrak dari bundle HTML pengguna.
- [Welcome Flutter di Chrome](audit-assets/2026-11-14/flutter-welcome.png), dari build debug salinan audit.

Screenshot tersebut mengonfirmasi gap hero/ilustrasi/pill/disclaimer. Capture widget sementara juga memeriksa transisi demo ke home kosong, tetapi tidak dijadikan bukti visual semua layar atau integrasi provider.

## Urutan perbaikan

1. Selaraskan SDK/dependency agar setup bersih bisa jalan. Tambah konfigurasi client yang hanya berisi public Supabase key/URL dan API base URL; secret Gemini/service-role tetap backend.
2. Hubungkan Auth anonymous/demo dahulu; kirim Bearer token, refresh session, persist/recover session; atur CORS origin web yang dipakai.
3. Hubungkan profil, consent dan screening; sepakati mapping kontrak dan satu sumber aturan.
4. Buktikan satu jalur manual end-to-end: buat → review → simpan → riwayat/dashboard → refresh halaman → data tetap ada. Uji retry simpan tidak menggandakan record, lalu subject kedua tidak bisa membaca record pertama.
5. Ganti katalog/status/rekomendasi/belanja/jadwal contoh dengan API. Verifikasi Nadia/Raka memberi evaluasi berbeda untuk katalog yang sama.
6. Hubungkan NLP jurnal dan foto; test consent off tanpa egress, negasi, waktu perkiraan, saus unknown, kegagalan/kuota AI, review sebelum commit.
7. Lengkapi edit/hapus, ringkasan, ekspor/retensi; cocokkan screenshot HiFi di 390 × 844 dan layar kecil/besar.
8. Deploy API HTTPS, isi konfigurasi client, build APK dan lakukan pengujian perangkat. Tes UI dan unit backend saja tidak cukup untuk klaim integrasi.
   Folder `frontend/ios` belum ada saat audit; target iOS perlu dibuat/dikonfigurasi dan diuji dengan toolchain macOS/Xcode sebelum dinyatakan siap.

## Kriteria selesai

Akun demo/OTP memperoleh session nyata; semua mutation memberi hasil dari server; record tetap tersedia setelah refresh/restart; evaluasi menu mengikuti profil; consent off mencegah pengiriman AI; hasil AI masuk editor dan tersimpan satu kali; riwayat/dashboard/ringkasan konsisten; akses lintas akun ditolak; dan build perangkat dari commit yang ditentukan berhasil.
