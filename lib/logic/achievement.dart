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
