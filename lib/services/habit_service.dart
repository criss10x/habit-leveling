import 'package:flutter/foundation.dart';

import '../data/achievement_preset.dart';
import '../data/habit.dart';
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
    final mulai = terakhir == null
        ? hariIni.subtract(const Duration(days: 1))
        : DateTime.parse(terakhir);

    final tanggalUrut = <String>[];
    var kursor = mulai.add(const Duration(days: 1));
    while (kursor.isBefore(hariIni)) {
      tanggalUrut.add(tanggalKe(kursor));
      kursor = kursor.add(const Duration(days: 1));
    }
    if (tanggalUrut.isEmpty) {
      // Belum pernah diproses dan belum ada satu hari penuh pun untuk
      // diproses (mis. buka pertama kali). Simpan jangkar `mulai` supaya
      // panggilan berikutnya menghitung rentang relatif terhadap tanggal
      // tetap ini, bukan terhadap "kemarin" yang bergeser setiap hari —
      // tanpa ini `terakhir_diproses` tidak akan pernah tersimpan dan
      // rentang yang dihitung akan selalu kosong.
      if (terakhir == null) {
        await _db.setMeta('terakhir_diproses', tanggalKe(mulai));
      }
      return;
    }

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
}
