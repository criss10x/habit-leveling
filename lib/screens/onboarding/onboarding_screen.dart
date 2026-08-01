import 'package:flutter/material.dart';

import '../../data/habit.dart';
import '../../data/habit_preset.dart';
import '../../db/database.dart';
import '../../services/habit_service.dart';
import '../kerangka.dart';

/// Onboarding tiga langkah: sambutan, pemilihan habit, jam pengingat.
///
/// Izin notifikasi dan pedometer sengaja TIDAK diminta di sini — masing-
/// masing service memintanya sendiri saat pertama kali dibutuhkan.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.db, required this.service});

  final AppDatabase db;
  final HabitService service;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  // Preset habit sudah dimuat sekali di initState; diagram pilihan (id ->
  // tercentang atau tidak) dibangun begitu future itu selesai.
  late final Future<List<Habit>> _habitFuture;
  final Map<int, bool> _centang = {};

  int _langkah = 0;
  TimeOfDay _jam = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _habitFuture = widget.db.semuaHabit().then((list) {
      for (final h in list) {
        // id selalu ada: baris datang langsung dari kolom AUTOINCREMENT.
        _centang[h.id!] = h.aktif;
      }
      return list;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _majuHalaman() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _mundurHalaman() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onCentang(Habit h, bool? nilai) {
    if (nilai == true) {
      final jumlahAktif = _centang.values.where((c) => c).length;
      if (jumlahAktif >= maksHabitAktifDefault) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maksimal 8 habit aktif. Nonaktifkan salah satu dulu.',
            ),
          ),
        );
        return;
      }
    }
    setState(() => _centang[h.id!] = nilai ?? false);
  }

  Future<void> _pilihJam() async {
    final dipilih = await showTimePicker(context: context, initialTime: _jam);
    if (dipilih == null) return;
    if (!mounted) return;
    setState(() => _jam = dipilih);
  }

  Future<void> _selesai(List<Habit> habitList) async {
    for (final h in habitList) {
      final baru = _centang[h.id!] ?? false;
      if (baru != h.aktif) {
        await widget.db.setAktif(h.id!, baru);
      }
    }
    final jamText = '${_jam.hour.toString().padLeft(2, '0')}:'
        '${_jam.minute.toString().padLeft(2, '0')}';
    await widget.db.setMeta('jam_pengingat', jamText);
    await widget.db.setMeta('onboarding_selesai', '1');
    await widget.service.muat(DateTime.now());
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Kerangka(db: widget.db, service: widget.service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _langkah > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _mundurHalaman,
                )
              : null,
          title: Text('Langkah ${_langkah + 1} dari 3'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<Habit>>(
            future: _habitFuture,
            builder: (context, snapshot) {
              final habitList = snapshot.data;
              if (habitList == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _langkah = i),
                      children: [
                        _langkahSambutan(),
                        _langkahPemilihanHabit(habitList),
                        _langkahJamPengingat(),
                      ],
                    ),
                  ),
                  _tombolBawah(habitList),
                ],
              );
            },
          ),
        ),
      );

  Widget _langkahSambutan() => ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Selamat datang di Habit Leveling',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Kebiasaan sehat dibagi ke empat pilar. Kamu naik level di '
            'masing-masing pilar dengan mencatat habit harian.',
          ),
          SizedBox(height: 20),
          _PilarSambutan(
            judul: 'Gerak',
            teks: 'Langkah harian, olahraga, dan peregangan supaya tubuh '
                'tetap aktif setiap hari.',
          ),
          _PilarSambutan(
            judul: 'Makan',
            teks: 'Pola makan seimbang, cukup protein, dan cukup minum air '
                'putih.',
          ),
          _PilarSambutan(
            judul: 'Tidur',
            teks: 'Jam tidur dan bangun yang konsisten supaya istirahat '
                'benar-benar memulihkan.',
          ),
          _PilarSambutan(
            judul: 'Pikiran',
            teks: 'Jeda dari layar, bersyukur, dan waktu tenang untuk '
                'menjaga ketenangan pikiran.',
          ),
        ],
      );

  Widget _langkahPemilihanHabit(List<Habit> habitList) {
    final perPilar = <Pilar, List<Habit>>{
      for (final p in Pilar.values)
        p: habitList.where((h) => h.pilar == p).toList(),
    };
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Pilih habit yang ingin kamu mulai. Lima habit di bawah ini '
            'sudah tercentang sebagai saran, dan kamu bisa aktifkan sampai '
            'maksimal 8 habit.',
          ),
        ),
        for (final p in Pilar.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              _namaPilar(p),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final h in perPilar[p]!)
            CheckboxListTile(
              title: Text(h.nama),
              subtitle: Text(_subjudulHabit(h)),
              value: _centang[h.id!] ?? false,
              onChanged: (v) => _onCentang(h, v),
            ),
        ],
      ],
    );
  }

  String _subjudulHabit(Habit h) => h.tipe == TipeHabit.waktu
      ? 'Ambang jam ${_formatMenit(h.target)}'
      : 'Target ${h.target} ${h.satuan}'.trim();

  String _formatMenit(int menit) =>
      '${(menit ~/ 60).toString().padLeft(2, '0')}:'
      '${(menit % 60).toString().padLeft(2, '0')}';

  String _namaPilar(Pilar p) => switch (p) {
        Pilar.gerak => 'Gerak',
        Pilar.makan => 'Makan',
        Pilar.tidur => 'Tidur',
        Pilar.pikiran => 'Pikiran',
      };

  Widget _langkahJamPengingat() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Jam pengingat harian',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kami akan mengingatkan kamu untuk mencatat habit pada jam '
              'ini setiap hari.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text(_jam.format(context)),
              onPressed: _pilihJam,
            ),
          ],
        ),
      );

  Widget _tombolBawah(List<Habit> habitList) {
    final adaTercentang = _centang.values.any((c) => c);
    final String label;
    final VoidCallback? aksi;
    switch (_langkah) {
      case 0:
        label = 'Lanjut';
        aksi = _majuHalaman;
      case 1:
        label = 'Lanjut';
        aksi = adaTercentang ? _majuHalaman : null;
      default:
        label = 'Selesai';
        aksi = () => _selesai(habitList);
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: aksi, child: Text(label)),
      ),
    );
  }
}

class _PilarSambutan extends StatelessWidget {
  const _PilarSambutan({required this.judul, required this.teks});

  final String judul;
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(teks),
          ],
        ),
      );
}
