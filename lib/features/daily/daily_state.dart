import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'phrases.dart';

String _today([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year}-${d.month}-${d.day}';
}

final seenPhrasesProvider = NotifierProvider<SeenPhrasesNotifier, Set<String>>(
  SeenPhrasesNotifier.new,
);

/// 오늘 이미 본 문구 id. 날짜가 바뀌면 비운다.
class SeenPhrasesNotifier extends Notifier<Set<String>> {
  static const _key = 'daily.seen';

  @override
  Set<String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['date'] != _today()) return;
    state = {...state, ...(json['ids'] as List).cast<String>()};
  }

  Future<void> add(String id) async {
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({'date': _today(), 'ids': state.toList()}),
    );
  }
}

final zodiacProvider = NotifierProvider<ZodiacNotifier, Zodiac?>(
  ZodiacNotifier.new,
);

/// 내 별자리 (선택). 한 번 고르면 기기에 기억한다.
class ZodiacNotifier extends Notifier<Zodiac?> {
  static const _key = 'daily.zodiac';

  @override
  Zodiac? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null) state = Zodiac.values.asNameMap()[name];
  }

  Future<void> set(Zodiac? sign) async {
    state = sign;
    final prefs = await SharedPreferences.getInstance();
    if (sign == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, sign.name);
    }
  }
}

/// 저장한 문구 한 개.
class SavedPhrase {
  const SavedPhrase({
    required this.id,
    required this.category,
    required this.text,
    required this.savedAt,
  });

  final String id;
  final PhraseCategory category;
  final String text;
  final DateTime savedAt;

  Map<String, Object> toJson() => {
    'id': id,
    'category': category.name,
    'text': text,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedPhrase.fromJson(Map<String, dynamic> json) => SavedPhrase(
    id: json['id'] as String,
    category: PhraseCategory.values.byName(json['category'] as String),
    text: json['text'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}

final savedPhrasesProvider =
    NotifierProvider<SavedPhrasesNotifier, List<SavedPhrase>>(
      SavedPhrasesNotifier.new,
    );

/// 기기에 저장한 문구 목록 (최신순).
class SavedPhrasesNotifier extends Notifier<List<SavedPhrase>> {
  static const _key = 'daily.saved';

  @override
  List<SavedPhrase> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    state = [
      for (final e in jsonDecode(raw) as List)
        SavedPhrase.fromJson(e as Map<String, dynamic>),
    ];
  }

  bool contains(String id) => state.any((p) => p.id == id);

  Future<void> add(Phrase phrase) async {
    if (contains(phrase.id)) return;
    state = [
      SavedPhrase(
        id: phrase.id,
        category: phrase.category,
        text: phrase.text,
        savedAt: DateTime.now(),
      ),
      ...state,
    ];
    await _persist();
  }

  /// 삭제를 되돌릴 때 원래 저장 시각 그대로 다시 넣는다.
  Future<void> restore(SavedPhrase phrase) async {
    if (contains(phrase.id)) return;
    state = [...state, phrase]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [
      for (final p in state)
        if (p.id != id) p,
    ];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final p in state) p.toJson()]),
    );
  }
}
