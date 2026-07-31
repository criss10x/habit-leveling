const int maksJeda = 3;

/// Melacak keadaan streak pada hari tertentu.
/// Streak yang ditahan oleh jeda tetap tak berubah;
/// pernahPutus tetap false jika streak belum pernah lebih dari nol.
class KeadaanStreak {
  const KeadaanStreak({
    required this.streak,
    required this.jeda,
    this.pernahPutus = false,
    this.pernahPakaiJeda = false,
  });

  final int streak;
  final int jeda;
  final bool pernahPutus;
  final bool pernahPakaiJeda;
}

/// Hasil proses satu atau lebih hari: keadaan akhir dan daftar tanggal yang memakai jeda.
class HasilProses {
  const HasilProses(this.keadaan, this.tanggalDijeda);

  final KeadaanStreak keadaan;
  final List<String> tanggalDijeda;
}

/// Proses satu hari: naikkan streak jika quest selesai,
/// atau gunakan jeda jika tersedia, atau reset ke 0.
KeadaanStreak prosesSatuHari(KeadaanStreak awal, bool questSelesai) {
  if (questSelesai) {
    final streak = awal.streak + 1;
    final dapatJeda = streak % 7 == 0 && awal.jeda < maksJeda;
    return KeadaanStreak(
      streak: streak,
      jeda: dapatJeda ? awal.jeda + 1 : awal.jeda,
      pernahPutus: awal.pernahPutus,
      pernahPakaiJeda: awal.pernahPakaiJeda,
    );
  }
  if (awal.jeda > 0) {
    return KeadaanStreak(
      streak: awal.streak,
      jeda: awal.jeda - 1,
      pernahPutus: awal.pernahPutus,
      pernahPakaiJeda: true,
    );
  }
  return KeadaanStreak(
    streak: 0,
    jeda: 0,
    // Streak yang memang belum pernah jalan tidak dihitung "putus".
    pernahPutus: awal.pernahPutus || awal.streak > 0,
    pernahPakaiJeda: awal.pernahPakaiJeda,
  );
}

/// Proses rentang tanggal dalam satu panggilan.
/// Menangani celah lama (misalnya, 30 hari tanpa buka aplikasi)
/// dengan memproses setiap hari melalui prosesSatuHari.
HasilProses prosesRentang(
  KeadaanStreak awal,
  List<String> tanggalUrut,
  bool Function(String tanggal) questSelesai,
) {
  var keadaan = awal;
  final dijeda = <String>[];
  for (final tanggal in tanggalUrut) {
    final selesai = questSelesai(tanggal);
    final sebelum = keadaan;
    keadaan = prosesSatuHari(keadaan, selesai);
    if (!selesai && keadaan.jeda < sebelum.jeda) {
      dijeda.add(tanggal);
    }
  }
  return HasilProses(keadaan, dijeda);
}
