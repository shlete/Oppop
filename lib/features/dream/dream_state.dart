import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dream_ai.dart';

/// 저장한 해몽. 쓴 꿈 이야기는 이 기기에만 남는다.
class SavedDream {
  const SavedDream({
    required this.id,
    required this.symbolIds,
    required this.story,
    required this.savedAt,
    this.ai,
  });

  factory SavedDream.fromJson(Map<String, dynamic> json) => SavedDream(
    id: json['id'] as String,
    symbolIds: [for (final s in json['symbols'] as List) s as String],
    story: json['story'] as String? ?? '',
    savedAt: DateTime.parse(json['savedAt'] as String),
    ai: DreamAi.tryParse(json['ai']),
  );

  final String id;
  final List<String> symbolIds;
  final String story;
  final DateTime savedAt;

  /// AI 해몽. 키워드만 골랐거나 서버가 실패했으면 null.
  final DreamAi? ai;

  Map<String, Object> toJson() => {
    'id': id,
    'symbols': symbolIds,
    'story': story,
    'savedAt': savedAt.toIso8601String(),
    'ai': ?ai?.toJson(),
  };
}

final savedDreamsProvider =
    NotifierProvider<SavedDreamsNotifier, List<SavedDream>>(
      SavedDreamsNotifier.new,
    );

/// 기기에 저장한 해몽 (최신순).
class SavedDreamsNotifier extends Notifier<List<SavedDream>> {
  static const _key = 'dream.saved';

  @override
  List<SavedDream> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    state = [
      for (final e in jsonDecode(raw) as List)
        SavedDream.fromJson(e as Map<String, dynamic>),
    ];
  }

  bool contains(String id) => state.any((d) => d.id == id);

  Future<void> add(SavedDream dream) async {
    if (contains(dream.id)) return;
    state = [dream, ...state];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [
      for (final d in state)
        if (d.id != id) d,
    ];
    await _persist();
  }

  /// 삭제를 되돌릴 때 원래 자리로 다시 넣는다.
  Future<void> restore(SavedDream dream) async {
    if (contains(dream.id)) return;
    state = [...state, dream]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final d in state) d.toJson()]),
    );
  }
}
