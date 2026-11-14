# Deploy demo AIBS ke Render Free

**Panduan historis:** pengguna beralih ke Vercel karena verifikasi kartu Render gagal. Gunakan [panduan Vercel](vercel-deployment.md) untuk deployment sekarang. Docker/Render tetap tersedia sebagai alternatif.

Konfigurasi repo ada di `render.yaml`. Backend memakai Docker, satu instance Free, dan Supabase untuk database/storage. Frontend Flutter tetap dapat dijalankan di Chrome atau dibangun menjadi APK. Deployment belum dilakukan sampai pemilik menghubungkan akun Render.

## Langkah pemilik akun

1. Buka https://dashboard.render.com, daftar/login dengan GitHub.
2. Pilih **New > Blueprint**, hubungkan repo `danariqbalabi/AIBS`. Pilih branch **feat/app-completion** untuk pengujian perubahan ini.
3. Render membaca `render.yaml`; pastikan service **aibs-api**, region **Singapore**, plan **Free**. Blueprint ini tidak membuat database berbayar.
4. Isi variabel yang diminta dari `backend/.env` langsung di Render:

   | Variabel | Isi |
   | --- | --- |
   | DATABASE_URL | URL Supabase **Session pooler**, awalan `postgresql+psycopg://`, tambahkan `?sslmode=require` (atau `&sslmode=require` jika sudah ada query). Password harus URL-encoded. |
   | SUPABASE_SERVICE_ROLE_KEY | Key server Supabase; hanya di backend |
   | GEMINI_API_KEY | Key Gemini backend |
   | GEMINI_MODEL | Model yang sudah diuji pada konfigurasi lokal |

5. Deploy lalu tunggu status **Live**. Saat startup, backend menjalankan migrasi dan seed katalog sintetis dalam transaksi dengan advisory lock. Ini tidak mereset catatan pengguna. Kegagalan migrasi menghentikan startup.
6. Buka `https://NAMA-SERVICE.onrender.com/ready`: hasil yang diharapkan `{"status":"ready"}`. Buka `/docs` untuk Swagger.

Jangan upload `.env` ke GitHub, mengisi key server ke Flutter, atau menggunakan database lokal SQLite pada Render. [Panduan FastAPI Render](https://render.com/docs/deploy-fastapi), [spesifikasi Blueprint](https://render.com/docs/blueprint-spec), [batas Free](https://render.com/docs/free).

## Hubungkan Flutter

Duplikat `frontend/config/example.json` menjadi `frontend/config/render.local.json` (diabaikan Git), isi URL backend HTTPS di `API_BASE_URL`, URL Supabase, dan **publishable** key. Jalankan dari folder frontend:

```powershell
flutter run -d chrome --web-port 5173 --dart-define-from-file=config/render.local.json
```

Jika frontend nanti di-host pada domain lain, tambahkan origin persisnya ke `CORS_ORIGINS` di Render, contoh `["http://localhost:5173","https://aibs.example.com"]`. Jangan memakai wildcard. APK menggunakan URL backend yang sama; `localhost` pada HP berarti HP itu sendiri.

Layanan Free tidur setelah idle dan perlu waktu saat aktif kembali. Buka `/ready` dan tunggu respons sebelum memulai demo; jika permintaan aplikasi timeout, input tetap dipertahankan dan dapat dicoba ulang. Jangan mengulang analisis AI berulang kali karena kuota provider.

## APK untuk pengujian

```powershell
flutter build apk --debug --dart-define-from-file=config/render.local.json
```

File: `frontend/build/app/outputs/flutter-apk/app-debug.apk`. Ini APK demo untuk instalasi manual, belum distribusi Play Store. Build tidak membuktikan kamera, login, dan persistensi bekerja di perangkat. Pengujian Android nyata menunggu HP/emulator tersedia.

## Verifikasi sebelum demo

Workflow **Flutter** di GitHub Actions memeriksa format, analyze, test, build web, dan build APK debug ARM64. Artifact `aibs-android-debug` disimpan tujuh hari. Pada push/PR, APK hanya untuk pemeriksaan kompilasi dan belum diisi key client. Sesudah workflow ada di default branch, **Run workflow** dapat diberi `api_base_url` HTTPS Render dan `supabase_publishable_key` untuk APK demo yang terhubung. Kedua input ini publik; jangan memasukkan service-role atau secret key. [flutter-action](https://github.com/subosito/flutter-action).

- Login akun email yang sama, tambah catatan, refresh, logout/login: catatan tetap ada.
- Ubah dan hapus catatan; akun lain tidak dapat melihatnya.
- Mode Tanpa AI tetap bisa isi manual; cerita/foto tidak dikirim ke AI.
- Periksa error, retry, dan input saat koneksi putus.
- Sesudah perubahan digabung ke main, ubah branch service/Blueprint ke `main` sebelum deployment selanjutnya. Auto deploy sengaja dimatikan; deploy manual setelah pemeriksaan.
