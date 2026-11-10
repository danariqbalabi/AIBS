# Integrasi AI untuk review draft

Adapter Gemini REST mengirim structured output JSON Schema `DraftContent` melalui backend saja. Pilih ID model tersedia dan isi `GEMINI_MODEL` serta `GEMINI_API_KEY` pada environment lokal/server. Nama model dalam PRD tidak diperlakukan sebagai ID yang pasti tersedia. Tidak ada training model atau AI pada aturan/menu/dashboard.

Analisis hanya pada `POST /api/v1/analysis/photo` dan `/analysis/journal`, dengan `request_id` UUID unik per tindakan eksplisit. Body foto memakai media ID privat, intent dan reference_date; body jurnal memakai text dan reference_date. Timezone dari profil server. Response berisi `analysis_status=needs_confirmation` dan draft yang belum tersimpan sebagai event.

Consent dasar dan AI diperiksa sebelum egress. PostgreSQL row lock per profil menyerialkan pemeriksaan consent, quota dan dispatch; jika pencabutan izin lebih dahulu mendapat lock, panggilan ditolak. Panggilan yang sudah berjalan tidak bisa ditarik kembali. Lock ditahan selama panggilan bounded timeout; perubahan profil/consent user yang sama dapat menunggu sampai panggilan selesai.

Kuota default 20 percobaan per owner per hari **UTC**, termasuk percobaan gagal yang sudah mencapai adapter. Request ID sama tidak memanggil provider ulang; ID sama/payload berbeda 409. Kegagalan yang sudah tercatat memerlukan tindakan baru dengan ID baru untuk retry, atau manual. Tidak ada automatic HTTP retry agar timeout tidak menggandakan panggilan berbayar. Crash/putus koneksi setelah provider menerima request tetapi sebelum transaksi DB commit masih dapat menyebabkan panggilan ulang pada retry; provider ini tidak menyediakan exactly-once billing. Gateway perlu melengkapi rate limit lintas owner.

Output AI divalidasi dan dinormalisasi dengan katalog: UUID dari model tidak dipercaya, alias ambigu tetap unknown, ingredient AI tetap candidate, seluruh waktu belum dikonfirmasi, komposisi belum lengkap, foto tidak menghasilkan gejala. Prompt meminta negasi dan ketidakpastian dipertahankan; ketepatan semantik tetap harus dievaluasi Miguel menggunakan provider/model nyata. Tes fixture tidak membuktikan kualitas model.

Draft jurnal menyimpan `story` milik user untuk melanjutkan/review, tanpa menuliskannya ke log. `ai_runs` hanya metadata fitur/model/prompt, hash request, status, token usage dan latency, tanpa isi jurnal/foto atau secret. Setelah user mengedit draft, simpan memakai endpoint commit yang sama dengan manual; review/edit/simpan tidak memanggil AI.

Hasil invalid -> 502; timeout/unavailable -> 503; kuota -> 429; AI nonaktif -> 403. FE tetap membuka editor manual dan mempertahankan input. Panggilan nyata, biaya/token nyata, evaluasi “nggak mual/nggak muntah”, serta pemilihan model masih pending sampai key/model tersedia.
