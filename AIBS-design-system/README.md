# AIBS

AIBS (AI for IBS) bantu orang dewasa dengan IBS (Irritable Bowel Syndrome) milih makanan sesuai arahan dokter dan mencatat gejala. Rasanya harus aman dan bisa dipercaya, tapi tetap ramah dan ringan buat anak muda.

## Suara dan teks

- Bahasa Indonesia santai, sapa user dengan "kamu". Kalimat pendek.
- Tanpa subjudul penjelas dan tanpa catatan tentang cara kerja sistem. Kalau sebuah layar butuh penjelasan, desainnya yang diperbaiki.
- Tombol pakai kata kerja: "Catat", "Cek makanan", "Saya makan ini".
- Hindari klaim sebab-akibat medis. Pola selalu diberi label kecil "Belum tentu penyebab".

## Warna

- **Biru (`primary`) adalah warna brand.** Dipakai untuk aksi utama, nav aktif, dan header bergradasi. Gradasi selalu dari `sky` ke `primary`, lembut dan satu arah, cuma di header dan tombol utama.
- **Empat warna status hanya untuk hasil cek.** `ok` Sesuai, `warn` Perlu hati-hati, `bad` Tidak sesuai arahan, `unknown` Belum bisa dinilai. Jangan dipakai buat dekorasi. Teks status pakai varian `-ink`, latar pakai `-soft`.
- Status selalu dibarengi simbol (✓ ! × ?) supaya tidak bergantung pada warna saja.
- Latar halaman `surface`, kartu `card` dengan `shadow-card`. Banyak ruang kosong: jarak antar section `space-6`.

## Tipografi

Satu keluarga: Nunito (Google Fonts). Judul tebal (800), isi 600. Pakai gaya `display` untuk sapaan dan hasil besar, `heading` untuk judul section, `label` untuk kategori kecil di atas nilai pilihan user. Pilihan user selalu lebih menonjol dari nama kategorinya.

## Ikon

Ikon fitur berupa ilustrasi kecil berwarna penuh dengan gradasi lembut, ditaruh di kotak `primary-soft` dengan `radius-sm`. Ikon navigasi dan aksi kecil berupa garis 2px warna `ink` atau `ink-muted`.

## Maskot

Koala abu-abu dengan syal biru dan daun hijau. Ilustrasinya orisinal, tidak meniru gambar stok. Tiga ekspresi di grup aset Maskot:

- `koala-senang.svg`: layar sambutan, Hari Ini, simpan berhasil.
- `koala-mikir.svg`: saat foto dianalisis atau data belum cukup.
- `koala-khawatir.svg`: hasil cek Tidak sesuai arahan. Tetap tenang, tidak dramatis.

Maskot muncul paling banyak satu kali per layar dan tidak pernah menutupi informasi status.

## Prinsip layout

- **Tiap elemen harus punya tujuan.** Kartu atau header yang cuma jadi wadah sapaan dibuang. Pertanyaan utama layar langsung di atas.
- **Yang berhubungan ditaruh berdekatan.** Link seperti "Lihat semua" jadi bagian dari kelompok yang dirujuknya (mis. kartu terakhir di slider), bukan melayang sendiri dan bukan sebaris dengan judul besar.
- **Teks seminimal mungkin.** Tanpa subjudul penjelas, tanpa keterangan di dalam kartu, tanpa catatan cara kerja sistem. Disclaimer dan "Belum tentu penyebab" tetap ada, tapi kecil.
- **Pilihan user lebih menonjol dari kategorinya.** Nama kategori kecil (`caption`, `ink-muted`), nilai pilihan tebal dan besar.
- **Maskot harus punya peran**, misalnya jadi yang bertanya lewat gelembung chat. Jangan ditempel sekadar hiasan. Teks di sebelahnya tidak boleh lebih tinggi dari ujung kuping koala.
- **Aksi ikonik tanpa label tambahan.** Foto makanan cukup lewat tombol kamera di tengah nav.

## Bentuk

Sudut membulat besar: kartu `radius-md`, header dan sheet `radius-lg`, chip dan badge `radius-pill`. Target sentuh minimal 44px.
