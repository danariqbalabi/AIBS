# Database dan seed

SQLAlchemy + psycopg mengakses PostgreSQL langsung melalui FastAPI; Alembic adalah sumber migrasi. Startup API tidak menjalankan `create_all` atau migrasi otomatis. Perubahan model baru harus disertai revision baru; migrasi yang sudah dipublikasikan tidak diedit untuk perubahan fitur berikutnya.

Dari `backend/`, setelah `DATABASE_URL` dan `SUPABASE_URL` diisi di `.env`:

```powershell
uv run alembic upgrade head
uv run python -m seeds.catalog
uv run alembic check
```

Jalankan pada database dev yang memang ditujukan untuk AIBS. URL PostgreSQL memakai driver `postgresql+psycopg://` dan opsi TLS sesuai konfigurasi Supabase; salin connection string yang sesuai dari dashboard, jangan menebak alamat pooler/password. Seed hanya mengisi katalog sintetis; profil privat dibuat per sesi pada tahap Auth.

Migrasi PostgreSQL mengaktifkan RLS tanpa policy client pada tabel AIBS dan mencabut hak client `anon`/`authenticated` jika role tersebut ada. Frontend memakai Supabase Auth saja; seluruh data fitur melalui FastAPI. Role koneksi backend harus diizinkan membaca/menulis tabel (owner migrasi melewati RLS); seluruh query privat tetap wajib memakai owner terverifikasi. Jangan mengirim database URL/service key ke Flutter. Hindari expose schema/tabel ini lewat Supabase Data API.

Semua referensi batch/event/draft lintas owner memakai FK komposit; idempotency dan satu commit per draft memakai unique constraint. Konsumsi dan gejala disimpan dalam tabel terpisah. Diet profile adalah JSON tervalidasi di profil, bukan tabel duplikat; alias bahan adalah JSON pada katalog. Snapshot event mempertahankan data saat pencatatan.

Seed berisi 10 bahan dan 6 menu buatan tim untuk demonstrasi aturan, tanpa sumber dataset pasien. Harga/komposisi/tag diet sintetis, **bukan basis rekomendasi klinis yang tervalidasi**. Penggunaan di luar demo memerlukan kurasi bahan, porsi, sumber dan peninjauan profesional. Seed dapat diulang tanpa duplikasi ID.

Tes lokal memakai SQLite file terisolasi dengan FK aktif, termasuk upgrade/downgrade/re-upgrade hanya pada database sementara. CI juga menguji PostgreSQL disposable. `TEST_DATABASE_URL` hanya boleh menunjuk database berakhiran `_test`; fixture membuat schema acak lalu menghapus schema tes tersebut, tidak menyentuh schema aplikasi. Jangan mengisi variabel ini dengan database Supabase asli.
