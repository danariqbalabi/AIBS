# Integrasi FE–BE untuk tes manual

Branch: `feat/frontend-backend-integration`. Desain dipertahankan. Tidak ada merge ke main atau deployment publik.

## Commit bertahap

1. `a9ff527`: konfigurasi lokal, SDK, HTTP client, Bearer token, refresh dan error envelope.
2. `43cc7c0`: Supabase anonymous/OTP, pemulihan sesi, profil/consent/screening; dukungan rentang bulan dan katalog bahan onboarding.
3. `9eb4e13`: katalog/status server, draft/commit makanan/gejala, link makanan tersimpan, riwayat, dashboard/ringkasan, rencana dan belanja.
4. Verifikasi/handoff: food-check manual, mempertahankan input saat gagal, pemeriksaan provider nyata dan panduan run.
5. Perbaikan refresh/sesi: tunggu pemulihan identitas, pertahankan subject pada retry demo, bedakan gagal load dari riwayat kosong, dan jelaskan logout anonymous.

## Run dan konfigurasi

Ikuti [frontend README](../frontend/README.md). Workspace ini sudah mempunyai `frontend/config/local.json` dan CORS lokal; keduanya tidak membawa secret server ke Flutter. File lokal tidak di-commit:

- `backend/.env`: DB URL, Supabase service-role, Gemini, CORS.
- `frontend/config/local.json`: API base URL, Supabase URL, publishable key client.

Gunakan Chrome port 5173. Perubahan dart-define perlu stop/run ulang; perubahan `.env` perlu restart backend. Android emulator memakai API URL `http://10.0.2.2:8000`; HP fisik memakai IP LAN komputer. HTTP Android lokal mungkin perlu pengaturan development; hosting memakai HTTPS. INTERNET permission tersedia, tetapi APK belum diuji.

## Perilaku integrasi

- Demo memperoleh anonymous session nyata, lalu bootstrap `/demo/sessions` untuk subject tersebut. Session SDK dipulihkan setelah refresh; data dimuat dari backend.
- OTP dikirim dan diverifikasi lewat Supabase, tidak sekadar memeriksa enam digit terisi. Pengiriman email nyata perlu SMTP/template project; belum diklaim telah dites dari inbox pengguna.
- Label profil dipetakan ke kontrak/UUID bahan. Rentang bulan disimpan sebagai rentang. Alergi yang tidak dikenali ditolak, tidak dihilangkan.
- Makanan/gejala: create draft → konfirmasi waktu/konsumsi → commit dengan versi dan Idempotency-Key stabil saat retry. UI menunggu hasil sebelum menyatakan tersimpan.
- Link gejala memakai ID makanan. Backend menolak target lintas subject dan makanan setelah waktu gejala, tanpa menggandakan konsumsi.
- Food-check tidak otomatis menyimpan konsumsi. Pilihan Nggak ada mencatat observasi negatif; tidak menambah jumlah gejala positif.
- Setelah mutation/tab dipilih, snapshot server dimuat ulang. Kegagalan refresh setelah commit tidak membatalkan transaksi yang sudah berhasil.
- Cerita asli disimpan sebagai `draft.content.story` dan dimuat ulang; belum diekstrak NLP, sehingga tidak menambah food/symptom counts.
- Rencana terpisah dari konsumsi. Checklist mengambil jumlah/satuan server dan menyimpan status dibeli.
- Ringkasan mengikuti status kelengkapan server (minimal tujuh hari tercatat), bukan ambang lokal tiga hari sebelumnya.

## Bukti pengujian

- Backend: **80 passed, 2 skipped**, lint dan ekspor kontrak diperiksa. Skip memerlukan PostgreSQL disposable/row locks.
- Flutter: **32 tes lulus**: pengujian sebelumnya ditambah pemulihan sesi tertunda/gagal, retry data, penggunaan ulang identitas demo, bootstrap gagal tanpa rotasi akun, serta pembatalan logout anonymous.
- Web debug build dengan konfigurasi lokal berhasil. Build release/APK/iOS belum diverifikasi.
- Smoke API Supabase nyata: readiness DB, CORS, dua anonymous JWT asli, bootstrap Nadia/Raka dan status menu berbeda; commit/replay tanpa duplikasi; link gejala; akses silang ditolak; rencana, belanja/checked, dashboard dan ringkasan.
- Consent AI nonaktif menghasilkan 403 sebelum provider dipanggil. Tidak mengirim data tes ini ke Gemini.
- Akun/record sintetis smoke API dibersihkan berdasarkan UUID yang dibuat tes itu sendiri; tidak menghapus data pengguna lain.
- Chrome nyata/headless: pilihan demo mencapai dashboard backend, reload memulihkan session/data, dan form makanan manual menghasilkan commit 200. Setelah reload kedua, GET riwayat 200 dan [capture Jurnal](integration-evidence/journal-after-reload.png) yang diperiksa visual menampilkan makanan uji tersebut. Assertion otomatis terakhir dengan locator teks/label Flutter tidak menemukan elemen meskipun record terlihat pada capture; tidak mengklaim seluruh runner browser otomatis hijau. Akun dan record uji browser juga dibersihkan.

## Urutan tes pengguna

1. Jalankan backend dan Chrome; `/ready` harus 200.
2. Coba Demo → Nadia. Menu berasal dari katalog server, bukan lima contoh Flutter lama.
3. Kamera → Sudah dimakan → Isi manual. Simpan makanan, cek Jurnal, refresh. Session dan record tetap ada.
4. Tambah gejala dan hubungkan makanan tersimpan. Periksa riwayat/ringkasan; periode belum cukup tetap menampilkan empty state.
5. Tambah bahan dari menu ke belanja, tandai dibeli, buka ulang/refresh. Buat rencana besok; tidak boleh menambah konsumsi.
6. Ubah profil/consent, refresh dan periksa hasil. Bahan di luar katalog belum didukung; form tidak boleh hilang saat gagal.
7. Logout lalu pilih Raka. Akun demo baru tidak melihat data Nadia; beberapa status menu berbeda.

## Batas tahap ini

Belum dikerjakan: perombakan visual; kamera/galeri; editor NLP/foto; edit event penuh; PDF/share; ekspor/hapus seluruh data/akun; retensi foto otomatis; iOS/APK/hosting HTTPS. Delete-all tidak lagi diarahkan ke logout palsu pada mode connected; simpan foto ditolak sampai fiturnya ada.

`frontend/ios` belum tersedia. Default fixture `AibsApp()` tanpa services dipakai tes UI saja, bukan fallback aplikasi produksi.

## Audit refresh dan logout

Pemeriksaan metadata read-only menemukan 3 subject demo Nadia dan 3 food events tersimpan saat audit lanjutan. Tidak membaca isi jurnal dan tidak menghapus atau menggabungkan data akun tersebut.

Penyebab di client:

- Startup menampilkan welcome ketika proses restore masih berjalan. Mengetuk Nadia saat itu dapat mengganti identitas karena handler demo sebelumnya selalu sign-out lalu sign-in anonymous baru.
- Restore yang gagal kembali ke welcome; pengguna dapat mengira sesi sudah hilang.
- Initial load menggabungkan beberapa endpoint. Kegagalan satu endpoint menghasilkan list awal kosong, tanpa status gagal yang bertahan.

Perbaikan: loading/retry menahan akses selama restore; error tidak membuang session; memilih template yang sama menggunakan ulang subject aktif; memilih template berbeda tidak otomatis logout; initial-load error tidak dianggap data kosong; reload yang bertabrakan dijadwalkan ulang. Anonymous logout sekarang meminta konfirmasi yang menjelaskan dampaknya.

**F5 berbeda dari logout.** F5 pada origin dan profil Chrome yang sama harus memulihkan subject beserta catatan. Logout anonymous membuang akses ke sesi demo itu; nama Nadia/Raka bukan kredensial untuk masuk kembali. Data server tetap ada tetapi sesi baru tidak boleh membaca data subject lama. Gunakan akun email OTP yang sama untuk login ulang permanen. Menghapus browser storage, mengganti origin/port, atau memakai profil Chrome baru juga dapat kehilangan akses ke sesi anonymous lama.

Data dari sesi anonymous yang sudah di-logout tidak otomatis dipindahkan ke sesi baru. Tidak membuat akun Nadia bersama untuk semua pengguna dan tidak menyimpan ulang token yang seharusnya dihapus saat logout.

[Audit sebelum integrasi](integration-design-audit-2026-11-14.md) adalah snapshot source `012a497`; gunakan dokumen ini untuk status sesudah integrasi.
