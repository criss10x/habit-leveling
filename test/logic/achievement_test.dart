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

  test('seimbang_5 tidak boleh diberikan jika ada pilar yang absen', () {
    // Membuat RingkasanKeadaan dengan pilar pikiran tidak ada di map,
    // sementara tiga pilar lain di level 5.
    // Dengan cara kerja lama (menggunakan .values.every), test ini akan
    // GAGAL karena pilar absen tidak diperhatikan dan test vacuously true.
    const keadaanTanpaPikiran = RingkasanKeadaan(
      levelPilar: {
        Pilar.gerak: 5,
        Pilar.makan: 5,
        Pilar.tidur: 5,
        // Pilar.pikiran TIDAK ADA
      },
      levelGlobal: 1,
      streak: 0,
      skorKeseimbangan: 100,
      akumulasi: {},
      hariSempurna: 0,
      pernahPutus: false,
      pernahPakaiJeda: false,
    );

    final kunci = medaliBaru(keadaanTanpaPikiran, {}).map((m) => m.key);
    expect(kunci, isNot(contains('seimbang_5')));
  });

  test('medali global level terbuka di ambangnya', () {
    // global_10
    expect(medaliBaru(ringkasan(global: 9), {}).map((m) => m.key),
        isNot(contains('global_10')));
    expect(medaliBaru(ringkasan(global: 10), {}).map((m) => m.key),
        contains('global_10'));

    // global_25
    expect(medaliBaru(ringkasan(global: 24), {}).map((m) => m.key),
        isNot(contains('global_25')));
    expect(medaliBaru(ringkasan(global: 25), {}).map((m) => m.key),
        contains('global_25'));

    // global_50
    expect(medaliBaru(ringkasan(global: 49), {}).map((m) => m.key),
        isNot(contains('global_50')));
    expect(medaliBaru(ringkasan(global: 50), {}).map((m) => m.key),
        contains('global_50'));
  });

  test('medali akumulasi terbuka di ambangnya dengan kunci yang tepat', () {
    // akumulasi_air (1.000 gelas)
    expect(
        medaliBaru(ringkasan(akumulasi: {'minum_air': 999}), {})
            .map((m) => m.key),
        isNot(contains('akumulasi_air')));
    expect(
        medaliBaru(ringkasan(akumulasi: {'minum_air': 1000}), {})
            .map((m) => m.key),
        contains('akumulasi_air'));

    // akumulasi_olahraga (1.000 menit)
    expect(
        medaliBaru(ringkasan(akumulasi: {'olahraga': 999}), {})
            .map((m) => m.key),
        isNot(contains('akumulasi_olahraga')));
    expect(
        medaliBaru(ringkasan(akumulasi: {'olahraga': 1000}), {})
            .map((m) => m.key),
        contains('akumulasi_olahraga'));

    // akumulasi_syukur (300 hal)
    expect(
        medaliBaru(ringkasan(akumulasi: {'jurnal_syukur': 299}), {})
            .map((m) => m.key),
        isNot(contains('akumulasi_syukur')));
    expect(
        medaliBaru(ringkasan(akumulasi: {'jurnal_syukur': 300}), {})
            .map((m) => m.key),
        contains('akumulasi_syukur'));
  });

  test('medali seimbang_skor terbuka di ambangnya', () {
    expect(medaliBaru(ringkasan(skor: 89), {}).map((m) => m.key),
        isNot(contains('seimbang_skor')));
    expect(medaliBaru(ringkasan(skor: 90), {}).map((m) => m.key),
        contains('seimbang_skor'));
  });

  test('medali jeda_pertama terbuka saat pertama kali memakai jeda', () {
    expect(medaliBaru(ringkasan(pernahPakaiJeda: false), {}).map((m) => m.key),
        isNot(contains('jeda_pertama')));
    expect(medaliBaru(ringkasan(pernahPakaiJeda: true), {}).map((m) => m.key),
        contains('jeda_pertama'));
  });

  test('medali sempurna terbuka di ambangnya', () {
    // sempurna_1
    expect(medaliBaru(ringkasan(hariSempurna: 0), {}).map((m) => m.key),
        isNot(contains('sempurna_1')));
    expect(medaliBaru(ringkasan(hariSempurna: 1), {}).map((m) => m.key),
        contains('sempurna_1'));

    // sempurna_10
    expect(medaliBaru(ringkasan(hariSempurna: 9), {}).map((m) => m.key),
        isNot(contains('sempurna_10')));
    expect(medaliBaru(ringkasan(hariSempurna: 10), {}).map((m) => m.key),
        contains('sempurna_10'));
  });

  test('medali streak 30, 100, 365 terbuka di ambangnya', () {
    // streak_30
    expect(medaliBaru(ringkasan(streak: 29), {}).map((m) => m.key),
        isNot(contains('streak_30')));
    expect(medaliBaru(ringkasan(streak: 30), {}).map((m) => m.key),
        contains('streak_30'));

    // streak_100
    expect(medaliBaru(ringkasan(streak: 99), {}).map((m) => m.key),
        isNot(contains('streak_100')));
    expect(medaliBaru(ringkasan(streak: 100), {}).map((m) => m.key),
        contains('streak_100'));

    // streak_365
    expect(medaliBaru(ringkasan(streak: 364), {}).map((m) => m.key),
        isNot(contains('streak_365')));
    expect(medaliBaru(ringkasan(streak: 365), {}).map((m) => m.key),
        contains('streak_365'));
  });
}
