import 'dart:math';
import 'dart:ui';

/// 사다리. [rungs]의 각 줄(row)에는 가로줄이 걸린 왼쪽 세로줄 번호가 들어 있다.
/// 예: rungs[3] = {0, 2} 이면 4번째 줄에 0-1, 2-3 사이 가로줄이 있다.
class Ladder {
  Ladder({required this.columns, required this.rungs});

  final int columns;
  final List<Set<int>> rungs;

  int get rows => rungs.length;

  factory Ladder.random(int columns, {Random? random, int rows = 10}) {
    final r = random ?? Random();
    final rungs = List.generate(rows, (_) {
      final row = <int>{};
      for (var c = 0; c < columns - 1; c++) {
        if (!row.contains(c - 1) && r.nextDouble() < 0.4) row.add(c);
      }
      return row;
    });
    // 이웃한 세로줄 사이에 가로줄이 하나도 없으면 결과가 뻔하므로 하나씩은 보장한다.
    for (var c = 0; c < columns - 1; c++) {
      if (rungs.any((row) => row.contains(c))) continue;
      final free = [
        for (var i = 0; i < rows; i++)
          if (!rungs[i].contains(c - 1) && !rungs[i].contains(c + 1)) i,
      ];
      if (free.isEmpty) {
        rungs.add({c});
      } else {
        rungs[free[r.nextInt(free.length)]].add(c);
      }
    }
    return Ladder(columns: columns, rungs: rungs);
  }

  /// [start] 세로줄에서 내려갔을 때 도착하는 세로줄.
  int destination(int start) => path(start).last.dx.round();

  /// 내려가는 경로의 꺾이는 점들. x는 세로줄 번호, y는 0(위)~1(아래).
  List<Offset> path(int start) {
    var col = start;
    final points = [Offset(col.toDouble(), 0)];
    for (var i = 0; i < rows; i++) {
      final y = (i + 1) / (rows + 1);
      if (rungs[i].contains(col)) {
        points
          ..add(Offset(col.toDouble(), y))
          ..add(Offset((col + 1).toDouble(), y));
        col++;
      } else if (rungs[i].contains(col - 1)) {
        points
          ..add(Offset(col.toDouble(), y))
          ..add(Offset((col - 1).toDouble(), y));
        col--;
      }
    }
    points.add(Offset(col.toDouble(), 1));
    return points;
  }
}
