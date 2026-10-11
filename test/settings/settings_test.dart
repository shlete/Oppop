import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/core/haptics.dart';
import 'package:oneul_ppopgi/core/theme_mode.dart';
import 'package:oneul_ppopgi/features/my/my_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget app() => const ProviderScope(child: MaterialApp(home: MyScreen()));

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('설정'), 200);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
  }

  testWidgets('전체 삭제는 확인 후 모든 저장 기록을 지운다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lotto.saved': jsonEncode([
        {
          'numbers': [3, 11, 19, 25, 33, 41],
          'savedAt': '2026-10-09T10:00:00.000',
          'memo': '',
        },
      ]),
    });
    await openSettings(tester);

    await tester.tap(find.text('저장 기록 전체 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lotto.saved'), contains('41'));

    await tester.tap(find.text('저장 기록 전체 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('저장 기록을 모두 지웠어요'), findsOneWidget);
    prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('lotto.saved')!), isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 저장한 기록이 없어요'), findsOneWidget);
  });

  testWidgets('진동 스위치는 설정을 저장한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppHaptics.enabled = true;
    await openSettings(tester);
    expect(find.text('카드 그림 출처'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(AppHaptics.enabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppHaptics.key), isFalse);
    AppHaptics.enabled = true;
  });

  testWidgets('테마를 다크로 고르면 저장되고 화면에 표시된다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppThemeMode.initial = ThemeMode.system;
    await openSettings(tester);
    expect(find.text('휴대폰 설정 따라가기'), findsOneWidget);

    await tester.tap(find.text('테마'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();
    expect(find.text('다크'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppThemeMode.key), 'dark');
    AppThemeMode.initial = ThemeMode.system;
  });

  testWidgets('개인정보처리방침을 열면 본문이 보인다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openSettings(tester);
    await tester.ensureVisible(find.text('개인정보처리방침'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('개인정보처리방침'));
    await tester.pumpAndSettle();
    // 본문은 실제 파일에서 읽으므로 그 시간을 기다린다.
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('오늘의 뽑기 개인정보처리방침'), findsOneWidget);
    expect(find.text('1. 수집하는 개인정보와 이용 목적'), findsOneWidget);
  });
}
