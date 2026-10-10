import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tarot_cards.dart';
import 'tarot_logic.dart';

/// 기기마다 한 번 정해 두는 숫자. 오늘의 카드가 사람마다 다르게 나오도록 날짜와 섞는다.
/// 로그인하면 회원 id로 바꿀 수 있다.
final tarotSeedProvider = FutureProvider<int>((ref) async {
  const key = 'tarot.seed';
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getInt(key);
  if (saved != null) return saved;
  final seed = Random().nextInt(1 << 31);
  await prefs.setInt(key, seed);
  return seed;
});

final dailyFlippedProvider = NotifierProvider<DailyFlippedNotifier, bool?>(
  DailyFlippedNotifier.new,
);

/// 오늘의 카드를 이미 뒤집어 봤는지. 읽는 중이면 null.
class DailyFlippedNotifier extends Notifier<bool?> {
  static const _key = 'tarot.dailyFlipped';

  @override
  bool? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) == dayKey(DateTime.now());
  }

  Future<void> flip() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, dayKey(DateTime.now()));
  }
}

/// 저장한 타로 결과 한 개.
class SavedReading {
  const SavedReading({
    required this.id,
    required this.cards,
    required this.savedAt,
    this.topic,
    this.luckyColor,
    this.luckyNumber,
  });

  final String id;

  /// 오늘의 운세면 1장, 고민상담이면 과거·현재·미래 순 3장.
  final List<DrawnCard> cards;
  final DateTime savedAt;

  /// 고민상담 주제. 오늘의 운세면 null.
  final TarotTopic? topic;

  /// 오늘의 운세에만 있다.
  final String? luckyColor;
  final int? luckyNumber;

  bool get isDaily => topic == null;

  String get title => isDaily ? '오늘의 운세' : '고민상담 · ${topic!.label}';

  Map<String, Object> toJson() => {
    'id': id,
    'cards': [for (final c in cards) c.toJson()],
    'savedAt': savedAt.toIso8601String(),
    'topic': ?topic?.name,
    'luckyColor': ?luckyColor,
    'luckyNumber': ?luckyNumber,
  };

  factory SavedReading.fromJson(Map<String, dynamic> json) => SavedReading(
    id: json['id'] as String,
    cards: [
      for (final c in json['cards'] as List)
        DrawnCard.fromJson(c as Map<String, dynamic>),
    ],
    savedAt: DateTime.parse(json['savedAt'] as String),
    topic: json['topic'] == null
        ? null
        : TarotTopic.values.byName(json['topic'] as String),
    luckyColor: json['luckyColor'] as String?,
    luckyNumber: json['luckyNumber'] as int?,
  );
}

final savedReadingsProvider =
    NotifierProvider<SavedReadingsNotifier, List<SavedReading>>(
      SavedReadingsNotifier.new,
    );

/// 기기에 저장한 타로 결과 (최신순). 나중에 마이 탭 기록으로 옮긴다.
class SavedReadingsNotifier extends Notifier<List<SavedReading>> {
  static const _key = 'tarot.saved';

  @override
  List<SavedReading> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    state = [
      for (final e in jsonDecode(raw) as List)
        SavedReading.fromJson(e as Map<String, dynamic>),
    ];
  }

  bool contains(String id) => state.any((r) => r.id == id);

  Future<void> add(SavedReading reading) async {
    if (contains(reading.id)) return;
    state = [reading, ...state];
    await _persist();
  }

  /// 삭제를 되돌릴 때 원래 자리로 다시 넣는다.
  Future<void> restore(SavedReading reading) async {
    if (contains(reading.id)) return;
    state = [...state, reading]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [
      for (final r in state)
        if (r.id != id) r,
    ];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final r in state) r.toJson()]),
    );
  }
}
