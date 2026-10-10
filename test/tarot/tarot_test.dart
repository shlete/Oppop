import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/features/daily/phrase_card.dart' show keepWords;
import 'package:oneul_ppopgi/features/tarot/consult_screen.dart';
import 'package:oneul_ppopgi/features/tarot/daily_tarot_screen.dart';
import 'package:oneul_ppopgi/features/tarot/tarot_cards.dart';
import 'package:oneul_ppopgi/features/tarot/tarot_logic.dart';
import 'package:oneul_ppopgi/features/tarot/tarot_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final deck = TarotDeck.fromJson(
    jsonDecode(File('assets/tarot/cards.json').readAsStringSync()) as List,
  );
  final ids = [for (final c in deck.cards) c.id];

  test('덱: 78장, id가 겹치지 않고, 그림과 해석이 모두 있다', () {
    expect(deck.cards.length, 78);
    expect(ids.toSet().length, 78);
    for (final c in deck.cards) {
      expect(File(c.image).existsSync(), isTrue, reason: '${c.id} 그림 없음');
      for (final r in [c.upright, c.reversed]) {
        expect(r.keywords.length, 3, reason: c.id);
        expect(r.today.trim(), isNotEmpty, reason: c.id);
        for (final t in TarotTopic.values) {
          expect(r.topics[t]!.trim(), isNotEmpty, reason: '${c.id} ${t.name}');
        }
      }
    }
  });

  test('오늘의 카드는 같은 날·같은 기기면 같고, 날이 바뀌면 달라질 수 있다', () {
    final a = dailyFortune(
      cardIds: ids,
      date: DateTime(2026, 10, 10, 8),
      deviceSeed: 7,
    );
    final b = dailyFortune(
      cardIds: ids,
      date: DateTime(2026, 10, 10, 23),
      deviceSeed: 7,
    );
    expect(a.card, b.card);
    expect(a.luckyNumber, b.luckyNumber);
    final days = {
      for (var d = 1; d <= 20; d++)
        dailyFortune(
          cardIds: ids,
          date: DateTime(2026, 10, d),
          deviceSeed: 7,
        ).card,
    };
    expect(days.length, greaterThan(10));
  });

  test('역방향은 30% 안팎으로 나온다', () {
    final r = Random(1);
    var reversed = 0;
    for (var i = 0; i < 200; i++) {
      reversed += shuffledSpread(ids, r).where((c) => c.reversed).length;
    }
    expect(reversed / (200 * ids.length), closeTo(0.3, 0.03));
  });

  testWidgets('오늘의 운세: 카드를 뒤집으면 이름과 해석이 나오고 저장할 수 있다', (tester) async {
    final container = ProviderContainer(
      overrides: [tarotDeckProvider.overrideWith((ref) => deck)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: DailyTarotScreen(now: DateTime(2026, 10, 10))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('카드 뒤집기'));
    await tester.pumpAndSettle();

    final seed = container.read(tarotSeedProvider).value!;
    final f = dailyFortune(
      cardIds: ids,
      date: DateTime(2026, 10, 10),
      deviceSeed: seed,
    );
    final card = deck.byId(f.card.cardId)!;
    expect(find.text(card.name), findsOneWidget);
    expect(
      find.text(keepWords(card.reading(f.card.reversed).today)),
      findsOneWidget,
    );
    expect(container.read(dailyFlippedProvider), isTrue);

    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(container.read(savedReadingsProvider).single.cards.single, f.card);
  });

  testWidgets('고민상담: 주제를 고르고 3장을 골라 결과를 본다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [tarotDeckProvider.overrideWith((ref) => deck)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ConsultScreen(random: Random(5))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('연애'));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(FilledButton, '결과 보기');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    // 처음에는 가운데쯤이 보인다.
    for (final i in [36, 39, 42]) {
      // 카드가 겹쳐 있어 왼쪽 가장자리 쪽이 보인다.
      final rect = tester.getRect(find.byKey(ValueKey('spread-$i')));
      await tester.tapAt(Offset(rect.left + rect.width * 0.15, rect.center.dy));
      await tester.pump();
    }
    expect(find.text('카드를 다 골랐어요'), findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('타로 결과'), findsOneWidget);
    expect(find.text('통합 점괘'), findsOneWidget);
    // 통합 점괘에는 세 자리 해석이 모두 있다.
    for (final label in ['과거 · 원인  |', '현재 · 상황  |', '미래 · 조언  |']) {
      expect(find.textContaining(label), findsOneWidget);
    }

    await tester.tap(find.text('저장'));
    await tester.pump();
    final saved = container.read(savedReadingsProvider).single;
    expect(saved.topic, TarotTopic.love);
    expect(saved.cards.length, 3);
  });
}
