# Aturan Kerja — Habit Leveling

Dokumen ini untuk siapa pun yang melanjutkan proyek ini, terutama asisten AI yang baru masuk tanpa konteks percakapan sebelumnya.

## Urutan baca wajib

Sebelum menulis kode atau mengusulkan perubahan apa pun:

1. `docs/PRD.md` — apa yang dibangun dan untuk siapa
2. `docs/design.md` — bagaimana cara kerjanya (satu-satunya sumber kebenaran teknis)
3. `docs/decisions.md` — kenapa dirancang begitu, dan apa yang **sudah ditolak beserta alasannya**
4. `docs/plan.md` — langkah implementasi dan progres saat ini

Nomor 3 penting. Banyak hal yang terlihat seperti "kekurangan" di aplikasi ini sebenarnya keputusan sadar yang sudah ditimbang. Sebelum mengusulkan sesuatu yang terasa jelas kurang — sinkronisasi cloud, integrasi Health Connect, fitur sosial — periksa dulu apakah sudah tercatat sebagai keputusan yang ditolak.

## Istilah

| Istilah | Arti |
|---------|------|
| **Pilar** | Salah satu dari empat kategori: Gerak, Makan, Tidur, Pikiran. Tiap pilar punya XP dan level sendiri. |
| **Habit** | Satu kebiasaan yang dicatat harian. Milik tepat satu pilar. |
| **Preset** | 16 habit bawaan aplikasi. Terkalibrasi dan tidak bisa dihapus, hanya dinonaktifkan. |
| **Habit custom** | Habit buatan user. Maksimal 5. |
| **Aktif** | Habit yang dipilih user untuk dikerjakan. Hanya habit aktif yang muncul di beranda dan masuk perhitungan. Maksimal 8. |
| **Quest** | Tiga habit fokus yang dipilih sistem setiap hari. Menyelesaikan ketiganya memberi bonus XP dan menaikkan streak. |
| **Streak** | Jumlah hari beruntun quest harian diselesaikan. |
| **Jeda** | Token yang otomatis menutup satu hari kosong agar streak tidak putus. Maksimal 3 tersimpan. |
| **Skor Keseimbangan** | Level pilar terendah dibagi level pilar tertinggi, dalam persen. Hanya ditampilkan, tidak memengaruhi XP. |

## Konvensi kode

- Bahasa antarmuka: **Indonesia**. Nama variabel, fungsi, dan kelas: **Inggris**. Komentar boleh Indonesia.
- Kunci habit (`habit.key`) memakai snake_case Indonesia dan **tidak boleh diubah** setelah rilis — kunci itu tersimpan di database pengguna.
- `lib/logic/` hanya berisi fungsi murni. Dilarang menyentuh database, `DateTime.now()`, atau `SharedPreferences` di dalamnya. Tanggal selalu dioper sebagai argumen. Ini yang membuat aturan XP, streak, dan quest bisa diuji tanpa emulator.
- State memakai `ValueNotifier` di dalam service. Jangan menambahkan Riverpod, Bloc, atau GetX.
- `flutter analyze` harus bersih. Import yang tidak terpakai saja membuat CI gagal.
- Sebelum menambah dependensi baru: cek apakah pustaka standar Dart/Flutter sudah cukup. Daftar dependensi yang disetujui ada di `docs/design.md`.

## Alur git

- **Jangan push langsung ke `main`.** Selalu buat feature branch, lalu Pull Request.
- Pesan commit: conventional commits, bahasa Indonesia. Contoh: `feat: tambah pemilihan quest harian`, `fix: acuan pedometer setelah restart`.
- Selalu `git fetch` dan `git pull` sebelum mulai bekerja. Pemilik repo sering commit langsung di antara sesi.
- Rilis lewat tag GitHub. Tidak ada CHANGELOG.md.

## Jebakan yang sudah diketahui

Diwarisi dari proyek Muslim Leveling. Ketiganya nyata dan sudah pernah memakan waktu berhari-hari:

1. **R8 merusak Gson di release build.** Tanpa keep rules Gson di `android/app/proguard-rules.pro`, seluruh jalur persistensi `flutter_local_notifications` (`zonedSchedule`, `cancelAll`, `pendingNotificationRequests`) melempar `Missing type parameter`. Gejalanya **tidak muncul di debug build**. Keep rules harus ada sejak commit pertama yang menambahkan notifikasi.
2. **Notifikasi terjadwal butuh dua izin terpisah** di Android modern: exact alarm dan pengecualian optimasi baterai. Tanpa keduanya, notifikasi diam tanpa error.
3. **Sensor langkah dihitung sejak perangkat menyala**, bukan sejak tengah malam. Restart perangkat mengembalikan hitungan ke nol. Aplikasi harus menyimpan nilai acuan harian dan mendeteksi ketika nilai baru lebih kecil dari acuan.

## Yang tidak boleh dilakukan tanpa persetujuan pemilik

- Menambahkan dependensi di luar daftar yang disetujui
- Menambahkan izin Android baru
- Mengubah rumus XP, level, atau streak
- Mengubah `habit.key` yang sudah ada
- Menambahkan jaringan, telemetri, analitik, atau iklan dalam bentuk apa pun
