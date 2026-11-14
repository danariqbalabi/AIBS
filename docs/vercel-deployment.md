# Deploy AIBS ke Vercel Hobby

Target hosting berubah dari Render ke Vercel karena verifikasi kartu Render gagal. Repo menghasilkan dua project: **aibs-api** (FastAPI) dan **aibs-web** (Flutter Web). Database, Auth, dan foto tetap di Supabase yang sama. Desain tidak diubah.

Domain frontend baru mempunyai browser storage berbeda dari localhost. Untuk membuka kembali catatan demo lokal di domain baru, hubungkan sesi anonymous ke email terlebih dahulu lalu login dengan email yang sama. Pindah hosting tidak otomatis memindahkan token browser atau menggabungkan akun demo.

## Backend dahulu

Review/gabungkan PR `feat/vercel-deployment` sebelum mengimpor branch `main`. Jika menggunakan branch fitur untuk demo, atur Production Branch project ke `feat/vercel-deployment` sebelum deployment production.

1. Login https://vercel.com dengan akun pribadi, pilih plan **Hobby**.
2. **Add New → Project**, import repo `danariqbalabi/AIBS`.
3. Nama `aibs-api` (boleh ditambah akhiran), **Root Directory `backend`**, Framework Preset **FastAPI**.
4. Biarkan build mengikuti `backend/vercel.json`/`pyproject.toml`. Tidak memakai Docker, Start Command Uvicorn, atau Output Directory Flutter.
5. Tambahkan environment **Production**:

   | Key | Isi |
   | --- | --- |
   | DATABASE_URL | URL Supabase Session pooler dari `backend/.env`; awalan `postgresql+psycopg://`, gunakan `sslmode=require`, password URL-encoded |
   | SUPABASE_URL | `https://fpaposwwnqdtvvjaelar.supabase.co` |
   | SUPABASE_SERVICE_ROLE_KEY | Nilai server dari `backend/.env` |
   | GEMINI_API_KEY | Nilai backend dari `backend/.env` |
   | GEMINI_MODEL | Model yang sudah diuji pada konfigurasi lokal |
   | CRON_SECRET | Nilai acak di akhir `backend/.env`; jangan kirim ke chat |
   | CORS_ORIGINS | `["http://localhost:5173","http://127.0.0.1:5173"]` |

   APP_ENV production, RUNTIME_MODE serverless, dan MAX_PHOTO_BYTES 4000000 ditetapkan oleh `vercel.json`. Bucket default aibs-food-photos, batas AI default 20/hari. Jangan mengimpor `.env` lokal utuh karena APP_ENV lokal bukan production. Key server hanya pada project backend.

6. Klik **Deploy**. Sesudah **Ready**, buka URL **production** dengan `/ready` dan `/docs`. Hasil `/ready`: `{"status":"ready"}`. URL root `/` boleh 404 karena backend tidak mempunyai halaman utama.
7. Jika route meminta login Vercel, periksa Deployment Protection. API production harus dapat dijangkau publik; endpoint data tetap dilindungi JWT Supabase.

[FastAPI Vercel](https://vercel.com/docs/frameworks/backend/fastapi), [runtime Python](https://vercel.com/docs/functions/runtimes/python).

## Flutter Web

1. Import **repo yang sama sebagai project baru** bernama `aibs-web`.
2. **Root Directory `frontend`**, Framework Preset **Other**.
3. Gunakan `frontend/vercel.json`: Build Command `bash scripts/vercel-build.sh`, Output Directory `build/web`. Script memasang Flutter 3.47.7, menginstal dependency dari lockfile, lalu membangun web.
4. Isi hanya konfigurasi publik:

   | Key | Isi |
   | --- | --- |
   | API_BASE_URL | URL backend HTTPS, tanpa `/docs` atau `/api/v1`; contoh `https://aibs-api-xxxx.vercel.app` |
   | SUPABASE_URL | `https://fpaposwwnqdtvvjaelar.supabase.co` |
   | SUPABASE_PUBLISHABLE_KEY | Key `sb_publishable_...` dari `frontend/config/local.json` |

5. Deploy. Script menolak konfigurasi kosong, URL non-HTTPS, dan key yang bukan publishable tanpa mencetak nilainya.
6. Salin URL frontend production. Pada project **aibs-api → Settings → Environment Variables**, tambahkan origin frontend persis ke `CORS_ORIGINS`:

   ```json
   ["http://localhost:5173","http://127.0.0.1:5173","https://aibs-web-xxxx.vercel.app"]
   ```

7. **Redeploy backend** agar perubahan environment aktif. Tes frontend production; URL preview berbeda perlu whitelist sendiri. Jangan menaruh service-role, Gemini key, atau cron secret pada frontend.

SMTP tetap di Supabase. Template Magic link/OTP dan Change email harus memuat `{{ .Token }}` untuk OTP angka. SMTP sudah disimpan pengguna; pengujian inbox belum diklaim selesai.

## Migrasi dan foto sementara

Import ASGI/request Vercel tidak menjalankan migrasi. Build preview tidak mengubah database production. Migrasi 0002 sudah diterapkan saat tahap sebelumnya. Jika release berikutnya menambah migrasi, jalankan dari folder backend pada lingkungan tepercaya dengan DATABASE_URL tujuan:

```powershell
uv run python -m app.migrate
uv run alembic check
```

Migrasi/seed memakai transaksi/advisory lock dan tidak mereset catatan. Preview yang memerlukan data terpisah harus memakai database/project Supabase terpisah.

Foto sementara tetap kedaluwarsa setelah **24 jam**, lalu ditolak untuk akses/analisis. Vercel Hobby membatasi cron sekali sehari: `/api/internal/retention` dijadwalkan pada jam 03 UTC (sekitar 10–11 WIB). Upload juga meminta pembersihan terbatas untuk pemilik akun tersebut. Penghapusan fisik dapat tertunda sampai cron berikutnya; kegagalan storage atau backlog membutuhkan retry berikutnya. Foto dengan preferensi simpan aktif tidak ikut dibersihkan. Mematikan preferensi atau menghapus data aplikasi tetap menghapus foto melalui API.

Periksa **Cron Jobs/Schedules** backend production agar tidak ada 401/503. Vercel mengirim `Authorization: Bearer CRON_SECRET`. Sesudah mengganti token, redeploy. [Batas cron Hobby](https://vercel.com/docs/cron-jobs/usage-and-pricing), [pengamanan cron](https://vercel.com/docs/cron-jobs/manage-cron-jobs).

JPEG/PNG sampai 5 MiB tetap dapat dipilih. Foto lebih dari 4.000.000 byte dikompres/diperkecil sebelum upload agar multipart di bawah batas Vercel 4,5 MB. Backend tetap memvalidasi format/piksel dan menghapus metadata. API langsung pada Vercel menerima maksimal 4.000.000 byte foto. [Batas Functions](https://vercel.com/docs/functions/limitations).

## Verifikasi

- `/ready` dan Swagger publik; data pribadi tetap meminta JWT.
- Login OTP/demo, refresh, logout/login email yang sama; data akun tetap ada.
- Simpan/edit/hapus makanan/gejala, replay tanpa duplikasi, rencana/belanja.
- Cerita/foto → Gemini → review → simpan; Tanpa AI tidak upload/analisis.
- Simpan draft, refresh, lanjutkan; ekspor ZIP/PDF; uji hapus hanya pada akun uji.
- Periksa cron dan preferensi foto.

Untuk Chrome lokal/APK, ubah **API_BASE_URL** pada konfigurasi publik yang diabaikan Git, misalnya `frontend/config/vercel.local.json`, kemudian run/build ulang memakai `--dart-define-from-file=config/vercel.local.json`. URL Supabase dan identitas akun tetap sama.

Konfigurasi dan tes lokal/CI tidak berarti situs sudah tayang. Deployment baru dinyatakan berhasil setelah kedua project Ready dan URL production diuji. Build APK tetap membutuhkan tes perangkat.
