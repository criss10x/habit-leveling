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
