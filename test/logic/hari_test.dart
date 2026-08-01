import 'package:flutter_test/flutter_test.dart';
import 'package:habit_leveling/logic/quest.dart';

void main() {
  const xpDasar = {1: 10, 2: 15, 3: 10};

  test('semua habit aktif mencapai xp dasar berarti sempurna', () {
    expect(
      hariSempurna([1, 2], {1: 10, 2: 15}, xpDasar),
      isTrue,
    );
  });

  test('satu habit setengah jalan membatalkan hari sempurna', () {
    expect(
      hariSempurna([1, 2], {1: 10, 2: 7}, xpDasar),
      isFalse,
    );
  });

  test('habit aktif tanpa catatan sama sekali membatalkan', () {
    expect(hariSempurna([1, 2], {1: 10}, xpDasar), isFalse);
  });

  test('habit yang dicatat tapi tidak aktif hari itu diabaikan', () {
    expect(
      hariSempurna([1], {1: 10, 3: 2}, xpDasar),
      isTrue,
    );
  });

  test('tanpa habit aktif bukan hari sempurna', () {
    expect(hariSempurna([], {}, xpDasar), isFalse);
  });
}
