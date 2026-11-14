# Integrasi FE–BE dan pengujian AIBS

Status integrasi awal 14 November 2026. Pembaruan audit PRD ada di [kesiapan demo](hackathon-readiness.md); angka tes dan status deployment di bawah merupakan snapshot historis. Implementasi fitur sudah masuk `main` melalui PR #31–#33; pemeriksaan Flutter/web/APK masuk melalui PR #35. Target hosting beralih ke **Vercel Hobby** setelah verifikasi kartu Render gagal. Branch `feat/vercel-deployment` memuat adaptasi backend dan Flutter Web. Desain dipertahankan; deployment publik belum dinyatakan berhasil. Ikuti [panduan Vercel](vercel-deployment.md).

## Jalankan lokal

Konfigurasi lokal yang diabaikan Git:

- `backend/.env`: database URL, Supabase service-role, Gemini, dan CORS.
- `frontend/config/local.json`: API base URL, Supabase URL, dan publishable key client. Tidak boleh berisi secret server.

Dari folder `backend`:

```powershell
uv sync --locked
uv run alembic upgrade head
uv run python -m seeds.catalog
uv run uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000 --no-access-log
```

Dari folder `frontend`:

```powershell
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define-from-file=config/local.json
```

Jika Flutter masih terbuka, lakukan hot restart dengan `R`. Perubahan dart-define memerlukan stop/run ulang; perubahan `.env` memerlukan restart backend. Pastikan `/ready` menghasilkan 200. Panduan hosting ada di [vercel-deployment.md](vercel-deployment.md).

## Alur yang terhubung

| Area | Perilaku |
| --- | --- |
| Sesi | Supabase JWT nyata; refresh menunggu pemulihan sesi, kegagalan tidak mengganti identitas atau dianggap riwayat kosong |
| Email | OTP Supabase; anonymous dapat ditautkan ke email dengan UUID yang sama. Pengiriman inbox menunggu SMTP/template |
| Profil | Consent/screening/diet tersimpan. Rentang bulan tetap rentang. Bahan khusus disimpan sebagai nama; batasan di luar katalog membuat penilaian konservatif |
| Makanan/gejala | Draft → konfirmasi → commit dengan versi dan idempotency key. Edit/hapus memakai owner dan versi; tautan makanan–gejala memeriksa urutan waktu |
| NLP | Cerita dikirim hanya saat AI aktif dan pengguna meminta analisis; hasil terstruktur dapat dikoreksi, termasuk observasi negatif dan waktu perkiraan |
| Foto | Kamera/galeri menampilkan foto lokal; Analisis mengunggah ke bucket privat lalu memanggil backend. Mode Tanpa AI tetap manual tanpa upload |
| Draft | Draft cerita/foto tampil di Jurnal; bisa dibuka ulang, diedit, disimpan sebagai draft atau dihapus tanpa analisis ulang |
| Cek makanan | Hasil server; tidak otomatis mencatat konsumsi. Simpan konsumsi memerlukan konfirmasi sudah dimakan dan waktu |
| Rencana/belanja | Rencana terpisah dari konsumsi; jumlah/satuan serta status dibeli tersimpan di server |
| Ringkasan | Periode dan kelengkapan mengikuti backend; PDF konsultasi memuat catatan dan pertanyaan pengguna, tanpa klaim penyebab |
| Privasi | ZIP data/foto akun sendiri; hapus data aplikasi dengan konfirmasi; preferensi simpan foto dan masa berlaku foto sementara |

Foto tanpa preferensi simpan kini dihapus setelah percobaan ekstraksi; upload terbengkalai/cleanup gagal memiliki TTL akses 24 jam; akses/analisis ditolak setelah kedaluwarsa. Pada Vercel Hobby, cron harian dan pembersihan terbatas saat upload menggantikan worker permanen; penghapusan fisik dapat tertunda sampai jadwal berikutnya atau retry bila ada kegagalan/backlog. Mematikan simpan foto menghapus foto milik akun tersebut dan mempertahankan isi catatan. Hapus semua data menghapus data aplikasi dan foto; identitas login Supabase tetap ada.

## Bukti pengujian

- Lokal: **88 tes backend lulus, 2 dilewati** karena memerlukan PostgreSQL disposable/row locks; lint dan ekspor kontrak diperiksa. **42 tes Flutter lulus**, format/analyze bersih.
- CI backend pada main: PostgreSQL dan Python 3.12/3.13 berhasil. [Run backend](https://github.com/danariqbalabi/AIBS/actions/runs/43563137341).
- Migrasi `0002` diterapkan ke Supabase; `alembic check` tidak menemukan selisih schema.
- Smoke API nyata: readiness DB, browser CORS, dua anonymous JWT, bootstrap Nadia/Raka dengan status menu berbeda; commit/replay tanpa duplikasi; tautan gejala; penolakan akses lintas akun; rencana, belanja/checked, dashboard/ringkasan, dan penolakan AI saat consent mati.
- Gemini nyata: ekstraksi cerita sintetis mempertahankan negasi tidak mual; hasil belum terkonfirmasi; request sama mengembalikan draft sama; review dan commit/replay berhasil tanpa duplikasi.
- Storage Supabase nyata: upload privat, ZIP berisi data dan foto akun uji, lalu penghapusan data/foto berhasil. Semua akun sintetis pada smoke ini dibersihkan. Data akun pengguna tidak dihapus atau digabung.
- Format/analyze/test, build release web, build APK debug ARM64 dan upload artifact berhasil pada [run Flutter 43563381257](https://github.com/danariqbalabi/AIBS/actions/runs/43563381257). Artifact `aibs-android-debug` baru pemeriksaan kompilasi tanpa key client; APK demo terhubung dibangun setelah URL Render siap. Tes perangkat belum tersedia.
- Pengujian Chrome sebelumnya mencapai dashboard, restore session, dan commit manual 200. [Capture Jurnal setelah reload](integration-evidence/journal-after-reload.png) memperlihatkan makanan uji; assertion terakhir runner browser lama gagal menemukan locator Flutter. Runner browser menyeluruh untuk fitur baru belum diklaim lulus.

## Urutan tes pengguna

1. Jalankan backend dan Flutter. Pilih demo Nadia; tambah makanan manual dan gejala yang dihubungkan. Refresh: data tetap ada.
2. Edit makanan/gejala, simpan, refresh; lalu uji hapus. Waktu makanan setelah gejala yang terhubung harus ditolak, input tetap tersedia.
3. Buat rencana dan checklist belanja; tandai dibeli lalu refresh. Rencana tidak menambah catatan konsumsi.
4. Aktifkan Bantuan AI di Privasi. Ceritakan makanan dan gejala, termasuk kalimat “tidak mual”. Review hasil, konfirmasi waktu dan sudah dimakan, simpan. Negasi tidak menambah jumlah gejala positif.
5. Analisis foto makanan. Periksa nama, bahan/saus, porsi, waktu dan konsumsi; koreksi sebelum simpan. Simpan sebagai draft lalu refresh dan lanjutkan lewat Jurnal.
6. Matikan AI. Cerita/foto tidak dikirim ke AI; isi manual tetap tersedia.
7. Unduh data saya dan PDF konsultasi. Hapus semua data hanya pada akun uji setelah membaca konfirmasi; tindakan tidak dapat dibatalkan.
8. Setelah SMTP siap, hubungkan akun demo ke email, verifikasi OTP sendiri, logout/login email yang sama, lalu pastikan catatan tetap ada. Jangan kirim OTP/password/secret ke chat.

## Refresh dan logout

**F5 berbeda dari logout.** F5 pada origin dan profil Chrome yang sama memulihkan subject beserta catatan. Logout anonymous membuang akses ke sesi demo itu; Nadia/Raka bukan kredensial untuk masuk kembali. Data server tetap ada, tetapi sesi baru tidak boleh membaca data subject lama. Gunakan email OTP yang sama untuk login ulang permanen; tautkan email sebelum logout anonymous jika ingin mempertahankan akses.

Menghapus browser storage, mengganti origin/port, atau memakai profil Chrome baru dapat kehilangan akses ke sesi anonymous lama. Sesi anonymous yang sudah di-logout tidak otomatis dipindahkan. Tidak ada akun Nadia bersama dan token yang dihapus saat logout tidak disimpan ulang.

## Yang masih membutuhkan tindakan luar repo

- Dua project Vercel dan koneksi GitHub pemilik; isi environment variables langsung di dashboard, deploy backend/frontend, lalu daftarkan origin frontend pada CORS backend. Jangan menaruh secret backend di frontend.
- SMTP dan template OTP/Change email Supabase serta inbox untuk pengujian login nyata.
- HP Android atau emulator. Build lokal pertama kehabisan memori JVM; heap Gradle kini dibatasi dan CI menyiapkan build APK. Build yang berhasil tetap perlu tes kamera, login, dan persistensi di perangkat.
- `frontend/ios` belum tersedia; iOS belum dibangun/diuji. Default `AibsApp()` tanpa services hanya fixture tes UI, bukan fallback produksi.

[Rincian branch/commit](app-completion.md). [Audit sebelum integrasi](integration-design-audit-2026-11-14.md) adalah snapshot historis source `012a497`; gunakan dokumen ini untuk status integrasi terbaru.
