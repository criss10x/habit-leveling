# Habit Leveling

Aplikasi Android untuk membangun kebiasaan sehat, dengan sistem gamifikasi berbasis level dan streak.

Empat pilar kesehatan — **Gerak, Makan, Tidur, Pikiran** — masing-masing punya level sendiri. User memilih habit yang ingin dikerjakan dari daftar preset, mencatatnya setiap hari, dan mengumpulkan XP yang menaikkan level pilar terkait.

Aplikasi berjalan sepenuhnya offline. Tidak ada akun, tidak ada server, tidak ada data yang meninggalkan perangkat.

## Status

Tahap desain. Belum ada kode.

## Dokumentasi

Baca berurutan:

| File | Isi |
|------|-----|
| [AGENTS.md](AGENTS.md) | Aturan kerja untuk AI/kontributor, istilah, konvensi |
| [docs/PRD.md](docs/PRD.md) | Untuk siapa, untuk apa, kriteria terima |
| [docs/design.md](docs/design.md) | Cara kerjanya — sumber kebenaran teknis |
| [docs/decisions.md](docs/decisions.md) | Kenapa begitu, dan apa yang sudah ditolak |
| [docs/plan.md](docs/plan.md) | Langkah implementasi (dibuat setelah desain disetujui) |

## Menjalankan

```bash
flutter pub get
flutter run
```

Butuh Flutter stable dan Android SDK. Target minimum Android 8.0 (API 26).

## Lisensi

Belum ditentukan.
