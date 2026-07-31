# PRD — Habit Leveling

## Masalah

Aplikasi habit tracker yang ada umumnya berakhir sama: user semangat di minggu pertama, bolos sekali, streak hangus, lalu berhenti membuka aplikasi. Aplikasi kesehatan yang ada juga cenderung sempit — hanya soal makan, atau hanya soal olahraga — padahal tidur dan kondisi pikiran sama menentukannya.

## Produk

Aplikasi Android yang menggabungkan pencatatan kebiasaan sehat lintas empat pilar dengan sistem progres bergaya RPG, dirancang supaya tetap bertahan di hari-hari buruk.

Empat pilar: **Gerak, Makan, Tidur, Pikiran**. Masing-masing punya level sendiri, sehingga ketimpangan terlihat — bukan tersembunyi di balik satu angka tunggal.

## Untuk siapa

Pengguna Android berbahasa Indonesia yang ingin memperbaiki kebiasaan harian, menyukai progres yang terukur dan terasa seperti permainan, dan tidak ingin data kesehatannya disimpan di server orang lain.

Bukan untuk: atlet yang butuh metrik latihan detail, pengguna yang ingin menghitung kalori, atau siapa pun yang mencari fitur sosial dan kompetisi.

## Prinsip

1. **Hari buruk tidak boleh menghancurkan progres.** Jatah jeda, XP proporsional, dan quest tiga habit semuanya ada untuk ini.
2. **Ketimpangan ditampilkan, bukan dihukum.** Radar dan Skor Keseimbangan menunjukkan kelemahan; XP tidak pernah berkurang karenanya.
3. **Sedikit gesekan lebih baik daripada banyak fitur.** Batas 8 habit aktif adalah fitur, bukan keterbatasan.
4. **Data kesehatan tetap di perangkat.** Tanpa akun, tanpa jaringan.
5. **Setiap habit menjelaskan dirinya.** User berhak tahu kenapa sesuatu penting sebelum diminta melakukannya setiap hari.

## Fitur versi pertama

### Pemilihan habit
- 16 habit preset, 4 per pilar, dengan target dan XP yang sudah terkalibrasi
- User mengaktifkan habit yang ingin dikerjakan, maksimal 8 (bisa diubah di pengaturan)
- Target preset bisa disesuaikan, misalnya langkah 5.000 menjadi 8.000
- Maksimal 5 habit custom buatan user

### Pencatatan harian
- Dua tipe habit: `hitung` (punya target dan satuan) dan `waktu` (tercapai bila lebih awal/lebih lambat dari ambang)
- Langkah harian terisi otomatis dari sensor pedometer; sisanya dicatat manual
- Bila izin sensor ditolak atau perangkat tidak punya pedometer, habit langkah beralih ke input manual

### Kartu penjelasan
- Setiap habit preset punya kartu berisi **kenapa penting**, **manfaatnya**, dan **cara mudah melakukannya**
- Bisa dibuka dari ikon di samping tiap habit

### Progres
- XP proporsional terhadap pencapaian — 6 dari 8 gelas tetap mendapat 75% XP
- Level per pilar dan level global
- Radar empat pilar dan Skor Keseimbangan
- Riwayat mingguan dan persentase keberhasilan 30 hari per habit

### Quest harian
- Tiga habit fokus dipilih sistem setiap hari, terkunci oleh tanggal
- Prioritas jatuh ke pilar dengan level terendah dan habit yang paling jarang selesai
- Menyelesaikan seluruhnya memberi bonus XP dan menaikkan streak

### Streak dan jeda
- Streak naik saat quest harian selesai
- Satu jeda diperoleh tiap 7 hari beruntun, tersimpan maksimal 3
- Hari kosong otomatis memakai satu jeda; tanpa jeda, streak kembali ke nol

### Medali
- 30 medali: milestone streak, level pilar, level global, akumulasi, keseimbangan, dan pemulihan
- Popup pengumuman saat terbuka

### Notifikasi
- Satu pengingat harian pada jam pilihan user
- Satu peringatan malam, hanya muncul bila quest hari itu belum selesai

### Data
- Seluruh data di perangkat, database SQLite
- Ekspor dan impor satu file JSON

## Kriteria terima

Ada sembilan kriteria fungsional plus satu kriteria kualitas kode. Versi pertama dianggap selesai bila:

1. User baru bisa melewati onboarding, memilih habit, dan mencatat progres pertamanya tanpa instruksi tambahan
2. XP, level pilar, dan level global terhitung sesuai rumus di `docs/design.md`, dibuktikan lewat unit test
3. Streak bertahan melewati satu hari kosong bila jeda tersedia, dan kembali ke nol bila tidak — dibuktikan lewat unit test yang melintasi banyak hari kosong sekaligus
4. Quest harian tidak berubah ketika aplikasi ditutup dan dibuka ulang di hari yang sama
5. Langkah harian terisi otomatis di perangkat dengan pedometer, dan beralih ke input manual tanpa error di perangkat tanpa pedometer atau saat izin ditolak
6. Kedua notifikasi menyala di **release build**, bukan hanya debug build
7. Setiap habit preset punya kartu penjelasan yang terisi lengkap
8. Ekspor menghasilkan file JSON yang bisa diimpor kembali dan memulihkan seluruh keadaan
9. Mengubah target habit atau mengaktifkan habit baru tidak mengubah XP, level, maupun status hari sempurna di masa lalu — dibuktikan lewat unit test
10. `flutter analyze` bersih dan seluruh unit test lulus

## Di luar lingkup versi pertama

Berat badan, BMI, penghitungan kalori, basis data makanan, integrasi Health Connect atau Google Fit, akun pengguna, sinkronisasi cloud, fitur sosial, papan peringkat, tantangan mingguan bertema, avatar visual, iOS, iklan, pembelian dalam aplikasi.

Alasan setiap penolakan tercatat di `docs/decisions.md`.
