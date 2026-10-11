import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/app.dart';
import 'package:oneul_ppopgi/shell/nav_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppNavTabs.initial = AppNavTabs.defaults;
  });

  test('저장값이 이상하면 기본 하단 메뉴로', () {
    expect(AppNavTabs.parse(null), AppNavTabs.defaults);
    expect(AppNavTabs.parse(['tarot', 'lotto']), AppNavTabs.defaults);
    expect(AppNavTabs.parse(['tarot', 'tarot', 'lotto']), AppNavTabs.defaults);
    expect(AppNavTabs.parse(['tarot', 'nope', 'lotto']), AppNavTabs.defaults);
    expect(AppNavTabs.parse(['dream', 'daily', 'lotto']), [
      NavItem.dream,
      NavItem.daily,
      NavItem.lotto,
    ]);
  });

  test('이미 다른 칸에 있는 메뉴를 고르면 두 칸이 자리를 바꾼다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final tabs = container.read(navTabsProvider.notifier);

    await tabs.setSlot(0, NavItem.random);
    expect(container.read(navTabsProvider), [
      NavItem.random,
      NavItem.lotto,
      NavItem.tarot,
    ]);

    await tabs.setSlot(1, NavItem.dream);
    expect(container.read(navTabsProvider), [
      NavItem.random,
      NavItem.dream,
      NavItem.tarot,
    ]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(AppNavTabs.key), ['random', 'dream', 'tarot']);
    expect(AppNavTabs.parse(prefs.getStringList(AppNavTabs.key)), [
      NavItem.random,
      NavItem.dream,
      NavItem.tarot,
    ]);
  });

  testWidgets('설정에서 고른 메뉴가 하단 탭에 나오고, 홈 타일은 그 탭으로 간다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OneulPpopgiApp()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('하단 메뉴'));
    await tester.pumpAndSettle();

    // 2번째 칸(로또)을 해몽으로.
    await tester.tap(find.text('2번째 칸'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('해몽').last);
    await tester.pumpAndSettle();
    expect(find.text('해몽'), findsWidgets);

    // 저장 전에는 하단 탭이 그대로다.
    final bar = find.byType(NavigationBar).last;
    expect(find.descendant(of: bar, matching: find.text('해몽')), findsNothing);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('하단 메뉴를 저장했어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // 안내 문구가 사라질 때까지
    await tester.pumpAndSettle();
    expect(find.text('로또'), findsNothing);

    // 저장하면 탭바에 해몽이 생긴다.
    expect(find.descendant(of: bar, matching: find.text('해몽')), findsOneWidget);

    // 홈의 해몽뽑기 타일은 해몽 탭으로 옮겨 간다 (탭바에서 해몽이 선택됨).
    await tester.tap(find.descendant(of: bar, matching: find.text('홈')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('해몽뽑기'));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<NavigationBar>(bar).selectedIndex, 2);
    expect(find.text('어떤 꿈을 꾸셨나요?'), findsOneWidget);

    // 탭에서 빠진 로또는 홈 안에서 열린다 (선택된 탭은 홈 그대로).
    await tester.tap(find.descendant(of: bar, matching: find.text('홈')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('로또뽑기'));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<NavigationBar>(bar).selectedIndex, 0);
    expect(find.text('번호 뽑기'), findsOneWidget);
  });
}
