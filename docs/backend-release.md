# Setup, verifikasi dan handoff release backend

Dokumen historis tahap backend awal. Untuk status release setelah integrasi dan deployment, gunakan [kesiapan demo](hackathon-readiness.md) dan README utama. Klaim pending/tidak ada migrasi dalam bagian lama di bawah bukan status terkini.

Ini dokumentasi source/tes dan pekerjaan yang masih membutuhkan konfigurasi nyata atau build rekan, bukan release submission final.

## Bukti yang tersedia

- Lint/format, schema/fixture, migration roundtrip/check, seed repeatable, signed JWT RSA, consent, ownership, rules/menu, draft, transaksi/concurrency, riwayat, rencana/belanja, media dan dashboard.
- Mock HTTP memeriksa kontrak Gemini/Storage dan error/bucket privat. Adapter memory membantu alur editor. Tidak ada model live yang diklaim sudah diuji.
- Lokal tahap 15: 71 passed, 2 skipped, Python 3.13.15. [CI tahap 15](https://github.com/danariqbalabi/AIBS/actions/runs/42751323377) success dengan PostgreSQL 17 disposable dan Python 3.12/3.13; dua tes khusus PostgreSQL dijalankan di CI. Semua branch sebelumnya sampai tahap 15 juga success saat diperiksa.
- Clone bersih dari GitHub branch tahap 15 (`4e0c013`) sudah diuji dengan environment baru: `uv sync --locked`, Ruff, 71 tes lulus/2 PostgreSQL-only skip, migration upgrade/check, seed dua kali tanpa duplikasi, lalu server Uvicorn nyata pada localhost. `/health`, `/ready`, `/docs`, `/openapi.json` memberi 200 dan endpoint privat tanpa Bearer memberi 401. Server tes dihentikan setelah pemeriksaan.
- Clone bersih memakai SQLite sementara dan Supabase URL contoh, tanpa kredensial proyek pengguna. Ini membuktikan setup/source backend, bukan integrasi provider nyata. Dockerfile tersedia, tetapi build image belum diuji karena Docker tidak ada pada mesin ini.

## Supabase nyata

Project URL dari pengguna telah disimpan di `.env` lokal yang tidak terlacak. URL saja tidak memberi akses DB/Storage. Lengkapi lokal:

1. DATABASE_URL dari dashboard, driver postgresql+psycopg, password dan TLS/pooler yang sesuai; gunakan database dev yang memang dituju.
2. SUPABASE_URL, asymmetric JWT signing ES256/RS256, email OTP dan anonymous sign-in untuk demo. Publishable key client hanya pada Flutter; key server tidak dikirim ke client.
3. Dari backend: `uv run alembic upgrade head`, `uv run python -m seeds.catalog`, `uv run alembic check`. RLS menutup akses client pada tabel; server tetap mengontrol owner.
4. Bucket aibs-food-photos privat dan SUPABASE_SERVICE_ROLE_KEY pada server; batas file/MIME, tanpa public read policy. [Media](media.md).
5. Uji token nyata, dua subject, akses/edit/hapus silang akun dan media. Dependency override test bukan bukti Auth provider nyata.

## AI dan handoff Miguel

Isi GEMINI_API_KEY/GEMINI_MODEL lokal. Verifikasi ID model tersedia; PRD memuat arahan berbeda sehingga tidak ada default yang ditebak. Uji foto nyata dengan saus belum diketahui dan jurnal “nggak mual”/“nggak muntah”; periksa waktu, negasi, bahan ambigu, JSON, token/latency dan fallback.

Miguel perlu review prompt/schema dan mengukur field salah/diada-adakan. Catat model/prompt version dan hasil aktual. Prompt/schema serta fixture tidak membuktikan ketepatan semantik. Review/edit/simpan tidak memanggil model. Batas retry/crash/exactly-once provider ada di [integrasi AI](ai-integration.md).

## Server dan deployment

[Backend README](../backend/README.md) memuat setup/env. Production memerlukan PostgreSQL, Supabase HTTPS, APP_ENV=production dan host HTTPS. Migrasi dijalankan terpisah sebelum startup, tanpa autoreload:

```text
uv run uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000 --no-access-log
```

Docker opsional, dari backend setelah Docker tersedia:

```powershell
docker build -t aibs-backend:review .
docker run --rm --env-file .env -p 8000:8000 aibs-backend:review
```

Image tidak membawa `.env` atau menjalankan migrasi otomatis. Konfigurasi gateway: TLS, body limit misalnya 8 MiB sebelum multipart, rate limit lintas subject dan origin web eksplisit jika diperlukan. Jangan log token, signed URL, jurnal atau foto. Limit demo in-process bukan pengganti perlindungan signup/gateway.

Storage/PostgreSQL tidak berbagi transaksi; rekonsiliasi orphan diperlukan bila cleanup jaringan gagal. Tentukan retensi, hapus akun/data dan kebijakan pihak ketiga sebelum penggunaan di luar demo sintetis. Ekspor/hapus akun menyeluruh/retensi foto otomatis belum ada; selaraskan tombol hi-fi.

## Handoff Kwien dan release tim

1. Integrasikan Auth/base URL, kontrak/fixture dan editor manual. Lengkapi state unknown/needs_confirmation/error dan pertahankan input saat gagal.
2. Gunakan versi terbaru saat PATCH/DELETE, refresh pada 409. Idempotency-Key sama untuk retry simpan yang sama. Akun biasa diawali POST /me/profile; demo memakai anonymous subject terpisah.
3. Refresh riwayat/Hari Ini/ringkasan setelah mutation. Timeline diurutkan tanggal kejadian lalu waktu input; perkiraan tetap ditandai, tanpa jam buatan.
4. Uji reopen/reinstall, token expired, jaringan/AI/kuota gagal, simpan ganda dan dua akun pada Android.
5. Review/merge semua PR, tetapkan commit final, uji clone hash itu, build APK, deploy source sama dan rekam aplikasi berjalan 3–5 menit. Hash PR sekarang bukan hash final seluruh aplikasi.
6. Lengkapi README/link/identitas/atribusi/surat orisinalitas dan akses juri. Pastikan kuota/layanan aktif. Batas guidebook: 14 November 2026, 23.59 WIB; jam portal dan klarifikasi resmi terbaru menjadi acuan.

## Pending

- DB URL/password, service-role key/bucket, token Auth, Gemini key/model.
- Review kontrak/copy FE/UX, evaluasi Miguel, serta klinisi/instrumen untuk penggunaan di luar demo.
- Flutter, APK, deployment HTTPS, video dan artefak submission.

Tidak ada database Supabase yang dimigrasikan, akun yang dihapus, deployment dipublikasikan, atau PR di-merge dalam pengerjaan ini.
