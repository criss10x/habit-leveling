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

    test('menahan lalu lanjut sampai kelipatan tujuh tetap memberi jeda', () {
      final ditahan = prosesSatuHari(
        const KeadaanStreak(streak: 6, jeda: 1),
        false,
      );
      expect(ditahan.streak, 6);
      expect(ditahan.jeda, 0);

      final hasil = prosesSatuHari(ditahan, true);
      expect(hasil.streak, 7);
      expect(hasil.jeda, 1);
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

    test('rentang tercampur: lengkap, lengkap, kosong, lengkap, lengkap, kosong', () {
      final tanggal = [
        '2026-08-01',
        '2026-08-02',
        '2026-08-03',
        '2026-08-04',
        '2026-08-05',
        '2026-08-06',
      ];
      final questSelesaiMap = {
        '2026-08-01': true,
        '2026-08-02': true,
        '2026-08-03': false,
        '2026-08-04': true,
        '2026-08-05': true,
        '2026-08-06': false,
      };
      final hasil = prosesRentang(
        const KeadaanStreak(streak: 5, jeda: 0),
        tanggal,
        (t) => questSelesaiMap[t] ?? false,
      );
      expect(hasil.keadaan.streak, 0);
      expect(hasil.keadaan.jeda, 0);
      expect(hasil.tanggalDijeda, ['2026-08-03']);
      expect(hasil.keadaan.pernahPutus, isTrue);
      expect(hasil.keadaan.pernahPakaiJeda, isTrue);
    });
  });
}
