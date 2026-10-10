import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/app.dart';
import 'package:oneul_ppopgi/features/tarot/tarot_cards.dart';

void main() {
  testWidgets('홈에서 탭과 메뉴로 각 화면에 이동한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OneulPpopgiApp()));

    expect(find.text('오늘의 뽑기'), findsWidgets);

    await tester.tap(find.byIcon(Icons.casino));
    await tester.pumpAndSettle();
    expect(find.text('번호 뽑기'), findsOneWidget);

    await tester.tap(find.text('랜덤').last);
    await tester.pumpAndSettle();
    expect(find.text('룰렛'), findsOneWidget);

    // 홈의 카드는 계속 둥둥 떠 있어서 pumpAndSettle 대신 시간을 넘긴다.
    await tester.tap(find.text('홈'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('요일'), findsOneWidget);
    await tester.tap(find.text('뽑으러 가기 ›'));
    await tester.pumpAndSettle();
    expect(find.text('응원 한마디'), findsOneWidget);
  });

  testWidgets('홈으로 가면 다른 탭은 첫 화면으로 돌아간다', (tester) async {
    final deck = TarotDeck.fromJson(
      jsonDecode(File('assets/tarot/cards.json').readAsStringSync()) as List,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tarotDeckProvider.overrideWith((ref) => deck)],
        child: const OneulPpopgiApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('타로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('고민상담'));
    await tester.pumpAndSettle();
    expect(find.text('어떤 고민이 있나요?'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('어떤 고민이 있나요?'), findsNothing);

    await tester.tap(find.text('타로'));
    await tester.pumpAndSettle();
    expect(find.text('어떤 고민이 있나요?'), findsNothing);
    expect(find.text('고민상담'), findsOneWidget);
  });

  testWidgets('넓은 화면에서는 가운데 480px 폭으로 제한된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(child: OneulPpopgiApp()));

    final nav = tester.getRect(find.byType(NavigationBar));
    expect(nav.width, 480);
    expect(nav.left, 360);
  });
}
