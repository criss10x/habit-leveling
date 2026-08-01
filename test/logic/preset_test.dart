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
