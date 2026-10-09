import 'dart:math';

/// 룰렛 회전 계산. 0번 칸은 12시 방향에서 시계 방향으로 시작하고,
/// 바늘은 12시 방향에 고정되어 있다. [rotation]은 시계 방향 라디안.
class RouletteLogic {
  /// 현재 회전값에서 바늘이 가리키는 칸 번호.
  static int indexAtPointer(double rotation, int count) {
    final seg = 2 * pi / count;
    final underPointer = (-rotation) % (2 * pi);
    return (underPointer / seg).floor() % count;
  }

  /// [index] 칸이 바늘에 오도록 하는 최종 회전값.
  /// [jitter]는 -1~1 사이 값으로, 칸 안에서 멈추는 위치를 흔든다.
  static double targetRotation({
    required double current,
    required int index,
    required int count,
    int extraTurns = 5,
    double jitter = 0,
  }) {
    final seg = 2 * pi / count;
    final aim = -(index + 0.5 + jitter.clamp(-1.0, 1.0) * 0.35) * seg;
    final delta = (aim - current) % (2 * pi);
    return current + extraTurns * 2 * pi + delta;
  }
}
