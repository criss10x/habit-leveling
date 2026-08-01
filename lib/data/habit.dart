enum Pilar { gerak, makan, tidur, pikiran }

enum TipeHabit { hitung, waktu }

class Habit {
  const Habit({
    this.id,
    required this.key,
    required this.nama,
    required this.pilar,
    required this.tipe,
    required this.target,
    required this.satuan,
    required this.xpDasar,
    this.sumber = 'manual',
    this.aktif = false,
    this.isCustom = false,
  });

  final int? id;
  final String key;
  final String nama;
  final Pilar pilar;
  final TipeHabit tipe;

  /// Target untuk tipe hitung, atau ambang dalam menit untuk tipe waktu.
  final int target;
  final String satuan;
  final int xpDasar;
  final String sumber;
  final bool aktif;
  final bool isCustom;

  Habit salin({int? id, int? target, bool? aktif}) => Habit(
        id: id ?? this.id,
        key: key,
        nama: nama,
        pilar: pilar,
        tipe: tipe,
        target: target ?? this.target,
        satuan: satuan,
        xpDasar: xpDasar,
        sumber: sumber,
        aktif: aktif ?? this.aktif,
        isCustom: isCustom,
      );
}
