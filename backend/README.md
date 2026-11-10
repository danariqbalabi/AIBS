# Backend AIBS

Python 3.12/3.13, FastAPI dan Pydantic Settings. Tahap 01 menyediakan app factory, liveness, konfigurasi tervalidasi, CORS eksplisit, request ID, dan lint/test CI. Endpoint fitur belum tersedia pada tahap ini.

Jalankan dari direktori `backend/` dengan [uv](https://docs.astral.sh/uv/):

```powershell
uv sync --locked
Copy-Item .env.example .env
```

Isi `DATABASE_URL` (PostgreSQL: `postgresql+psycopg://...`) dan `SUPABASE_URL` pada `.env`. SQLite hanya untuk pengembangan/tes lokal. Kedua nilai wajib; startup menolak konfigurasi kosong. Tahap ini belum menghubungi database atau Supabase.

```powershell
uv run uvicorn app.main:create_app --factory --reload --host 0.0.0.0 --port 8000
```

Liveness: `http://127.0.0.1:8000/health`; Swagger: `/docs`; OpenAPI: `/openapi.json`. API tidak mencetak konfigurasi/kredensial pada respons. `CORS_ORIGINS` adalah JSON array origin yang diizinkan, default kosong; Flutter native tidak membutuhkan CORS.

Pemeriksaan dari `backend/`:

```powershell
uv run ruff check .
uv run ruff format --check .
uv run pytest
```

Lockfile disimpan di Git. `.env` dan environment lokal tidak ikut commit. AI coding assistant dipakai untuk implementasi ini; tinjau kode dan hasil verifikasi sebelum merge.
