# Desain Teknis — Habit Leveling

Dokumen ini adalah sumber kebenaran teknis. Bila ada dokumen lain yang bertentangan dengan file ini, file ini yang menang.

---

## 1. Model habit

### Tipe

Hanya ada dua tipe habit di seluruh sistem.

**`hitung`** — punya `target` dan `satuan`. Nilai harian berupa angka.
Centang biasa adalah kasus khusus dengan `target = 1`. Tipe ini menutup 14 dari 16 preset.

**`waktu`** — punya `ambang` (menit sejak tengah malam) dan `arah` (`sebelum` atau `sesudah`). Nilai harian berupa jam yang dicatat user. Tercapai bila jam tersebut memenuhi arah terhadap ambang.

Tipe `waktu` wajib menangani jam yang melewati tengah malam. Tidur jam 00:30 bernilai 30 menit, dan tanpa penanganan khusus 30 < 1380 sehingga "tidur sebelum jam 23" dinyatakan berhasil — persis kebalikan dari yang dimaksud. Aturannya:

```
nilai_efektif = (arah == sebelum && nilai < ambang − 720)
                ? nilai + 1440
                : nilai
```

Jendela 12 jam sebelum ambang itu yang memisahkan "larut malam" dari "pagi berikutnya". Untuk `tidur_sebelum_23` (ambang 1380), jam apa pun sebelum 11:00 dianggap dini hari dan digeser ke hari berikutnya, sehingga 00:30 menjadi 1470 dan gagal — benar. Untuk `bangun_konsisten` (ambang 360), `ambang − 720` bernilai negatif sehingga tidak pernah ada pergeseran — juga benar.

Pedometer **bukan tipe ketiga**. Ia hanya sumber nilai untuk habit `hitung` biasa. Bila sumber tidak tersedia, habit itu jatuh ke input manual tanpa jalur kode terpisah.

### Katalog preset

16 habit, 4 per pilar. Kolom `key` tersimpan di database pengguna dan tidak boleh berubah setelah rilis.

#### Pilar Gerak

| key | Nama tampilan | Tipe | Target | Satuan | XP dasar | Sumber |
|-----|---------------|------|--------|--------|----------|--------|
| `langkah_harian` | Langkah harian | hitung | 5000 | langkah | 10 | pedometer |
| `olahraga` | Olahraga | hitung | 10 | menit | 15 | manual |
| `peregangan_pagi` | Peregangan pagi | hitung | 1 | kali | 10 | manual |
| `peregangan_malam` | Peregangan sebelum tidur | hitung | 1 | kali | 10 | manual |

#### Pilar Makan

| key | Nama tampilan | Tipe | Target | Satuan | XP dasar | Sumber |
|-----|---------------|------|--------|--------|----------|--------|
| `isi_piringku` | Makan sesuai Isi Piringku | hitung | 2 | makan utama | 15 | manual |
| `prioritas_protein` | Prioritas protein | hitung | 2 | makan utama | 10 | manual |
| `minum_air` | Minum air | hitung | 8 | gelas | 10 | manual |
| `batasi_gula_olahan` | Batasi gula tambahan & makanan olahan | hitung | 1 | kali | 10 | manual |

#### Pilar Tidur

| key | Nama tampilan | Tipe | Target / Ambang | Satuan | XP dasar | Sumber |
|-----|---------------|------|-----------------|--------|----------|--------|
| `tidur_sebelum_23` | Tidur sebelum jam 23 | waktu | 23:00, sebelum | — | 15 | manual |
| `durasi_tidur` | Durasi tidur | hitung | 420 | menit | 15 | manual |
| `bangun_konsisten` | Bangun jam konsisten | waktu | 06:00, sebelum | — | 10 | manual |
| `tanpa_layar_sebelum_tidur` | Tanpa layar 30 menit sebelum tidur | hitung | 1 | kali | 10 | manual |

#### Pilar Pikiran

| key | Nama tampilan | Tipe | Target | Satuan | XP dasar | Sumber |
|-----|---------------|------|--------|--------|----------|--------|
| `napas_meditasi` | Napas atau meditasi | hitung | 5 | menit | 10 | manual |
| `jurnal_syukur` | Jurnal syukur | hitung | 3 | hal | 10 | manual |
| `batas_medsos` | Batas medsos di bawah 2 jam | hitung | 1 | kali | 10 | manual |
| `kena_matahari` | Keluar rumah kena matahari | hitung | 1 | kali | 10 | manual |

Ambang pada habit `waktu` bisa disesuaikan user, begitu juga target pada habit `hitung`. XP dasar **tidak** bisa disesuaikan.

Dua catatan tentang tabel di atas:

- **Semua nilai disimpan sebagai bilangan bulat.** Habit bersatuan waktu disimpan dalam menit dan ditampilkan dalam jam, supaya "tidur 7,5 jam" tidak hilang menjadi 7. `durasi_tidur` bertarget 420 menit dan tampil sebagai "7 jam".
- **`bangun_konsisten` diukur sebagai "bangun sebelum ambang"**, bukan sebagai keseragaman antar hari. Mengukur keseragaman butuh riwayat dan membuat aturannya tidak bisa dijelaskan dalam satu kalimat. Ambangnya bisa disesuaikan user, dan konsistensi tetap terbentuk karena ambangnya sama setiap hari.

### Habit custom

- Maksimal 5, selalu tipe `hitung`
- User menentukan nama, satuan, target, dan pilar
- XP dasar dipatok **5**, tidak peduli isi habitnya
- Tidak pernah dipilih menjadi quest harian
- Tidak dihitung untuk medali apa pun
- Tidak punya kartu penjelasan

Kombinasi XP flat 5 dan batas 5 slot sudah membatasi kontribusi custom di **25 XP per hari** — kurang dari satu habit preset yang dikerjakan penuh. Itu yang menutup celah farming; tidak perlu aturan pembatas tambahan. User boleh menulis habit apa pun tanpa bisa mengubahnya menjadi mesin XP.

### Kartu penjelasan

Setiap habit preset punya entri di `lib/data/habit_info.dart`, berisi tiga bagian: **kenapa penting**, **manfaat**, **cara mudah**. Panjangnya bebas per habit — `isi_piringku` wajar panjang, `peregangan_pagi` cukup beberapa kalimat.

Isinya hidup di Dart, bukan di markdown. Menulisnya di dua tempat menjamin keduanya berbeda dalam sebulan.

---

## 2. Aturan XP dan level

Seluruh aturan di bagian ini diterapkan sebagai fungsi murni di `lib/logic/xp.dart`.

### XP per habit per hari

Tipe `hitung`:

```
xp = round(xp_dasar × min(1, nilai / target))
```

Tipe `waktu`: `xp_dasar` bila tercapai, `0` bila tidak.

XP proporsional adalah keputusan produk, bukan kemudahan implementasi. Setengah jalan yang dihargai adalah yang membuat orang kembali besok.

### XP dibekukan saat dicatat

**XP dihitung sekali saat pencatatan, lalu disimpan di baris `logs` itu sendiri.** XP tidak pernah dihitung ulang dari `xp_dasar` dan `target` yang berlaku sekarang.

Ini bukan optimasi, melainkan syarat kebenaran. User boleh mengubah target — misalnya langkah 5.000 menjadi 8.000. Bila XP dihitung ulang dari target yang berlaku, seluruh riwayat ikut dinilai dengan target baru, XP masa lalu menyusut, dan level bisa **turun** hanya karena user menaikkan tantangannya sendiri. Aturan "XP tidak pernah berkurang" tidak bisa dipenuhi tanpa pembekuan ini.

Konsekuensinya, mengubah target hanya berlaku untuk hari-hari berikutnya. Itu memang perilaku yang benar.

### XP pilar dan level pilar

XP pilar adalah jumlah kolom `xp` dari seluruh baris `logs` milik habit pilar itu, ditambah bagian bonus quest pilar tersebut. XP tidak pernah berkurang.

Level terendah adalah **1**, dicapai dengan 0 XP. Naik dari level `L` ke `L+1` butuh `100 × L` XP. Maka XP kumulatif untuk mencapai level `L`:

```
xpUntukLevel(L) = 50 × L × (L − 1)
```

Cek: level 1 = 0 XP, level 2 = 100 XP, level 3 = 300 XP, level 4 = 600 XP.

### Level global

Dihitung dari **total XP seluruh pilar**, bukan rata-rata level pilar. Ambangnya empat kali lipat ambang pilar:

```
xpUntukLevelGlobal(L) = 200 × L × (L − 1)
```

Konsekuensinya, usaha di pilar mana pun selalu terbaca. Pilar yang tertinggal tidak menahan level global.

### Skor Keseimbangan

```
skor = level pilar terendah / level pilar tertinggi × 100
```

Karena level terendah adalah 1, penyebutnya tidak pernah nol. User baru mendapat skor 100. Hanya ditampilkan; tidak memengaruhi XP, level, maupun streak.

**Keempat pilar selalu ikut dihitung**, termasuk pilar yang tidak punya satu pun habit aktif. Pilar yang diabaikan memang seharusnya menurunkan skor keseimbangan — itu justru informasi yang ingin ditampilkan. Karena itu lima habit yang tercentang sebagai saran saat onboarding wajib mencakup keempat pilar, supaya user baru tidak dibukakan aplikasi dengan skor rendah yang tidak ia mengerti.

Skor hari itu disimpan di kolom `hari.skor_keseimbangan` saat pemrosesan hari. Tanpa itu, medali "≥90% selama 7 hari beruntun" tidak punya data untuk dievaluasi — level hanya diketahui nilainya sekarang, bukan nilainya minggu lalu.

### Bonus quest

Menyelesaikan **seluruh** habit quest di hari yang sama memberi **25 XP bonus**, dibagi rata ke pilar habit-habit tersebut. Bonus hanya bisa diambil sekali per hari, ditandai lewat kolom `bonus_diambil`.

---

## 3. Quest harian

Diterapkan di `lib/logic/quest.dart` sebagai fungsi murni: masuk daftar habit aktif, level tiap pilar, riwayat 7 hari, dan tanggal — keluar tiga `habit_id`.

### Pemilihan

1. Kandidat adalah seluruh habit aktif yang bukan custom
2. Urutkan menaik berdasarkan level pilar habit tersebut
3. Bila seri, urutkan menaik berdasarkan tingkat keberhasilan habit itu dalam 7 hari terakhir
4. Bila masih seri, urutkan dengan pengacakan deterministik yang diunggulkan oleh tanggal (`yyyyMMdd`)
5. Ambil tiga teratas

Bila habit preset yang aktif kurang dari tiga, seluruhnya menjadi quest. Bila tidak ada satu pun, hari itu tidak punya quest dan tidak bisa menaikkan streak — keadaan yang hanya mungkin terjadi kalau user sengaja menonaktifkan semua preset, dan pengaturan harus memperingatkannya.

Karena unggulan acaknya berasal dari tanggal, quest tidak berubah saat aplikasi ditutup dan dibuka ulang di hari yang sama. Quest yang sudah tersimpan di tabel `hari` selalu dipakai apa adanya dan tidak pernah dihitung ulang.

### Efek

Habit di luar quest tetap bisa dicatat dan tetap memberi XP penuh. Quest hanya menentukan bonus dan streak.

---

## 4. Streak dan jeda

Diterapkan di `lib/logic/streak.dart` sebagai fungsi murni.

### Definisi

- **Streak** bertambah satu untuk setiap hari yang quest-nya selesai
- **Jeda** diperoleh satu setiap kali streak mencapai kelipatan 7, tersimpan maksimal 3
- Hari kosong memakai satu jeda bila tersedia. Streak **tidak bertambah dan tidak direset** — ia tertahan
- Hari kosong tanpa jeda tersisa mereset streak ke 0

### Pemrosesan hari

Tidak ada background service dan tidak ada alarm tengah malam. Kedua hal itu sumber bug yang tidak perlu diundang.

Saat aplikasi dibuka, jalankan pemrosesan untuk setiap tanggal antara `terakhir_diproses + 1` hingga **kemarin**. Hari ini sengaja tidak diproses — quest-nya masih terbuka.

```
untuk setiap tanggal T dari (terakhir_diproses + 1) sampai (hari_ini - 1):
    jika quest tanggal T selesai:
        streak += 1
        jika streak % 7 == 0: jeda = min(3, jeda + 1)
    selain itu jika jeda > 0:
        jeda -= 1
        tandai hari T sebagai 'dijeda'
        (streak tidak berubah)
    selain itu:
        streak = 0
    terakhir_diproses = T
```

Selain streak dan jeda, perulangan ini juga membekukan `sempurna` dan `skor_keseimbangan` untuk tanggal yang diproses.

Perulangan ini harus benar untuk celah panjang. Aplikasi yang tidak dibuka selama 30 hari akan memproses 30 tanggal sekaligus, memakai jeda yang tersedia lebih dulu, lalu mereset.

**Streak yang ditampilkan** adalah nilai `meta.streak` ditambah satu bila quest hari ini sudah selesai. Penambahan itu hanya untuk tampilan dan tidak pernah ditulis ke `meta` — hari ini baru dibukukan besok, saat pemrosesan hari berjalan. Tanpa aturan ini, user yang baru menuntaskan quest hari ini akan melihat streak-nya seolah tidak bergerak.

### Waktu dan zona waktu

Tanggal disimpan sebagai `yyyy-MM-dd` dalam waktu lokal. Tanggal yang sudah tercatat di tabel `hari` tidak pernah diproses ulang. Jam perangkat yang mundur atau perpindahan zona waktu karena itu tidak bisa menghapus streak — kasus terburuknya hanya satu hari yang tertunda pemrosesannya.

---

## 5. Medali

30 medali. Evaluasinya ada di `lib/logic/achievement.dart` sebagai fungsi murni: service membaca database, lalu mengoper ringkasan keadaan (level tiap pilar, level global, streak, akumulasi per habit, riwayat hari sempurna) sebagai argumen. Fungsi itu sendiri tidak menyentuh database. Habit custom tidak dihitung untuk medali mana pun.

| Kelompok | Jumlah | Isi |
|----------|--------|-----|
| Streak | 4 | 7, 30, 100, 365 hari beruntun |
| Level pilar | 12 | Tiap pilar mencapai Lv.5, Lv.10, Lv.25 |
| Level global | 3 | Lv.10, Lv.25, Lv.50 |
| Akumulasi | 4 | 500.000 langkah, 1.000 gelas air, 1.000 menit olahraga, 300 hal jurnal syukur |
| Keseimbangan | 3 | Empat pilar tembus Lv.5, empat pilar tembus Lv.10, Skor Keseimbangan ≥ 90% selama 7 hari beruntun |
| Pemulihan | 2 | Memakai jeda pertama kali, mencapai streak 7 lagi setelah streak pernah putus |
| Konsistensi | 2 | Satu hari sempurna (semua habit aktif selesai), 10 hari sempurna |

Keempat medali akumulasi dihitung dalam satuan habitnya sendiri dan sengaja disetarakan pada sekitar 100 hari pengerjaan penuh: 500.000 langkah pada target 5.000, 1.000 menit olahraga pada target 10, 300 hal jurnal pada target 3. Yang 1.000 gelas air sedikit lebih jauh, sekitar 125 hari.

Medali yang terbuka memicu popup pengumuman, mengikuti pola Muslim Leveling. Medali terkunci tetap terlihat di grid beserta syaratnya — syarat yang tersembunyi tidak memotivasi siapa pun.

---

## 6. Data

### Skema

**`habits`**

| Kolom | Tipe | Catatan |
|-------|------|---------|
| `id` | INTEGER PK | |
| `key` | TEXT UNIQUE | kunci preset, atau `custom_<n>` |
| `nama` | TEXT | |
| `pilar` | TEXT | `gerak`, `makan`, `tidur`, `pikiran` |
| `tipe` | TEXT | `hitung` atau `waktu` |
| `target` | INTEGER | target, atau ambang dalam menit untuk tipe `waktu` |
| `arah` | TEXT NULL | `sebelum` / `sesudah`, hanya untuk tipe `waktu` |
| `satuan` | TEXT | |
| `xp_dasar` | INTEGER | |
| `sumber` | TEXT | `manual` atau `pedometer` |
| `aktif` | INTEGER | 0 / 1 |
| `urutan` | INTEGER | |
| `is_custom` | INTEGER | 0 / 1 |

**`logs`**

| Kolom | Tipe | Catatan |
|-------|------|---------|
| `id` | INTEGER PK | |
| `habit_id` | INTEGER FK | |
| `tanggal` | TEXT | `yyyy-MM-dd` |
| `nilai` | INTEGER | jumlah, atau menit sejak tengah malam untuk tipe `waktu` |
| `xp` | INTEGER | XP yang dibekukan saat pencatatan |

UNIQUE `(habit_id, tanggal)`. Index pada `tanggal`.

**`hari`**

| Kolom | Tipe | Catatan |
|-------|------|---------|
| `tanggal` | TEXT PK | |
| `quest_ids` | TEXT | hingga tiga id dipisah koma |
| `bonus_diambil` | INTEGER | 0 / 1 |
| `dijeda` | INTEGER | 0 / 1 |
| `sempurna` | INTEGER | 0 / 1, dibekukan saat pemrosesan hari |
| `skor_keseimbangan` | INTEGER | 0–100, dibekukan saat pemrosesan hari |

Dua kolom terakhir dibekukan karena alasan yang sama dengan kolom `xp` di `logs`. "Hari sempurna" berarti seluruh habit yang aktif **pada hari itu** selesai; kalau dihitung ulang dari daftar aktif hari ini, hari sempurna bulan lalu bisa berubah status hanya karena user mengaktifkan habit baru hari ini. Riwayat tidak boleh berubah karena keputusan hari ini.

Baris `hari` dibuat saat aplikasi pertama dibuka di tanggal tersebut. **Tanggal tanpa baris `hari` berarti aplikasi tidak dibuka hari itu, dan diperlakukan sebagai quest tidak selesai** oleh perulangan pemrosesan hari.

**`meta`** — pasangan kunci-nilai: `jeda_tersedia`, `streak`, `streak_pernah_putus`, `terakhir_diproses`, `acuan_langkah`, `acuan_langkah_tanggal`, `jam_pengingat`, `maks_habit_aktif`.

**`medali`** — `key` TEXT PK, `dibuka_pada` TEXT.

### Pengisian awal

Preset diisi ke tabel `habits` saat pertama kali dijalankan, bukan dibaca langsung dari konstanta setiap saat. Alasannya: user bisa mengubah target, dan habit custom hidup di tabel yang sama. Satu jalur kode untuk semua habit.

Bila versi aplikasi baru menambah preset, migrasi menyisipkan habit yang `key`-nya belum ada, dalam keadaan tidak aktif. Preset yang sudah ada tidak pernah ditimpa — user mungkin sudah mengubah targetnya.

### Ekspor dan impor

Satu file JSON berisi seluruh tabel plus nomor versi skema, dibagikan lewat `share_plus`. Impor **mengganti seluruh data** setelah konfirmasi eksplisit. Impor dari versi skema yang lebih baru ditolak dengan pesan jelas.

Ini pengganti backup cloud. Tanpanya, ganti perangkat berarti kehilangan seluruh riwayat.

---

## 7. Arsitektur aplikasi

```
lib/
  main.dart
  data/
    habit_preset.dart        16 preset sebagai konstanta
    habit_info.dart          isi kartu penjelasan
    achievement_preset.dart  30 definisi medali
  db/
    database.dart            sqflite, skema, migrasi
    habit_dao.dart
    log_dao.dart
  logic/                     FUNGSI MURNI SAJA
    xp.dart
    streak.dart
    quest.dart
    achievement.dart
  services/
    habit_service.dart       ValueNotifier, orkestrasi baca/tulis
    step_service.dart        pedometer, acuan harian
    notification_service.dart
    backup_service.dart      ekspor / impor JSON
  screens/
    onboarding/
    beranda/
    statistik/
    medali/
    pengaturan/
  widgets/
```

`lib/logic/` tidak boleh menyentuh database, `DateTime.now()`, atau penyimpanan. Tanggal selalu dioper sebagai argumen. Aturan inilah yang membuat XP, streak, jeda, dan pemilihan quest bisa diuji tanpa emulator dan tanpa menunggu tengah malam.

**State:** service dengan `ValueNotifier`, mengikuti pola Muslim Leveling. Tidak ada Riverpod, Bloc, atau GetX — tidak ada masalah di aplikasi ini yang mereka pecahkan.

**Navigasi:** empat tab dalam `IndexedStack` — Beranda, Statistik, Medali, Pengaturan.

### Dependensi yang disetujui

| Paket | Untuk |
|-------|-------|
| `sqflite`, `path` | database |
| `flutter_local_notifications`, `timezone` | notifikasi terjadwal |
| `permission_handler` | izin notifikasi, exact alarm, activity recognition |
| `pedometer` | langkah harian |
| `fl_chart` | radar dan grafik batang |
| `share_plus`, `file_picker`, `path_provider` | ekspor dan impor |
| `flutter_lints` | analisis statis |

Menambah paket di luar daftar ini butuh persetujuan pemilik repo.

---

## 8. Layar

### Onboarding

Sekali di awal. Sambutan singkat menjelaskan empat pilar, lalu pemilihan habit dengan 5 tercentang sebagai saran, lalu pemilihan jam pengingat, lalu permintaan izin notifikasi dan pedometer.

Lima saran bawaannya: `langkah_harian`, `minum_air`, `isi_piringku`, `tidur_sebelum_23`, `napas_meditasi` — mencakup keempat pilar, sesuai alasan di bagian Skor Keseimbangan.

Batas 8 adalah fitur. Dua belas habit aktif di hari pertama adalah cara tercepat membuat orang berhenti di hari ketiga. Batasnya bisa diubah di pengaturan bagi yang bersikeras. **Batas berlaku untuk total habit aktif, preset dan custom digabung** — kalau custom kebal batas, batasnya tidak ada artinya.

### Beranda

Level global dan bar XP · streak berjalan dan sisa jeda · **Quest Hari Ini** sebagai tiga kartu besar · habit aktif sisanya sebagai daftar ringkas.

Setiap baris habit menampilkan nama, progres (`6/8 gelas`), tombol tambah, dan ikon yang membuka kartu penjelasan.

### Statistik

Radar empat pilar dengan Skor Keseimbangan · grafik batang mingguan · persentase keberhasilan tiap habit dalam 30 hari terakhir.

### Medali

Grid. Yang terkunci berwarna abu-abu namun syaratnya tetap terbaca.

### Pengaturan

Kelola habit (aktif/nonaktif, ubah target dan ambang) · habit custom · jam pengingat · ekspor dan impor · tentang.

---

## 9. Notifikasi

Dua jadwal:

1. **Pengingat harian** pada jam pilihan user
2. **Peringatan malam** pukul 21:00, dijadwalkan ulang setiap kali data berubah, dan dibatalkan begitu quest hari itu selesai

Pengingat per-habit sengaja tidak dibuat. Delapan habit aktif berarti delapan notifikasi sehari, yang berujung pada user mematikan notifikasi aplikasi — dan setelah itu aplikasi diam selamanya.

**Wajib sejak commit pertama yang menyentuh notifikasi:** keep rules Gson di `android/app/proguard-rules.pro`. Lihat `AGENTS.md` bagian jebakan. Notifikasi wajib diverifikasi di **release build**; bug ini tidak muncul di debug build.

---

## 10. Penanganan error

| Kondisi | Perilaku |
|---------|----------|
| Izin activity recognition ditolak | `langkah_harian` beralih ke input manual, banner sekali di beranda |
| Perangkat tanpa pedometer | Sama seperti di atas, tanpa banner |
| Perangkat restart | Nilai sensor lebih kecil dari acuan tersimpan berarti acuan direset ke nilai baru; langkah hari itu dihitung dari titik tersebut |
| Izin notifikasi ditolak | Aplikasi berjalan normal, banner di pengaturan menjelaskan apa yang hilang |
| Exact alarm tidak diizinkan | Turun ke jadwal inexact, banner menjelaskan notifikasi bisa meleset |
| Aplikasi tidak dibuka berhari-hari | Pemrosesan hari mengejar seluruh celah saat dibuka |
| Jam perangkat mundur | Tanggal yang sudah diproses tidak pernah diproses ulang |
| Impor JSON rusak atau versi skema lebih baru | Ditolak dengan pesan jelas, data lama tidak tersentuh |
| Migrasi database | Bernomor versi sejak versi pertama |

---

## 11. Pengujian

Unit test untuk `lib/logic/`, tanpa emulator:

- XP proporsional, termasuk nilai melampaui target dan target bernilai nol
- **XP yang dibekukan tidak berubah setelah target habit diubah** — uji regresi untuk lubang paling berbahaya di desain ini
- Ambang level pilar dan level global di titik batas
- Habit custom memakai XP flat 5, dan tidak pernah masuk perhitungan quest maupun medali
- **Pergeseran tengah malam pada tipe `waktu`**: tidur 00:30 gagal untuk ambang 23:00, tidur 22:30 berhasil, bangun 05:00 berhasil untuk ambang 06:00
- Konsumsi jeda melintasi banyak hari kosong sekaligus, termasuk kasus jeda habis di tengah celah
- Tanggal tanpa baris `hari` diperlakukan sebagai quest tidak selesai
- Perolehan jeda pada kelipatan 7 dan batas maksimal 3
- Determinisme pemilihan quest untuk tanggal yang sama, dan prioritas pilar terlemah
- Syarat setiap medali di titik batas

Tidak ada widget test dan tidak ada integration test di versi pertama. Yang perlu dijaga adalah logika yang kalau salah, salahnya diam-diam — bukan tata letak yang salahnya langsung kelihatan.
