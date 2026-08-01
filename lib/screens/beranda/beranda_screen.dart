import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/habit_service.dart';

/// Kerangka Beranda. Isi sesungguhnya (kartu quest, bar XP, daftar habit)
/// ditulis di Task 10 — ini hanya membuktikan rantai database → service →
/// UI sudah hidup.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key, required this.db, required this.service});

  final AppDatabase db;
  final HabitService service;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: service.keadaan,
        builder: (context, keadaan, _) {
          if (keadaan == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final jumlahAktif = keadaan.habit.where((h) => h.aktif).length;
          return Center(
            child: Text(
              'Level ${keadaan.levelGlobal}\n'
              '$jumlahAktif habit aktif',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
        },
      );
}
