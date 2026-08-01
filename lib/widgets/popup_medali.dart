import 'package:flutter/material.dart';

import '../data/achievement_preset.dart';

/// Menampilkan satu dialog per medali yang baru terbuka, berurutan.
/// Setiap dialog ditunggu sampai ditutup sebelum dialog berikutnya muncul,
/// dan `context.mounted` dicek sebelum tiap pemakaian karena ini rentetan
/// operasi async.
Future<void> tampilkanPopupMedali(
  BuildContext context,
  List<Medali> medaliBaru,
) async {
  for (final m in medaliBaru) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medali terbuka!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(m.syarat),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
