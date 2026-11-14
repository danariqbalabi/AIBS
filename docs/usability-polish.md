# Perbaikan alur pemakaian — 14 November 2026

Branch: `feat/usability-polish`. Perubahan ini menindaklanjuti review UX dan persetujuan pengguna untuk menyederhanakan alur. Identitas visual dan aturan penilaian makanan tetap mengacu pada handoff serta backend.

## Perilaku baru

- Tombol tengah **+** membuka pilihan **Cek makanan**, **Catat makan**, **Catat gejala**, dan **Tulis cerita** jika AI aktif. Tombol Catat di Jurnal dan ajakan mencatat di Hari Ini menggunakan pilihan yang sama. Aksi **Sudah dimakan** pada menu tetap langsung membuka form berisi menu tersebut.
- **Catat makan** langsung membuka form manual. Menutup form kembali ke layar asal, dengan perlindungan perubahan yang belum disimpan. **Cek makanan** membuka kamera saat AI aktif dan form bahan manual saat AI dimatikan.
- Setelah simpan makan, **Ada keluhan** membuka form gejala dengan ID makanan yang baru disimpan sebagai pilihan awal. Pilihan ini bisa diganti atau dilepas. Hasil commit beserta ID tetap sama saat penyimpanan diulang; nama makanan tidak dipakai untuk menebak hubungan.
- Menu berstatus **Tidak sesuai** mengutamakan **Lihat pilihan sesuai**. Daftar alternatif menampilkan status sesuai, dengan tombol untuk membuka semua status lagi. **Tetap catat** meminta konfirmasi bahwa makanan sudah dimakan. Tidak ada klaim bahwa makanan pasti aman atau penyebab keluhan.
- Alergi serta budget, tingkat pedas, dan preferensi bisa diedit dari kartu Profil. Form mempertahankan isian saat server gagal. Menghapus alergi memerlukan konfirmasi. Versi profil tetap diteruskan agar perubahan lama tidak menimpa perubahan yang lebih baru.
- Gambar detail diperkecil; kedua aksi menu mendapat ruang seimbang; subtitle generik berulang dihilangkan; isi tab diberi jarak dari tombol tengah. Waktu catatan dan jadwal tampil 24 jam.
- Checklist bahan hanya tersedia untuk **Masak**. Menu **Beli** menyediakan **Salin cara pesan**.

## Coba di Chrome

Jalankan backend dan Flutter sesuai [panduan integrasi](frontend-backend-integration.md). Untuk proses Flutter yang masih berjalan, lakukan hot restart (`R`).

1. Tekan **+ → Catat makan**, isi makanan, tinjau waktu, lalu konfirmasi sudah dimakan.
2. Tekan **Ada keluhan**, pilih gejala, cek makanan terhubung, dan simpan. Refresh: kedua catatan harus tetap ada di Jurnal.
3. Ulangi dengan dua makanan bernama sama: hubungan harus menggunakan makanan yang dipilih, bukan nama.
4. Dari **Profil → Alergi**, ubah daftar dipisahkan koma lalu simpan. Coba juga **Budget & preferensi** dan refresh.
5. Buka menu yang tidak sesuai: coba alternatif; kembali dan coba batal pada konfirmasi **Tetap catat**.
6. Buka menu Beli untuk menyalin cara pesan dan menu Masak untuk checklist. Coba ukuran layar 390 × 844.
7. Matikan AI dari Profil: Catat makan dan Cek makanan tetap berfungsi manual, tanpa mengunggah foto/cerita.

Pengingat otomatis 2–3 jam, push notification, dan penjadwalan di sistem operasi belum ditambahkan. Penghubung gejala tersedia langsung setelah simpan serta dari Jurnal; hubungan tersebut bukan kesimpulan sebab-akibat. Pengujian perangkat Android/iOS fisik masih diperlukan.

## Validasi

`flutter analyze` bersih, 59 tes Flutter lulus, dan build web release berhasil. Smoke Chrome release berhasil menyimpan makanan, meneruskan ID makanan yang tepat ke gejala, dan memulihkan catatan setelah refresh.

Regresi Flutter mencakup alur demo, retry commit, AI nonaktif, kembali dari manual ke asal, makanan bernama sama, konfirmasi menu tidak sesuai, penyimpanan alergi, dan mempertahankan budget saat server gagal. `scripts/browser_smoke.py` menguji build web release pada 390 × 844 melalui backend nyata dengan akun anonim baru, kemudian membersihkan akun uji tersebut. Bukti eksekusi ada di `docs/evidence/browser-smoke.json`.
