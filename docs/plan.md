# Rencana Implementasi — Habit Leveling

> **Untuk pekerja agentik:** SUB-SKILL WAJIB: pakai superpowers:subagent-driven-development (disarankan) atau superpowers:executing-plans untuk mengerjakan rencana ini tugas demi tugas. Langkah memakai sintaks checkbox (`- [ ]`) untuk pelacakan.

**Goal:** Membangun aplikasi Android Flutter offline untuk mencatat kebiasaan sehat lintas empat pilar, dengan XP, level, streak berjatah jeda, quest harian, dan 30 medali.

**Architecture:** Seluruh aturan permainan hidup sebagai fungsi murni di `lib/logic/` — tanpa database, tanpa `DateTime.now()`, tanggal selalu dioper sebagai argumen — sehingga bisa diuji tanpa emulator. Di atasnya, `lib/db/database.dart` memegang sqflite dan seluruh kueri, dan `lib/services/` membungkusnya dengan `ValueNotifier` untuk UI. Riwayat dipotret di momen kejadian dan tidak pernah dinilai ulang dengan pengaturan yang berlaku sekarang.

**Tech Stack:** Flutter (stable), Dart, sqflite, flutter_local_notifications, timezone, permission_handler, pedometer, fl_chart, share_plus, file_picker, path_provider, flutter_lints.

## Global Constraints

Berlaku untuk **setiap** tugas di bawah ini.

- Baca `docs/design.md` dan `docs/decisions.md` sebelum menulis kode. Bila rencana ini bertentangan dengan `docs/design.md`, `docs/design.md` yang menang — dan laporkan pertentangannya.
- Bahasa antarmuka **Indonesia**. Komentar boleh Indonesia. Penamaan kode: istilah domain Indonesia (`Pilar`, `jeda`, `xpDasar`, `hitungXp`), selebihnya Inggris. Lihat `AGENTS.md`.
- `lib/logic/` hanya berisi fungsi murni. Dilarang menyentuh database, `DateTime.now()`, atau `SharedPreferences` di dalamnya.
- **Riwayat dipotret di momen kejadian.** XP dibekukan di `logs.xp` saat pencatatan. `quest_ids` dan `aktif_ids` dibekukan di baris `hari` saat hari itu dimulai. Pertanyaan "habit ini selesai atau belum" **selalu** dijawab `logs.xp == xp_dasar`, tidak pernah `nilai >= target`.
- Kunci habit (`habit.key`) tidak boleh diubah setelah rilis.
- Dilarang menambah dependensi di luar Tech Stack di atas tanpa persetujuan pemilik repo.
- `flutter analyze` harus bersih. Import tidak terpakai saja membuat CI gagal.
- Target minimum Android **API 26**. Aplikasi Android saja.
- Dilarang menambahkan jaringan, telemetri, analitik, atau iklan dalam bentuk apa pun.
- Jangan push langsung ke `main`. Feature branch lalu Pull Request. Pesan commit conventional commits bahasa Indonesia.
- Unit test hanya untuk `lib/logic/`. Tidak ada widget test dan tidak ada integration test. Tugas UI diverifikasi dengan menjalankan aplikasi.

---

## Struktur File

| File | Tanggung jawab |
|------|----------------|
| `lib/data/habit.dart` | Model `Habit`, enum `Pilar`, enum `TipeHabit` |
| `lib/data/habit_preset.dart` | 16 preset sebagai konstanta |
| `lib/data/habit_info.dart` | Isi kartu penjelasan, satu entri per preset |
| `lib/data/achievement_preset.dart` | 30 definisi medali |
| `lib/logic/xp.dart` | XP per habit, ambang level, skor keseimbangan, bonus quest |
| `lib/logic/streak.dart` | Streak, jeda, pemrosesan rentang hari |
| `lib/logic/quest.dart` | Pemilihan tiga habit fokus |
| `lib/logic/achievement.dart` | Evaluasi syarat medali |
| `lib/db/database.dart` | sqflite, skema, migrasi, seluruh kueri |
| `lib/services/habit_service.dart` | `ValueNotifier`, orkestrasi baca/tulis, pemrosesan hari |
| `lib/services/step_service.dart` | Pedometer, acuan langkah harian |
| `lib/services/notification_service.dart` | Dua jadwal notifikasi, izin |
| `lib/services/backup_service.dart` | Ekspor dan impor JSON |
| `lib/screens/onboarding/` | Alur pertama kali |
| `lib/screens/beranda/` | Quest hari ini, daftar habit, level global |
| `lib/screens/statistik/` | Radar, grafik mingguan, keberhasilan 30 hari |
| `lib/screens/medali/` | Grid medali |
| `lib/screens/pengaturan/` | Kelola habit, custom habit, notifikasi, backup |
| `lib/widgets/` | Widget bersama (kartu habit, popup medali, bar XP) |

`lib/data/habit.dart` adalah tambahan atas daftar folder di `docs/design.md` — modelnya butuh rumah sendiri karena dipakai oleh `logic/`, `db/`, dan `screens/`.

---

### Task 1: Scaffold proyek, lints, proguard, CI

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `android/app/proguard-rules.pro`, `.github/workflows/flutter.yml`
- Modify: `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: tidak ada
- Produces: proyek Flutter yang bisa dibangun, dengan `flutter analyze` bersih dan proguard sudah benar sejak awal

- [ ] **Step 1: Buat proyek Flutter**

```bash
cd "C:/Users/Administrator/Documents"
flutter create --org com.criss10x --project-name habit_leveling --platforms android "Habit Leveling"
```

Perintah ini menulis ke folder yang sudah berisi `docs/` dan `.git` — itu disengaja dan aman, `flutter create` tidak menghapus file yang sudah ada.

- [ ] **Step 2: Kunci dependensi di `pubspec.yaml`**

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.9.0
  flutter_local_notifications: ^22.2.0
  timezone: ^0.11.1
  permission_handler: ^13.0.0
  pedometer: ^4.0.1
  fl_chart: ^1.2.0
  share_plus: ^12.0.2
  path_provider: ^2.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

- [ ] **Step 3: Pasang proguard rules sebelum ada notifikasi**

Ini bug R8/Gson dari Muslim Leveling. Dipasang sekarang supaya tidak pernah terjadi.

Buat `android/app/proguard-rules.pro`:

```proguard
# Gson — R8 full mode merusak TypeToken generic signature.
# Tanpa ini, seluruh jalur persistensi flutter_local_notifications
# melempar "Missing type parameter" di release build saja.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# flutter_local_notifications
-keep class com.dexterous.** { *; }
```

Di `android/app/build.gradle`, pada `buildTypes.release`:

```gradle
release {
    signingConfig signingConfigs.debug
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```

- [ ] **Step 4: Set minSdk dan izin**

Di `android/app/build.gradle`, `defaultConfig`: `minSdkVersion 26`.

Aktifkan juga core library desugaring. `flutter_local_notifications` menolak dibangun tanpanya, dan kegagalannya baru muncul saat `assembleRelease` — bukan saat `pub get` maupun `flutter analyze`:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

Di `android/app/src/main/AndroidManifest.xml`, di dalam `<manifest>` sebelum `<application>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

- [ ] **Step 5: Aktifkan lints**

`analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_final_locals: true
```

- [ ] **Step 6: Buat workflow CI**

`.github/workflows/flutter.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

- [ ] **Step 7: Verifikasi**

```bash
flutter pub get && flutter analyze && flutter build apk --release
```

Diharapkan: `No issues found!` dan APK release berhasil dibangun.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: scaffold proyek Flutter dengan proguard dan CI"
```

---

### Task 2: Model habit dan aturan XP

**Files:**
- Create: `lib/data/habit.dart`, `lib/logic/xp.dart`
- Test: `test/logic/xp_test.dart`

**Interfaces:**
- Consumes: tidak ada
- Produces:
  - `enum Pilar { gerak, makan, tidur, pikiran }`
  - `enum TipeHabit { hitung, waktu }`
  - `class Habit` dengan field `int? id, String key, String nama, Pilar pilar, TipeHabit tipe, int target, String satuan, int xpDasar, String sumber, bool aktif, bool isCustom`
  - `int nilaiEfektifWaktu(int nilai, int ambang)`
  - `bool tercapaiWaktu(int nilai, int ambang)`
  - `int hitungXp({required TipeHabit tipe, required int nilai, required int target, required int xpDasar})`
  - `int xpUntukLevel(int level)` / `int xpUntukLevelGlobal(int level)`
  - `int levelDariXp(int xp)` / `int levelGlobalDariXp(int xp)`
  - `int skorKeseimbangan(List<int> levelPilar)`
  - `int bonusPerPilar(int jumlahPilar)`

- [ ] **Step 1: Tulis test yang gagal**

`test/logic/xp_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/data/habit.dart';
import 'package:habit_leveling/logic/xp.dart';

void main() {
  group('hitungXp tipe hitung', () {
    test('target tercapai penuh memberi xp dasar', () {
      expect(
        hitungXp(tipe: TipeHabit.hitung, nilai: 8, target: 8, xpDasar: 10),
        10,
      );
    });

    test('setengah jalan memberi xp proporsional', () {
      expect(
        hitungXp(tipe: TipeHabit.hitung, nilai: 6, target: 8, xpDasar: 10),
        8, // round(10 * 0.75) = 8 (round half to even tidak berlaku, 7.5 -> 8)
      );
    });

    test('melebihi target tidak memberi xp lebih', () {
      expect(
        hitungXp(tipe: TipeHabit.hitung, nilai: 20, target: 8, xpDasar: 10),
        10,
      );
    });

    test('nilai nol memberi nol', () {
      expect(
        hitungXp(tipe: TipeHabit.hitung, nilai: 0, target: 8, xpDasar: 10),
        0,
      );
    });

    test('target nol tidak membelah nol', () {
      expect(
        hitungXp(tipe: TipeHabit.hitung, nilai: 5, target: 0, xpDasar: 10),
        10,
      );
    });
  });

  group('tipe waktu dan pergeseran tengah malam', () {
    // ambang 23:00 = 1380 menit
    test('tidur 22:30 berhasil', () {
      expect(tercapaiWaktu(22 * 60 + 30, 1380), isTrue);
    });

    test('tidur 00:30 gagal, bukan berhasil', () {
      expect(tercapaiWaktu(30, 1380), isFalse);
    });

    test('tidur 10:00 dianggap dini hari dan gagal', () {
      expect(tercapaiWaktu(600, 1380), isFalse);
    });

    test('tidur 11:30 di luar jendela geser, dihitung apa adanya', () {
      expect(tercapaiWaktu(690, 1380), isTrue);
    });

    // ambang 06:00 = 360 menit, tidak pernah bergeser
    test('bangun 05:00 berhasil', () {
      expect(tercapaiWaktu(300, 360), isTrue);
    });

    test('bangun 23:00 gagal', () {
      expect(tercapaiWaktu(1380, 360), isFalse);
    });

    test('xp tipe waktu bersifat semua atau tidak sama sekali', () {
      expect(
        hitungXp(tipe: TipeHabit.waktu, nilai: 1350, target: 1380, xpDasar: 15),
        15,
      );
      expect(
        hitungXp(tipe: TipeHabit.waktu, nilai: 30, target: 1380, xpDasar: 15),
        0,
      );
    });
  });

  group('ambang level', () {
    test('level pilar di titik batas', () {
      expect(xpUntukLevel(1), 0);
      expect(xpUntukLevel(2), 100);
      expect(xpUntukLevel(3), 300);
      expect(xpUntukLevel(4), 600);
    });

    test('levelDariXp adalah kebalikan yang benar di titik batas', () {
      expect(levelDariXp(0), 1);
      expect(levelDariXp(99), 1);
      expect(levelDariXp(100), 2);
      expect(levelDariXp(299), 2);
      expect(levelDariXp(300), 3);
      expect(levelDariXp(599), 3);
      expect(levelDariXp(600), 4);
    });

    test('level global memakai ambang empat kali lipat', () {
      expect(xpUntukLevelGlobal(2), 400);
      expect(levelGlobalDariXp(399), 1);
      expect(levelGlobalDariXp(400), 2);
      expect(levelGlobalDariXp(1200), 3);
    });

    test('level tetap benar untuk xp besar', () {
      expect(levelDariXp(xpUntukLevel(50)), 50);
      expect(levelDariXp(xpUntukLevel(50) - 1), 49);
      expect(levelGlobalDariXp(xpUntukLevelGlobal(80)), 80);
    });
  });

  group('skor keseimbangan', () {
    test('user baru mendapat seratus', () {
      expect(skorKeseimbangan([1, 1, 1, 1]), 100);
    });

    test('timpang menurunkan skor', () {
      expect(skorKeseimbangan([20, 10, 5, 5]), 25);
    });
  });

  group('bonus quest', () {
    test('24 terbagi habis untuk satu sampai empat pilar', () {
      expect(bonusPerPilar(1), 24);
      expect(bonusPerPilar(2), 12);
      expect(bonusPerPilar(3), 8);
      expect(bonusPerPilar(4), 6);
    });
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

```bash
flutter test test/logic/xp_test.dart
```

Diharapkan: GAGAL dengan error kompilasi, `habit.dart` dan `xp.dart` belum ada.

- [ ] **Step 3: Tulis model**

`lib/data/habit.dart`:

```dart
enum Pilar { gerak, makan, tidur, pikiran }

enum TipeHabit { hitung, waktu }

class Habit {
  const Habit({
    this.id,
    required this.key,
    required this.nama,
    required this.pilar,
    required this.tipe,
    required this.target,
    required this.satuan,
    required this.xpDasar,
    this.sumber = 'manual',
    this.aktif = false,
    this.isCustom = false,
  });

  final int? id;
  final String key;
  final String nama;
  final Pilar pilar;
  final TipeHabit tipe;

  /// Target untuk tipe hitung, atau ambang dalam menit untuk tipe waktu.
  final int target;
  final String satuan;
  final int xpDasar;
  final String sumber;
  final bool aktif;
  final bool isCustom;

  Habit salin({int? id, int? target, bool? aktif}) => Habit(
        id: id ?? this.id,
        key: key,
        nama: nama,
        pilar: pilar,
        tipe: tipe,
        target: target ?? this.target,
        satuan: satuan,
        xpDasar: xpDasar,
        sumber: sumber,
        aktif: aktif ?? this.aktif,
        isCustom: isCustom,
      );
}
```

- [ ] **Step 4: Tulis aturan XP**

`lib/logic/xp.dart`:

```dart
import 'dart:math';

import '../data/habit.dart';

/// Menggeser jam dini hari ke hari berikutnya, supaya "tidur sebelum jam 23"
/// tidak dianggap berhasil ketika user tidur jam 00:30.
int nilaiEfektifWaktu(int nilai, int ambang) =>
    nilai < ambang - 720 ? nilai + 1440 : nilai;

bool tercapaiWaktu(int nilai, int ambang) =>
    nilaiEfektifWaktu(nilai, ambang) < ambang;

int hitungXp({
  required TipeHabit tipe,
  required int nilai,
  required int target,
  required int xpDasar,
}) {
  if (tipe == TipeHabit.waktu) {
    return tercapaiWaktu(nilai, target) ? xpDasar : 0;
  }
  if (target <= 0) return xpDasar;
  final rasio = min(1.0, nilai / target);
  return (xpDasar * rasio).round();
}

int xpUntukLevel(int level) => 50 * level * (level - 1);

int xpUntukLevelGlobal(int level) => 200 * level * (level - 1);

int _level(int xp, int Function(int) ambang) {
  var level = 1;
  while (ambang(level + 1) <= xp) {
    level++;
  }
  return level;
}

int levelDariXp(int xp) => _level(xp, xpUntukLevel);

int levelGlobalDariXp(int xp) => _level(xp, xpUntukLevelGlobal);

int skorKeseimbangan(List<int> levelPilar) {
  final tertinggi = levelPilar.reduce(max);
  if (tertinggi <= 0) return 100;
  return (levelPilar.reduce(min) / tertinggi * 100).round();
}

const int bonusQuest = 24;

int bonusPerPilar(int jumlahPilar) =>
    jumlahPilar <= 0 ? 0 : bonusQuest ~/ jumlahPilar;
```

Perulangan `_level` sengaja dipakai alih-alih rumus akar kuadrat: aman dari kesalahan pembulatan floating point di titik batas, dan level tertinggi yang realistis masih di bawah seratus.

- [ ] **Step 5: Jalankan test untuk memastikan lulus**

```bash
flutter test test/logic/xp_test.dart
```

Diharapkan: seluruh test LULUS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/habit.dart lib/logic/xp.dart test/logic/xp_test.dart
git commit -m "feat: tambah model habit dan aturan XP"
```

---

### Task 3: Streak dan jeda

**Files:**
- Create: `lib/logic/streak.dart`
- Test: `test/logic/streak_test.dart`

**Interfaces:**
- Consumes: tidak ada
- Produces:
  - `class KeadaanStreak { final int streak; final int jeda; final bool pernahPutus; final bool pernahPakaiJeda; }`
  - `KeadaanStreak prosesSatuHari(KeadaanStreak awal, bool questSelesai)`
  - `class HasilProses { final KeadaanStreak keadaan; final List<String> tanggalDijeda; }`
  - `HasilProses prosesRentang(KeadaanStreak awal, List<String> tanggalUrut, bool Function(String) questSelesai)`
  - `const int maksJeda = 3;`

- [ ] **Step 1: Tulis test yang gagal**

`test/logic/streak_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/logic/streak.dart';

const kosong = KeadaanStreak(streak: 0, jeda: 0);

void main() {
  group('satu hari', () {
    test('quest selesai menaikkan streak', () {
      final hasil = prosesSatuHari(kosong, true);
      expect(hasil.streak, 1);
      expect(hasil.jeda, 0);
    });

    test('hari ketujuh memberi satu jeda', () {
      final hasil = prosesSatuHari(
        const KeadaanStreak(streak: 6, jeda: 0),
        true,
      );
      expect(hasil.streak, 7);
      expect(hasil.jeda, 1);
    });

    test('jeda tidak melebihi tiga', () {
      final hasil = prosesSatuHari(
        const KeadaanStreak(streak: 27, jeda: 3),
        true,
      );
      expect(hasil.streak, 28);
      expect(hasil.jeda, 3);
    });

    test('hari kosong memakai jeda dan menahan streak', () {
      final hasil = prosesSatuHari(
        const KeadaanStreak(streak: 10, jeda: 2),
        false,
      );
      expect(hasil.streak, 10);
      expect(hasil.jeda, 1);
      expect(hasil.pernahPakaiJeda, isTrue);
      expect(hasil.pernahPutus, isFalse);
    });

    test('hari kosong tanpa jeda mereset streak', () {
      final hasil = prosesSatuHari(
        const KeadaanStreak(streak: 10, jeda: 0),
        false,
      );
      expect(hasil.streak, 0);
      expect(hasil.pernahPutus, isTrue);
    });

    test('hari kosong saat streak nol tidak menandai pernah putus', () {
      final hasil = prosesSatuHari(kosong, false);
      expect(hasil.streak, 0);
      expect(hasil.pernahPutus, isFalse);
    });
  });

  group('rentang panjang', () {
    test('tiga jeda menutup tiga hari kosong berturut-turut', () {
      final tanggal = ['2026-08-01', '2026-08-02', '2026-08-03'];
      final hasil = prosesRentang(
        const KeadaanStreak(streak: 21, jeda: 3),
        tanggal,
        (_) => false,
      );
      expect(hasil.keadaan.streak, 21);
      expect(hasil.keadaan.jeda, 0);
      expect(hasil.tanggalDijeda, tanggal);
      expect(hasil.keadaan.pernahPutus, isFalse);
    });

    test('jeda habis di tengah celah lalu streak jatuh', () {
      final tanggal = [
        '2026-08-01',
        '2026-08-02',
        '2026-08-03',
        '2026-08-04',
      ];
      final hasil = prosesRentang(
        const KeadaanStreak(streak: 21, jeda: 2),
        tanggal,
        (_) => false,
      );
      expect(hasil.keadaan.streak, 0);
      expect(hasil.keadaan.jeda, 0);
      expect(hasil.tanggalDijeda, ['2026-08-01', '2026-08-02']);
      expect(hasil.keadaan.pernahPutus, isTrue);
    });

    test('celah tiga puluh hari tanpa jeda berakhir nol', () {
      final tanggal = List.generate(
        30,
        (i) => '2026-09-${(i + 1).toString().padLeft(2, '0')}',
      );
      final hasil = prosesRentang(kosong, tanggal, (_) => false);
      expect(hasil.keadaan.streak, 0);
      expect(hasil.tanggalDijeda, isEmpty);
    });

    test('empat belas hari penuh memberi dua jeda', () {
      final tanggal = List.generate(
        14,
        (i) => '2026-10-${(i + 1).toString().padLeft(2, '0')}',
      );
      final hasil = prosesRentang(kosong, tanggal, (_) => true);
      expect(hasil.keadaan.streak, 14);
      expect(hasil.keadaan.jeda, 2);
    });
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

```bash
flutter test test/logic/streak_test.dart
```

Diharapkan: GAGAL, `streak.dart` belum ada.

- [ ] **Step 3: Tulis implementasi**

`lib/logic/streak.dart`:

```dart
const int maksJeda = 3;

class KeadaanStreak {
  const KeadaanStreak({
    required this.streak,
    required this.jeda,
    this.pernahPutus = false,
    this.pernahPakaiJeda = false,
  });

  final int streak;
  final int jeda;
  final bool pernahPutus;
  final bool pernahPakaiJeda;
}

class HasilProses {
  const HasilProses(this.keadaan, this.tanggalDijeda);

  final KeadaanStreak keadaan;
  final List<String> tanggalDijeda;
}

KeadaanStreak prosesSatuHari(KeadaanStreak awal, bool questSelesai) {
  if (questSelesai) {
    final streak = awal.streak + 1;
    final dapatJeda = streak % 7 == 0 && awal.jeda < maksJeda;
    return KeadaanStreak(
      streak: streak,
      jeda: dapatJeda ? awal.jeda + 1 : awal.jeda,
      pernahPutus: awal.pernahPutus,
      pernahPakaiJeda: awal.pernahPakaiJeda,
    );
  }
  if (awal.jeda > 0) {
    return KeadaanStreak(
      streak: awal.streak,
      jeda: awal.jeda - 1,
      pernahPutus: awal.pernahPutus,
      pernahPakaiJeda: true,
    );
  }
  return KeadaanStreak(
    streak: 0,
    jeda: 0,
    // Streak yang memang belum pernah jalan tidak dihitung "putus".
    pernahPutus: awal.pernahPutus || awal.streak > 0,
    pernahPakaiJeda: awal.pernahPakaiJeda,
  );
}

HasilProses prosesRentang(
  KeadaanStreak awal,
  List<String> tanggalUrut,
  bool Function(String tanggal) questSelesai,
) {
  var keadaan = awal;
  final dijeda = <String>[];
  for (final tanggal in tanggalUrut) {
    final selesai = questSelesai(tanggal);
    final sebelum = keadaan;
    keadaan = prosesSatuHari(keadaan, selesai);
    if (!selesai && sebelum.jeda > 0) {
      dijeda.add(tanggal);
    }
  }
  return HasilProses(keadaan, dijeda);
}
```

- [ ] **Step 4: Jalankan test untuk memastikan lulus**

```bash
flutter test test/logic/streak_test.dart
```

Diharapkan: seluruh test LULUS.

- [ ] **Step 5: Commit**

```bash
git add lib/logic/streak.dart test/logic/streak_test.dart
git commit -m "feat: tambah aturan streak dan jatah jeda"
```

---

### Task 4: Pemilihan quest harian

**Files:**
- Create: `lib/logic/quest.dart`
- Test: `test/logic/quest_test.dart`

**Interfaces:**
- Consumes: `Pilar` dari `lib/data/habit.dart`
- Produces:
  - `class KandidatQuest { final int habitId; final Pilar pilar; final int levelPilar; final int selesai7Hari; }`
  - `List<int> pilihQuest(List<KandidatQuest> kandidat, String tanggal)`

- [ ] **Step 1: Tulis test yang gagal**

`test/logic/quest_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/data/habit.dart';
import 'package:habit_leveling/logic/quest.dart';

KandidatQuest k(int id, Pilar pilar, int level, int selesai) =>
    KandidatQuest(
      habitId: id,
      pilar: pilar,
      levelPilar: level,
      selesai7Hari: selesai,
    );

void main() {
  test('mengambil tiga habit dari pilar dengan level terendah', () {
    final kandidat = [
      k(1, Pilar.gerak, 20, 7),
      k(2, Pilar.gerak, 20, 7),
      k(3, Pilar.tidur, 2, 0),
      k(4, Pilar.tidur, 2, 1),
      k(5, Pilar.makan, 5, 3),
    ];
    final hasil = pilihQuest(kandidat, '2026-08-01');
    expect(hasil, containsAll([3, 4]));
    expect(hasil.length, 3);
    expect(hasil, isNot(contains(1)));
  });

  test('pada level sama, habit yang paling jarang selesai didahulukan', () {
    final kandidat = [
      k(1, Pilar.gerak, 5, 7),
      k(2, Pilar.gerak, 5, 1),
      k(3, Pilar.gerak, 5, 4),
      k(4, Pilar.gerak, 5, 6),
    ];
    expect(pilihQuest(kandidat, '2026-08-01'), [2, 3, 4]);
  });

  test('hasilnya sama untuk tanggal yang sama', () {
    final kandidat = List.generate(
      8,
      (i) => k(i + 1, Pilar.gerak, 5, 3),
    );
    final pertama = pilihQuest(kandidat, '2026-08-01');
    final kedua = pilihQuest(kandidat, '2026-08-01');
    expect(pertama, kedua);
  });

  test('hasilnya berbeda antar tanggal ketika semua seri', () {
    final kandidat = List.generate(
      8,
      (i) => k(i + 1, Pilar.gerak, 5, 3),
    );
    final hasil = <String>{};
    for (var hari = 1; hari <= 20; hari++) {
      final tanggal = '2026-08-${hari.toString().padLeft(2, '0')}';
      hasil.add(pilihQuest(kandidat, tanggal).join(','));
    }
    expect(hasil.length, greaterThan(1));
  });

  test('kandidat kurang dari tiga dipakai seluruhnya', () {
    final kandidat = [k(1, Pilar.gerak, 5, 3), k(2, Pilar.makan, 5, 3)];
    expect(pilihQuest(kandidat, '2026-08-01').length, 2);
  });

  test('tanpa kandidat menghasilkan daftar kosong', () {
    expect(pilihQuest([], '2026-08-01'), isEmpty);
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

```bash
flutter test test/logic/quest_test.dart
```

Diharapkan: GAGAL, `quest.dart` belum ada.

- [ ] **Step 3: Tulis implementasi**

`lib/logic/quest.dart`:

```dart
import '../data/habit.dart';

class KandidatQuest {
  const KandidatQuest({
    required this.habitId,
    required this.pilar,
    required this.levelPilar,
    required this.selesai7Hari,
  });

  final int habitId;
  final Pilar pilar;
  final int levelPilar;

  /// Berapa hari dari tujuh hari terakhir habit ini selesai.
  final int selesai7Hari;
}

/// Hash deterministik yang stabil antar proses. `String.hashCode` bawaan Dart
/// tidak dijamin sama antar eksekusi, dan quest harus terkunci oleh tanggal.
///
/// Tahap avalanche di bawah wajib ada. Tanpa itu, seluruh kandidat pada satu
/// tanggal hanya bergeser oleh konstanta yang sama sehingga urutan seed jatuh
/// kembali menjadi urutan habitId, dan tanggal tidak berpengaruh sama sekali.
int _seed(String tanggal, int habitId) {
  var h = 17;
  for (final c in tanggal.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  var x = (h * 31 + habitId) & 0xffffffff;
  x ^= x >> 16;
  x = (x * 0x85ebca6b) & 0xffffffff;
  x ^= x >> 13;
  x = (x * 0xc2b2ae35) & 0xffffffff;
  x ^= x >> 16;
  return x;
}

List<int> pilihQuest(List<KandidatQuest> kandidat, String tanggal) {
  final urut = [...kandidat]..sort((a, b) {
      final level = a.levelPilar.compareTo(b.levelPilar);
      if (level != 0) return level;
      final jarang = a.selesai7Hari.compareTo(b.selesai7Hari);
      if (jarang != 0) return jarang;
      return _seed(tanggal, a.habitId).compareTo(_seed(tanggal, b.habitId));
    });
  return urut.take(3).map((k) => k.habitId).toList();
}
```

- [ ] **Step 4: Jalankan test untuk memastikan lulus**

```bash
flutter test test/logic/quest_test.dart
```

Diharapkan: seluruh test LULUS.

- [ ] **Step 5: Commit**

```bash
git add lib/logic/quest.dart test/logic/quest_test.dart
git commit -m "feat: tambah pemilihan quest harian yang deterministik"
```

---

### Task 5: Definisi dan evaluasi medali

**Files:**
- Create: `lib/data/achievement_preset.dart`, `lib/logic/achievement.dart`
- Test: `test/logic/achievement_test.dart`

**Interfaces:**
- Consumes: `Pilar`
- Produces:
  - `class Medali { final String key; final String nama; final String syarat; final bool Function(RingkasanKeadaan) tercapai; }`
  - `final List<Medali> medaliPreset` berisi 30 entri — `final`, bukan `const`, karena tiap medali memegang closure `tercapai`
  - `class RingkasanKeadaan` dengan field `Map<Pilar,int> levelPilar, int levelGlobal, int streak, int skorKeseimbangan, Map<String,int> akumulasi, int hariSempurna, bool pernahPutus, bool pernahPakaiJeda`
  - `List<Medali> medaliBaru(RingkasanKeadaan keadaan, Set<String> sudahTerbuka)`

- [ ] **Step 1: Tulis test yang gagal**

`test/logic/achievement_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/data/achievement_preset.dart';
import 'package:habit_leveling/data/habit.dart';
import 'package:habit_leveling/logic/achievement.dart';

RingkasanKeadaan ringkasan({
  int gerak = 1,
  int makan = 1,
  int tidur = 1,
  int pikiran = 1,
  int global = 1,
  int streak = 0,
  int skor = 100,
  Map<String, int> akumulasi = const {},
  int hariSempurna = 0,
  bool pernahPutus = false,
  bool pernahPakaiJeda = false,
}) =>
    RingkasanKeadaan(
      levelPilar: {
        Pilar.gerak: gerak,
        Pilar.makan: makan,
        Pilar.tidur: tidur,
        Pilar.pikiran: pikiran,
      },
      levelGlobal: global,
      streak: streak,
      skorKeseimbangan: skor,
      akumulasi: akumulasi,
      hariSempurna: hariSempurna,
      pernahPutus: pernahPutus,
      pernahPakaiJeda: pernahPakaiJeda,
    );

void main() {
  test('ada tepat tiga puluh medali dengan kunci unik', () {
    expect(medaliPreset.length, 30);
    expect(medaliPreset.map((m) => m.key).toSet().length, 30);
  });

  test('medali streak terbuka tepat di ambangnya', () {
    final kunci = medaliBaru(ringkasan(streak: 6), {}).map((m) => m.key);
    expect(kunci, isNot(contains('streak_7')));

    final kunci7 = medaliBaru(ringkasan(streak: 7), {}).map((m) => m.key);
    expect(kunci7, contains('streak_7'));
  });

  test('medali yang sudah terbuka tidak dilaporkan lagi', () {
    final hasil = medaliBaru(ringkasan(streak: 7), {'streak_7'});
    expect(hasil.map((m) => m.key), isNot(contains('streak_7')));
  });

  test('medali level pilar hanya melihat pilarnya sendiri', () {
    final kunci = medaliBaru(ringkasan(gerak: 5), {}).map((m) => m.key);
    expect(kunci, contains('level_gerak_5'));
    expect(kunci, isNot(contains('level_tidur_5')));
  });

  test('medali keseimbangan butuh keempat pilar', () {
    final belum = medaliBaru(
      ringkasan(gerak: 5, makan: 5, tidur: 5, pikiran: 4),
      {},
    ).map((m) => m.key);
    expect(belum, isNot(contains('seimbang_5')));

    final sudah = medaliBaru(
      ringkasan(gerak: 5, makan: 5, tidur: 5, pikiran: 5),
      {},
    ).map((m) => m.key);
    expect(sudah, contains('seimbang_5'));
  });

  test('medali akumulasi memakai satuan habitnya', () {
    final kunci = medaliBaru(
      ringkasan(akumulasi: {'langkah_harian': 500000}),
      {},
    ).map((m) => m.key);
    expect(kunci, contains('akumulasi_langkah'));
  });

  test('medali bangkit butuh streak tujuh setelah pernah putus', () {
    final tanpaPutus =
        medaliBaru(ringkasan(streak: 7), {}).map((m) => m.key);
    expect(tanpaPutus, isNot(contains('bangkit')));

    final setelahPutus = medaliBaru(
      ringkasan(streak: 7, pernahPutus: true),
      {},
    ).map((m) => m.key);
    expect(setelahPutus, contains('bangkit'));
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

```bash
flutter test test/logic/achievement_test.dart
```

Diharapkan: GAGAL, kedua file belum ada.

- [ ] **Step 3: Tulis ringkasan keadaan dan evaluator**

`lib/logic/achievement.dart`:

```dart
import '../data/achievement_preset.dart';
import '../data/habit.dart';

class RingkasanKeadaan {
  const RingkasanKeadaan({
    required this.levelPilar,
    required this.levelGlobal,
    required this.streak,
    required this.skorKeseimbangan,
    required this.akumulasi,
    required this.hariSempurna,
    required this.pernahPutus,
    required this.pernahPakaiJeda,
  });

  final Map<Pilar, int> levelPilar;
  final int levelGlobal;
  final int streak;
  final int skorKeseimbangan;

  /// Total nilai sepanjang waktu per kunci habit preset.
  final Map<String, int> akumulasi;
  final int hariSempurna;
  final bool pernahPutus;
  final bool pernahPakaiJeda;

  int level(Pilar pilar) => levelPilar[pilar] ?? 1;

  int total(String key) => akumulasi[key] ?? 0;
}

List<Medali> medaliBaru(RingkasanKeadaan keadaan, Set<String> sudahTerbuka) =>
    medaliPreset
        .where((m) => !sudahTerbuka.contains(m.key) && m.tercapai(keadaan))
        .toList();
```

- [ ] **Step 4: Tulis tiga puluh definisi medali**

`lib/data/achievement_preset.dart`:

```dart
import '../logic/achievement.dart';
import 'habit.dart';

class Medali {
  const Medali({
    required this.key,
    required this.nama,
    required this.syarat,
    required this.tercapai,
  });

  final String key;
  final String nama;
  final String syarat;
  final bool Function(RingkasanKeadaan) tercapai;
}

Medali _streak(int hari, String nama) => Medali(
      key: 'streak_$hari',
      nama: nama,
      syarat: '$hari hari beruntun',
      tercapai: (k) => k.streak >= hari,
    );

Medali _levelPilar(Pilar pilar, String label, int level) => Medali(
      key: 'level_${pilar.name}_$level',
      nama: '$label Lv.$level',
      syarat: 'Pilar $label mencapai level $level',
      tercapai: (k) => k.level(pilar) >= level,
    );

const _labelPilar = {
  Pilar.gerak: 'Gerak',
  Pilar.makan: 'Makan',
  Pilar.tidur: 'Tidur',
  Pilar.pikiran: 'Pikiran',
};

final List<Medali> medaliPreset = [
  _streak(7, 'Seminggu Utuh'),
  _streak(30, 'Sebulan Utuh'),
  _streak(100, 'Seratus Hari'),
  _streak(365, 'Setahun Penuh'),

  for (final entri in _labelPilar.entries)
    for (final level in [5, 10, 25])
      _levelPilar(entri.key, entri.value, level),

  Medali(
    key: 'global_10',
    nama: 'Pendaki',
    syarat: 'Level global 10',
    tercapai: (k) => k.levelGlobal >= 10,
  ),
  Medali(
    key: 'global_25',
    nama: 'Penempuh',
    syarat: 'Level global 25',
    tercapai: (k) => k.levelGlobal >= 25,
  ),
  Medali(
    key: 'global_50',
    nama: 'Penguasa Kebiasaan',
    syarat: 'Level global 50',
    tercapai: (k) => k.levelGlobal >= 50,
  ),

  Medali(
    key: 'akumulasi_langkah',
    nama: 'Setengah Juta Langkah',
    syarat: 'Total 500.000 langkah',
    tercapai: (k) => k.total('langkah_harian') >= 500000,
  ),
  Medali(
    key: 'akumulasi_air',
    nama: 'Seribu Gelas',
    syarat: 'Total 1.000 gelas air',
    tercapai: (k) => k.total('minum_air') >= 1000,
  ),
  Medali(
    key: 'akumulasi_olahraga',
    nama: 'Seribu Menit',
    syarat: 'Total 1.000 menit olahraga',
    tercapai: (k) => k.total('olahraga') >= 1000,
  ),
  Medali(
    key: 'akumulasi_syukur',
    nama: 'Tiga Ratus Syukur',
    syarat: 'Total 300 hal dalam jurnal syukur',
    tercapai: (k) => k.total('jurnal_syukur') >= 300,
  ),

  Medali(
    key: 'seimbang_5',
    nama: 'Empat Kaki',
    syarat: 'Keempat pilar mencapai level 5',
    tercapai: (k) => k.levelPilar.values.every((l) => l >= 5),
  ),
  Medali(
    key: 'seimbang_10',
    nama: 'Empat Pilar Kokoh',
    syarat: 'Keempat pilar mencapai level 10',
    tercapai: (k) => k.levelPilar.values.every((l) => l >= 10),
  ),
  Medali(
    key: 'seimbang_skor',
    nama: 'Nyaris Rata',
    syarat: 'Skor Keseimbangan menyentuh 90%',
    tercapai: (k) => k.skorKeseimbangan >= 90,
  ),

  Medali(
    key: 'jeda_pertama',
    nama: 'Istirahat Itu Boleh',
    syarat: 'Memakai jeda untuk pertama kali',
    tercapai: (k) => k.pernahPakaiJeda,
  ),
  Medali(
    key: 'bangkit',
    nama: 'Bangkit Lagi',
    syarat: 'Kembali ke streak 7 setelah pernah putus',
    tercapai: (k) => k.pernahPutus && k.streak >= 7,
  ),

  Medali(
    key: 'sempurna_1',
    nama: 'Hari Sempurna',
    syarat: 'Seluruh habit aktif selesai dalam satu hari',
    tercapai: (k) => k.hariSempurna >= 1,
  ),
  Medali(
    key: 'sempurna_10',
    nama: 'Sepuluh Hari Sempurna',
    syarat: 'Sepuluh hari sempurna',
    tercapai: (k) => k.hariSempurna >= 10,
  ),
];
```

Hitungan: 4 streak + 12 level pilar + 3 level global + 4 akumulasi + 3 keseimbangan + 2 pemulihan + 2 konsistensi = 30.

- [ ] **Step 5: Jalankan test untuk memastikan lulus**

```bash
flutter test test/logic/achievement_test.dart
```

Diharapkan: seluruh test LULUS, termasuk yang memeriksa jumlah tepat 30.

- [ ] **Step 6: Commit**

```bash
git add lib/data/achievement_preset.dart lib/logic/achievement.dart test/logic/achievement_test.dart
git commit -m "feat: tambah 30 definisi medali dan evaluatornya"
```

---

### Task 6: Katalog 16 habit preset

**Files:**
- Create: `lib/data/habit_preset.dart`
- Test: `test/logic/preset_test.dart`

**Interfaces:**
- Consumes: `Habit`, `Pilar`, `TipeHabit`
- Produces:
  - `const List<Habit> habitPreset` berisi 16 entri
  - `const List<String> saranAwal` berisi 5 kunci
  - `const int maksHabitAktifDefault = 8;`
  - `const int maksHabitCustom = 5;`
  - `const int xpDasarCustom = 5;`

- [ ] **Step 1: Tulis test yang gagal**

`test/logic/preset_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/data/habit.dart';
import 'package:habit_leveling/data/habit_preset.dart';

void main() {
  test('ada 16 preset, empat per pilar, kunci unik', () {
    expect(habitPreset.length, 16);
    expect(habitPreset.map((h) => h.key).toSet().length, 16);
    for (final pilar in Pilar.values) {
      expect(
        habitPreset.where((h) => h.pilar == pilar).length,
        4,
        reason: 'pilar ${pilar.name} harus punya 4 habit',
      );
    }
  });

  test('setiap target minimal satu', () {
    for (final h in habitPreset) {
      expect(h.target, greaterThanOrEqualTo(1), reason: h.key);
    }
  });

  test('lima saran awal mencakup keempat pilar', () {
    expect(saranAwal.length, 5);
    final pilarSaran = habitPreset
        .where((h) => saranAwal.contains(h.key))
        .map((h) => h.pilar)
        .toSet();
    expect(pilarSaran.length, 4);
  });

  test('hanya langkah harian yang bersumber pedometer', () {
    final otomatis = habitPreset.where((h) => h.sumber == 'pedometer');
    expect(otomatis.map((h) => h.key), ['langkah_harian']);
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

```bash
flutter test test/logic/preset_test.dart
```

Diharapkan: GAGAL, `habit_preset.dart` belum ada.

- [ ] **Step 3: Tulis katalog**

`lib/data/habit_preset.dart`:

```dart
import 'habit.dart';

const int maksHabitAktifDefault = 8;
const int maksHabitCustom = 5;
const int xpDasarCustom = 5;

const List<String> saranAwal = [
  'langkah_harian',
  'minum_air',
  'isi_piringku',
  'tidur_sebelum_23',
  'napas_meditasi',
];

const List<Habit> habitPreset = [
  // Gerak
  Habit(
    key: 'langkah_harian',
    nama: 'Langkah harian',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 5000,
    satuan: 'langkah',
    xpDasar: 10,
    sumber: 'pedometer',
  ),
  Habit(
    key: 'olahraga',
    nama: 'Olahraga',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 10,
    satuan: 'menit',
    xpDasar: 15,
  ),
  Habit(
    key: 'peregangan_pagi',
    nama: 'Peregangan pagi',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),
  Habit(
    key: 'peregangan_malam',
    nama: 'Peregangan sebelum tidur',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),

  // Makan
  Habit(
    key: 'isi_piringku',
    nama: 'Makan sesuai Isi Piringku',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 2,
    satuan: 'makan utama',
    xpDasar: 15,
  ),
  Habit(
    key: 'prioritas_protein',
    nama: 'Prioritas protein',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 2,
    satuan: 'makan utama',
    xpDasar: 10,
  ),
  Habit(
    key: 'minum_air',
    nama: 'Minum air',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 8,
    satuan: 'gelas',
    xpDasar: 10,
  ),
  Habit(
    key: 'batasi_gula_olahan',
    nama: 'Batasi gula tambahan & makanan olahan',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),

  // Tidur
  Habit(
    key: 'tidur_sebelum_23',
    nama: 'Tidur sebelum jam 23',
    pilar: Pilar.tidur,
    tipe: TipeHabit.waktu,
    target: 1380, // 23:00
    satuan: '',
    xpDasar: 15,
  ),
  Habit(
    key: 'durasi_tidur',
    nama: 'Durasi tidur',
    pilar: Pilar.tidur,
    tipe: TipeHabit.hitung,
    target: 420,
    satuan: 'menit',
    xpDasar: 15,
  ),
  Habit(
    key: 'bangun_konsisten',
    nama: 'Bangun jam konsisten',
    pilar: Pilar.tidur,
    tipe: TipeHabit.waktu,
    target: 360, // 06:00
    satuan: '',
    xpDasar: 10,
  ),
  Habit(
    key: 'tanpa_layar_sebelum_tidur',
    nama: 'Tanpa layar 30 menit sebelum tidur',
    pilar: Pilar.tidur,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),

  // Pikiran
  Habit(
    key: 'napas_meditasi',
    nama: 'Napas atau meditasi',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 5,
    satuan: 'menit',
    xpDasar: 10,
  ),
  Habit(
    key: 'jurnal_syukur',
    nama: 'Jurnal syukur',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 3,
    satuan: 'hal',
    xpDasar: 10,
  ),
  Habit(
    key: 'batas_medsos',
    nama: 'Batas medsos di bawah 2 jam',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),
  Habit(
    key: 'kena_matahari',
    nama: 'Keluar rumah kena matahari',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),
];
```

- [ ] **Step 4: Jalankan seluruh test**

```bash
flutter test
```

Diharapkan: seluruh test LULUS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/habit_preset.dart test/logic/preset_test.dart
git commit -m "feat: tambah katalog 16 habit preset"
```

---

### Task 7: Database

**Files:**
- Create: `lib/db/database.dart`

**Interfaces:**
- Consumes: `Habit`, `habitPreset`
- Produces kelas `AppDatabase` dengan:
  - `static Future<AppDatabase> buka()`
  - `Future<List<Habit>> semuaHabit()`
  - `Future<void> setAktif(int habitId, bool aktif)`
  - `Future<void> setTarget(int habitId, int target)`
  - `Future<int> tambahCustom(Habit habit)`
  - `Future<void> hapusCustom(int habitId)`
  - `Future<void> catat({required int habitId, required String tanggal, required int nilai, required int xp})`
  - `Future<Map<int,int>> nilaiHari(String tanggal)` — habitId ke nilai
  - `Future<Map<int,int>> xpHari(String tanggal)` — habitId ke xp beku
  - `Future<Map<String,int>> akumulasiPerKey()`
  - `Future<Map<Pilar,int>> xpPerPilar()`
  - `Future<Map<int,int>> selesai7Hari(String sejak)` — habitId ke jumlah hari selesai
  - `Future<BarisHari?> hari(String tanggal)` / `Future<void> simpanHari(BarisHari baris)`
  - `Future<List<BarisHari>> hariSejak(String tanggal)`
  - `Future<String?> meta(String key)` / `Future<void> setMeta(String key, String nilai)`
  - `Future<Set<String>> medaliTerbuka()` / `Future<void> bukaMedali(String key, String waktu)`
  - `Future<Map<String,List<Map<String,Object?>>>> dumpSemua()` / `Future<void> gantiSemua(Map<String,List<Map<String,Object?>>> data)`
  - `class BarisHari { final String tanggal; final List<int> questIds; final List<int> aktifIds; final bool bonusDiambil; final bool dijeda; }`

Tidak ada unit test untuk tugas ini — `docs/design.md` membatasi unit test ke `lib/logic/`. Verifikasinya lewat menjalankan aplikasi di Task 9.

- [ ] **Step 1: Tulis skema dan pengisian awal**

`lib/db/database.dart`:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/habit.dart';
import '../data/habit_preset.dart';

class BarisHari {
  const BarisHari({
    required this.tanggal,
    required this.questIds,
    required this.aktifIds,
    this.bonusDiambil = false,
    this.dijeda = false,
  });

  final String tanggal;
  final List<int> questIds;
  final List<int> aktifIds;
  final bool bonusDiambil;
  final bool dijeda;
}

List<int> _keIds(String? teks) => (teks == null || teks.isEmpty)
    ? const []
    : teks.split(',').map(int.parse).toList();

String _dariIds(List<int> ids) => ids.join(',');

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static Future<AppDatabase> buka() async {
    final path = p.join(await getDatabasesPath(), 'habit_leveling.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE NOT NULL,
            nama TEXT NOT NULL,
            pilar TEXT NOT NULL,
            tipe TEXT NOT NULL,
            target INTEGER NOT NULL,
            satuan TEXT NOT NULL,
            xp_dasar INTEGER NOT NULL,
            sumber TEXT NOT NULL,
            aktif INTEGER NOT NULL,
            is_custom INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            tanggal TEXT NOT NULL,
            nilai INTEGER NOT NULL,
            xp INTEGER NOT NULL,
            UNIQUE (habit_id, tanggal)
          )
        ''');
        await db.execute('CREATE INDEX idx_logs_tanggal ON logs (tanggal)');
        await db.execute('''
          CREATE TABLE hari (
            tanggal TEXT PRIMARY KEY,
            quest_ids TEXT NOT NULL,
            aktif_ids TEXT NOT NULL,
            bonus_diambil INTEGER NOT NULL,
            dijeda INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE TABLE meta (key TEXT PRIMARY KEY, nilai TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE medali (key TEXT PRIMARY KEY, dibuka_pada TEXT NOT NULL)',
        );
        await _isiPreset(db);
      },
    );
    return AppDatabase._(db);
  }

  /// Menyisipkan preset yang kuncinya belum ada. Preset yang sudah ada tidak
  /// pernah ditimpa — user mungkin sudah mengubah targetnya.
  static Future<void> _isiPreset(DatabaseExecutor db) async {
    for (final h in habitPreset) {
      await db.insert(
        'habits',
        {
          'key': h.key,
          'nama': h.nama,
          'pilar': h.pilar.name,
          'tipe': h.tipe.name,
          'target': h.target,
          'satuan': h.satuan,
          'xp_dasar': h.xpDasar,
          'sumber': h.sumber,
          'aktif': saranAwal.contains(h.key) ? 1 : 0,
          'is_custom': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
```

- [ ] **Step 2: Tambahkan kueri habit**

Di dalam kelas `AppDatabase`:

```dart
  Habit _keHabit(Map<String, Object?> r) => Habit(
        id: r['id']! as int,
        key: r['key']! as String,
        nama: r['nama']! as String,
        pilar: Pilar.values.byName(r['pilar']! as String),
        tipe: TipeHabit.values.byName(r['tipe']! as String),
        target: r['target']! as int,
        satuan: r['satuan']! as String,
        xpDasar: r['xp_dasar']! as int,
        sumber: r['sumber']! as String,
        aktif: (r['aktif']! as int) == 1,
        isCustom: (r['is_custom']! as int) == 1,
      );

  Future<List<Habit>> semuaHabit() async {
    final rows = await _db.query('habits', orderBy: 'pilar, id');
    return rows.map(_keHabit).toList();
  }

  Future<void> setAktif(int habitId, bool aktif) => _db.update(
        'habits',
        {'aktif': aktif ? 1 : 0},
        where: 'id = ?',
        whereArgs: [habitId],
      );

  Future<void> setTarget(int habitId, int target) => _db.update(
        'habits',
        {'target': target < 1 ? 1 : target},
        where: 'id = ?',
        whereArgs: [habitId],
      );

  Future<int> tambahCustom(Habit h) => _db.insert('habits', {
        'key': h.key,
        'nama': h.nama,
        'pilar': h.pilar.name,
        'tipe': TipeHabit.hitung.name,
        'target': h.target < 1 ? 1 : h.target,
        'satuan': h.satuan,
        'xp_dasar': xpDasarCustom,
        'sumber': 'manual',
        'aktif': 1,
        'is_custom': 1,
      });

  /// Menghapus habit custom beserta seluruh catatannya.
  ///
  /// Ini satu-satunya jalur di aplikasi yang boleh menurunkan XP, dan hanya
  /// berlaku untuk habit custom. Penghapusan log digantung pada keberhasilan
  /// penghapusan barisnya, supaya id habit preset yang salah masuk tidak bisa
  /// memusnahkan riwayatnya. Keduanya dalam satu transaksi agar tidak mungkin
  /// tersisa setengah jalan.
  Future<void> hapusCustom(int habitId) async {
    await _db.transaction((txn) async {
      final terhapus = await txn.delete(
        'habits',
        where: 'id = ? AND is_custom = 1',
        whereArgs: [habitId],
      );
      if (terhapus > 0) {
        await txn.delete('logs', where: 'habit_id = ?', whereArgs: [habitId]);
      }
    });
  }
```

Menghapus habit custom ikut menghapus lognya. Itu berarti XP-nya hilang dan level bisa turun — satu-satunya pengecualian dari aturan "XP tidak pernah berkurang", dan user harus dikonfirmasi lebih dulu di layar pengaturan (Task 15).

- [ ] **Step 3: Tambahkan kueri log dan agregat**

```dart
  Future<void> catat({
    required int habitId,
    required String tanggal,
    required int nilai,
    required int xp,
  }) =>
      _db.insert(
        'logs',
        {'habit_id': habitId, 'tanggal': tanggal, 'nilai': nilai, 'xp': xp},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Map<int, int>> _kolomHari(String tanggal, String kolom) async {
    final rows = await _db.query(
      'logs',
      columns: ['habit_id', kolom],
      where: 'tanggal = ?',
      whereArgs: [tanggal],
    );
    return {
      for (final r in rows) r['habit_id']! as int: r[kolom]! as int,
    };
  }

  Future<Map<int, int>> nilaiHari(String tanggal) =>
      _kolomHari(tanggal, 'nilai');

  Future<Map<int, int>> xpHari(String tanggal) => _kolomHari(tanggal, 'xp');

  Future<Map<String, int>> akumulasiPerKey() async {
    final rows = await _db.rawQuery('''
      SELECT h.key AS key, SUM(l.nilai) AS total
      FROM logs l JOIN habits h ON h.id = l.habit_id
      WHERE h.is_custom = 0
      GROUP BY h.key
    ''');
    return {
      for (final r in rows) r['key']! as String: (r['total'] as int?) ?? 0,
    };
  }

  Future<Map<Pilar, int>> xpPerPilar() async {
    final rows = await _db.rawQuery('''
      SELECT h.pilar AS pilar, SUM(l.xp) AS total
      FROM logs l JOIN habits h ON h.id = l.habit_id
      GROUP BY h.pilar
    ''');
    final hasil = {for (final p in Pilar.values) p: 0};
    for (final r in rows) {
      hasil[Pilar.values.byName(r['pilar']! as String)] =
          (r['total'] as int?) ?? 0;
    }
    return hasil;
  }

  Future<Map<int, int>> selesai7Hari(String sejak) async {
    final rows = await _db.rawQuery('''
      SELECT l.habit_id AS habit_id, COUNT(*) AS jumlah
      FROM logs l JOIN habits h ON h.id = l.habit_id
      WHERE l.tanggal >= ? AND l.xp >= h.xp_dasar
      GROUP BY l.habit_id
    ''', [sejak]);
    return {
      for (final r in rows) r['habit_id']! as int: r['jumlah']! as int,
    };
  }
```

`selesai7Hari` memakai `l.xp >= h.xp_dasar`, bukan `nilai >= target` — itu aturan global yang wajib dipatuhi di seluruh kueri.

- [ ] **Step 4: Tambahkan kueri hari, meta, dan medali**

```dart
  BarisHari _keHari(Map<String, Object?> r) => BarisHari(
        tanggal: r['tanggal']! as String,
        questIds: _keIds(r['quest_ids'] as String?),
        aktifIds: _keIds(r['aktif_ids'] as String?),
        bonusDiambil: (r['bonus_diambil']! as int) == 1,
        dijeda: (r['dijeda']! as int) == 1,
      );

  Future<BarisHari?> hari(String tanggal) async {
    final rows = await _db.query(
      'hari',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
    );
    return rows.isEmpty ? null : _keHari(rows.first);
  }

  Future<List<BarisHari>> hariSejak(String tanggal) async {
    final rows = await _db.query(
      'hari',
      where: 'tanggal >= ?',
      whereArgs: [tanggal],
      orderBy: 'tanggal',
    );
    return rows.map(_keHari).toList();
  }

  Future<void> simpanHari(BarisHari h) => _db.insert(
        'hari',
        {
          'tanggal': h.tanggal,
          'quest_ids': _dariIds(h.questIds),
          'aktif_ids': _dariIds(h.aktifIds),
          'bonus_diambil': h.bonusDiambil ? 1 : 0,
          'dijeda': h.dijeda ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<String?> meta(String key) async {
    final rows = await _db.query('meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['nilai'] as String;
  }

  Future<void> setMeta(String key, String nilai) => _db.insert(
        'meta',
        {'key': key, 'nilai': nilai},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Set<String>> medaliTerbuka() async {
    final rows = await _db.query('medali', columns: ['key']);
    return rows.map((r) => r['key']! as String).toSet();
  }

  Future<void> bukaMedali(String key, String waktu) => _db.insert(
        'medali',
        {'key': key, 'dibuka_pada': waktu},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  static const List<String> _tabel = [
    'habits',
    'logs',
    'hari',
    'meta',
    'medali',
  ];

  Future<Map<String, List<Map<String, Object?>>>> dumpSemua() async {
    final hasil = <String, List<Map<String, Object?>>>{};
    for (final t in _tabel) {
      hasil[t] = await _db.query(t);
    }
    return hasil;
  }

  Future<void> gantiSemua(
    Map<String, List<Map<String, Object?>>> data,
  ) async {
    await _db.transaction((txn) async {
      for (final t in _tabel) {
        await txn.delete(t);
      }
      for (final t in _tabel) {
        for (final baris in data[t] ?? const []) {
          await txn.insert(t, baris);
        }
      }
    });
  }
```

- [ ] **Step 5: Verifikasi kompilasi**

```bash
flutter analyze
```

Diharapkan: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/db/database.dart
git commit -m "feat: tambah skema database dan seluruh kueri"
```

---

### Task 8: Service habit dan pemrosesan hari

**Files:**
- Create: `lib/services/habit_service.dart`
- Test: `test/logic/hari_test.dart`
- Modify: `lib/logic/quest.dart` (tambah helper hari sempurna)

**Interfaces:**
- Consumes: seluruh `lib/logic/`, `AppDatabase`
- Produces `class HabitService` dengan:
  - `final ValueNotifier<KeadaanApp?> keadaan` — bernilai `null` sampai `muat` pertama selesai
  - `Future<void> muat(DateTime sekarang)`
  - `Future<void> catatHabit(int habitId, int nilai, DateTime sekarang)`
  - `Future<List<Medali>> periksaMedali(DateTime sekarang)`
  - `class KeadaanApp` dengan `List<Habit> habit, BarisHari hariIni, Map<int,int> nilaiHariIni, Map<int,int> xpHariIni, Map<Pilar,int> levelPilar, int levelGlobal, int xpGlobal, int streakTampil, int jeda, int skorKeseimbangan`
- Produces di `lib/logic/quest.dart`: `bool hariSempurna(List<int> aktifIds, Map<int,int> xpHari, Map<int,int> xpDasarPerHabit)`

- [ ] **Step 1: Tulis test yang gagal untuk hari sempurna**

`test/logic/hari_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/logic/quest.dart';

void main() {
  const xpDasar = {1: 10, 2: 15, 3: 10};

  test('semua habit aktif mencapai xp dasar berarti sempurna', () {
    expect(
      hariSempurna([1, 2], {1: 10, 2: 15}, xpDasar),
      isTrue,
    );
  });

  test('satu habit setengah jalan membatalkan hari sempurna', () {
    expect(
      hariSempurna([1, 2], {1: 10, 2: 7}, xpDasar),
      isFalse,
    );
  });

  test('habit aktif tanpa catatan sama sekali membatalkan', () {
    expect(hariSempurna([1, 2], {1: 10}, xpDasar), isFalse);
  });

  test('habit yang dicatat tapi tidak aktif hari itu diabaikan', () {
    expect(
      hariSempurna([1], {1: 10, 3: 2}, xpDasar),
      isTrue,
    );
  });

  test('tanpa habit aktif bukan hari sempurna', () {
    expect(hariSempurna([], {}, xpDasar), isFalse);
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

```bash
flutter test test/logic/hari_test.dart
```

Diharapkan: GAGAL, `hariSempurna` belum ada.

- [ ] **Step 3: Tambahkan `hariSempurna` ke `lib/logic/quest.dart`**

```dart
/// Sebuah hari sempurna bila seluruh habit yang aktif PADA HARI ITU mencapai
/// xp dasarnya. Perbandingan memakai xp beku, bukan target yang berlaku
/// sekarang — target boleh berubah, dan riwayat tidak boleh ikut berubah.
bool hariSempurna(
  List<int> aktifIds,
  Map<int, int> xpHari,
  Map<int, int> xpDasarPerHabit,
) {
  if (aktifIds.isEmpty) return false;
  return aktifIds.every(
    (id) => (xpHari[id] ?? 0) >= (xpDasarPerHabit[id] ?? 0),
  );
}
```

Fungsi yang sama dipakai untuk menjawab "quest selesai": panggil dengan `questIds` sebagai argumen pertama.

- [ ] **Step 4: Jalankan test untuk memastikan lulus**

```bash
flutter test test/logic/hari_test.dart
```

Diharapkan: seluruh test LULUS.

- [ ] **Step 5: Tulis service**

`lib/services/habit_service.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../data/achievement_preset.dart';
import '../data/habit.dart';
import '../data/habit_preset.dart';
import '../db/database.dart';
import '../logic/achievement.dart';
import '../logic/quest.dart';
import '../logic/streak.dart';
import '../logic/xp.dart';

String tanggalKe(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class KeadaanApp {
  const KeadaanApp({
    required this.habit,
    required this.hariIni,
    required this.nilaiHariIni,
    required this.xpHariIni,
    required this.levelPilar,
    required this.levelGlobal,
    required this.xpGlobal,
    required this.streakTampil,
    required this.jeda,
    required this.skorKeseimbangan,
  });

  final List<Habit> habit;
  final BarisHari hariIni;
  final Map<int, int> nilaiHariIni;
  final Map<int, int> xpHariIni;
  final Map<Pilar, int> levelPilar;
  final int levelGlobal;
  final int xpGlobal;
  final int streakTampil;
  final int jeda;
  final int skorKeseimbangan;

  Habit? cari(int id) {
    for (final h in habit) {
      if (h.id == id) return h;
    }
    return null;
  }
}

class HabitService {
  HabitService(this._db);

  final AppDatabase _db;

  final ValueNotifier<KeadaanApp?> keadaan = ValueNotifier(null);

  Future<void> muat(DateTime sekarang) async {
    await _prosesHariTertunda(sekarang);
    final hariIni = await _pastikanBarisHariIni(sekarang);
    final habit = await _db.semuaHabit();
    final xpPilar = await _db.xpPerPilar();
    final levelPilar = {
      for (final e in xpPilar.entries) e.key: levelDariXp(e.value),
    };
    final xpGlobal = xpPilar.values.fold(0, (a, b) => a + b);
    final xpHariIni = await _db.xpHari(tanggalKe(sekarang));
    final xpDasar = {for (final h in habit) h.id!: h.xpDasar};
    final questSelesai = hariSempurna(hariIni.questIds, xpHariIni, xpDasar);
    final streak = int.parse(await _db.meta('streak') ?? '0');

    keadaan.value = KeadaanApp(
      habit: habit,
      hariIni: hariIni,
      nilaiHariIni: await _db.nilaiHari(tanggalKe(sekarang)),
      xpHariIni: xpHariIni,
      levelPilar: levelPilar,
      levelGlobal: levelGlobalDariXp(xpGlobal),
      xpGlobal: xpGlobal,
      // Hari ini baru dibukukan besok; +1 hanya untuk tampilan.
      streakTampil: questSelesai ? streak + 1 : streak,
      jeda: int.parse(await _db.meta('jeda_tersedia') ?? '0'),
      skorKeseimbangan: skorKeseimbangan(levelPilar.values.toList()),
    );
  }

  Future<void> catatHabit(int habitId, int nilai, DateTime sekarang) async {
    final habit = (await _db.semuaHabit()).firstWhere((h) => h.id == habitId);
    final xp = hitungXp(
      tipe: habit.tipe,
      nilai: nilai,
      target: habit.target,
      xpDasar: habit.xpDasar,
    );
    await _db.catat(
      habitId: habitId,
      tanggal: tanggalKe(sekarang),
      nilai: nilai,
      xp: xp,
    );
    await _cekBonusQuest(sekarang);
    await muat(sekarang);
  }
}
```

- [ ] **Step 6: Tulis pemrosesan hari dan bonus quest**

Lanjutan kelas `HabitService`:

```dart
  Future<BarisHari> _pastikanBarisHariIni(DateTime sekarang) async {
    final tanggal = tanggalKe(sekarang);
    final ada = await _db.hari(tanggal);
    if (ada != null) return ada;

    final habit = await _db.semuaHabit();
    final aktif = habit.where((h) => h.aktif).toList();
    final xpPilar = await _db.xpPerPilar();
    final sejak = tanggalKe(sekarang.subtract(const Duration(days: 7)));
    final selesai = await _db.selesai7Hari(sejak);

    final kandidat = aktif
        .where((h) => !h.isCustom)
        .map((h) => KandidatQuest(
              habitId: h.id!,
              pilar: h.pilar,
              levelPilar: levelDariXp(xpPilar[h.pilar] ?? 0),
              selesai7Hari: selesai[h.id!] ?? 0,
            ))
        .toList();

    final baris = BarisHari(
      tanggal: tanggal,
      questIds: pilihQuest(kandidat, tanggal),
      // Potret diambil SEKARANG, di awal hari — bukan saat pemrosesan besok.
      aktifIds: aktif.where((h) => !h.isCustom).map((h) => h.id!).toList(),
    );
    await _db.simpanHari(baris);
    return baris;
  }

  Future<void> _prosesHariTertunda(DateTime sekarang) async {
    final terakhir = await _db.meta('terakhir_diproses');
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    var mulai = terakhir == null
        ? hariIni.subtract(const Duration(days: 1))
        : DateTime.parse(terakhir);

    final tanggalUrut = <String>[];
    var kursor = mulai.add(const Duration(days: 1));
    while (kursor.isBefore(hariIni)) {
      tanggalUrut.add(tanggalKe(kursor));
      kursor = kursor.add(const Duration(days: 1));
    }
    if (tanggalUrut.isEmpty) return;

    final habit = await _db.semuaHabit();
    final xpDasar = {for (final h in habit) h.id!: h.xpDasar};
    final selesaiPerTanggal = <String, bool>{};
    for (final t in tanggalUrut) {
      final baris = await _db.hari(t);
      if (baris == null) {
        // Aplikasi tidak dibuka hari itu. Simpan baris kosong supaya setiap
        // tanggal yang sudah lewat punya tepat satu baris.
        await _db.simpanHari(
          BarisHari(tanggal: t, questIds: const [], aktifIds: const []),
        );
        selesaiPerTanggal[t] = false;
      } else {
        selesaiPerTanggal[t] = baris.questIds.isNotEmpty &&
            hariSempurna(baris.questIds, await _db.xpHari(t), xpDasar);
      }
    }

    final awal = KeadaanStreak(
      streak: int.parse(await _db.meta('streak') ?? '0'),
      jeda: int.parse(await _db.meta('jeda_tersedia') ?? '0'),
      pernahPutus: (await _db.meta('pernah_putus')) == '1',
      pernahPakaiJeda: (await _db.meta('pernah_pakai_jeda')) == '1',
    );
    final hasil = prosesRentang(
      awal,
      tanggalUrut,
      (t) => selesaiPerTanggal[t] ?? false,
    );

    for (final t in hasil.tanggalDijeda) {
      final b = await _db.hari(t);
      if (b != null) {
        await _db.simpanHari(BarisHari(
          tanggal: b.tanggal,
          questIds: b.questIds,
          aktifIds: b.aktifIds,
          bonusDiambil: b.bonusDiambil,
          dijeda: true,
        ));
      }
    }

    await _db.setMeta('streak', '${hasil.keadaan.streak}');
    await _db.setMeta('jeda_tersedia', '${hasil.keadaan.jeda}');
    await _db.setMeta('pernah_putus', hasil.keadaan.pernahPutus ? '1' : '0');
    await _db.setMeta(
      'pernah_pakai_jeda',
      hasil.keadaan.pernahPakaiJeda ? '1' : '0',
    );
    await _db.setMeta('terakhir_diproses', tanggalUrut.last);
  }

  Future<void> _cekBonusQuest(DateTime sekarang) async {
    final tanggal = tanggalKe(sekarang);
    final baris = await _db.hari(tanggal);
    if (baris == null || baris.bonusDiambil || baris.questIds.isEmpty) return;

    final habit = await _db.semuaHabit();
    final xpDasar = {for (final h in habit) h.id!: h.xpDasar};
    final xpHari = await _db.xpHari(tanggal);
    if (!hariSempurna(baris.questIds, xpHari, xpDasar)) return;

    // Bonus dibagi rata ke pilar yang terlibat, dicatat sebagai tambahan xp
    // pada log habit quest itu sendiri supaya tetap terbawa agregat per pilar.
    final pilarQuest = baris.questIds
        .map((id) => habit.firstWhere((h) => h.id == id).pilar)
        .toSet();
    final perPilar = bonusPerPilar(pilarQuest.length);
    for (final pilar in pilarQuest) {
      final id = baris.questIds.firstWhere(
        (i) => habit.firstWhere((h) => h.id == i).pilar == pilar,
      );
      await _db.catat(
        habitId: id,
        tanggal: tanggal,
        nilai: (await _db.nilaiHari(tanggal))[id] ?? 0,
        xp: (xpHari[id] ?? 0) + perPilar,
      );
    }
    await _db.simpanHari(BarisHari(
      tanggal: baris.tanggal,
      questIds: baris.questIds,
      aktifIds: baris.aktifIds,
      bonusDiambil: true,
      dijeda: baris.dijeda,
    ));
  }

  Future<List<Medali>> periksaMedali(DateTime sekarang) async {
    final k = keadaan.value;
    if (k == null) return const [];
    final sempurna = await _db.hariSejak('0000-01-01');
    final xpDasar = {for (final h in k.habit) h.id!: h.xpDasar};
    var jumlahSempurna = 0;
    for (final b in sempurna) {
      if (hariSempurna(b.aktifIds, await _db.xpHari(b.tanggal), xpDasar)) {
        jumlahSempurna++;
      }
    }
    final ringkasan = RingkasanKeadaan(
      levelPilar: k.levelPilar,
      levelGlobal: k.levelGlobal,
      streak: k.streakTampil,
      skorKeseimbangan: k.skorKeseimbangan,
      akumulasi: await _db.akumulasiPerKey(),
      hariSempurna: jumlahSempurna,
      pernahPutus: (await _db.meta('pernah_putus')) == '1',
      pernahPakaiJeda: (await _db.meta('pernah_pakai_jeda')) == '1',
    );
    final baru = medaliBaru(ringkasan, await _db.medaliTerbuka());
    for (final m in baru) {
      await _db.bukaMedali(m.key, sekarang.toIso8601String());
    }
    return baru;
  }
```

Perhatikan `_cekBonusQuest`: bonus ditambahkan ke kolom `xp` log habit quest, jadi ia otomatis ikut agregat `xpPerPilar` tanpa tabel baru. Karena `bonus_diambil` dicek lebih dulu, bonus tidak bisa ditambahkan dua kali.

- [ ] **Step 7: Verifikasi**

```bash
flutter analyze && flutter test
```

Diharapkan: `No issues found!` dan seluruh test lulus.

- [ ] **Step 8: Commit**

```bash
git add lib/services/habit_service.dart lib/logic/quest.dart test/logic/hari_test.dart
git commit -m "feat: tambah service habit dan pemrosesan hari"
```

---

### Task 9: Onboarding dan kerangka aplikasi

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/screens/onboarding/onboarding_screen.dart`, `lib/screens/beranda/beranda_screen.dart` (kerangka), `lib/screens/kerangka.dart`

**Interfaces:**
- Consumes: `HabitService`, `AppDatabase`, `habitPreset`, `saranAwal`
- Produces: `class Kerangka` — `IndexedStack` empat tab; `class OnboardingScreen`

Onboarding dianggap selesai bila `meta['onboarding_selesai'] == '1'`.

- [ ] **Step 1: Tulis `main.dart`**

```dart
import 'package:flutter/material.dart';

import 'db/database.dart';
import 'screens/kerangka.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/habit_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.buka();
  final service = HabitService(db);
  final sudahOnboarding = (await db.meta('onboarding_selesai')) == '1';
  if (sudahOnboarding) {
    await service.muat(DateTime.now());
  }
  runApp(HabitLevelingApp(
    db: db,
    service: service,
    sudahOnboarding: sudahOnboarding,
  ));
}

class HabitLevelingApp extends StatelessWidget {
  const HabitLevelingApp({
    super.key,
    required this.db,
    required this.service,
    required this.sudahOnboarding,
  });

  final AppDatabase db;
  final HabitService service;
  final bool sudahOnboarding;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Habit Leveling',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D5B),
          useMaterial3: true,
        ),
        home: sudahOnboarding
            ? Kerangka(db: db, service: service)
            : OnboardingScreen(db: db, service: service),
      );
}
```

- [ ] **Step 2: Tulis kerangka empat tab**

`lib/screens/kerangka.dart` menampilkan `IndexedStack` dengan empat halaman dan `NavigationBar` berlabel **Beranda, Statistik, Medali, Pengaturan**. Tiga tab terakhir diisi placeholder `Center(child: Text('...'))` yang diganti di Task 13, 14, dan 15. Konstruktor menerima `AppDatabase db` dan `HabitService service` dan meneruskannya ke setiap halaman.

- [ ] **Step 3: Tulis layar onboarding**

Tiga langkah dalam satu `PageView`:

1. **Sambutan** — menjelaskan empat pilar Gerak, Makan, Tidur, Pikiran dalam satu paragraf pendek per pilar.
2. **Pemilihan habit** — daftar 16 preset dikelompokkan per pilar, dengan `CheckboxListTile`. Lima kunci di `saranAwal` sudah tercentang. Mencentang habit ke sembilan ditolak dengan `SnackBar` bertuliskan "Maksimal 8 habit aktif. Nonaktifkan salah satu dulu." Tombol lanjut nonaktif bila tidak ada satu pun yang tercentang.
3. **Jam pengingat** — `TimePicker`, default 20:00, disimpan ke `meta['jam_pengingat']` dalam format `HH:mm`.

Saat tombol selesai ditekan: panggil `db.setAktif` untuk setiap perubahan, `db.setMeta('onboarding_selesai', '1')`, `service.muat(DateTime.now())`, lalu `Navigator.pushReplacement` ke `Kerangka`.

Izin notifikasi dan pedometer **tidak** diminta di sini — keduanya diminta oleh service-nya masing-masing di Task 11 dan 12, saat pertama kali dibutuhkan.

- [ ] **Step 4: Beranda kerangka**

`beranda_screen.dart` untuk sementara cukup menampilkan `ValueListenableBuilder` atas `service.keadaan` dan mencetak level global serta jumlah habit aktif sebagai teks. Isi sesungguhnya ditulis di Task 10. Tujuan langkah ini adalah membuktikan rantai database → service → UI sudah hidup.

- [ ] **Step 5: Jalankan di perangkat**

```bash
flutter run
```

Diharapkan: onboarding muncul di jalankan pertama, memilih habit berhasil, dan setelah selesai beranda menampilkan "Level 1" dengan jumlah habit aktif sesuai pilihan. Tutup dan buka lagi aplikasi: langsung masuk beranda, tidak mengulang onboarding.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/screens
git commit -m "feat: tambah onboarding dan kerangka empat tab"
```

---

### Task 10: Beranda

**Files:**
- Create: `lib/widgets/kartu_habit.dart`, `lib/widgets/bar_xp.dart`, `lib/widgets/popup_medali.dart`
- Modify: `lib/screens/beranda/beranda_screen.dart`

**Interfaces:**
- Consumes: `HabitService.keadaan`, `KeadaanApp`, `catatHabit`, `periksaMedali`
- Produces: `KartuHabit` (`Habit habit, int nilai, int xp, VoidCallback onTambah, VoidCallback onInfo`), `BarXp` (`int xp, int level, bool global`), `Future<void> tampilkanPopupMedali(BuildContext, List<Medali>)`

- [ ] **Step 1: Susun beranda**

Urutan dari atas: `BarXp` dengan level global · baris streak berjalan dan sisa jeda · judul **Quest Hari Ini** dengan tiga `KartuHabit` berukuran besar · judul **Habit Lainnya** dengan sisa habit aktif sebagai `KartuHabit` ringkas.

Sumber datanya hanya `service.keadaan` melalui satu `ValueListenableBuilder`. Tidak ada `setState` yang membaca database langsung.

- [ ] **Step 2: Tulis `KartuHabit`**

Menampilkan nama habit, progres `${nilai}/${target} ${satuan}`, indikator selesai bila `xp >= habit.xpDasar`, tombol tambah, dan ikon `Icons.help_outline` yang memanggil `onInfo`.

Aturan tombol tambah menurut tipe:

- `TipeHabit.hitung` dengan `target == 1`: tombol centang, menaikkan nilai ke 1 atau mengembalikan ke 0
- `TipeHabit.hitung` dengan `target > 1` dan satuan `menit` atau `langkah`: membuka dialog input angka
- `TipeHabit.hitung` lainnya: tombol `+1`
- `TipeHabit.waktu`: membuka `TimePicker`, nilai disimpan sebagai menit sejak tengah malam

Habit dengan `sumber == 'pedometer'` tidak punya tombol tambah selama sensor tersedia — nilainya diisi Task 11.

Satuan `menit` dengan `target >= 60` ditampilkan dalam jam (`420 menit` menjadi `7 jam`). Aturan ini umum, bukan kekhususan satu habit.

- [ ] **Step 3: Sambungkan popup medali**

Setelah setiap `catatHabit` selesai, panggil `service.periksaMedali(DateTime.now())`. Bila daftarnya tidak kosong, tampilkan dialog berisi nama dan syarat tiap medali secara berurutan.

- [ ] **Step 4: Jalankan dan verifikasi**

```bash
flutter run
```

Diharapkan: mencentang habit menaikkan bar XP; menyelesaikan ketiga quest memunculkan tambahan XP bonus dan indikator streak berubah menjadi 1; menutup lalu membuka aplikasi tidak mengubah pilihan quest hari itu.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/beranda lib/widgets
git commit -m "feat: tambah beranda dengan quest harian dan pencatatan"
```

---

### Task 11: Pedometer

**Files:**
- Create: `lib/services/step_service.dart`
- Modify: `lib/screens/beranda/beranda_screen.dart`

**Interfaces:**
- Consumes: `AppDatabase` (`meta`, `setMeta`), `HabitService.catatHabit`
- Produces `class StepService`:
  - `Future<bool> mintaIzin()`
  - `Future<void> mulai(DateTime sekarang, void Function(int langkah) onLangkah)`
  - `final ValueNotifier<bool> tersedia`

- [ ] **Step 1: Tulis service**

Sensor Android menghitung langkah sejak perangkat menyala, bukan sejak tengah malam. Karena itu service menyimpan dua meta: `acuan_langkah` dan `acuan_langkah_tanggal`.

Aturannya:

```dart
Future<int> langkahHariIni(int nilaiSensor, DateTime sekarang) async {
  final tanggal = tanggalKe(sekarang);
  final tanggalAcuan = await _db.meta('acuan_langkah_tanggal');
  var acuan = int.tryParse(await _db.meta('acuan_langkah') ?? '') ?? nilaiSensor;

  // Hari baru, atau perangkat baru restart sehingga hitungan sensor mundur.
  if (tanggalAcuan != tanggal || nilaiSensor < acuan) {
    acuan = nilaiSensor;
    await _db.setMeta('acuan_langkah', '$acuan');
    await _db.setMeta('acuan_langkah_tanggal', tanggal);
  }
  return nilaiSensor - acuan;
}
```

- [ ] **Step 2: Tangani izin dan ketiadaan sensor**

`mintaIzin` memakai `Permission.activityRecognition`. Bila ditolak atau `Pedometer.stepCountStream` melempar, set `tersedia.value = false` dan jangan pernah mencoba lagi di sesi itu.

- [ ] **Step 3: Sambungkan ke beranda**

Saat beranda dibuka, panggil `mulai` dan teruskan hasilnya ke `service.catatHabit(idLangkahHarian, langkah, DateTime.now())`. Bila `tersedia.value == false`, tampilkan banner sekali berbunyi "Izin sensor langkah tidak aktif. Langkah harian dicatat manual." dan aktifkan tombol input manual pada kartu habit langkah.

- [ ] **Step 4: Verifikasi di perangkat fisik**

```bash
flutter run --release
```

Emulator tidak punya sensor langkah, jadi jalur gagal justru yang teruji di sana — itu berguna. Verifikasi keduanya: di perangkat fisik langkah terisi sendiri, di emulator banner muncul dan input manual jalan.

- [ ] **Step 5: Commit**

```bash
git add lib/services/step_service.dart lib/screens/beranda
git commit -m "feat: tambah pencatatan langkah otomatis dari pedometer"
```

---

### Task 12: Notifikasi

**Files:**
- Create: `lib/services/notification_service.dart`
- Modify: `lib/main.dart`, `lib/services/habit_service.dart`

**Interfaces:**
- Consumes: `meta['jam_pengingat']`
- Produces `class NotificationService`:
  - `Future<void> init()`
  - `Future<bool> mintaIzin()`
  - `Future<void> jadwalkanPengingatHarian(String jamHHmm)`
  - `Future<void> jadwalkanPeringatanMalam({required bool questSelesai})`

- [ ] **Step 1: Init dan izin**

`init` memanggil `tz.initializeTimeZones()` dan `setLocalLocation`. `mintaIzin` meminta `Permission.notification` lalu `Permission.scheduleExactAlarm`. Bila exact alarm ditolak, jadwal turun ke `AndroidScheduleMode.inexactAllowWhileIdle` dan pengaturan menampilkan banner "Notifikasi bisa meleset beberapa menit karena izin alarm presisi tidak aktif."

- [ ] **Step 2: Dua jadwal**

1. **Pengingat harian** — id notifikasi `1`, berulang harian pada `jam_pengingat`, judul "Quest hari ini menunggu".
2. **Peringatan malam** — id notifikasi `2`, pukul 21:00. Dijadwalkan ulang setiap kali `HabitService.muat` atau `catatHabit` selesai: bila quest hari itu sudah selesai, batalkan id `2`; bila belum, jadwalkan dengan teks "Masih ada quest yang belum selesai malam ini."

- [ ] **Step 3: Verifikasi di release build**

Bug R8/Gson **hanya muncul di release build**. Debug build yang lolos tidak membuktikan apa pun.

```bash
flutter build apk --release
flutter install
```

Set jam pengingat ke dua menit dari sekarang, tutup aplikasi sepenuhnya, tunggu. Notifikasi harus muncul. Lalu buka aplikasi dan periksa log tidak ada `Missing type parameter`.

- [ ] **Step 4: Commit**

```bash
git add lib/services/notification_service.dart lib/main.dart lib/services/habit_service.dart
git commit -m "feat: tambah dua jadwal notifikasi"
```

---

### Task 13: Statistik

**Files:**
- Create: `lib/screens/statistik/statistik_screen.dart`
- Modify: `lib/db/database.dart` (tambah kueri riwayat)

**Interfaces:**
- Consumes: `KeadaanApp.levelPilar`, `skorKeseimbangan`
- Produces di `AppDatabase`: `Future<Map<String,int>> xpPerTanggal(String sejak)`, `Future<Map<int,int>> keberhasilan30Hari(String sejak)`

- [ ] **Step 1: Tambah kueri riwayat**

```dart
  Future<Map<String, int>> xpPerTanggal(String sejak) async {
    final rows = await _db.rawQuery('''
      SELECT tanggal, SUM(xp) AS total FROM logs
      WHERE tanggal >= ? GROUP BY tanggal ORDER BY tanggal
    ''', [sejak]);
    return {
      for (final r in rows)
        r['tanggal']! as String: (r['total'] as int?) ?? 0,
    };
  }

  Future<Map<int, int>> keberhasilan30Hari(String sejak) async {
    final rows = await _db.rawQuery('''
      SELECT l.habit_id AS habit_id, COUNT(*) AS jumlah
      FROM logs l JOIN habits h ON h.id = l.habit_id
      WHERE l.tanggal >= ? AND l.xp >= h.xp_dasar
      GROUP BY l.habit_id
    ''', [sejak]);
    return {
      for (final r in rows) r['habit_id']! as int: r['jumlah']! as int,
    };
  }
```

- [ ] **Step 2: Susun layar**

Tiga bagian berurutan:

1. **Radar empat pilar** dengan `RadarChart` dari `fl_chart`, sumbu berlabel Gerak, Makan, Tidur, Pikiran, nilainya level tiap pilar. Di bawahnya angka Skor Keseimbangan beserta satu kalimat penjelasan.
2. **Grafik batang mingguan** dengan `BarChart`, tujuh batang berisi total XP per hari dari `xpPerTanggal`.
3. **Daftar keberhasilan 30 hari** per habit aktif, ditampilkan sebagai persentase dan `LinearProgressIndicator`.

- [ ] **Step 3: Verifikasi**

```bash
flutter run
```

Diharapkan: radar terisi, dan mencatat habit hari ini menaikkan batang hari ini pada grafik mingguan.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/statistik lib/db/database.dart
git commit -m "feat: tambah layar statistik dengan radar dan riwayat"
```

---

### Task 14: Medali

**Files:**
- Create: `lib/screens/medali/medali_screen.dart`

**Interfaces:**
- Consumes: `medaliPreset`, `AppDatabase.medaliTerbuka`

- [ ] **Step 1: Susun grid**

`GridView` tiga kolom berisi seluruh 30 medali. Yang terbuka berwarna penuh dengan tanggal terbuka; yang terkunci abu-abu **dengan syaratnya tetap terbaca** — syarat yang disembunyikan tidak memotivasi siapa pun. Header menampilkan "x dari 30 terbuka".

- [ ] **Step 2: Verifikasi**

```bash
flutter run
```

Diharapkan: 30 kartu tampil, medali yang sudah didapat berwarna.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/medali
git commit -m "feat: tambah layar medali"
```

---

### Task 15: Pengaturan dan habit custom

**Files:**
- Create: `lib/screens/pengaturan/pengaturan_screen.dart`, `lib/screens/pengaturan/form_custom.dart`

**Interfaces:**
- Consumes: `AppDatabase` (`setAktif`, `setTarget`, `tambahCustom`, `hapusCustom`, `setMeta`), `maksHabitCustom`, `maksHabitAktifDefault`

- [ ] **Step 1: Susun pengaturan**

Bagian berurutan: **Kelola habit** (16 preset dengan switch aktif dan tombol ubah target/ambang) · **Habit custom** (daftar, tombol tambah, tombol hapus) · **Jam pengingat** · **Batas habit aktif** · **Cadangkan data** (diisi Task 16) · **Tentang**.

Aturan yang wajib ditegakkan di layar ini:

- Total habit aktif — preset **dan** custom digabung — tidak boleh melebihi `meta['maks_habit_aktif']`, default 8. Melewati batas ditolak dengan `SnackBar`.
- Habit custom maksimal `maksHabitCustom` (5).
- Bila seluruh preset dinonaktifkan, tampilkan peringatan menetap: "Tanpa habit preset aktif, tidak ada quest harian dan streak tidak bisa berjalan."
- Menghapus habit custom butuh dialog konfirmasi bertuliskan "Menghapus habit ini juga menghapus seluruh catatannya. XP dari habit ini akan hilang dan level bisa turun." Ini satu-satunya jalur di aplikasi yang boleh menurunkan XP.

- [ ] **Step 2: Form habit custom**

Field: nama (wajib, maksimal 40 karakter), satuan (wajib, maksimal 12 karakter), target (angka, **minimal 1**, ditolak bila 0 atau kosong), pilar (`DropdownButton` empat pilihan).

Kunci dibuat otomatis `custom_<n>` dengan `n` angka berurut yang belum terpakai. XP dasarnya selalu `xpDasarCustom` dan tidak bisa diubah user — beri teks penjelas "Habit custom bernilai 5 XP dan tidak menghitung medali."

- [ ] **Step 3: Verifikasi**

```bash
flutter run
```

Diharapkan: mengaktifkan habit ke sembilan ditolak; membuat habit custom keenam ditolak; target 0 ditolak; menghapus custom meminta konfirmasi; mengubah target habit preset **tidak** mengubah XP hari-hari sebelumnya (periksa lewat level di beranda sebelum dan sesudah).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/pengaturan
git commit -m "feat: tambah pengaturan dan habit custom"
```

---

### Task 16: Ekspor dan impor

**Files:**
- Create: `lib/services/backup_service.dart`
- Modify: `lib/screens/pengaturan/pengaturan_screen.dart`

**Interfaces:**
- Consumes: `AppDatabase.dumpSemua`, `AppDatabase.gantiSemua`
- Produces `class BackupService`: `Future<void> ekspor()`, `Future<String?> impor()` (mengembalikan pesan error, atau `null` bila berhasil)

- [ ] **Step 1: Ekspor**

```dart
Future<void> ekspor() async {
  final data = await _db.dumpSemua();
  final isi = jsonEncode({'versi_skema': 1, 'data': data});
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/habit-leveling-backup.json');
  await file.writeAsString(isi);
  await Share.shareXFiles([XFile(file.path)]);
}
```

- [ ] **Step 2: Impor**

Alur: pilih file lewat paket pemilih berkas (belum dipilih —  dibuang di Task 7 karena menggagalkan build; evaluasi  yang dirawat tim Flutter, dan minta persetujuan pemilik repo sebelum menambahkannya) → baca → `jsonDecode` → validasi. Tolak dengan pesan jelas bila:

- Bukan JSON yang valid: "File tidak bisa dibaca. Pastikan file berasal dari Habit Leveling."
- `versi_skema` lebih besar dari versi aplikasi: "Cadangan ini dari versi aplikasi yang lebih baru. Perbarui aplikasi lebih dulu."
- Kunci `data` hilang atau tidak berisi kelima tabel: pesan yang sama dengan kasus pertama.

Data lama **tidak boleh** tersentuh sampai seluruh validasi lolos. Setelah lolos, tampilkan dialog konfirmasi "Impor akan mengganti seluruh data yang ada sekarang. Lanjutkan?" lalu panggil `gantiSemua` dan `service.muat(DateTime.now())`.

- [ ] **Step 3: Verifikasi putaran penuh**

Catat beberapa habit, ekspor, hapus data aplikasi lewat pengaturan Android, jalankan lagi, lewati onboarding, lalu impor file tadi.

Diharapkan: level, streak, jatah jeda, medali, dan seluruh riwayat kembali persis seperti sebelumnya.

- [ ] **Step 4: Commit**

```bash
git add lib/services/backup_service.dart lib/screens/pengaturan
git commit -m "feat: tambah ekspor dan impor cadangan JSON"
```

---

### Task 17: Isi kartu penjelasan

**Files:**
- Create: `lib/data/habit_info.dart`
- Modify: `lib/widgets/kartu_habit.dart`
- Test: `test/logic/habit_info_test.dart`

**Interfaces:**
- Produces: `class HabitInfo { final String kenapaPenting; final String manfaat; final String caraMudah; }` dan `const Map<String, HabitInfo> habitInfo`

- [ ] **Step 1: Tulis test yang gagal**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/data/habit_info.dart';
import 'package:habit_leveling/data/habit_preset.dart';

void main() {
  test('setiap preset punya kartu penjelasan yang terisi', () {
    for (final h in habitPreset) {
      final info = habitInfo[h.key];
      expect(info, isNotNull, reason: 'kartu info hilang untuk ${h.key}');
      expect(info!.kenapaPenting.trim(), isNotEmpty, reason: h.key);
      expect(info.manfaat.trim(), isNotEmpty, reason: h.key);
      expect(info.caraMudah.trim(), isNotEmpty, reason: h.key);
    }
  });

  test('tidak ada entri info untuk kunci yang bukan preset', () {
    final kunciPreset = habitPreset.map((h) => h.key).toSet();
    expect(habitInfo.keys.every(kunciPreset.contains), isTrue);
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan gagal**

```bash
flutter test test/logic/habit_info_test.dart
```

Diharapkan: GAGAL, `habit_info.dart` belum ada.

- [ ] **Step 3: Tulis isinya**

Enam belas entri, satu per kunci preset. Panduan isi:

- **kenapaPenting** — satu sampai tiga kalimat, alasan fisiologis atau perilaku. Contoh untuk `tidur_sebelum_23`: "Tubuh melepas hormon pertumbuhan dan memperbaiki jaringan paling banyak di paruh pertama malam. Tidur jam 1 lalu bangun jam 9 tidak sama dengan tidur jam 11 lalu bangun jam 7, walaupun durasinya sama."
- **manfaat** — apa yang user rasakan, bukan istilah medis.
- **caraMudah** — satu langkah paling kecil yang bisa dilakukan hari ini.

`isi_piringku` boleh paling panjang karena merupakan panduan Kemenkes dengan proporsi spesifik: separuh piring sayur dan buah, separuh lagi makanan pokok dan lauk berprotein. Jangan mengarang angka gizi yang tidak ada di panduan resmi.

- [ ] **Step 4: Sambungkan ke kartu habit**

Ikon `?` pada `KartuHabit` membuka `showModalBottomSheet` berisi tiga bagian berjudul **Kenapa penting**, **Manfaat**, dan **Cara mudah**. Habit custom tidak punya entri, jadi ikonnya disembunyikan bila `habitInfo[habit.key] == null`.

- [ ] **Step 5: Jalankan test**

```bash
flutter test
```

Diharapkan: seluruh test lulus, termasuk pemeriksaan 16 kartu terisi.

- [ ] **Step 6: Commit**

```bash
git add lib/data/habit_info.dart lib/widgets/kartu_habit.dart test/logic/habit_info_test.dart
git commit -m "feat: tambah isi kartu penjelasan 16 habit"
```

---

### Task 18: Verifikasi rilis

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Jalankan seluruh gerbang**

```bash
flutter analyze && flutter test && flutter build apk --release
```

Diharapkan: `No issues found!`, seluruh test lulus, APK terbentuk.

- [ ] **Step 2: Periksa kriteria terima satu per satu**

Buka `docs/PRD.md` bagian Kriteria terima dan uji kesepuluh butirnya di **release build** pada perangkat fisik. Butir 6 (notifikasi menyala di release build) dan butir 9 (mengubah target tidak mengubah riwayat) adalah yang paling gampang lolos dari pengujian biasa — jangan dilewati.

Untuk butir 9: catat habit langkah sampai selesai hari ini, catat level pilar Gerak, lalu ubah target langkah dari 5.000 ke 8.000 di pengaturan, kembali ke beranda. Level pilar Gerak **tidak boleh** berubah, dan habit hari ini **tetap** berstatus selesai.

- [ ] **Step 3: Perbarui status di README**

Ganti bagian Status dari "Tahap desain. Belum ada kode." menjadi keterangan versi pertama beserta tanggalnya.

- [ ] **Step 4: Commit dan buka PR**

```bash
git add -A
git commit -m "docs: perbarui status proyek ke versi pertama"
git push -u origin <nama-branch>
gh pr create --title "Habit Leveling versi pertama" --body "Implementasi lengkap sesuai docs/design.md dan docs/plan.md."
```

- [ ] **Step 5: Tandai rilis setelah PR ter-merge**

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Catatan penutup

Rencana ini tidak mencakup: berat badan, BMI, kalori, Health Connect, akun, sinkronisasi cloud, fitur sosial, tantangan mingguan bertema, avatar visual, iOS, iklan. Alasan setiap penolakan ada di `docs/decisions.md` — periksa di sana lebih dulu sebelum mengusulkan menambahkannya.
