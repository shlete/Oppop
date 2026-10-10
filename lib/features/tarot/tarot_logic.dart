import 'dart:math';

import 'package:flutter/painting.dart';

/// 뽑힌 카드 한 장 (덱 위치 + 방향).
class DrawnCard {
  const DrawnCard(this.cardId, {required this.reversed});

  final String cardId;
  final bool reversed;

  Map<String, Object> toJson() => {'id': cardId, 'reversed': reversed};

  factory DrawnCard.fromJson(Map<String, dynamic> json) =>
      DrawnCard(json['id'] as String, reversed: json['reversed'] as bool);

  @override
  bool operator ==(Object other) =>
      other is DrawnCard &&
      other.cardId == cardId &&
      other.reversed == reversed;

  @override
  int get hashCode => Object.hash(cardId, reversed);
}

/// 역방향이 너무 자주 나오지 않게 30%만.
const reversedChance = 0.3;

/// 행운의 색. 이름과 실제 색.
const luckyColors = <(String, Color)>[
  ('빨강', Color(0xFFE5484D)),
  ('주황', Color(0xFFF76B15)),
  ('노랑', Color(0xFFFFC53D)),
  ('연두', Color(0xFF8BC34A)),
  ('초록', Color(0xFF30A46C)),
  ('하늘', Color(0xFF4CB5F5)),
  ('파랑', Color(0xFF3E63DD)),
  ('남색', Color(0xFF2F3A8F)),
  ('보라', Color(0xFF8E4EC6)),
  ('분홍', Color(0xFFF178B6)),
  ('흰색', Color(0xFFF5F5F5)),
  ('검정', Color(0xFF2B2B2B)),
  ('베이지', Color(0xFFE8D8C3)),
  ('민트', Color(0xFF7CE0C3)),
];

/// 오늘의 운세 결과.
class DailyFortune {
  const DailyFortune({
    required this.card,
    required this.luckyColor,
    required this.luckyNumber,
  });

  final DrawnCard card;
  final (String, Color) luckyColor;
  final int luckyNumber;
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 날짜 문자열을 섞어 시드로 쓴다. Object.hash는 실행마다 달라질 수 있어 직접 계산한다.
int _seedFor(String day, int deviceSeed) {
  var h = deviceSeed & 0x7fffffff;
  for (final c in day.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// 같은 기기·같은 날이면 늘 같은 카드가 나온다.
DailyFortune dailyFortune({
  required List<String> cardIds,
  required DateTime date,
  required int deviceSeed,
}) {
  final r = Random(_seedFor(dayKey(date), deviceSeed));
  final id = cardIds[r.nextInt(cardIds.length)];
  final reversed = r.nextDouble() < reversedChance;
  return DailyFortune(
    card: DrawnCard(id, reversed: reversed),
    luckyColor: luckyColors[r.nextInt(luckyColors.length)],
    luckyNumber: r.nextInt(30) + 1,
  );
}

/// 덱을 섞어 펼칠 카드 [count]장을 고른다. 사용자가 이 중 3장을 탭한다.
List<DrawnCard> shuffledSpread(
  List<String> cardIds,
  Random r, {
  int count = 21,
}) {
  final ids = [...cardIds]..shuffle(r);
  return [
    for (final id in ids.take(count))
      DrawnCard(id, reversed: r.nextDouble() < reversedChance),
  ];
}
