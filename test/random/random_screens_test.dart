import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/features/random/ladder/ladder_screen.dart';
import 'package:oneul_ppopgi/features/random/presets.dart';
import 'package:oneul_ppopgi/features/random/roulette/roulette_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('룰렛을 돌리면 결과가 나오고, 빼고 다시 돌릴 수 있다', (tester) async {
    final expected = builtInPresets.first.items[Random(7).nextInt(6)];
    await tester.pumpWidget(_wrap(RouletteScreen(random: Random(7))));

    await tester.tap(find.text('돌리기'));
    await tester.pumpAndSettle();

    expect(find.text('결과'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(expected),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('이 항목 빼고 다시'));
    await tester.pumpAndSettle();
    expect(find.text('결과'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(expected),
      ),
      findsNothing,
    );
  });

  testWidgets('룰렛 항목을 편집하고 프리셋으로 저장한다', (tester) async {
    await tester.pumpWidget(_wrap(const RouletteScreen()));

    await tester.tap(find.byTooltip('항목 편집'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '마라탕');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '내 점심');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('random.presets'), contains('마라탕'));

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('룰렛'), findsOneWidget);
  });

  testWidgets('사다리: 참가자를 늘리면 결과칸도 늘고, 전체 결과를 볼 수 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(LadderScreen(random: Random(3))));

    await tester.tap(find.text('참가자 추가'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(4), 'E');
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(10));

    await tester.ensureVisible(find.text('사다리 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사다리 만들기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(find.text('?'), findsNWidgets(4));

    await tester.tap(find.text('전체 결과'));
    await tester.pumpAndSettle();
    expect(find.text('?'), findsNothing);
    expect(find.text('당첨'), findsWidgets);
  });

  testWidgets('애니메이션 줄이기 설정에서도 룰렛은 끝까지 천천히 돈다', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_wrap(RouletteScreen(random: Random(7))));

    await tester.tap(find.text('돌리기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('결과'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('결과'), findsOneWidget);
  });
}
