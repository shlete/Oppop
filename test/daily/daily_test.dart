import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/features/daily/daily_screen.dart';
import 'package:oneul_ppopgi/features/daily/phrases.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final book = PhraseBook.fromJson(
    jsonDecode(File('assets/phrases/daily.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('문구 데이터: 카테고리마다 충분히 있고 id가 겹치지 않는다', () {
    final ids = <String>{};
    for (final c in PhraseCategory.values) {
      expect(book.byCategory[c]!.length, greaterThanOrEqualTo(50));
      for (final p in book.byCategory[c]!) {
        expect(ids.add(p.id), isTrue, reason: '중복 id ${p.id}');
        expect(p.text.trim(), isNotEmpty);
      }
    }
    for (final z in Zodiac.values) {
      expect(
        book.byCategory[PhraseCategory.caution]!.where((p) => p.sign == z),
        isNotEmpty,
        reason: '${z.label} 문구가 없어요',
      );
    }
  });

  test('별자리를 고르면 공통 문구와 그 별자리 문구에서만 뽑는다', () {
    final pool = book.pool(PhraseCategory.caution, Zodiac.leo);
    expect(pool.every((p) => p.sign == null || p.sign == Zodiac.leo), isTrue);
    expect(pool.any((p) => p.sign == Zodiac.leo), isTrue);
  });

  test('오늘 본 문구는 다시 나오지 않고, 다 보면 처음부터 다시 나온다', () {
    final r = Random(3);
    final all = book.pool(PhraseCategory.cheer, null);
    final seen = <String>{};
    for (var i = 0; i < all.length; i++) {
      final p = book.pick(PhraseCategory.cheer, seen: seen, random: r)!;
      expect(seen.add(p.id), isTrue, reason: '${p.id} 반복');
    }
    expect(book.pick(PhraseCategory.cheer, seen: seen, random: r), isNotNull);
  });

  testWidgets('카테고리를 골라 뽑고, 저장하고, 저장한 문구에서 지운다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: DailyScreen(random: Random(1))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('뽑기 버튼을 누르면\n오늘의 문구가 나와요'), findsOneWidget);

    await tester.tap(find.text('응원 한마디'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('뽑기'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    final cheers = book.byCategory[PhraseCategory.cheer]!.map((p) => p.text);
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where(cheers.contains)
        .toList();
    expect(shown, hasLength(1));
    expect(find.text('다시 뽑기'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('저장됨'), findsOneWidget);
    expect(find.text('저장 목록 1'), findsOneWidget);

    await tester.tap(find.text('저장 목록 1'));
    await tester.pumpAndSettle();
    expect(find.text(shown.single!), findsOneWidget);
    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('아직 저장한 문구가 없어요'), findsOneWidget);
  });

  testWidgets('오늘 주의할 점에서는 별자리를 고를 수 있다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DailyScreen())),
    );
    expect(find.text('내 별자리 고르기 (선택)'), findsNothing);
    await tester.tap(find.text('오늘 주의할 점'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 별자리 고르기 (선택)'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('사자자리'));
    await tester.pumpAndSettle();
    expect(find.text('내 별자리: 사자자리 · 바꾸기'), findsOneWidget);
  });
}
