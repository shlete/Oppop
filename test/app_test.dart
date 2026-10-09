import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/app.dart';

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

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('좋은 글귀 · 응원 한마디 · 오늘 주의할 점'));
    await tester.pumpAndSettle();
    expect(find.text('응원 한마디'), findsOneWidget);
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
