import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 오늘의 뽑기 카테고리.
enum PhraseCategory {
  quote('좋은 글귀'),
  cheer('응원 한마디'),
  caution('오늘 주의할 점');

  const PhraseCategory(this.label);

  final String label;
}

/// 별자리. '오늘 주의할 점'에서 고르면 그 별자리 문구가 함께 뽑힌다.
enum Zodiac {
  aries('양자리', '3.21~4.19'),
  taurus('황소자리', '4.20~5.20'),
  gemini('쌍둥이자리', '5.21~6.21'),
  cancer('게자리', '6.22~7.22'),
  leo('사자자리', '7.23~8.22'),
  virgo('처녀자리', '8.23~9.22'),
  libra('천칭자리', '9.23~10.22'),
  scorpio('전갈자리', '10.23~11.22'),
  sagittarius('사수자리', '11.23~12.24'),
  capricorn('염소자리', '12.25~1.19'),
  aquarius('물병자리', '1.20~2.18'),
  pisces('물고기자리', '2.19~3.20');

  const Zodiac(this.label, this.dates);

  final String label;
  final String dates;
}

class Phrase {
  const Phrase({
    required this.id,
    required this.category,
    required this.text,
    this.sign,
  });

  final String id;
  final PhraseCategory category;
  final String text;

  /// 별자리 전용 문구면 그 별자리, 공통 문구면 null.
  final Zodiac? sign;
}

/// 카테고리별 문구 묶음. 지금은 앱에 넣어둔 JSON에서 읽고,
/// 나중에 원격 설정으로 바꿔도 이 형태만 맞추면 된다.
class PhraseBook {
  PhraseBook(this.byCategory);

  factory PhraseBook.fromJson(Map<String, dynamic> json) => PhraseBook({
    for (final c in PhraseCategory.values)
      c: [
        for (final e in (json[c.name] as List? ?? const []))
          Phrase(
            id: e['id'] as String,
            category: c,
            text: e['text'] as String,
            sign: e['sign'] == null ? null : Zodiac.values.byName(e['sign']),
          ),
      ],
  });

  final Map<PhraseCategory, List<Phrase>> byCategory;

  /// 뽑을 수 있는 문구. 별자리를 골랐으면 공통 문구와 그 별자리 문구,
  /// 안 골랐으면 전체에서 뽑는다.
  List<Phrase> pool(PhraseCategory category, Zodiac? sign) => [
    for (final p in byCategory[category] ?? const <Phrase>[])
      if (sign == null || p.sign == null || p.sign == sign) p,
  ];

  /// [seen]에 없는 문구 중 하나를 고른다. 모두 봤으면 전체에서 다시 고른다.
  Phrase? pick(
    PhraseCategory category, {
    Zodiac? sign,
    Set<String> seen = const {},
    Random? random,
  }) {
    final all = pool(category, sign);
    if (all.isEmpty) return null;
    final fresh = [
      for (final p in all)
        if (!seen.contains(p.id)) p,
    ];
    final from = fresh.isEmpty ? all : fresh;
    return from[(random ?? Random()).nextInt(from.length)];
  }
}

final phraseBookProvider = FutureProvider<PhraseBook>((ref) async {
  final raw = await rootBundle.loadString('assets/phrases/daily.json');
  return PhraseBook.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});
