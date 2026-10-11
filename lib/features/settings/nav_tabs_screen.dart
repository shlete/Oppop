import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/main_shell.dart' show navItemIcon;
import '../../shell/nav_tabs.dart';

/// 설정 > 하단 메뉴: 홈과 마이 사이 세 칸에 둘 메뉴를 고른다.
class NavTabsScreen extends ConsumerWidget {
  const NavTabsScreen({super.key});

  static String slotName(int slot) => '${slot + 1}번째 칸';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(navTabsProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('하단 메뉴')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            '홈과 마이 사이에 둘 메뉴 세 개를 골라 주세요. 빠진 메뉴는 홈에서 들어갈 수 있어요.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          // 미리보기: 실제 탭바와 같은 모양, 누를 수는 없다.
          Card(
            clipBehavior: Clip.antiAlias,
            child: IgnorePointer(
              child: NavigationBar(
                selectedIndex: 0,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '홈',
                  ),
                  for (final item in tabs)
                    NavigationDestination(
                      icon: navItemIcon(item),
                      label: item.label,
                    ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: '마이',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var slot = 0; slot < tabs.length; slot++)
                  ListTile(
                    title: Text(slotName(slot)),
                    subtitle: Text(tabs[slot].label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pick(context, ref, slot, tabs),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            child: TextButton(
              onPressed: tabs.toString() == AppNavTabs.defaults.toString()
                  ? null
                  : () => ref.read(navTabsProvider.notifier).reset(),
              child: const Text('기본값으로 되돌리기'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    int slot,
    List<NavItem> tabs,
  ) async {
    final picked = await showModalBottomSheet<NavItem>(
      context: context,
      showDragHandle: true,
      // 메뉴 다섯 개가 다 들어가게 높이를 내용만큼 쓰고, 작은 화면에서는 스크롤.
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: RadioGroup<NavItem>(
            groupValue: tabs[slot],
            onChanged: (item) => Navigator.pop(context, item),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slotName(slot),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                for (final item in NavItem.values)
                  RadioListTile<NavItem>(
                    value: item,
                    title: Text(item.label),
                    subtitle: switch (tabs.indexOf(item)) {
                      final other when other >= 0 && other != slot => Text(
                        '${slotName(other)}과 자리를 바꿔요',
                      ),
                      _ => null,
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(navTabsProvider.notifier).setSlot(slot, picked);
    }
  }
}
