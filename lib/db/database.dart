import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/habit.dart';
import '../data/habit_preset.dart';

class BarisHari {
  const BarisHari({
    required this.tanggal,
    required this.questIds,
    required this.aktifIds,
    this.bonusDiambil = false,
    this.dijeda = false,
  });

  final String tanggal;
  final List<int> questIds;
  final List<int> aktifIds;
  final bool bonusDiambil;
  final bool dijeda;
}

List<int> _keIds(String? teks) => (teks == null || teks.isEmpty)
    ? const []
    : teks.split(',').map(int.parse).toList();

String _dariIds(List<int> ids) => ids.join(',');

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static Future<AppDatabase> buka() async {
    final path = p.join(await getDatabasesPath(), 'habit_leveling.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE NOT NULL,
            nama TEXT NOT NULL,
            pilar TEXT NOT NULL,
            tipe TEXT NOT NULL,
            target INTEGER NOT NULL,
            satuan TEXT NOT NULL,
            xp_dasar INTEGER NOT NULL,
            sumber TEXT NOT NULL,
            aktif INTEGER NOT NULL,
            is_custom INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            tanggal TEXT NOT NULL,
            nilai INTEGER NOT NULL,
            xp INTEGER NOT NULL,
            UNIQUE (habit_id, tanggal)
          )
        ''');
        await db.execute('CREATE INDEX idx_logs_tanggal ON logs (tanggal)');
        await db.execute('''
          CREATE TABLE hari (
            tanggal TEXT PRIMARY KEY,
            quest_ids TEXT NOT NULL,
            aktif_ids TEXT NOT NULL,
            bonus_diambil INTEGER NOT NULL,
            dijeda INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE TABLE meta (key TEXT PRIMARY KEY, nilai TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE medali (key TEXT PRIMARY KEY, dibuka_pada TEXT NOT NULL)',
        );
        await _isiPreset(db);
      },
    );
    return AppDatabase._(db);
  }

  /// Menyisipkan preset yang kuncinya belum ada. Preset yang sudah ada tidak
  /// pernah ditimpa — user mungkin sudah mengubah targetnya.
  static Future<void> _isiPreset(DatabaseExecutor db) async {
    for (final h in habitPreset) {
      await db.insert(
        'habits',
        {
          'key': h.key,
          'nama': h.nama,
          'pilar': h.pilar.name,
          'tipe': h.tipe.name,
          'target': h.target,
          'satuan': h.satuan,
          'xp_dasar': h.xpDasar,
          'sumber': h.sumber,
          'aktif': saranAwal.contains(h.key) ? 1 : 0,
          'is_custom': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Habit _keHabit(Map<String, Object?> r) => Habit(
        id: r['id']! as int,
        key: r['key']! as String,
        nama: r['nama']! as String,
        pilar: Pilar.values.byName(r['pilar']! as String),
        tipe: TipeHabit.values.byName(r['tipe']! as String),
        target: r['target']! as int,
        satuan: r['satuan']! as String,
        xpDasar: r['xp_dasar']! as int,
        sumber: r['sumber']! as String,
        aktif: (r['aktif']! as int) == 1,
        isCustom: (r['is_custom']! as int) == 1,
      );

  Future<List<Habit>> semuaHabit() async {
    final rows = await _db.query('habits', orderBy: 'pilar, id');
    return rows.map(_keHabit).toList();
  }

  Future<void> setAktif(int habitId, bool aktif) => _db.update(
        'habits',
        {'aktif': aktif ? 1 : 0},
        where: 'id = ?',
        whereArgs: [habitId],
      );

  Future<void> setTarget(int habitId, int target) => _db.update(
        'habits',
        {'target': target < 1 ? 1 : target},
        where: 'id = ?',
        whereArgs: [habitId],
      );

  Future<int> tambahCustom(Habit h) => _db.insert('habits', {
        'key': h.key,
        'nama': h.nama,
        'pilar': h.pilar.name,
        'tipe': TipeHabit.hitung.name,
        'target': h.target < 1 ? 1 : h.target,
        'satuan': h.satuan,
        'xp_dasar': xpDasarCustom,
        'sumber': 'manual',
        'aktif': 1,
        'is_custom': 1,
      });

  /// Menghapus habit custom beserta seluruh catatannya.
  ///
  /// Ini satu-satunya jalur di aplikasi yang boleh menurunkan XP, dan hanya
  /// berlaku untuk habit custom. Penghapusan log digantung pada keberhasilan
  /// penghapusan barisnya, supaya id habit preset yang salah masuk tidak bisa
  /// memusnahkan riwayatnya. Keduanya dalam satu transaksi agar tidak mungkin
  /// tersisa setengah jalan.
  Future<void> hapusCustom(int habitId) async {
    await _db.transaction((txn) async {
      final terhapus = await txn.delete(
        'habits',
        where: 'id = ? AND is_custom = 1',
        whereArgs: [habitId],
      );
      if (terhapus > 0) {
        await txn.delete('logs', where: 'habit_id = ?', whereArgs: [habitId]);
      }
    });
  }

  Future<void> catat({
    required int habitId,
    required String tanggal,
    required int nilai,
    required int xp,
  }) =>
      _db.insert(
        'logs',
        {'habit_id': habitId, 'tanggal': tanggal, 'nilai': nilai, 'xp': xp},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Map<int, int>> _kolomHari(String tanggal, String kolom) async {
    final rows = await _db.query(
      'logs',
      columns: ['habit_id', kolom],
      where: 'tanggal = ?',
      whereArgs: [tanggal],
    );
    return {
      for (final r in rows) r['habit_id']! as int: r[kolom]! as int,
    };
  }

  Future<Map<int, int>> nilaiHari(String tanggal) =>
      _kolomHari(tanggal, 'nilai');

  Future<Map<int, int>> xpHari(String tanggal) => _kolomHari(tanggal, 'xp');

  Future<Map<String, int>> akumulasiPerKey() async {
    final rows = await _db.rawQuery('''
      SELECT h.key AS key, SUM(l.nilai) AS total
      FROM logs l JOIN habits h ON h.id = l.habit_id
      WHERE h.is_custom = 0
      GROUP BY h.key
    ''');
    return {
      for (final r in rows) r['key']! as String: (r['total'] as int?) ?? 0,
    };
  }

  Future<Map<Pilar, int>> xpPerPilar() async {
    final rows = await _db.rawQuery('''
      SELECT h.pilar AS pilar, SUM(l.xp) AS total
      FROM logs l JOIN habits h ON h.id = l.habit_id
      GROUP BY h.pilar
    ''');
    final hasil = {for (final p in Pilar.values) p: 0};
    for (final r in rows) {
      hasil[Pilar.values.byName(r['pilar']! as String)] =
          (r['total'] as int?) ?? 0;
    }
    return hasil;
  }

  Future<Map<int, int>> selesai7Hari(String sejak) async {
    final rows = await _db.rawQuery('''
      SELECT l.habit_id AS habit_id, COUNT(*) AS jumlah
      FROM logs l JOIN habits h ON h.id = l.habit_id
      WHERE l.tanggal >= ? AND l.xp >= h.xp_dasar
      GROUP BY l.habit_id
    ''', [sejak]);
    return {
      for (final r in rows) r['habit_id']! as int: r['jumlah']! as int,
    };
  }

  BarisHari _keHari(Map<String, Object?> r) => BarisHari(
        tanggal: r['tanggal']! as String,
        questIds: _keIds(r['quest_ids'] as String?),
        aktifIds: _keIds(r['aktif_ids'] as String?),
        bonusDiambil: (r['bonus_diambil']! as int) == 1,
        dijeda: (r['dijeda']! as int) == 1,
      );

  Future<BarisHari?> hari(String tanggal) async {
    final rows = await _db.query(
      'hari',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
    );
    return rows.isEmpty ? null : _keHari(rows.first);
  }

  Future<List<BarisHari>> hariSejak(String tanggal) async {
    final rows = await _db.query(
      'hari',
      where: 'tanggal >= ?',
      whereArgs: [tanggal],
      orderBy: 'tanggal',
    );
    return rows.map(_keHari).toList();
  }

  Future<void> simpanHari(BarisHari h) => _db.insert(
        'hari',
        {
          'tanggal': h.tanggal,
          'quest_ids': _dariIds(h.questIds),
          'aktif_ids': _dariIds(h.aktifIds),
          'bonus_diambil': h.bonusDiambil ? 1 : 0,
          'dijeda': h.dijeda ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<String?> meta(String key) async {
    final rows = await _db.query('meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['nilai'] as String;
  }

  Future<void> setMeta(String key, String nilai) => _db.insert(
        'meta',
        {'key': key, 'nilai': nilai},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Set<String>> medaliTerbuka() async {
    final rows = await _db.query('medali', columns: ['key']);
    return rows.map((r) => r['key']! as String).toSet();
  }

  Future<void> bukaMedali(String key, String waktu) => _db.insert(
        'medali',
        {'key': key, 'dibuka_pada': waktu},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  static const List<String> _tabel = [
    'habits',
    'logs',
    'hari',
    'meta',
    'medali',
  ];

  Future<Map<String, List<Map<String, Object?>>>> dumpSemua() async {
    final hasil = <String, List<Map<String, Object?>>>{};
    for (final t in _tabel) {
      hasil[t] = await _db.query(t);
    }
    return hasil;
  }

  /// Mengganti seluruh data dari impor backup atau pemulihan.
  ///
  /// Memvalidasi setiap baris habit sebelum mengganti tabel — `pilar` dan
  /// `tipe` harus merupakan nama enum yang valid. Jika ada yang tidak sesuai,
  /// melempar `FormatException` dan membiarkan data yang lama utuh.
  Future<void> gantiSemua(
    Map<String, List<Map<String, Object?>>> data,
  ) async {
    final habitRows = data['habits'] ?? const [];
    for (final baris in habitRows) {
      final pilarStr = baris['pilar'];
      final tipeStr = baris['tipe'];
      if (pilarStr is String) {
        if (!Pilar.values.any((p) => p.name == pilarStr)) {
          throw FormatException('Pilar tidak dikenal: $pilarStr');
        }
      }
      if (tipeStr is String) {
        if (!TipeHabit.values.any((t) => t.name == tipeStr)) {
          throw FormatException('Tipe habit tidak dikenal: $tipeStr');
        }
      }
    }

    await _db.transaction((txn) async {
      for (final t in _tabel) {
        await txn.delete(t);
      }
      for (final t in _tabel) {
        for (final baris in data[t] ?? const []) {
          await txn.insert(t, baris);
        }
      }
    });
  }
}
