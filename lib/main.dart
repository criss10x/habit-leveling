import 'package:flutter/material.dart';

import 'db/database.dart';
import 'screens/kerangka.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/habit_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.buka();
  final service = HabitService(db);
  final sudahOnboarding = (await db.meta('onboarding_selesai')) == '1';
  if (sudahOnboarding) {
    await service.muat(DateTime.now());
  }
  runApp(HabitLevelingApp(
    db: db,
    service: service,
    sudahOnboarding: sudahOnboarding,
  ));
}

class HabitLevelingApp extends StatelessWidget {
  const HabitLevelingApp({
    super.key,
    required this.db,
    required this.service,
    required this.sudahOnboarding,
  });

  final AppDatabase db;
  final HabitService service;
  final bool sudahOnboarding;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Habit Leveling',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D5B),
          useMaterial3: true,
        ),
        home: sudahOnboarding
            ? Kerangka(db: db, service: service)
            : OnboardingScreen(db: db, service: service),
      );
}
