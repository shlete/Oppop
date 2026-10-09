import 'dart:math';
import 'dart:ui';

/// 1~45 중 서로 다른 6개를 오름차순으로.
List<int> drawLotto(Random random) {
  final pool = List.generate(45, (i) => i + 1)..shuffle(random);
  return pool.take(6).toList()..sort();
}

/// 동행복권 공 색상 (1~10 노랑, 11~20 파랑, 21~30 빨강, 31~40 회색, 41~45 초록).
Color lottoBallColor(int n) {
  if (n <= 10) return const Color(0xFFFBC400);
  if (n <= 20) return const Color(0xFF69C8F2);
  if (n <= 30) return const Color(0xFFFF7272);
  if (n <= 40) return const Color(0xFFAAAAAA);
  return const Color(0xFFB0D840);
}

String formatLotto(List<int> numbers) => numbers.join(', ');
