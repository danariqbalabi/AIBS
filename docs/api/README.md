# Kontrak backend v1

`contracts.json` dihasilkan dari `backend/app/schemas/domain.py` dengan `uv run python -m app.export_contracts` (dari `backend/`). Fixture `photo-v1.json` dan `journal-v1.json` di `docs/fixtures/backend/` merupakan `DraftContent` valid untuk editor. File `*-draft.json` sebelumnya adalah ilustrasi analisis, bukan payload endpoint.

Kontrak ini baseline implementasi untuk review FE/AI, belum menyatakan persetujuan rekan tim. Bahan dengan ID belum dikenal tetap meminta konfirmasi. `present=false` adalah negasi dan tidak boleh diberi severity. Waktu perkiraan memakai `period` tanpa jam buatan; waktu pasti wajib offset timezone. `confirmed` pada waktu berarti telah ditinjau user, terpisah dari apakah presisinya exact/approximate.

Severity demo memakai 1–5, Bristol 1–7 khusus observasi `bowel`, stres low/medium/high/unknown. Sesuaikan UI melalui perubahan kontrak baru jika tim memilih skala berbeda. Assessment menerima angka Q2 atau bucket hi-fi, tidak keduanya; unknown terpisah dari jawaban no dan null (belum diisi).

Semua model menolak field tambahan termasuk owner/user ID dari request. Error memakai envelope `{error: {code, message, fields, retryable}, request_id}` tanpa mencerminkan isi jurnal atau input sensitif. Versi profil/draft/assessment diperlukan pada perubahan untuk mencegah overwrite editor yang sudah usang.

Swagger `/docs` dan `/openapi.json` menampilkan endpoint yang benar-benar tersedia pada branch terkait. Rencana endpoint yang belum ada tetap ada di `docs/backend-design.md`; jangan menganggap semuanya sudah diimplementasikan.
