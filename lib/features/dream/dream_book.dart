import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 꿈 키워드의 기운. 총평과 조언 문구를 고를 때 쓴다.
enum DreamTone { good, neutral, care }

/// 꿈 속 장면 하나 (뱀, 하늘을 날기 등)와 미리 써 둔 해몽.
class DreamSymbol {
  const DreamSymbol({
    required this.id,
    required this.name,
    required this.group,
    required this.tone,
    required this.meaning,
  });

  factory DreamSymbol.fromJson(Map<String, dynamic> json) => DreamSymbol(
    id: json['id'] as String,
    name: json['name'] as String,
    group: json['group'] as String,
    tone: DreamTone.values.byName(json['tone'] as String),
    meaning: json['meaning'] as String,
  );

  final String id;
  final String name;

  /// 화면에서 묶어 보여줄 분류 (동물, 사람, 자연 ...).
  final String group;
  final DreamTone tone;
  final String meaning;
}

class DreamBook {
  DreamBook(this.symbols) : _byId = {for (final s in symbols) s.id: s};

  factory DreamBook.fromJson(List<dynamic> json) => DreamBook([
    for (final e in json) DreamSymbol.fromJson(e as Map<String, dynamic>),
  ]);

  final List<DreamSymbol> symbols;
  final Map<String, DreamSymbol> _byId;

  DreamSymbol? byId(String id) => _byId[id];

  /// 파일에 적힌 순서대로의 분류 목록.
  List<String> get groups =>
      [for (final s in symbols) s.group]
          .fold(<String>[], (l, g) => l.contains(g) ? l : (l..add(g)));

  List<DreamSymbol> inGroup(String group) => [
    for (final s in symbols)
      if (s.group == group) s,
  ];

  /// 키워드만 골랐을 때 보여줄 한 줄 총평.
  static String summary(List<DreamSymbol> picked) {
    final good = picked.where((s) => s.tone == DreamTone.good).length;
    final care = picked.where((s) => s.tone == DreamTone.care).length;
    if (care == 0 && good == picked.length) return '좋은 기운이 가득한 길몽이에요';
    if (care == 0) return '잔잔하게 좋은 흐름을 알려 주는 꿈이에요';
    if (good > care) return '좋은 기운이 더 큰, 기대해 볼 만한 꿈이에요';
    if (good == care) return '마음을 정리하면 좋은 일이 따라오는 꿈이에요';
    return '쉬어 가라고 마음이 보내는 신호 같은 꿈이에요';
  }

  /// 키워드만 골랐을 때 보여줄 오늘의 한마디.
  static String advice(List<DreamSymbol> picked) {
    final care = picked.where((s) => s.tone == DreamTone.care).length;
    final good = picked.where((s) => s.tone == DreamTone.good).length;
    if (care > good) return '오늘은 무리하지 말고, 좋아하는 걸 하나 챙겨 보세요.';
    if (good > 0 && care == 0) return '좋은 기운이 들어올 때예요. 미뤄 둔 일을 하나 시작해 보세요.';
    return '오늘 마주치는 작은 신호에 한 번 더 귀 기울여 보세요.';
  }
}

final dreamBookProvider = FutureProvider<DreamBook>((ref) async {
  final raw = await rootBundle.loadString('assets/dream/symbols.json');
  return DreamBook.fromJson(jsonDecode(raw) as List);
});
