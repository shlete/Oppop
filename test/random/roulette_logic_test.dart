import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/features/random/roulette/roulette_logic.dart';

void main() {
  test('목표 회전값에서 바늘은 항상 고른 칸을 가리킨다', () {
    final r = Random(1);
    for (var n = 2; n <= 20; n++) {
      var current = r.nextDouble() * 2 * pi;
      for (var i = 0; i < n; i++) {
        final target = RouletteLogic.targetRotation(
          current: current,
          index: i,
          count: n,
          jitter: r.nextDouble() * 2 - 1,
        );
        expect(target, greaterThan(current + 5 * 2 * pi - 1e-9));
        expect(RouletteLogic.indexAtPointer(target, n), i, reason: 'n=$n i=$i');
        current = target % (2 * pi);
      }
    }
  });
}
