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

  test('id non-kontinu tetap menghasilkan variasi antar tanggal', () {
    // Id realistis dari autoincrement SQLite: tidak kontinu 1..N, dan
    // beberapa berjarak kelipatan 8 satu sama lain (mis. 3 & 11, 19 & 27) —
    // persis pola yang membuat implementasi berbasis rotasi mod-8 gagal,
    // karena selisih kelipatan 8 membuat _seed collide untuk id berbeda.
    final ids = [3, 11, 19, 27, 35, 43];
    final kandidat = ids.map((id) => k(id, Pilar.gerak, 5, 3)).toList();
    final hasil = <String>{};
    for (var hari = 1; hari <= 20; hari++) {
      final tanggal = '2026-08-${hari.toString().padLeft(2, '0')}';
      final quest = pilihQuest(kandidat, tanggal);
      expect(quest.every(ids.contains), isTrue);
      hasil.add(quest.join(','));
    }
    expect(hasil.length, greaterThan(1));
  });

  test('hasilnya sama untuk tanggal yang sama dengan id non-kontinu', () {
    final ids = [3, 11, 19, 27, 35, 43];
    final kandidat = ids.map((id) => k(id, Pilar.gerak, 5, 3)).toList();
    final pertama = pilihQuest(kandidat, '2026-08-01');
    final kedua = pilihQuest(kandidat, '2026-08-01');
    expect(pertama, kedua);
  });

  test('urutan level pilar tidak terganggu oleh tie-break tanggal', () {
    final kandidat = [
      k(3, Pilar.tidur, 2, 0),
      k(4, Pilar.tidur, 2, 1),
      k(1, Pilar.gerak, 20, 7),
      k(2, Pilar.gerak, 20, 7),
      k(5, Pilar.makan, 5, 3),
    ];
    for (var hari = 1; hari <= 5; hari++) {
      final tanggal = '2026-09-0$hari';
      final hasil = pilihQuest(kandidat, tanggal);
      expect(hasil, containsAll([3, 4]));
      expect(hasil, isNot(contains(1)));
      expect(hasil, isNot(contains(2)));
    }
  });
}
