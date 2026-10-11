import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ads/banner_ad_bar.dart';
import '../core/widgets/dream_icon.dart';
import '../features/daily/daily_screen.dart';
import '../features/dream/dream_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lotto/lotto_screen.dart';
import '../features/my/my_screen.dart';
import '../features/random/random_screen.dart';
import '../features/tarot/tarot_screen.dart';
import 'nav_tabs.dart';

/// 하단 탭: 홈 · (설정에서 고른 메뉴 3개) · 마이. 배너 광고는 탭바 바로 위에 고정.
/// 탭마다 화면 이동 기록(Navigator)을 따로 두어, 안쪽 화면으로 들어가도
/// 탭바와 배너가 늘 보이고 탭을 바꿨다 돌아와도 보던 화면이 그대로 남는다.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

/// 메뉴 첫 화면.
Widget navItemScreen(NavItem item) => switch (item) {
  NavItem.tarot => const TarotScreen(),
  NavItem.dream => const DreamScreen(),
  NavItem.lotto => const LottoScreen(),
  NavItem.random => const RandomScreen(),
  NavItem.daily => const DailyScreen(),
};

/// 탭바에 쓰는 메뉴 아이콘 (고르기 전 / 고른 뒤).
Widget navItemIcon(NavItem item, {bool selected = false}) => switch (item) {
  NavItem.tarot => Icon(selected ? Icons.style : Icons.style_outlined),
  NavItem.dream => Builder(
    builder: (context) =>
        DreamIcon(color: IconTheme.of(context).color ?? Colors.black, size: 22),
  ),
  NavItem.lotto => Icon(selected ? Icons.casino : Icons.casino_outlined),
  NavItem.random => const Icon(Icons.shuffle),
  NavItem.daily => Icon(
    selected ? Icons.auto_awesome : Icons.auto_awesome_outlined,
  ),
};

class _MainShellState extends ConsumerState<MainShell> {
  /// 마이는 늘 맨 끝 (홈 + 가운데 칸들 다음).
  static const _myTab = AppNavTabs.slots + 1;
  int _index = 0;
  final _navigators = List.generate(
    AppNavTabs.slots + 2,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// 홈 타일에서 메뉴를 열 때: 하단 탭에 있으면 그 탭으로, 없으면 홈 안에서 연다.
  void _open(NavItem item) {
    final slot = ref.read(navTabsProvider).indexOf(item);
    if (slot >= 0) {
      _goTo(slot + 1);
    } else {
      _navigators[0].currentState?.push(
        MaterialPageRoute(builder: (_) => navItemScreen(item)),
      );
    }
  }

  void _goTo(int index) {
    if (index == _index) {
      // 지금 탭을 한 번 더 누르면 그 탭의 첫 화면으로.
      _navigators[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    // 마이 탭(설정 등)은 다른 탭으로 나가면 첫 화면으로 돌려 둔다.
    if (_index == _myTab) {
      _navigators[_myTab].currentState?.popUntil((r) => r.isFirst);
    }
    setState(() {
      // 홈으로 가면 다른 탭들은 새로 만들어 처음 상태로 되돌린다
      // (안쪽 화면은 닫히고, 로또에서 뽑아 둔 번호 같은 첫 화면 상태도 비워짐).
      // 홈 탭 안에서 열어 둔 화면(오늘의 뽑기 등)도 닫아서 홈 첫 화면이 나오게 한다.
      if (index == 0) {
        for (var i = 0; i < _navigators.length; i++) {
          _navigators[i] = GlobalKey<NavigatorState>();
        }
      }
      _index = index;
    });
  }

  // 안 보이는 탭의 애니메이션은 멈춰 둔다.
  Widget _tab(int i, Widget root) => TickerMode(
    enabled: i == _index,
    child: Navigator(
      key: _navigators[i],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(navTabsProvider);
    // 하단 메뉴를 바꾸면 가운데 탭들을 새로 만든다 (설정은 마이 탭 안이라 보던 화면은 그대로).
    ref.listen(navTabsProvider, (_, _) {
      setState(() {
        for (var i = 1; i <= AppNavTabs.slots; i++) {
          _navigators[i] = GlobalKey<NavigatorState>();
        }
      });
    });
    final pages = [
      _tab(0, HomeScreen(onOpen: _open)),
      for (var i = 0; i < tabs.length; i++) _tab(i + 1, navItemScreen(tabs[i])),
      _tab(_myTab, const MyScreen()),
    ];
    // 뒤로가기는 지금 탭 안에서 먼저 한 칸 돌아가고, 첫 화면이면 앱을 닫는다.
    return NavigatorPopHandler(
      onPopWithResult: (_) => _navigators[_index].currentState?.maybePop(),
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BannerAdBar(),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _goTo,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '홈',
                ),
                for (final item in tabs)
                  NavigationDestination(
                    icon: navItemIcon(item),
                    selectedIcon: navItemIcon(item, selected: true),
                    label: item.label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '마이',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
