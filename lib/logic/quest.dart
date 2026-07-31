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

/// Hash yang stabil antar proses. `String.hashCode` bawaan Dart tidak
/// dijamin sama antar eksekusi, dan quest harus terkunci oleh tanggal.
int _seed(String tanggal, int habitId) {
  var h = 17;
  for (final c in tanggal.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  // Rotasi habitId berdasarkan hash tanggal untuk menciptakan permutasi yang berbeda
  // Ini memastikan quest selection berubah antar tanggal meskipun semua habit seri
  final rotated = ((habitId - 1 + (h % 8)) % 8) + 1;
  return (rotated * 1000 + (h % 1000)) & 0x7fffffff;
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
