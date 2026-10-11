import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 하단 탭 가운데 칸에 넣을 수 있는 메뉴. 홈과 마이는 양 끝에 늘 고정이다.
enum NavItem {
  tarot('타로'),
  dream('해몽'),
  lotto('로또'),
  random('랜덤'),
  daily('오늘의 뽑기');

  const NavItem(this.label);

  final String label;
}

/// 설정 > 하단 메뉴: 가운데 [slots]칸에 무엇을 어떤 순서로 둘지.
abstract final class AppNavTabs {
  static const key = 'settings.navTabs';
  static const slots = 3;
  static const defaults = [NavItem.tarot, NavItem.lotto, NavItem.random];

  /// 앱 시작 전에 [load]로 읽어 둔 값. 첫 화면부터 고른 탭으로 그린다.
  static List<NavItem> initial = defaults;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    initial = parse(prefs.getStringList(key));
  }

  /// 저장된 이름 목록을 읽는다. 모르는 이름, 겹치는 메뉴, 개수가 맞지 않으면 기본값.
  static List<NavItem> parse(List<String>? names) {
    if (names == null || names.length != slots) return defaults;
    final items = <NavItem>[];
    for (final name in names) {
      final item = NavItem.values.where((i) => i.name == name).firstOrNull;
      if (item == null || items.contains(item)) return defaults;
      items.add(item);
    }
    return List.unmodifiable(items);
  }

  /// [slot]번째 칸을 [item]으로 바꾼 목록. 이미 다른 칸에 있던 메뉴면 두 칸을 맞바꾼다.
  static List<NavItem> withSlot(List<NavItem> tabs, int slot, NavItem item) {
    final next = [...tabs];
    final from = next.indexOf(item);
    if (from >= 0) next[from] = next[slot];
    next[slot] = item;
    return List.unmodifiable(next);
  }

  static bool same(List<NavItem> a, List<NavItem> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((e) => e);
}

final navTabsProvider = NotifierProvider<NavTabsNotifier, List<NavItem>>(
  NavTabsNotifier.new,
);

class NavTabsNotifier extends Notifier<List<NavItem>> {
  @override
  List<NavItem> build() => AppNavTabs.initial;

  /// [slot]번째 칸을 [item]으로 바꾼다. 이미 다른 칸에 있던 메뉴면 두 칸을 맞바꾼다.
  Future<void> setSlot(int slot, NavItem item) =>
      save(AppNavTabs.withSlot(state, slot, item));

  Future<void> reset() => save(AppNavTabs.defaults);

  Future<void> save(List<NavItem> items) async {
    state = List.unmodifiable(items);
    AppNavTabs.initial = state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppNavTabs.key, [for (final i in state) i.name]);
  }
}
