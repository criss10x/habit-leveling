import 'package:flutter/material.dart';

import '../data/habit.dart';

/// Menampilkan progres sesuai aturan tampilan di docs/design.md §1: satuan
/// `menit` dengan target >= 60 ditampilkan dalam jam, bukan menit. Aturan ini
/// umum untuk semua habit bersatuan menit dengan target besar (mis.
/// `durasi_tidur`), bukan kekhususan satu habit.
String formatProgres(Habit habit, int nilai) {
  if (habit.satuan == 'menit' && habit.target >= 60) {
    return '${_formatJam(nilai)}/${_formatJam(habit.target)} jam';
  }
  return '$nilai/${habit.target} ${habit.satuan}'.trim();
}

String _formatJam(int menit) {
  final jam = menit / 60;
  return jam == jam.roundToDouble()
      ? jam.round().toString()
      : jam.toStringAsFixed(1);
}

String _formatJamMenit(int menit) {
  final m = menit % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
}

/// Kartu satu habit: nama, progres, indikator selesai, kontrol tambah, dan
/// ikon bantuan. `besar` membedakan tampilan kartu Quest Hari Ini dari baris
/// ringkas Habit Lainnya.
class KartuHabit extends StatelessWidget {
  const KartuHabit({
    super.key,
    required this.habit,
    required this.nilai,
    required this.xp,
    required this.onCatat,
    required this.onInfo,
    this.besar = false,
    this.sensorTersedia = true,
  });

  final Habit habit;
  final int nilai;
  final int xp;

  /// Dipanggil dengan nilai baru yang akan dicatat lewat
  /// `service.catatHabit`.
  final ValueChanged<int> onCatat;
  final VoidCallback onInfo;
  final bool besar;

  /// Hanya relevan untuk `habit.sumber == 'pedometer'`. `false` berarti
  /// sensor gagal (izin ditolak, tidak ada sensor, atau error), sehingga
  /// kontrol tambah harus tetap muncul supaya user bisa mengisi manual.
  final bool sensorTersedia;

  bool get _selesai => xp >= habit.xpDasar;

  String get _progres => habit.tipe == TipeHabit.waktu
      ? '${_formatJamMenit(nilai)} (sebelum ${_formatJamMenit(habit.target)})'
      : formatProgres(habit, nilai);

  Future<void> _pilihWaktu(BuildContext context) async {
    final dipilih = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (nilai ~/ 60) % 24,
        minute: nilai % 60,
      ),
    );
    if (dipilih == null) return;
    onCatat(dipilih.hour * 60 + dipilih.minute);
  }

  Future<void> _bukaDialogAngka(BuildContext context) async {
    final hasil = await showDialog<int>(
      context: context,
      builder: (context) => _DialogAngka(habit: habit, nilaiAwal: nilai),
    );
    if (hasil != null) onCatat(hasil);
  }

  Widget? _kontrolTambah(BuildContext context) {
    // Sensor mengisi nilainya sendiri selama tersedia. Begitu sensor gagal
    // (izin ditolak, tidak ada sensor, error) habit ini jatuh ke input
    // manual seperti habit lain — tidak ada jalur kode terpisah, jadi ia
    // ikut logika di bawah (satuan 'langkah' -> dialog "Isi angka").
    if (habit.sumber == 'pedometer' && sensorTersedia) return null;

    if (habit.tipe == TipeHabit.waktu) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.access_time),
        label: const Text('Catat jam'),
        onPressed: () => _pilihWaktu(context),
      );
    }

    if (habit.target == 1) {
      return Checkbox(
        value: nilai >= 1,
        onChanged: (v) => onCatat(v == true ? 1 : 0),
      );
    }

    if (habit.target > 1 &&
        (habit.satuan == 'menit' || habit.satuan == 'langkah')) {
      return OutlinedButton(
        onPressed: () => _bukaDialogAngka(context),
        child: const Text('Isi angka'),
      );
    }

    return FilledButton(
      onPressed: () => onCatat(nilai + 1),
      child: const Text('+1'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kontrol = _kontrolTambah(context);
    final tema = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _selesai ? Icons.check_circle : Icons.check_circle_outline,
              color: _selesai ? Colors.green : tema.disabledColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.nama,
                    style: besar
                        ? tema.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)
                        : tema.textTheme.bodyLarge,
                  ),
                  Text(_progres, style: tema.textTheme.bodySmall),
                ],
              ),
            ),
            if (kontrol != null) ...[kontrol, const SizedBox(width: 4)],
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: onInfo,
              tooltip: 'Info habit',
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog input angka untuk habit `hitung` bersatuan menit/langkah.
/// Memvalidasi: kosong, bukan angka, negatif, dan angka yang tidak masuk
/// akal (di atas 100.000).
class _DialogAngka extends StatefulWidget {
  const _DialogAngka({required this.habit, required this.nilaiAwal});

  final Habit habit;
  final int nilaiAwal;

  @override
  State<_DialogAngka> createState() => _DialogAngkaState();
}

class _DialogAngkaState extends State<_DialogAngka> {
  late final _controller =
      TextEditingController(text: widget.nilaiAwal.toString());
  String? _error;

  void _submit() {
    final teks = _controller.text.trim();
    if (teks.isEmpty) {
      setState(() => _error = 'Isi angkanya dulu.');
      return;
    }
    final nilai = int.tryParse(teks);
    if (nilai == null) {
      setState(() => _error = 'Harus berupa angka bulat.');
      return;
    }
    if (nilai < 0) {
      setState(() => _error = 'Tidak boleh negatif.');
      return;
    }
    if (nilai > 100000) {
      setState(() => _error = 'Angkanya kelihatan tidak masuk akal.');
      return;
    }
    Navigator.of(context).pop(nilai);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.habit.nama),
        content: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.habit.satuan,
            errorText: _error,
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(onPressed: _submit, child: const Text('Simpan')),
        ],
      );
}
