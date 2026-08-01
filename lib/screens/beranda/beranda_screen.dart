import 'package:flutter/material.dart';

import '../../data/habit.dart';
import '../../db/database.dart';
import '../../services/habit_service.dart';
import '../../widgets/bar_xp.dart';
import '../../widgets/kartu_habit.dart';
import '../../widgets/popup_medali.dart';

/// Beranda: level global dan bar XP, streak dan jeda, Quest Hari Ini (tiga
/// kartu besar), lalu Habit Lainnya sebagai baris ringkas.
///
/// Seluruh data berasal dari satu `ValueListenableBuilder` atas
/// `service.keadaan` — tidak ada `setState` yang membaca database langsung.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.db, required this.service});

  final AppDatabase db;
  final HabitService service;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  Future<void> _catat(Habit habit, int nilai) async {
    await widget.service.catatHabit(habit.id!, nilai, DateTime.now());
    final medaliBaru = await widget.service.periksaMedali(DateTime.now());
    if (medaliBaru.isEmpty) return;
    if (!mounted) return;
    await tampilkanPopupMedali(context, medaliBaru);
  }

  // Placeholder — kartu penjelasan sesungguhnya ditulis di Task 17.
  void _info(Habit habit) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(habit.nama),
        content: const Text('Penjelasan habit ini segera hadir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: widget.service.keadaan,
        builder: (context, keadaan, _) {
          if (keadaan == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final questIds = keadaan.hariIni.questIds.toSet();
          final aktif = keadaan.habit.where((h) => h.aktif).toList();
          final quest = aktif.where((h) => questIds.contains(h.id)).toList();
          final lainnya =
              aktif.where((h) => !questIds.contains(h.id)).toList();
          final tema = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BarXp(
                xp: keadaan.xpGlobal,
                level: keadaan.levelGlobal,
                global: true,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Text(
                    'Streak ${keadaan.streakTampil} hari',
                    style: tema.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  const Icon(Icons.shield_outlined),
                  const SizedBox(width: 4),
                  Text('${keadaan.jeda} jeda tersisa'),
                ],
              ),
              const SizedBox(height: 24),
              if (quest.isNotEmpty) ...[
                Text('Quest Hari Ini', style: tema.textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final h in quest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KartuHabit(
                      habit: h,
                      nilai: keadaan.nilaiHariIni[h.id] ?? 0,
                      xp: keadaan.xpHariIni[h.id] ?? 0,
                      besar: true,
                      onCatat: (nilai) => _catat(h, nilai),
                      onInfo: () => _info(h),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              if (lainnya.isNotEmpty) ...[
                Text('Habit Lainnya', style: tema.textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final h in lainnya)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: KartuHabit(
                      habit: h,
                      nilai: keadaan.nilaiHariIni[h.id] ?? 0,
                      xp: keadaan.xpHariIni[h.id] ?? 0,
                      onCatat: (nilai) => _catat(h, nilai),
                      onInfo: () => _info(h),
                    ),
                  ),
              ],
              if (aktif.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Text(
                    'Belum ada habit aktif. Aktifkan habit di Pengaturan '
                    'untuk mulai mencatat.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      );
}
