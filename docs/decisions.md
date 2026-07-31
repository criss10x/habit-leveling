# Keputusan Desain — Habit Leveling

Catatan apa yang dipilih, apa yang ditolak, dan kenapa.

**Untuk AI yang baru masuk:** banyak hal di aplikasi ini yang terlihat seperti kekurangan sebenarnya keputusan sadar yang sudah ditimbang. Periksa daftar ini sebelum mengusulkan "perbaikan". Kalau tetap ingin mengusulkan, bawa alasan yang membantah alasan di sini — bukan sekadar menyebut fiturnya belum ada.

Tanggal keputusan: 2026-07-31.

---

### 1. Habit preset, bukan custom bebas

**Dipilih:** 16 preset terkalibrasi yang bisa diaktifkan/dinonaktifkan, plus maksimal 5 habit custom.

**Ditolak:** habit custom sepenuhnya bebas.

XP hanya bisa adil kalau bobot tiap habit dirancang. Dengan custom bebas, user bisa membuat "napas 1000 kali" dan memanen XP, dan medali terpaksa jadi generik karena sistem tidak tahu apa isi habitnya. Slot custom tetap ada supaya kebutuhan personal seperti fisioterapi lutut punya tempat — tapi dengan XP flat 5, tanpa medali, dan tanpa pernah masuk quest.

XP flat dikali batas 5 slot berarti seluruh habit custom bersama-sama hanya bernilai 25 XP per hari, lebih kecil dari satu habit preset yang dikerjakan penuh. **Itu yang menutup celah farming — pembatasan struktural, bukan pelarangan, dan tanpa aturan tambahan yang perlu ditegakkan.**

---

### 2. Empat pilar, bukan satu kolam XP

**Dipilih:** Gerak, Makan, Tidur, Pikiran — masing-masing punya XP dan level sendiri.

**Ditolak:** satu XP global tunggal.

Dengan satu angka, orang yang rajin olahraga tapi tidur berantakan tetap terlihat "level tinggi", dan aplikasi tidak pernah menunjukkan bahwa ada yang timpang. Empat level membuat kelemahan terbaca langsung: `Gerak Lv.12, Tidur Lv.3`.

Pilar kelima "Tubuh" (berat badan, BMI) sempat ada lalu dibuang — lihat butir 9.

---

### 3. Level global dari total XP, bukan rata-rata level pilar

**Dipilih:** level global dihitung dari total XP seluruh pilar.

**Ditolak:** level global sebagai rata-rata keempat level pilar.

Rancangan awal memakai rata-rata, sehingga pilar yang ditelantarkan menahan level global — `Gerak Lv.20` tapi `Tidur Lv.0` berarti global `Lv.5`. Sinyalnya memang tegas, tapi efek nyatanya menghukum orang karena tidak sempurna, dan itu bertabrakan dengan prinsip utama produk ini.

Gantinya, ketimpangan **ditampilkan** lewat radar dan Skor Keseimbangan, sementara dorongan ke pilar lemah dipindahkan ke jalur yang tidak menghukum: pemilihan quest mendahulukan pilar terendah, dan medali keseimbangan hanya terbuka kalau keempatnya naik bersama.

---

### 4. Jatah jeda, bukan streak habis-habisan

**Dipilih:** satu jeda per 7 hari beruntun, maksimal 3 tersimpan, otomatis menutup hari kosong.

**Ditolak:** streak murni (bolos sekali langsung nol) dan hukuman bergaya Solo Leveling (HP berkurang, level bisa turun).

Streak 40 hari yang hangus karena satu hari sakit adalah penyebab paling umum orang berhenti memakai habit tracker. Sistem hukuman lebih buruk lagi untuk aplikasi kesehatan: user yang sedang terpuruk justru dihajar aplikasinya, lalu menghapusnya.

Jeda tetap membuat sistem terasa punya taruhan karena jumlahnya terbatas dan terasa berharga. Mode bertingkat kesulitan bisa ditambahkan nanti untuk yang mencari tantangan.

---

### 5. XP proporsional, bukan tuntas-atau-nol

**Dipilih:** 6 dari 8 gelas mendapat 75% XP.

**Ditolak:** XP hanya diberikan bila target tercapai penuh.

Ini keputusan produk, bukan kemudahan implementasi. Usaha setengah jalan yang dihargai adalah yang membuat orang membuka aplikasi lagi besok.

---

### 6. Quest tiga habit

**Dipilih:** tiga habit fokus per hari, terkunci oleh tanggal, plus bonus XP.

**Ditolak:** tanpa quest sama sekali.

Kekhawatiran yang sah: habit aktif sudah menjadi checklist harian, jadi quest berisiko cuma menyalin isinya. Nilainya bukan menambah pekerjaan, melainkan di hari-hari buruk. Orang dengan 8 habit aktif yang sedang kelelahan membuka aplikasi, melihat 8 kotak kosong, lalu menutupnya. Tiga kotak masih mungkin dikerjakan.

Quest dikunci oleh tanggal supaya tidak bisa diacak ulang sampai dapat yang gampang.

---

### 7. Tanpa cloud, tanpa akun

**Dipilih:** SQLite lokal, tanpa login, ekspor/impor JSON manual.

**Ditolak:** sinkronisasi Firebase/Supabase, dan cloud penuh dengan papan peringkat serta teman.

Data habit itu kecil dan sangat pribadi. Menyimpan data kesehatan orang di server membawa tanggung jawab yang tidak sepadan dengan manfaatnya di versi pertama, ditambah biaya setup auth, aturan keamanan, dan penanganan konflik sync. Fitur sosial praktis aplikasi kedua di dalam aplikasi pertama: butuh akun, moderasi, dan server yang hidup terus.

Ekspor JSON menutup kasus ganti perangkat dengan kode beberapa baris. Kalau aplikasi terbukti dipakai, sync menyusul mudah karena datanya sudah rapi di satu database.

---

### 8. Pedometer saja, bukan Health Connect

**Dipilih:** hanya langkah harian yang otomatis, lewat sensor pedometer di perangkat.

**Ditolak:** integrasi Health Connect / Google Fit untuk langkah, tidur, dan olahraga.

Langkah adalah satu-satunya metrik yang bisa diukur andal oleh ponsel sendiri, dan kebetulan itu yang paling malas dicatat manual. Tidur dan olahraga dari Health Connect hanya terisi kalau user punya wearable — mayoritas tidak punya, jadi hasilnya banyak kerja untuk data kosong. Izin Health Connect di Android juga rumit dan sering berubah antar versi.

Mencatat sisanya secara manual justru berguna: mengetiknya sendiri adalah bagian dari sadar-diri.

---

### 9. Tanpa berat badan, BMI, dan kalori

**Dipilih:** tidak ada pelacakan berat, BMI, atau kalori.

**Ditolak:** pilar "Tubuh" berisi berat/BMI, dan pencatatan makanan berbasis kalori.

Kalori butuh basis data makanan yang besar untuk hasil yang tetap meleset. Berat badan dan BMI membuat aplikasi terasa menghakimi dan berisiko bagi sebagian pengguna. Tidak satu pun dari ketiganya diperlukan untuk membangun kebiasaan.

---

### 10. Maksimal 8 habit aktif

**Dipilih:** batas 8, dengan 5 tercentang sebagai saran saat onboarding. Bisa diubah di pengaturan.

**Ditolak:** tanpa batas.

Dua belas habit aktif di hari pertama adalah cara tercepat membuat orang berhenti di hari ketiga. Batasnya bisa dinaikkan bagi yang bersikeras, tapi bawaannya harus melindungi user dari semangat hari pertamanya sendiri.

---

### 11. Dua notifikasi, bukan per-habit

**Dipilih:** satu pengingat harian pada jam pilihan user, plus satu peringatan malam yang hanya muncul bila quest belum selesai.

**Ditolak:** pengingat terpisah untuk tiap habit.

Pengingat per-habit terlihat seperti fitur padahal jebakan: 8 habit aktif berarti 8 notifikasi sehari, user mematikan notifikasi aplikasi dalam seminggu, dan setelah itu aplikasi diam selamanya.

Peringatan malam adalah yang benar-benar menyelamatkan streak karena menembak persis saat orang masih sempat bertindak.

---

### 12. Pemrosesan hari saat aplikasi dibuka

**Dipilih:** streak dan jeda dihitung dengan membaca selisih tanggal dari catatan terakhir, dijalankan saat aplikasi dibuka.

**Ditolak:** background service atau alarm tengah malam.

Keduanya sumber bug yang tidak perlu diundang: dibunuh sistem, tertahan optimasi baterai, berperilaku beda antar produsen. Perhitungan saat dibuka memberi hasil yang sama dan tidak bisa gagal diam-diam. Konsekuensinya, perulangan pengejaran celah panjang harus benar — dan itu wajib punya unit test.

---

### 13. `ValueNotifier`, bukan Riverpod atau Bloc

**Dipilih:** service dengan `ValueNotifier`, mengikuti pola Muslim Leveling.

**Ditolak:** Riverpod, Bloc, GetX.

Aplikasi ini punya satu sumber data lokal dan tidak punya keadaan asinkron yang rumit. Tidak ada masalah di sini yang dipecahkan oleh pustaka state management, dan polanya sudah terbukti jalan di proyek sebelumnya.

---

### 14. Repo baru, bukan fork Muslim Leveling

**Dipilih:** proyek Flutter baru yang menyalin pola Muslim Leveling secara sadar.

**Ditolak:** fork lalu buang bagian Islami, dan package bersama `leveling_core` untuk kedua aplikasi.

Fork terlihat hemat tapi biasanya lebih lama: mencabut prayer_service, learning_content, kompas kiblat, dan 43 medali meninggalkan sisa yang tersangkut berbulan-bulan. Package bersama berarti membuat abstraksi untuk dua aplikasi sebelum aplikasi kedua terbukti jalan, dan setiap perubahan akan menarik-narik aplikasi lama.

Yang berharga dari Muslim Leveling adalah pengetahuannya — struktur service, proguard rules, penanganan izin notifikasi — bukan baris kodenya.

---

### 15. Riwayat dibekukan, bukan dihitung ulang

**Dipilih:** XP disimpan per baris `logs` saat pencatatan. Status hari sempurna dan Skor Keseimbangan disimpan per baris `hari` saat pemrosesan hari.

**Ditolak:** menghitung semuanya dari `logs` mentah setiap kali dibutuhkan.

Menghitung ulang terlihat lebih bersih — satu sumber data, tanpa nilai turunan yang bisa basi. Tapi rancangan ini punya dua hal yang boleh berubah kapan saja: target habit dan daftar habit aktif. Begitu keduanya dipakai untuk menilai ulang masa lalu, hasilnya:

- User menaikkan target langkah dari 5.000 ke 8.000, lalu seluruh riwayatnya dinilai ulang dengan target baru. XP masa lalu menyusut dan **level bisa turun** — sebagai hukuman karena menantang diri sendiri.
- User mengaktifkan habit kesembilan, lalu hari-hari sempurna bulan lalu berhenti dianggap sempurna, karena syaratnya "semua habit aktif selesai" dan sekarang ada habit yang belum ada waktu itu.

Keduanya membatalkan medali yang sudah terbuka dan melanggar janji "XP tidak pernah berkurang". Nilai turunan yang dibekukan adalah harga yang jauh lebih murah.

Efek sampingnya justru benar: mengubah target hanya berlaku untuk hari-hari berikutnya.

---

### 16. Isi kartu penjelasan hidup di Dart

**Dipilih:** `lib/data/habit_info.dart` sebagai satu-satunya tempat isi kartu penjelasan.

**Ditolak:** menulisnya juga sebagai markdown di `docs/`.

Konten yang ditulis di dua tempat akan berbeda dalam sebulan, dan tidak ada yang tahu mana yang benar.
