# Backend AIBS

FastAPI/Pydantic, SQLAlchemy/psycopg dan Alembic, Supabase Auth/Storage serta adapter Gemini. Integrasi Flutter/provider nyata telah diuji dengan data sintetis; lihat [status integrasi](../docs/frontend-backend-integration.md). Target deployment sekarang [Vercel Hobby](../docs/vercel-deployment.md).

Jalankan dari direktori `backend/` dengan [uv](https://docs.astral.sh/uv/):

```powershell
uv sync --locked
Copy-Item .env.example .env
```

Jika `.env` sudah ada, edit tanpa menimpanya. Isi `DATABASE_URL` (PostgreSQL: `postgresql+psycopg://...`) dan `SUPABASE_URL`. SQLite hanya untuk pengembangan/tes lokal; production menolak SQLite dan Supabase non-HTTPS. Kedua nilai wajib; startup menolak konfigurasi kosong. Provider opsional boleh kosong untuk alur manual. Jangan kirim connection string/key ke chat atau Git.

```powershell
uv run alembic upgrade head
uv run python -m seeds.catalog
uv run alembic check
uv run uvicorn app.main:create_app --factory --reload --host 0.0.0.0 --port 8000
```

Liveness: `http://127.0.0.1:8000/health`; database readiness: `/ready`; Swagger: `/docs`; OpenAPI: `/openapi.json`. Startup tidak membuat tabel otomatis. `CORS_ORIGINS` adalah JSON array origin yang diizinkan, default kosong; Flutter native tidak membutuhkan CORS.

| Variabel | Fungsi |
| --- | --- |
| `APP_ENV` | local/test/production |
| `DATABASE_URL` | SQL connection string wajib; TLS/pooler mengikuti Supabase |
| `SUPABASE_URL` | Project URL wajib untuk issuer/JWKS/Storage |
| `SUPABASE_SERVICE_ROLE_KEY` | Server saja, untuk media privat |
| `STORAGE_BUCKET` | Default aibs-food-photos; harus privat |
| `GEMINI_API_KEY`, `GEMINI_MODEL` | Server saja, untuk analisis; tidak ada ID model default yang ditebak |
| `AI_DAILY_LIMIT` | Default 20 percobaan per owner per hari UTC |
| `RUNTIME_MODE` | server untuk Uvicorn lokal; serverless untuk Vercel tanpa worker permanen |
| `MAX_PHOTO_BYTES` | 4000000 pada Vercel agar multipart di bawah batas platform |
| `CRON_SECRET` | Secret server untuk endpoint pembersihan terjadwal Vercel |

Login email OTP langsung dari Flutter ke Supabase Auth. Akun biasa diinisialisasi dengan `POST /api/v1/me/profile`, lalu consent/profil/assessment. Demo menggunakan anonymous Auth subject baru -> `POST /api/v1/demo/sessions` dengan template nadia/raka. Token harus asymmetric ES256/RS256; service-role token tidak diterima sebagai user. [Panduan Auth](../docs/auth.md).

Manual: POST draft -> review PATCH versi terbaru -> POST `/drafts/{id}/commit` dengan `{version, confirmed:true}` dan Idempotency-Key -> GET events/dashboard/summaries. Waktu dikonfirmasi sebagai exact/approximate; food memerlukan consumed=true. Before-meal/rencana/belanja tidak membuat konsumsi. Story yang belum dirapikan bisa disimpan pada `content.story`.

AI: opt-in -> upload media jika foto -> POST analysis dengan request_id -> review draft yang sama. Review/edit/simpan tidak memanggil AI. [Kontrak](../docs/api/README.md), [media](../docs/media.md), [AI](../docs/ai-integration.md), dan [database](../docs/database.md).

Android emulator standar: `http://10.0.2.2:8000`; perangkat fisik: alamat LAN komputer. Hosting demo memakai HTTPS. Vercel memuat `index.py:app`; migrasi dilakukan dengan `uv run python -m app.migrate` dari lingkungan rilis tepercaya, bukan dari request/build preview.

Pemeriksaan dari `backend/`:

```powershell
uv run ruff check .
uv run ruff format --check .
uv run pytest
```

Lockfile disimpan di Git. `.env` dan environment lokal tidak ikut commit. AI coding assistant dipakai untuk implementasi ini; tinjau kode dan hasil verifikasi sebelum merge.

Hasil lokal tahap 15: **71 passed, 2 skipped**. Dua skip khusus PostgreSQL dijalankan di CI dengan PostgreSQL 17 disposable/Python 3.12 dan 3.13. Ada deprecation warning Starlette/httpx TestClient yang tidak menggagalkan tes. Jangan isi `TEST_DATABASE_URL` dengan Supabase nyata; hanya database disposable berakhiran `_test`, dengan schema acak yang dibuang tes.

Export dokumentasi tanpa menghubungi provider:

```powershell
uv run python -m app.export_contracts
uv run python -m app.export_openapi
```

Untuk deploy, gunakan PostgreSQL, environment production, host HTTPS dan command Uvicorn tanpa reload (`--no-access-log` untuk menghindari log URL). Jalankan migrasi sebagai langkah rilis terpisah. Dockerfile disediakan; build Docker belum diuji karena Docker tidak tersedia. [Panduan release dan pending checks](../docs/backend-release.md).

Katalog/aturan hanya demo sintetis. Retensi foto otomatis, ekspor dan hapus akun menyeluruh belum tersedia; selaraskan UI/privasi sebelum penggunaan nyata. Fixture/mock lulus bukan bukti provider Gemini/Supabase atau APK sudah live.
