# Foto privat

Buat bucket Supabase Storage `aibs-food-photos` dengan **public=false**, batas file dan MIME JPEG/PNG. Jangan beri public read policy. Backend memakai service-role key di environment server; client selalu lewat API FastAPI dan ownership, termasuk untuk URL akses sementara. Key ini bypass RLS Storage sehingga tidak boleh ditanam pada Flutter.

`POST /api/v1/media` menerima multipart field `file`, maksimal input 5 MiB dan 16 megapiksel. Backend memeriksa isi gambar, tidak mempercayai ekstensi/MIME, lalu re-encode JPEG tanpa metadata EXIF. Simpan hanya setelah upload privat berhasil; path dibuat server di namespace owner. `GET /media/{id}/access` menghasilkan signed URL 60 detik sesudah ownership; jangan log URL bertoken. `DELETE` menghapus objek dan melepas referensi media pada draft, tanpa menghapus isi catatan terkonfirmasi.

Konfigurasi `.env`: `SUPABASE_SERVICE_ROLE_KEY` dan `STORAGE_BUCKET`. Upload/sign/download mengecek bucket tetap privat. Gateway hosting wajib membatasi total request body (misalnya 8 MiB) dan rate limit sebelum multipart diproses; batas file pada route bukan pengganti batas jaringan tersebut.

Saat simpan foto dimatikan, backend menghapus foto setelah percobaan ekstraksi selesai, termasuk saat AI gagal. Isi draft/catatan tetap tersedia. Upload yang ditinggalkan sebelum analisis atau penghapusan yang gagal memiliki TTL akses 24 jam; cron harian dan cleanup saat upload menangani retry penghapusan fisik. Preferensi simpan aktif mempertahankan foto sampai pengguna mematikan preferensi atau menghapus datanya.

Storage dan PostgreSQL tidak berbagi transaksi. Upload yang gagal disimpan ke DB dicoba dibersihkan; operator perlu rekonsiliasi orphan bila jaringan cleanup gagal. Hapus objek yang sudah tidak ada harus dapat diulang melalui Storage delete. Hapus data aplikasi belum menghapus identitas Supabase Auth.

Tes endpoint memakai adapter memory dan gambar sintetis kecil. Tes provider HTTP akan memeriksa kontrak request, namun bucket/key Supabase nyata tetap perlu smoke test setelah konfigurasi lokal diisi.
