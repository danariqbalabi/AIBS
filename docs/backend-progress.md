# Status tahap backend dan PR

Semua implementasi dibuat sebagai perubahan nyata, commit, push dan PR berantai. Belum ada merge ke main, deployment produksi, APK, atau klaim provider nyata sudah terhubung. Baseline kebutuhan/roadmap dibuat sebelum source ada; tabel ini adalah status aktual backend.

| Tahap | Branch | Commit utama | PR |
| --- | --- | --- | --- |
| Rencana | docs/backend-plan | 8762b11, 38512be, 4213b03 | [#1](https://github.com/danariqbalabi/AIBS/pull/1) |
| 01 Bootstrap | feat/backend-bootstrap | 69c09d8 | [#2](https://github.com/danariqbalabi/AIBS/pull/2) |
| 02 Kontrak | feat/backend-api-contract | 0e86bce | [#3](https://github.com/danariqbalabi/AIBS/pull/3) |
| 03 Database | feat/backend-database | 79d0e1b | [#4](https://github.com/danariqbalabi/AIBS/pull/4) |
| 04 Auth/demo | feat/backend-auth | ab21376 | [#5](https://github.com/danariqbalabi/AIBS/pull/5) |
| 05 Profil/consent | feat/backend-profile | 90b4d8a | [#6](https://github.com/danariqbalabi/AIBS/pull/6) |
| 06 Aturan demo | feat/backend-assessment | 4554391 | [#7](https://github.com/danariqbalabi/AIBS/pull/7) |
| 07 Menu/check | feat/backend-menu | 9a778e0 | [#8](https://github.com/danariqbalabi/AIBS/pull/8) |
| 08 Draft manual | feat/backend-drafts | 86c92cf | [#9](https://github.com/danariqbalabi/AIBS/pull/9) |
| 09 Transaksi/simpan | feat/backend-records | 89015e4 | [#10](https://github.com/danariqbalabi/AIBS/pull/10) |
| 10 Riwayat | feat/backend-history | e09f43b | [#11](https://github.com/danariqbalabi/AIBS/pull/11) |
| 11 Rencana/belanja | feat/backend-planning | a71c17b | [#12](https://github.com/danariqbalabi/AIBS/pull/12) |
| 12 Foto privat | feat/backend-media | 8488eb2 | [#13](https://github.com/danariqbalabi/AIBS/pull/13) |
| 13 Adapter AI | feat/backend-ai | 9a2b2ad | [#14](https://github.com/danariqbalabi/AIBS/pull/14) |
| 14 Dashboard | feat/backend-dashboard | 046ed39 | [#15](https://github.com/danariqbalabi/AIBS/pull/15) |
| 15 Integrasi/test | test/backend-integration | e81ef2f, 4e0c013 | [#16](https://github.com/danariqbalabi/AIBS/pull/16) |
| 16 Setup/release docs | docs/backend-release | Lihat head PR; bukan hash submission | [PR release](https://github.com/danariqbalabi/AIBS/pulls?q=is%3Apr+head%3Adocs%2Fbackend-release) |

Tahap 01–14 memiliki source dan tes lokal; tahap 15 menambah tes lintas modul/provider HTTP mock. CI sampai tahap 15 sudah dikonfirmasi success. Lokal tahap 15: 71 passed, 2 PostgreSQL-only skipped. PostgreSQL disposable CI menjalankan constraint/migrasi/RLS dan row-lock concurrency yang tidak bisa dibuktikan SQLite.

Kriteria yang memerlukan provider/aplikasi nyata **masih pending**: OTP/anonymous Supabase, migrasi proyek pengguna, Storage privat dengan key sebenarnya, Gemini/kuota/evaluasi semantik, integrasi Flutter, APK, backend HTTPS dan video. Tahap 16 mendokumentasikan hasil dan keterbatasan, bukan menyatakan submission siap.

Clone bersih dari GitHub tahap 15 juga lulus dependency install, lint/format, 71 tes/2 skip lokal, migrasi/seed berulang dan smoke server Uvicorn localhost. [Rincian bukti dan keterbatasan](backend-release.md).

## Urutan review/merge

PR #1 base main; PR #2 base branch #1; setiap PR berikutnya base tahap sebelumnya, sehingga diff hanya satu tahap. Review/merge mulai #1 lalu #2 dan seterusnya dengan merge commit biasa. Sesudah base di-merge ke main, retarget PR anak ke main bila GitHub belum menyesuaikan, lalu periksa diff.

Jangan hapus branch base sebelum PR anak di-retarget. Jangan squash/rebase/force-push riwayat yang dipublikasikan. Agent belum melakukan merge otomatis.

Untuk melihat semua source saat review, checkout docs/backend-release: semua tahap sebelumnya adalah ancestor branch ini. Main tetap baseline sampai tim mengintegrasikan PR.
