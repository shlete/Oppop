import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/features/my/my_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget app() => const ProviderScope(child: MaterialApp(home: MyScreen()));

  testWidgets('저장한 게 없으면 안내 문구가 나온다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 저장한 기록이 없어요'), findsOneWidget);
  });

  testWidgets('로또와 문구 저장 기록이 개수와 최근 목록에 모인다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lotto.saved': jsonEncode([
        {
          'numbers': [3, 11, 19, 25, 33, 41],
          'savedAt': '2026-10-09T10:00:00.000',
          'memo': '',
        },
      ]),
      'daily.saved': jsonEncode([
        {
          'id': 'c001',
          'category': 'cheer',
          'text': '오늘도 잘 해냈어요.',
          'savedAt': '2026-10-10T09:00:00.000',
        },
      ]),
    });
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('3  11  19  25  33  41'), findsOneWidget);
    expect(find.text('오늘도 잘 해냈어요.'), findsOneWidget);
    // 최신순: 문구(10일)가 로또(9일)보다 위.
    expect(
      tester.getTopLeft(find.text('오늘도 잘 해냈어요.')).dy,
      lessThan(tester.getTopLeft(find.text('3  11  19  25  33  41')).dy),
    );

    await tester.tap(find.text('로또'));
    await tester.pumpAndSettle();
    expect(find.text('저장한 번호'), findsOneWidget);
  });
}
