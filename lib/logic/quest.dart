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

/// Sebuah hari sempurna bila seluruh habit yang aktif PADA HARI ITU mencapai
/// xp dasarnya. Perbandingan memakai xp beku, bukan target yang berlaku
/// sekarang — target boleh berubah, dan riwayat tidak boleh ikut berubah.
///
/// Fungsi yang sama dipakai untuk menjawab "quest selesai": panggil dengan
/// `questIds` sebagai argumen pertama.
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
