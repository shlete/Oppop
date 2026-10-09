import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/features/random/ladder/ladder.dart';

void main() {
  test('도착 지점은 참가자마다 다르다 (일대일 대응)', () {
    for (var seed = 0; seed < 200; seed++) {
      for (var n = 2; n <= 8; n++) {
        final ladder = Ladder.random(n, random: Random(seed));
        final ends = {for (var i = 0; i < n; i++) ladder.destination(i)};
        expect(ends.length, n);
      }
    }
  });

  test('한 줄에서 가로줄이 서로 붙지 않고, 이웃 세로줄마다 가로줄이 있다', () {
    for (var seed = 0; seed < 200; seed++) {
      final ladder = Ladder.random(6, random: Random(seed));
      for (final row in ladder.rungs) {
        for (final c in row) {
          expect(row.contains(c + 1), isFalse);
        }
      }
      for (var c = 0; c < 5; c++) {
        expect(ladder.rungs.any((row) => row.contains(c)), isTrue);
      }
    }
  });

  test('경로는 정해진 가로줄을 따라 이동한다', () {
    final ladder = Ladder(
      columns: 3,
      rungs: [
        {0},
        {1},
        <int>{},
      ],
    );
    expect(ladder.destination(0), 2);
    expect(ladder.destination(1), 0);
    expect(ladder.destination(2), 1);
  });
}
