import '../logic/achievement.dart';
import 'habit.dart';

class Medali {
  const Medali({
    required this.key,
    required this.nama,
    required this.syarat,
    required this.tercapai,
  });

  final String key;
  final String nama;
  final String syarat;
  final bool Function(RingkasanKeadaan) tercapai;
}

Medali _streak(int hari, String nama) => Medali(
      key: 'streak_$hari',
      nama: nama,
      syarat: '$hari hari beruntun',
      tercapai: (k) => k.streak >= hari,
    );

Medali _levelPilar(Pilar pilar, String label, int level) => Medali(
      key: 'level_${pilar.name}_$level',
      nama: '$label Lv.$level',
      syarat: 'Pilar $label mencapai level $level',
      tercapai: (k) => k.level(pilar) >= level,
    );

const _labelPilar = {
  Pilar.gerak: 'Gerak',
  Pilar.makan: 'Makan',
  Pilar.tidur: 'Tidur',
  Pilar.pikiran: 'Pikiran',
};

final List<Medali> medaliPreset = [
  _streak(7, 'Seminggu Utuh'),
  _streak(30, 'Sebulan Utuh'),
  _streak(100, 'Seratus Hari'),
  _streak(365, 'Setahun Penuh'),

  for (final entri in _labelPilar.entries)
    for (final level in [5, 10, 25])
      _levelPilar(entri.key, entri.value, level),

  Medali(
    key: 'global_10',
    nama: 'Pendaki',
    syarat: 'Level global 10',
    tercapai: (k) => k.levelGlobal >= 10,
  ),
  Medali(
    key: 'global_25',
    nama: 'Penempuh',
    syarat: 'Level global 25',
    tercapai: (k) => k.levelGlobal >= 25,
  ),
  Medali(
    key: 'global_50',
    nama: 'Penguasa Kebiasaan',
    syarat: 'Level global 50',
    tercapai: (k) => k.levelGlobal >= 50,
  ),

  Medali(
    key: 'akumulasi_langkah',
    nama: 'Setengah Juta Langkah',
    syarat: 'Total 500.000 langkah',
    tercapai: (k) => k.total('langkah_harian') >= 500000,
  ),
  Medali(
    key: 'akumulasi_air',
    nama: 'Seribu Gelas',
    syarat: 'Total 1.000 gelas air',
    tercapai: (k) => k.total('minum_air') >= 1000,
  ),
  Medali(
    key: 'akumulasi_olahraga',
    nama: 'Seribu Menit',
    syarat: 'Total 1.000 menit olahraga',
    tercapai: (k) => k.total('olahraga') >= 1000,
  ),
  Medali(
    key: 'akumulasi_syukur',
    nama: 'Tiga Ratus Syukur',
    syarat: 'Total 300 hal dalam jurnal syukur',
    tercapai: (k) => k.total('jurnal_syukur') >= 300,
  ),

  Medali(
    key: 'seimbang_5',
    nama: 'Empat Kaki',
    syarat: 'Keempat pilar mencapai level 5',
    tercapai: (k) => k.levelPilar.values.every((l) => l >= 5),
  ),
  Medali(
    key: 'seimbang_10',
    nama: 'Empat Pilar Kokoh',
    syarat: 'Keempat pilar mencapai level 10',
    tercapai: (k) => k.levelPilar.values.every((l) => l >= 10),
  ),
  Medali(
    key: 'seimbang_skor',
    nama: 'Nyaris Rata',
    syarat: 'Skor Keseimbangan menyentuh 90%',
    tercapai: (k) => k.skorKeseimbangan >= 90,
  ),

  Medali(
    key: 'jeda_pertama',
    nama: 'Istirahat Itu Boleh',
    syarat: 'Memakai jeda untuk pertama kali',
    tercapai: (k) => k.pernahPakaiJeda,
  ),
  Medali(
    key: 'bangkit',
    nama: 'Bangkit Lagi',
    syarat: 'Kembali ke streak 7 setelah pernah putus',
    tercapai: (k) => k.pernahPutus && k.streak >= 7,
  ),

  Medali(
    key: 'sempurna_1',
    nama: 'Hari Sempurna',
    syarat: 'Seluruh habit aktif selesai dalam satu hari',
    tercapai: (k) => k.hariSempurna >= 1,
  ),
  Medali(
    key: 'sempurna_10',
    nama: 'Sepuluh Hari Sempurna',
    syarat: 'Sepuluh hari sempurna',
    tercapai: (k) => k.hariSempurna >= 10,
  ),
];
