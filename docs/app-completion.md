# Penyelesaian fitur aplikasi

Integrasi dikumpulkan di branch `feat/app-completion`. Setiap fitur dikerjakan pada branch sendiri, diperiksa, di-commit/push, lalu digabung lokal ke branch integrasi. Satu PR akhir menuju main; tidak menggabungkan PR ke main secara otomatis.

| Tahap | Branch | Status |
| --- | --- | --- |
| OTP dan hubungkan email | feat/account-otp-recovery | Implementasi selesai; tes inbox menunggu SMTP |
| Edit/hapus makanan dan gejala | feat/event-editor | Selesai; backend 83 tes dan Flutter 35 tes lulus |
| NLP cerita dan editor review | feat/journal-nlp | Berikutnya |
| Kamera/galeri/analisis foto | feat/photo-analysis | Berikutnya |
| Ekspor, hapus data, retensi foto | feat/data-privacy | Berikutnya |
| Render Free dan APK Android | chore/demo-deployment | Blueprint dan panduan disiapkan; deployment menunggu koneksi akun Render, APK menunggu build |

Pengujian email nyata memerlukan SMTP/template serta akses inbox pengguna. Kredensial SMTP dimasukkan langsung ke dashboard Supabase, tidak ke chat atau Git. Untuk menghubungkan akun anonymous ke email, template **Change email** harus memuat `{{ .Token }}` juga, selain template Magic link or OTP. Proses mempertahankan subject UUID; tidak menggabungkan akun lain atau memindahkan catatan lama secara otomatis.

Hosting yang dipilih pengguna: Render Free. Akun Render dan koneksi GitHub harus disiapkan pemilik akun. Basis data/foto tetap Supabase; tidak menaruh data permanen pada filesystem Render. Layanan gratis tidur setelah idle; frontend perlu menampilkan proses pemulihan/retry dengan benar. [Batas Render](https://render.com/docs/free).

Android SDK tersedia, tetapi belum ada device/emulator terkonfigurasi saat mulai. Build APK dapat diperiksa lebih dulu; pengujian perangkat tidak boleh diklaim selesai sebelum benar-benar dijalankan.
