import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/primary_button.dart';
import '../../shell/main_shell.dart' show navItemIcon;
import '../../shell/nav_tabs.dart';

/// 설정 > 하단 메뉴: 홈과 마이 사이 세 칸에 둘 메뉴를 고른다.
/// 고른 내용은 '저장'을 눌러야 하단 탭에 반영된다.
class NavTabsScreen extends ConsumerStatefulWidget {
  const NavTabsScreen({super.key});

  static String slotName(int slot) => '${slot + 1}번째 칸';

  @override
  ConsumerState<NavTabsScreen> createState() => _NavTabsScreenState();
}

class _NavTabsScreenState extends ConsumerState<NavTabsScreen> {
  late List<NavItem> _draft = ref.read(navTabsProvider);

  bool get _dirty => !AppNavTabs.same(_draft, ref.read(navTabsProvider));

  @override
  Widget build(BuildContext context) {
    ref.watch(navTabsProvider);
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text('바꾼 내용을 저장하지 않고 나갈까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 고르기'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('나가기'),
              ),
            ],
          ),
        );
        // Navigator.pop은 PopScope를 거치지 않고 바로 닫는다.
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
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
                    for (final item in _draft)
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
                  for (var slot = 0; slot < _draft.length; slot++)
                    ListTile(
                      title: Text(NavTabsScreen.slotName(slot)),
                      subtitle: Text(_draft[slot].label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pick(slot),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: '저장', onPressed: _dirty ? _save : null),
            const SizedBox(height: 8),
            Align(
              child: TextButton(
                onPressed: AppNavTabs.same(_draft, AppNavTabs.defaults)
                    ? null
                    : () => setState(() => _draft = AppNavTabs.defaults),
                child: const Text('기본값으로 되돌리기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(navTabsProvider.notifier).save(_draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('하단 메뉴를 저장했어요'),
          duration: Duration(milliseconds: 1500),
        ),
      );
  }

  Future<void> _pick(int slot) async {
    final picked = await showModalBottomSheet<NavItem>(
      context: context,
      showDragHandle: true,
      // 메뉴 다섯 개가 다 들어가게 높이를 내용만큼 쓰고, 작은 화면에서는 스크롤.
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: RadioGroup<NavItem>(
            groupValue: _draft[slot],
            onChanged: (item) => Navigator.pop(context, item),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  NavTabsScreen.slotName(slot),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                for (final item in NavItem.values)
                  RadioListTile<NavItem>(
                    value: item,
                    title: Text(item.label),
                    subtitle: switch (_draft.indexOf(item)) {
                      final other when other >= 0 && other != slot => Text(
                        '${NavTabsScreen.slotName(other)}과 자리를 바꿔요',
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
    if (picked != null && mounted) {
      setState(() => _draft = AppNavTabs.withSlot(_draft, slot, picked));
    }
  }
}
