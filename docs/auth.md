# Auth dan sesi demo

Flutter login email OTP langsung lewat Supabase Auth; panjang kode mengikuti konfigurasi proyek. Setiap request FastAPI fitur membawa `Authorization: Bearer <access_token>`. Backend memverifikasi signature dengan JWKS project URL yang dikonfigurasi, algoritma ES256/RS256, issuer `/auth/v1`, audience/role `authenticated`, exp/iat dan subject UUID. Tidak menerima owner dari payload.

Input login dan hubungkan email memakai `EMAIL_OTP_LENGTH`, default **8 digit** sesuai kode yang dikirim project saat uji. Vercel build script memvalidasi nilai 6–10 dan memasukkannya ke dart-define. Pada run/build lokal, variabel ini harus ada di file dart-define atau argumen `--dart-define`, bukan hanya environment shell. Perubahan panjang membutuhkan build/deploy frontend ulang dan harus disamakan dengan konfigurasi Supabase. Semua digit dikirim utuh; kode tidak dipotong menjadi enam digit. Template Confirm signup, Magic link/OTP dan Change email menggunakan `{{ .Token }}`.

Aktifkan asymmetric JWT signing key di Supabase jika proyek masih memakai legacy HS256; backend ini sengaja tidak menerima shared-secret token atau service-role token sebagai identitas pengguna. JWKS di-cache oleh PyJWT dan dapat refresh saat key rotation. Gangguan jaringan JWKS menghasilkan 503, bukan bypass validasi.

Jalur Coba Demo:

1. Client memperoleh sesi **anonymous Supabase Auth** baru (`signInAnonymously`) yang terpisah dari akun biasa. Aktifkan anonymous sign-in, rate limit dan perlindungan abuse di Supabase; untuk hosting multi-worker tambahkan limit gateway.
2. `GET /api/v1/demo/profiles` menampilkan Nadia/Raka sintetis.
3. Kirim token anonymous ke `POST /api/v1/demo/sessions` dengan `{ "template": "nadia" }` atau `raka`. Server memverifikasi token dan membuat data untuk subject tersebut, bukan akun demo bersama. Ulangi template sama idempotent; mengganti template memerlukan sesi baru. Akun non-anonymous ditolak agar profil nyata tidak tertimpa.
4. Profil demo mendapat consent dasar untuk data sintetis, **AI tetap off** sampai user memilihnya secara eksplisit. Ini tidak dianggap persetujuan untuk pemrosesan data pasien.

Rate limit bootstrap lokal per subject berlaku selama umur proses (10 percobaan); ini bukan pengganti rate limit signup/gateway dan tidak digunakan untuk menilai keamanan jaringan produksi. Tidak ada endpoint debug yang memalsukan token. Tes menggunakan signed RSA JWT untuk memeriksa claim/signature dan dependency override khusus test untuk alur database; tidak ada bypass pada app produksi.

Anonymous JWT dan integrasi backend/Supabase telah diuji dengan akun sintetis. Pengujian email OTP 14 November 2026 mengonfirmasi provider email aktif dan key frontend sesuai, tetapi pengiriman `/auth/v1/otp` gagal HTTP 500 dengan pesan `Error sending confirmation email`. Auth Logs menunjukkan Gmail SMTP `534 5.7.9 Application-specific password required`. Password SMTP harus diganti dengan Google App Password milik akun pengirim, bukan password login Gmail. Perubahan dilakukan langsung di dashboard Supabase, tidak di Git atau chat. Setelah disimpan, uji kirim ulang satu kali dan pengguna memasukkan OTP sendiri.

[Google App Passwords](https://myaccount.google.com/apppasswords) memerlukan verifikasi dua langkah; [panduan Google](https://support.google.com/accounts/answer/185833). Aplikasi memisahkan pesan gagal pengiriman email dari OTP salah/kedaluwarsa dan menjaga email/input ketika pengiriman gagal. Status pengiriman belum dinyatakan berhasil sebelum tes ulang sesudah konfigurasi diperbaiki.
