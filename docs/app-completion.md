# Penyelesaian fitur aplikasi

Snapshot riwayat implementasi. Status audit PRD dan release terbaru: [kesiapan demo](hackathon-readiness.md).

Integrasi dikumpulkan di branch `feat/app-completion`. Setiap fitur dikerjakan pada branch sendiri, diperiksa, di-commit/push, lalu digabung lokal ke branch integrasi. Satu PR akhir menuju main; tidak menggabungkan PR ke main secara otomatis.

| Tahap | Branch | Status |
| --- | --- | --- |
| OTP dan hubungkan email | feat/account-otp-recovery | Implementasi selesai; tes inbox menunggu SMTP |
| Edit/hapus makanan dan gejala | feat/event-editor | Selesai; backend 83 tes dan Flutter 35 tes lulus |
| NLP cerita dan editor review | feat/journal-nlp | API, editor terstruktur dan replay commit; uji Gemini nyata/negasi/commit berhasil |
| Pulihkan dan lanjutkan draft | feat/draft-recovery | Draft server bisa dibuka ulang dari Jurnal, diedit, disimpan atau dihapus; 42 tes Flutter lulus |
| Batasan bahan khusus dan gejala lain | feat/custom-constraints | Bahan di luar katalog disimpan sebagai nama, verdict konservatif; input gejala lain dan Bristol terhubung |
| Kamera/galeri/analisis foto | feat/photo-analysis | Picker dan upload privat tersambung ke API/review; pengujian perangkat belum tersedia |
| Ekspor, hapus data, retensi foto | feat/data-privacy | ZIP data/foto sendiri, PDF konsultasi, hapus data aplikasi, preferensi foto/TTL; 87 tes backend dan 41 tes Flutter lulus |
| Render Free dan APK Android | chore/demo-deployment | Blueprint siap; deployment menunggu akun Render. APK debug berhasil dibangun di CI, tes perangkat belum tersedia |
| CI Flutter/web/APK | chore/flutter-release-checks | Format/analyze/test/build web/build APK dan upload artifact berhasil pada run 43563381257 |
| Migrasi Vercel | feat/vercel-deployment | Entrypoint ASGI, pool serverless, cron terproteksi, kompresi foto, build Flutter Web dan panduan dua project; belum deploy publik |

Pengujian email nyata memerlukan SMTP/template serta akses inbox pengguna. Kredensial SMTP dimasukkan langsung ke dashboard Supabase, tidak ke chat atau Git. Untuk menghubungkan akun anonymous ke email, template **Change email** harus memuat `{{ .Token }}` juga, selain template Magic link or OTP. Proses mempertahankan subject UUID; tidak menggabungkan akun lain atau memindahkan catatan lama secara otomatis.

Hosting terbaru yang dipilih pengguna: **Vercel Hobby**, menggantikan Render setelah kartu ditolak. Basis data, Auth dan foto tetap Supabase. Backend dan Flutter Web menjadi dua project Vercel. Ikuti [panduan Vercel](vercel-deployment.md); konfigurasi Render di repo adalah alternatif historis.

Android SDK tersedia, tetapi belum ada device/emulator terkonfigurasi saat mulai. Build APK dapat diperiksa lebih dulu; pengujian perangkat tidak boleh diklaim selesai sebelum benar-benar dijalankan.

Foto sementara memiliki TTL akses 24 jam. Pada Vercel, cron harian dan pembersihan terbatas saat upload menggantikan worker 15 menit; penghapusan fisik bisa tertunda sampai jadwal berikutnya atau retry bila storage gagal/backlog. Mematikan simpan foto menghapus foto milik akun tersebut; isi catatan tetap ada. Hapus semua data menghapus data aplikasi dan foto, bukan identitas login Supabase. ZIP ekspor memuat data sensitif; simpan sesuai kebutuhan pengguna.

Build Android pertama gagal karena kehabisan memori JVM (konfigurasi template meminta heap 8 GB). Percobaan kedua dihentikan saat mesin kekurangan RAM. APK belum boleh dinyatakan siap sampai build berhasil dan pengujian perangkat dilakukan.

Build debug Android ARM64 berhasil di [CI 43563381257](https://github.com/danariqbalabi/AIBS/actions/runs/43563381257), beserta format/analyze/tes dan build release web. Artifact `aibs-android-debug` adalah APK pemeriksaan kompilasi tanpa key client; bukan APK demo yang sudah terhubung. Setelah Render aktif, jalankan build dengan konfigurasi URL HTTPS dan publishable key. HP/emulator masih diperlukan untuk uji alur perangkat.

Validasi integrasi langsung (data sintetis): Supabase JWT anonymous nyata, owner terpisah, status menu per profil, commit/replay, tautan makanan-gejala, rencana, belanja, dashboard/ringkasan dan blokir AI saat izin mati lulus. Akun dan catatan sintetis pengujian dibersihkan. Gemini nyata berhasil mengekstrak cerita dengan negasi tidak mual, hasil belum terkonfirmasi, dan retry request yang sama mengembalikan draft yang sama.

Review dan commit draft hasil Gemini nyata, replay tanpa duplikasi, upload Storage privat, ZIP data/foto serta penghapusan data/foto akun sintetis berhasil. Seluruh akun sintetis pengujian ini sudah dihapus.

Perubahan fitur telah masuk `main` melalui PR #31, #32, dan #33 yang digabung pemilik selama pengerjaan. Branch integrasi akan diselaraskan dengan main; PR berikutnya fokus pemeriksaan rilis Flutter/deployment yang belum digabung.
