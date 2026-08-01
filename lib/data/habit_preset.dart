import 'habit.dart';

const int maksHabitAktifDefault = 8;
const int maksHabitCustom = 5;
const int xpDasarCustom = 5;

const List<String> saranAwal = [
  'langkah_harian',
  'minum_air',
  'isi_piringku',
  'tidur_sebelum_23',
  'napas_meditasi',
];

const List<Habit> habitPreset = [
  // Gerak
  Habit(
    key: 'langkah_harian',
    nama: 'Langkah harian',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 5000,
    satuan: 'langkah',
    xpDasar: 10,
    sumber: 'pedometer',
  ),
  Habit(
    key: 'olahraga',
    nama: 'Olahraga',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 10,
    satuan: 'menit',
    xpDasar: 15,
  ),
  Habit(
    key: 'peregangan_pagi',
    nama: 'Peregangan pagi',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),
  Habit(
    key: 'peregangan_malam',
    nama: 'Peregangan sebelum tidur',
    pilar: Pilar.gerak,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),

  // Makan
  Habit(
    key: 'isi_piringku',
    nama: 'Makan sesuai Isi Piringku',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 2,
    satuan: 'makan utama',
    xpDasar: 15,
  ),
  Habit(
    key: 'prioritas_protein',
    nama: 'Prioritas protein',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 2,
    satuan: 'makan utama',
    xpDasar: 10,
  ),
  Habit(
    key: 'minum_air',
    nama: 'Minum air',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 8,
    satuan: 'gelas',
    xpDasar: 10,
  ),
  Habit(
    key: 'batasi_gula_olahan',
    nama: 'Batasi gula tambahan & makanan olahan',
    pilar: Pilar.makan,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),

  // Tidur
  Habit(
    key: 'tidur_sebelum_23',
    nama: 'Tidur sebelum jam 23',
    pilar: Pilar.tidur,
    tipe: TipeHabit.waktu,
    target: 1380, // 23:00
    satuan: 'jam',
    xpDasar: 15,
  ),
  Habit(
    key: 'durasi_tidur',
    nama: 'Durasi tidur',
    pilar: Pilar.tidur,
    tipe: TipeHabit.hitung,
    target: 420,
    satuan: 'menit',
    xpDasar: 15,
  ),
  Habit(
    key: 'bangun_konsisten',
    nama: 'Bangun jam konsisten',
    pilar: Pilar.tidur,
    tipe: TipeHabit.waktu,
    target: 360, // 06:00
    satuan: 'jam',
    xpDasar: 10,
  ),
  Habit(
    key: 'tanpa_layar_sebelum_tidur',
    nama: 'Tanpa layar 30 menit sebelum tidur',
    pilar: Pilar.tidur,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),

  // Pikiran
  Habit(
    key: 'napas_meditasi',
    nama: 'Napas atau meditasi',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 5,
    satuan: 'menit',
    xpDasar: 10,
  ),
  Habit(
    key: 'jurnal_syukur',
    nama: 'Jurnal syukur',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 3,
    satuan: 'hal',
    xpDasar: 10,
  ),
  Habit(
    key: 'batas_medsos',
    nama: 'Batas medsos di bawah 2 jam',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),
  Habit(
    key: 'kena_matahari',
    nama: 'Keluar rumah kena matahari',
    pilar: Pilar.pikiran,
    tipe: TipeHabit.hitung,
    target: 1,
    satuan: 'kali',
    xpDasar: 10,
  ),
];
