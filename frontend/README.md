# AIBS Flutter frontend

Flutter memakai Supabase Auth dan FastAPI untuk alur manual. Tampilan/handoff
dipertahankan; perubahan integrasi berfokus pada data dan aksi tombol.
Lihat [panduan integrasi FE–BE](../docs/frontend-backend-integration.md).

## Design source of truth

Use [`AGENTS.md`](AGENTS.md) and [`docs/design/`](docs/design/) for all mobile
UI work. The current handoff lives in this `frontend/` project: design docs are
under `docs/design/`, tokens and theme under `lib/core/theme/`, reusable
widgets under `lib/shared/widgets/`, and SVG assets under `assets/`.

`docs/design/SCREENS.md` and `docs/design/DATA.md` describe the screen and
data-behavior source of truth. Nunito is bundled locally for offline rendering.

## Connected scope and remaining work

- Supabase anonymous demo/email OTP, session recovery, token refresh, profile,
  consent, screening, catalog/status and manual food-check use real APIs.
- Manual meals/symptoms use draft/commit with idempotency; history, dashboard,
  summary, plans and shopping are loaded from the server after mutations/reload.
- Camera/gallery capture, AI photo analysis, and AI story extraction are not
  connected. Story text is saved as a server draft, without pretending NLP
  extracted food/symptom events. Use Isi manual for this testing phase.
- Privacy export copies the available profile fields to the clipboard.
  Full export/deletion, PDF/share, photo retention and event editing are pending.
  Connected mode rejects save-photos and delete-all until implemented; it does
  not report a false successful deletion.
- Demo menu/catalog and summary data are illustrative, not medical guidance.

Nunito is bundled locally as a variable font and licensed under the SIL Open
Font License in `assets/fonts/OFL.txt`. The theme maps its 600, 700, and 800
styles to the variable font's `wght` axis, so rendering does not require a
network connection.

## Run

```powershell
Copy-Item config/example.json config/local.json
# Isi API_BASE_URL, SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY.
# Jangan timpa config/local.json yang sudah ada; workspace ini sudah disiapkan.
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define-from-file=config/local.json
```

Jalankan FastAPI dari terminal lain di `backend/`:

```powershell
uv sync --locked
uv run alembic upgrade head
uv run python -m seeds.catalog
uv run uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000 --no-access-log
```

Backend `.env` harus valid. CORS untuk Chrome:

```dotenv
CORS_ORIGINS='["http://localhost:5173","http://127.0.0.1:5173"]'
```

Konfigurasi client hanya berisi public URL/publishable key, tidak pernah
service-role atau Gemini key. `config/local.json` di-ignore Git. Runtime tanpa
konfigurasi memberi error login, tidak masuk ke demo palsu. `AibsApp()` tanpa
services hanya fixture tes UI. SDK Supabase memulihkan session; data diambil
ulang dari FastAPI. Mengubah dart-define memerlukan stop/run ulang.

Tes awal: **Coba Demo → Nadia → catat makanan manual → Jurnal → refresh**.
Catatan harus tetap ada. Logout lalu pilih Raka membuat subject demo baru.
Saat refresh, tunggu pemulihan sesi/data; jika gagal pilih Coba lagi. Pilihan
Nadia tidak lagi otomatis mengganti sesi aktif. Logout anonymous tidak dapat
dipakai untuk kembali ke subject lama hanya dengan memilih nama demo; gunakan
akun email OTP untuk login ulang ke akun yang sama. Pakai origin/port dan profil
Chrome yang sama saat mengetes F5. Data anonymous lama tidak digabung otomatis.
OTP memerlukan SMTP/template Supabase yang sesuai. Bahan di luar katalog dan
gejala Lainnya belum didukung mapper; input ditolak, tidak dihilangkan diam-diam.
Minimum Dart: 3.13.5. APK/iOS/hosting HTTPS belum diverifikasi tahap ini.

## Verify

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
