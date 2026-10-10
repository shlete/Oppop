import 'package:flutter/material.dart';

import '../core/ads/banner_ad_bar.dart';
import '../features/home/home_screen.dart';
import '../features/lotto/lotto_screen.dart';
import '../features/my/my_screen.dart';
import '../features/random/random_screen.dart';
import '../features/tarot/tarot_screen.dart';

/// 하단 탭: 홈 · 타로 · 로또 · 랜덤 · 마이. 배너 광고는 탭바 바로 위에 고정.
/// 탭마다 화면 이동 기록(Navigator)을 따로 두어, 안쪽 화면으로 들어가도
/// 탭바와 배너가 늘 보이고 탭을 바꿨다 돌아와도 보던 화면이 그대로 남는다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void _goTo(int index) {
    if (index == _index) {
      // 지금 탭을 한 번 더 누르면 그 탭의 첫 화면으로.
      _navigators[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      // 홈으로 가면 다른 탭들은 새로 만들어 처음 상태로 되돌린다
      // (안쪽 화면은 닫히고, 로또에서 뽑아 둔 번호 같은 첫 화면 상태도 비워짐).
      if (index == 0) {
        for (var i = 1; i < _navigators.length; i++) {
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
    final pages = [
      _tab(0, HomeScreen(onOpenTab: _goTo)),
      _tab(1, const TarotScreen()),
      _tab(2, const LottoScreen()),
      _tab(3, const RandomScreen()),
      _tab(4, const MyScreen()),
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
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '홈',
                ),
                NavigationDestination(
                  icon: Icon(Icons.style_outlined),
                  selectedIcon: Icon(Icons.style),
                  label: '타로',
                ),
                NavigationDestination(
                  icon: Icon(Icons.casino_outlined),
                  selectedIcon: Icon(Icons.casino),
                  label: '로또',
                ),
                NavigationDestination(icon: Icon(Icons.shuffle), label: '랜덤'),
                NavigationDestination(
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
