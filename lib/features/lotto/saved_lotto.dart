import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 저장한 로또 번호 한 게임.
class SavedGame {
  const SavedGame({
    required this.numbers,
    required this.savedAt,
    this.memo = '',
  });

  final List<int> numbers;
  final DateTime savedAt;
  final String memo;

  SavedGame copyWith({String? memo}) =>
      SavedGame(numbers: numbers, savedAt: savedAt, memo: memo ?? this.memo);

  Map<String, Object> toJson() => {
    'numbers': numbers,
    'savedAt': savedAt.toIso8601String(),
    'memo': memo,
  };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
    numbers: (json['numbers'] as List).cast<int>(),
    savedAt: DateTime.parse(json['savedAt'] as String),
    memo: json['memo'] as String? ?? '',
  );
}

final savedLottoProvider =
    NotifierProvider<SavedLottoNotifier, List<SavedGame>>(
      SavedLottoNotifier.new,
    );

/// 기기에 저장한 번호 목록 (최신순).
class SavedLottoNotifier extends Notifier<List<SavedGame>> {
  static const _key = 'lotto.saved';

  @override
  List<SavedGame> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    state = [
      for (final e in jsonDecode(raw) as List)
        SavedGame.fromJson(e as Map<String, dynamic>),
    ];
  }

  bool contains(List<int> numbers) =>
      state.any((g) => _same(g.numbers, numbers));

  Future<void> add(List<int> numbers) async {
    if (contains(numbers)) return;
    state = [SavedGame(numbers: numbers, savedAt: DateTime.now()), ...state];
    await _persist();
  }

  /// 삭제를 되돌릴 때 원래 저장 시각·메모 그대로 다시 넣는다.
  Future<void> restore(SavedGame game) async {
    if (contains(game.numbers)) return;
    state = [...state, game]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    await _persist();
  }

  Future<void> remove(List<int> numbers) async {
    state = [
      for (final g in state)
        if (!_same(g.numbers, numbers)) g,
    ];
    await _persist();
  }

  Future<void> setMemo(SavedGame game, String memo) async {
    state = [
      for (final g in state) identical(g, game) ? g.copyWith(memo: memo) : g,
    ];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final g in state) g.toJson()]),
    );
  }
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
