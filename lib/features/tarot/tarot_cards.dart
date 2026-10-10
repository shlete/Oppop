import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 고민상담 주제.
enum TarotTopic {
  love('연애'),
  study('학업'),
  career('진로'),
  money('금전'),
  health('건강');

  const TarotTopic(this.label);

  final String label;
}

/// 고민상담 3장 자리.
enum SpreadPosition {
  past('과거', '원인'),
  present('현재', '상황'),
  future('미래', '조언');

  const SpreadPosition(this.label, this.meaning);

  final String label;
  final String meaning;
}

/// 정방향/역방향 한쪽의 해석.
class CardReading {
  const CardReading({
    required this.keywords,
    required this.today,
    required this.topics,
  });

  final List<String> keywords;

  /// 오늘의 운세 한 줄.
  final String today;

  /// 고민상담 주제별 한 줄.
  final Map<TarotTopic, String> topics;

  factory CardReading.fromJson(Map<String, dynamic> json) => CardReading(
    keywords: (json['keywords'] as List).cast<String>(),
    today: json['today'] as String,
    topics: {for (final t in TarotTopic.values) t: json[t.name] as String},
  );
}

class TarotCard {
  const TarotCard({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.upright,
    required this.reversed,
  });

  /// 'major-00', 'wands-01' 같은 id. 이미지 파일 이름도 같다.
  final String id;
  final String name;
  final String nameEn;
  final CardReading upright;
  final CardReading reversed;

  /// 카드 그림은 모두 이 폴더에 id 이름으로 둔다.
  /// 나중에 직접 그린 그림으로 바꿀 때 같은 이름으로 파일만 갈아 끼우면 된다.
  static const imageDir = 'assets/tarot/cards';

  String get image => '$imageDir/$id.jpg';

  CardReading reading(bool isReversed) => isReversed ? reversed : upright;

  factory TarotCard.fromJson(Map<String, dynamic> json) => TarotCard(
    id: json['id'] as String,
    name: json['name'] as String,
    nameEn: json['nameEn'] as String,
    upright: CardReading.fromJson(json['upright'] as Map<String, dynamic>),
    reversed: CardReading.fromJson(json['reversed'] as Map<String, dynamic>),
  );
}

/// 78장 덱.
class TarotDeck {
  TarotDeck(this.cards) : _byId = {for (final c in cards) c.id: c};

  factory TarotDeck.fromJson(List<dynamic> json) => TarotDeck([
    for (final e in json) TarotCard.fromJson(e as Map<String, dynamic>),
  ]);

  final List<TarotCard> cards;
  final Map<String, TarotCard> _byId;

  TarotCard? byId(String id) => _byId[id];
}

final tarotDeckProvider = FutureProvider<TarotDeck>((ref) async {
  final raw = await rootBundle.loadString('assets/tarot/cards.json');
  return TarotDeck.fromJson(jsonDecode(raw) as List);
});
