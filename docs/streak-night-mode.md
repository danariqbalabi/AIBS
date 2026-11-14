# Streak dan night mode

## Streak

Kesepakatan pengguna: minimal satu catatan makan tersimpan per hari, lewat cerita, foto, atau manual. Analisis saja, draft, catatan gejala, dan membuka aplikasi tidak dihitung. Beberapa makanan atau pengulangan commit di hari yang sama tetap bernilai satu hari.

Backend menambahkan `streak` pada respons `GET /api/v1/dashboard`: `current_days`, `best_days`, `completed_today`, `last_completed_date`, `as_of`, dan `timezone`. Perhitungan memakai tanggal **penyimpanan** FoodEvent dalam zona waktu profil, bukan tanggal makan yang bisa dimundurkan. Streak kemarin tetap terlihat selama hari ini belum berakhir; setelah satu hari penuh terlewat, streak aktif menjadi nol. Riwayat makanan yang dihapus tidak lagi dihitung; rekor terbaik dihitung ulang dari data yang masih tersedia. Tidak ada tabel/migrasi baru atau tugas cron.

Hari Ini menampilkan streak dan rekor terbaik dari backend. Menekan kartu membuka pilihan pencatatan. Setelah simpan makan, dashboard dimuat ulang. Jika tanggal berganti saat app tetap terbuka, buka ulang/tab kembali untuk memuat dashboard terbaru. Streak merupakan dorongan mencatat, bukan ukuran kesehatan atau kepatuhan diet.

## Night mode

Buka **Profil → Tampilan**, pilih **Ikuti perangkat**, **Terang**, atau **Gelap**. Pilihan awal mengikuti perangkat. Pengaturan disimpan lokal lewat shared_preferences dan dipulihkan sebelum app tampil. Pilihan tetap ada setelah logout; berbeda browser, perangkat, atau domain memiliki penyimpanan terpisah. Jika penyimpanan gagal, tema sebelumnya dipertahankan dan pesan retry ditampilkan.

Palet malam ada di `AibsDarkColors`. Widget menggunakan token warna/teks sesuai Theme; MaterialApp menyediakan tema gelap untuk form, dropdown, dialog, dan sheet. Gradien tombol brand serta ilustrasi mempertahankan warnanya, tanpa filter inversi gambar. Perubahan visual ini merupakan perluasan handoff yang diminta pengguna.

## Verifikasi

Backend: tes streak mencakup draft yang tidak dihitung, penyimpanan dan retry, penghapusan makanan, hari berturut-turut, pergantian hari Jakarta, masa sebelum hari ini berakhir, dan putus streak setelah satu hari kosong. Full suite lokal: 100 lulus, 2 tes khusus PostgreSQL dijalankan CI.

Flutter: analyze bersih dan 63 tes lulus. Tes pilihan tersimpan/dipulihkan, kegagalan penyimpanan, tema layar onboarding/Profil/sheet, dan pergantian kembali ke tema terang. Jalankan `flutter analyze` dan `flutter test --concurrency=1`. Untuk melihat perubahan lokal lakukan hot restart; production memerlukan merge PR dan deployment selesai.
