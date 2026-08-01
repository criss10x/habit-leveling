import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../db/database.dart';
import 'habit_service.dart' show tanggalKe;

/// Kode error yang dilempar plugin `pedometer` saat sensor step counter
/// tidak ada di perangkat sama sekali (lihat `SensorStreamHandler.kt` di
/// paket `pedometer`: `events.error("1", ...)`). Dipakai untuk membedakan
/// "tidak ada sensor" dari alasan lain (izin ditolak, error lain), karena
/// keduanya berakhir sama (`tersedia = false`) tapi hanya yang pertama
/// tidak menampilkan banner — tidak ada yang bisa dilakukan user soal
/// perangkat yang memang tidak punya sensornya.
///
/// Diverifkasi di `pedometer` versi 4.2.0. Kode internal ini mungkin berubah
/// di versi mendatang — jika terjadi perubahan, cek `SensorStreamHandler.kt`
/// lagi untuk nilai baru.
const _kodeSensorTidakAda = '1';

/// Menyambungkan sensor langkah Android ke habit `langkah_harian`.
///
/// Sensor Android menghitung langkah sejak perangkat menyala, bukan sejak
/// tengah malam. Karena itu service ini menyimpan acuan harian di `meta`
/// (`acuan_langkah`, `acuan_langkah_tanggal`) dan menurunkan langkah hari
/// ini sebagai selisih terhadap acuan tersebut.
class StepService {
  StepService(this._db);

  final AppDatabase _db;

  /// `false` berarti `langkah_harian` harus jatuh ke input manual: izin
  /// ditolak, sensor tidak ada di perangkat, atau stream sensor melempar
  /// error. Begitu jadi `false`, tidak pernah dicoba lagi di sesi ini.
  final ValueNotifier<bool> tersedia = ValueNotifier(true);

  /// `true` bila alasan `tersedia == false` adalah ketiadaan sensor —
  /// kasus itu sengaja tidak memicu banner (docs/design.md §10).
  bool tanpaSensor = false;

  StreamSubscription<StepCount>? _langganan;

  /// Bendera untuk mendeteksi `berhenti()` yang terpanggil saat `mulai()`
  /// masih menunggu (await izin, dll). Tanpa ini, subscription bisa terbuat
  /// setelah widget sudah dihancurkan, hidup selamanya tanpa dibatalkan.
  /// Sekali dihentikan, service tidak akan dimulai lagi (lifecycle per mount).
  bool _dihentikan = false;

  Future<bool> mintaIzin() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      tanpaSensor = false;
      tersedia.value = false;
      return false;
    }
    return true;
  }

  /// Menghitung langkah hari ini dari nilai mentah sensor.
  ///
  /// Hari baru, atau nilai sensor yang lebih kecil dari acuan tersimpan
  /// (perangkat baru restart sehingga hitungan sensor mundur), menggeser
  /// acuan ke nilai sensor sekarang.
  Future<int> langkahHariIni(int nilaiSensor, DateTime sekarang) async {
    final tanggal = tanggalKe(sekarang);
    final tanggalAcuan = await _db.meta('acuan_langkah_tanggal');
    var acuan =
        int.tryParse(await _db.meta('acuan_langkah') ?? '') ?? nilaiSensor;

    if (tanggalAcuan != tanggal || nilaiSensor < acuan) {
      acuan = nilaiSensor;
      await _db.setMeta('acuan_langkah', '$acuan');
      await _db.setMeta('acuan_langkah_tanggal', tanggal);
    }
    return nilaiSensor - acuan;
  }

  /// Mulai mendengarkan sensor langkah. Meminta izin terlebih dahulu, lalu
  /// berlangganan `Pedometer.stepCountStream`.
  ///
  /// `onLangkah` hanya dipanggil saat langkah hari ini benar-benar berubah
  /// nilainya — sensor mengirim event jauh lebih sering daripada itu, dan
  /// pemanggilnya mencatat ke database setiap kali dipanggil.
  ///
  /// Parameter `sekarang` tidak dipakai (waktu sensor pakai `DateTime.now()`
  /// saat event tiba), tapi disimpan agar skalabilitasnya terbuka kalau nanti
  /// lojik berubah. Menggunakan timestamp stale dari subscribe-time akan
  /// memecah logika rolloer tengah malam.
  Future<void> mulai(
    DateTime sekarang,
    void Function(int langkah) onLangkah,
  ) async {
    if (!await mintaIzin()) return;

    // Periksa lagi setelah await: bisa `berhenti()` dipanggil di sela ini.
    if (_dihentikan) return;

    int? langkahTerakhir;
    // Periksa terakhir kali sebelum berlangganan, untuk terjamin tidak ada
    // subscription yang tercipta setelah widget hancur.
    if (_dihentikan) return;
    _langganan = Pedometer.stepCountStream.listen(
      (event) async {
        final langkah = await langkahHariIni(event.steps, DateTime.now());
        if (langkah == langkahTerakhir) return;
        langkahTerakhir = langkah;
        onLangkah(langkah);
      },
      onError: (Object e) {
        tanpaSensor = e is PlatformException && e.code == _kodeSensorTidakAda;
        tersedia.value = false;
      },
      cancelOnError: true,
    );
  }

  /// Membatalkan langganan sensor. Wajib dipanggil dari `dispose` layar
  /// yang memakainya, supaya stream tidak terus hidup setelah widgetnya
  /// dibongkar. Juga memberi tahu `mulai()` yang mungkin sedang await, supaya
  /// tidak ada subscription yang tercipta setelah ini.
  void berhenti() {
    _dihentikan = true;
    _langganan?.cancel();
    _langganan = null;
  }
}
