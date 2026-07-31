import 'dart:math';

import '../data/habit.dart';

/// Menggeser jam dini hari ke hari berikutnya, supaya "tidur sebelum jam 23"
/// tidak dianggap berhasil ketika user tidur jam 00:30.
int nilaiEfektifWaktu(int nilai, int ambang) =>
    nilai < ambang - 720 ? nilai + 1440 : nilai;

bool tercapaiWaktu(int nilai, int ambang) =>
    nilaiEfektifWaktu(nilai, ambang) < ambang;

int hitungXp({
  required TipeHabit tipe,
  required int nilai,
  required int target,
  required int xpDasar,
}) {
  if (tipe == TipeHabit.waktu) {
    return tercapaiWaktu(nilai, target) ? xpDasar : 0;
  }
  if (target <= 0) return xpDasar;
  final rasio = min(1.0, nilai / target);
  return (xpDasar * rasio).round();
}

int xpUntukLevel(int level) => 50 * level * (level - 1);

int xpUntukLevelGlobal(int level) => 200 * level * (level - 1);

int _level(int xp, int Function(int) ambang) {
  var level = 1;
  while (ambang(level + 1) <= xp) {
    level++;
  }
  return level;
}

int levelDariXp(int xp) => _level(xp, xpUntukLevel);

int levelGlobalDariXp(int xp) => _level(xp, xpUntukLevelGlobal);

int skorKeseimbangan(List<int> levelPilar) {
  final tertinggi = levelPilar.reduce(max);
  if (tertinggi <= 0) return 100;
  return (levelPilar.reduce(min) / tertinggi * 100).round();
}

const int bonusQuest = 24;

int bonusPerPilar(int jumlahPilar) =>
    jumlahPilar <= 0 ? 0 : bonusQuest ~/ jumlahPilar;
