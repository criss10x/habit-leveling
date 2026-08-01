import 'package:flutter/material.dart';

import '../db/database.dart';
import '../services/habit_service.dart';
import 'beranda/beranda_screen.dart';

/// Kerangka empat tab: Beranda, Statistik, Medali, Pengaturan.
///
/// Hanya Beranda berisi konten sungguhan di task ini. Tiga tab lainnya
/// diganti placeholder-nya masing-masing di Task 13, 14, dan 15.
class Kerangka extends StatefulWidget {
  const Kerangka({super.key, required this.db, required this.service});

  final AppDatabase db;
  final HabitService service;

  @override
  State<Kerangka> createState() => _KerangkaState();
}

class _KerangkaState extends State<Kerangka> {
  int _indeks = 0;

  @override
  Widget build(BuildContext context) {
    final halaman = [
      BerandaScreen(db: widget.db, service: widget.service),
      const Center(child: Text('Statistik segera hadir')),
      const Center(child: Text('Medali segera hadir')),
      const Center(child: Text('Pengaturan segera hadir')),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _indeks, children: halaman),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeks,
        onDestinationSelected: (i) => setState(() => _indeks = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events),
            label: 'Medali',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
