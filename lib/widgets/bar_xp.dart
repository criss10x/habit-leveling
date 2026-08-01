import 'package:flutter/material.dart';

import '../logic/xp.dart';

/// Bar progres level: label "Level N" plus progres XP menuju level
/// berikutnya. `global` memilih ambang level global atau ambang level pilar
/// (lib/logic/xp.dart: `xpUntukLevelGlobal` vs `xpUntukLevel`).
class BarXp extends StatelessWidget {
  const BarXp({
    super.key,
    required this.xp,
    required this.level,
    required this.global,
  });

  final int xp;
  final int level;
  final bool global;

  int _ambang(int lvl) => global ? xpUntukLevelGlobal(lvl) : xpUntukLevel(lvl);

  @override
  Widget build(BuildContext context) {
    final batasBawah = _ambang(level);
    final batasAtas = _ambang(level + 1);
    final rentang = batasAtas - batasBawah;
    // Penjaga pembagian nol: rentang seharusnya selalu positif (400*level
    // untuk global, 100 untuk pilar), tapi tidak ada salahnya berjaga-jaga.
    final progres =
        rentang <= 0 ? 0.0 : ((xp - batasBawah) / rentang).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          global ? 'Level Global $level' : 'Level $level',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: progres, minHeight: 12),
        ),
        const SizedBox(height: 4),
        Text('$xp / $batasAtas XP'),
      ],
    );
  }
}
