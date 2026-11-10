# Auth dan sesi demo

Flutter login email OTP langsung lewat Supabase Auth; panjang kode mengikuti konfigurasi proyek. Setiap request FastAPI fitur membawa `Authorization: Bearer <access_token>`. Backend memverifikasi signature dengan JWKS project URL yang dikonfigurasi, algoritma ES256/RS256, issuer `/auth/v1`, audience/role `authenticated`, exp/iat dan subject UUID. Tidak menerima owner dari payload.

Aktifkan asymmetric JWT signing key di Supabase jika proyek masih memakai legacy HS256; backend ini sengaja tidak menerima shared-secret token atau service-role token sebagai identitas pengguna. JWKS di-cache oleh PyJWT dan dapat refresh saat key rotation. Gangguan jaringan JWKS menghasilkan 503, bukan bypass validasi.

Jalur Coba Demo:

1. Client memperoleh sesi **anonymous Supabase Auth** baru (`signInAnonymously`) yang terpisah dari akun biasa. Aktifkan anonymous sign-in, rate limit dan perlindungan abuse di Supabase; untuk hosting multi-worker tambahkan limit gateway.
2. `GET /api/v1/demo/profiles` menampilkan Nadia/Raka sintetis.
3. Kirim token anonymous ke `POST /api/v1/demo/sessions` dengan `{ "template": "nadia" }` atau `raka`. Server memverifikasi token dan membuat data untuk subject tersebut, bukan akun demo bersama. Ulangi template sama idempotent; mengganti template memerlukan sesi baru. Akun non-anonymous ditolak agar profil nyata tidak tertimpa.
4. Profil demo mendapat consent dasar untuk data sintetis, **AI tetap off** sampai user memilihnya secara eksplisit. Ini tidak dianggap persetujuan untuk pemrosesan data pasien.

Rate limit bootstrap lokal per subject berlaku selama umur proses (10 percobaan); ini bukan pengganti rate limit signup/gateway dan tidak digunakan untuk menilai keamanan jaringan produksi. Tidak ada endpoint debug yang memalsukan token. Tes menggunakan signed RSA JWT untuk memeriksa claim/signature dan dependency override khusus test untuk alur database; tidak ada bypass pada app produksi.

Pengujian Auth nyata dan konfigurasi anonymous/OTP Supabase belum dapat dilakukan tanpa konfigurasi proyek yang sesuai. URL proyek saja tidak memberi akses database atau izin membuat storage bucket.
