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

  test('setiap kunci saran awal ada di habitPreset', () {
    final presetKeys = habitPreset.map((h) => h.key).toSet();
    for (final key in saranAwal) {
      expect(
        presetKeys.contains(key),
        true,
        reason: 'kunci $key ada di saranAwal tapi tidak ada di habitPreset',
      );
    }
  });

  test('nilai penting habit tersimpan dengan benar', () {
    final habitByKey = {for (final h in habitPreset) h.key: h};

    // langkah_harian
    expect(habitByKey['langkah_harian']?.target, 5000);
    expect(habitByKey['langkah_harian']?.satuan, 'langkah');
    expect(habitByKey['langkah_harian']?.tipe, TipeHabit.hitung);
    expect(habitByKey['langkah_harian']?.xpDasar, 10);

    // durasi_tidur
    expect(habitByKey['durasi_tidur']?.target, 420);
    expect(habitByKey['durasi_tidur']?.satuan, 'menit');
    expect(habitByKey['durasi_tidur']?.tipe, TipeHabit.hitung);
    expect(habitByKey['durasi_tidur']?.xpDasar, 15);

    // tidur_sebelum_23
    expect(habitByKey['tidur_sebelum_23']?.target, 1380);
    expect(habitByKey['tidur_sebelum_23']?.satuan, '');
    expect(habitByKey['tidur_sebelum_23']?.tipe, TipeHabit.waktu);
    expect(habitByKey['tidur_sebelum_23']?.xpDasar, 15);

    // bangun_konsisten
    expect(habitByKey['bangun_konsisten']?.target, 360);
    expect(habitByKey['bangun_konsisten']?.satuan, '');
    expect(habitByKey['bangun_konsisten']?.tipe, TipeHabit.waktu);
    expect(habitByKey['bangun_konsisten']?.xpDasar, 10);

    // minum_air
    expect(habitByKey['minum_air']?.target, 8);
    expect(habitByKey['minum_air']?.satuan, 'gelas');
    expect(habitByKey['minum_air']?.tipe, TipeHabit.hitung);
    expect(habitByKey['minum_air']?.xpDasar, 10);
  });
}
