# Jurnal, pengganti bahan, dan offline

Branch: `feat/journal-offline-expansion`. Perlu deploy backend dan frontend; tidak ada migrasi database.

## Fitur baru

- **Catat ulang:** Jurnal → buka makanan → Catat ulang makanan. Nama dan bahan disalin ke input manual baru; waktu/porsi ditinjau sebelum simpan. ID catatan asal tidak diubah, dan penilaian lama tidak dianggap hasil penilaian baru.
- **Pengganti bahan:** pada hasil cek makanan pilih Saran pengganti bahan. Pada menu, buka Ubah porsi / ganti bahan → Saran pengganti bahan. Backend mencoba pasangan bahan kuliner yang terbatas pada katalog, memeriksa seluruh komposisi dengan profil terbaru, dan hanya mengembalikan hasil sesuai. Pengguna tetap meninjau porsi/cara olah; ini bukan database kadar FODMAP. Tidak ada janji semua makanan memiliki pengganti. Unknown atau konflik yang masih tersisa menghasilkan daftar kosong.
- **Grafik harian:** Ringkasan → ikon grafik. Pilih hari; batang membandingkan jumlah catatan makan/gejala per empat jam. Daftar menampilkan waktu dan skala gejala 1–5; ketuk untuk membuka catatan sumber di Jurnal. Waktu perkiraan tidak dipetakan sebagai jam pasti. Hubungan bukan kesimpulan sebab-akibat.
- **Gas dan urgensi BAB:** tersedia pada form, editor kartu, schema ekstraksi cerita AI, jurnal, dan agregat ringkasan. Urgensi tidak otomatis dianggap diare. Skala lama 1–5 tetap dipakai.
- **CSV:** Ringkasan → ikon unduh. Mengekspor makanan/gejala yang dimuat untuk periode ringkasan 7/30 hari, termasuk waktu, bahan, skala, ID hubungan, dan catatan. UTF-8 BOM untuk Excel; kutip, koma, baris baru, serta formula diawali karakter berbahaya ditangani. PDF tetap tersedia.

## Mengaktifkan offline

1. Saat online dan sudah login, buka Profil → Data offline.
2. Aktifkan **Simpan data di perangkat ini**. Jurnal, katalog/resep, checklist, profil, dan draft yang sudah dimuat disalin ke penyimpanan lokal akun tersebut. Pada web release, file aplikasi juga diunduh oleh service worker khusus.
3. Data kesehatan disimpan lokal tanpa enkripsi tambahan dari aplikasi; jangan aktifkan di perangkat bersama. Mematikan pilihan atau logout menghapus data lokal. Cache tiap akun terpisah dan tidak menyimpan token, password, atau foto.
4. Saat koneksi putus, buka ulang dengan sesi login yang masih tersedia: banner Offline menampilkan waktu salinan terakhir. Membaca cache tidak menganggap penilaian profil lama sebagai pemeriksaan terbaru. Login/OTP baru tetap membutuhkan koneksi.
5. Isi makan manual/gejala; tutup lalu **Simpan draft**. Dengan offline aktif, draft disimpan di perangkat, belum menjadi catatan di akun atau streak.
6. Dari Data offline buka draft, tinjau porsi, waktu, konsumsi/gejala, lalu **Tinjau & kirim** ketika online. Retry commit memakai draft server dan idempotency key yang disimpan sebelum request. Jika respons hilang lalu app dibuka ulang, kirim ulang isi yang sama; jangan membuat catatan baru.
7. Resep tersimpan bisa dibaca dan ditandai favorit. Checklist offline bisa dicentang; kirim perubahannya dari halaman Data offline. Versi yang berubah di perangkat lain tidak ditimpa otomatis. Saat konflik, hapus perubahan lokal dan tinjau ulang.

Pengiriman tidak otomatis, karena waktu dan isi perlu ditinjau. Tidak ada analisis AI atau pemeriksaan/swap baru ketika offline. Browser dapat menghapus storage karena kuota/izin; draft lokal bukan backup akun. Sesi yang hilang atau dicabut memerlukan login online. Penolakan akses 401/403 tidak diganti dengan cache.

Cache web khusus hanya berisi daftar file statis hasil build, tidak pernah respons API/auth. Dev server `flutter run` tidak menyediakan manifest build ini; untuk menguji offline web gunakan release:

```powershell
cd frontend
flutter build web --release --dart-define-from-file=config/local.json
python scripts/offline-assets.py
python -m http.server 5180 --bind 127.0.0.1 --directory build/web
```

Tambahkan origin lokal ke backend jika perlu. HTTPS atau localhost diperlukan untuk service worker. Script deployment Vercel sudah membuat manifest statis otomatis. Perubahan domain memiliki storage terpisah.

## Validasi

Tes backend mencakup round-trip gas/urgensi, ringkasan, dan pemeriksaan pengganti seluruh komposisi/alergi/unknown. Tes Flutter mencakup catat ulang, sumber grafik, escaping CSV, opt-in dan isolasi akun, hapus cache, fallback jaringan tanpa bypass akses, konflik checklist, serta retry commit lokal setelah restart. Smoke release dapat dijalankan dengan `AIBS_TEST_OFFLINE=1` pada `scripts/browser_smoke.py`; akun anonim sintetis dibersihkan setelah pengujian.


Status pemeriksaan terakhir: backend 102 tes lulus, 2 pengujian khusus PostgreSQL dijalankan CI. Suite gabungan setelah merge tema: 72 tes Flutter lulus, format dan analyze bersih.

Pada 14 November 2026 pukul 21.09 WIB, pengujian Chrome production di `https://aibs-frontend.vercel.app` pada viewport 390 × 844 berhasil: login demo anonim terisolasi, aktivasi cache aplikasi/data, reload tanpa jaringan dengan identitas yang sama, simpan draft makan lokal, kembali online, tinjau dan kirim, serta pemeriksaan server berisi tepat satu catatan dan draft lokal terhapus. Akun sintetis pengujian telah dibersihkan. Bukti terbaru: `docs/evidence/browser-smoke.json` dan `docs/evidence/offline-sync.png`.

Kegagalan langkah checkbox pada skrip sebelumnya diperbaiki dengan selector role checkbox yang sesuai semantik Flutter. Tidak diperlukan perubahan kode aplikasi untuk alur production yang diuji. Tes ini memverifikasi draft makan manual pada sesi yang masih tersedia; tidak menyatakan semua skenario offline, sesi kedaluwarsa, gejala, dan konflik multi-perangkat sudah diuji end-to-end.
