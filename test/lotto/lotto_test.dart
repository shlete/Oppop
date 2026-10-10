import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/features/lotto/lotto_ball.dart';
import 'package:oneul_ppopgi/features/lotto/lotto_logic.dart';
import 'package:oneul_ppopgi/features/lotto/lotto_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('1~45 중 서로 다른 6개를 오름차순으로 뽑는다', () {
    final r = Random(1);
    for (var i = 0; i < 1000; i++) {
      final n = drawLotto(r);
      expect(n.length, 6);
      expect(n.toSet().length, 6);
      expect(n.every((x) => x >= 1 && x <= 45), isTrue);
      expect(n, [...n]..sort());
    }
  });

  test('공 색상은 번호 구간별로 정해진다', () {
    expect(lottoBallColor(1), lottoBallColor(10));
    expect(lottoBallColor(11), isNot(lottoBallColor(10)));
    expect(lottoBallColor(45), lottoBallColor(41));
  });

  Widget app() => const ProviderScope(child: MaterialApp(home: LottoScreen()));

  testWidgets('1게임·5게임을 뽑고, 저장한 번호에서 메모·삭제·되돌리기를 한다', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('번호 뽑기'));
    await tester.pumpAndSettle();
    expect(find.byType(LottoBall), findsNWidgets(6));
    expect(find.text('다시 뽑기'), findsOneWidget);

    // 게임 수를 바꾸면 뽑아 둔 번호는 비워진다.
    await tester.tap(find.text('5게임'));
    await tester.pumpAndSettle();
    expect(find.byType(LottoBall), findsNothing);
    await tester.tap(find.text('번호 뽑기'));
    await tester.pumpAndSettle();
    expect(find.byType(LottoBall), findsNWidgets(30));

    await tester.tap(find.byTooltip('저장').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('저장 취소'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lotto.saved'), isNotNull);

    await tester.tap(find.byTooltip('저장한 번호'));
    await tester.pumpAndSettle();
    expect(find.byType(LottoBall), findsNWidgets(6));

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('메모'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '꿈에서 본 번호');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('꿈에서 본 번호'), findsOneWidget);

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('아직 저장한 번호가 없어요'), findsOneWidget);

    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.text('꿈에서 본 번호'), findsOneWidget);
  });
}
