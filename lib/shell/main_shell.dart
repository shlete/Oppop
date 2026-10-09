import 'package:flutter/material.dart';

import '../core/ads/banner_ad_bar.dart';
import '../features/home/home_screen.dart';
import '../features/lotto/lotto_screen.dart';
import '../features/my/my_screen.dart';
import '../features/random/random_screen.dart';
import '../features/tarot/tarot_screen.dart';

/// 하단 탭: 홈 · 타로 · 로또 · 랜덤 · 마이. 배너 광고는 탭바 바로 위에 고정.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: _goTo),
      const TarotScreen(),
      const LottoScreen(),
      const RandomScreen(),
      const MyScreen(),
    ];
    return Scaffold(
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
    );
  }
}
