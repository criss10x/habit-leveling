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

    test('nilai negatif memberi nol, bukan xp negatif', () {
      expect(
        hitungXp(tipe: TipeHabit.hitung, nilai: -5, target: 8, xpDasar: 10),
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

    test('tercapaiWaktu di batas geser (ambang - 720) adalah true', () {
      expect(tercapaiWaktu(660, 1380), isTrue);
    });

    test('tercapaiWaktu di ambang tepat adalah false', () {
      expect(tercapaiWaktu(1380, 1380), isFalse);
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

    test('levelDariXp dengan xp negatif mengembalikan 1', () {
      expect(levelDariXp(-100), 1);
    });

    test('levelDariXp tetap benar untuk level sangat besar', () {
      expect(levelDariXp(xpUntukLevel(1000)), 1000);
    });
  });

  group('skor keseimbangan', () {
    test('user baru mendapat seratus', () {
      expect(skorKeseimbangan([1, 1, 1, 1]), 100);
    });

    test('timpang menurunkan skor', () {
      expect(skorKeseimbangan([20, 10, 5, 5]), 25);
    });

    test('list kosong mengembalikan 100 tanpa throw', () {
      expect(skorKeseimbangan([]), 100);
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
