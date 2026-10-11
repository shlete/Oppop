import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/haptics.dart';
import '../../core/theme_mode.dart';
import '../daily/daily_state.dart';
import '../dream/dream_state.dart';
import '../lotto/saved_lotto.dart';
import '../../shell/nav_tabs.dart';
import '../tarot/tarot_state.dart';
import 'nav_tabs_screen.dart';
import 'privacy_screen.dart';

const appVersion = '1.0.0';

/// 설정: 테마, 하단 메뉴, 진동, 기록 삭제, 앱 정보.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final haptics = ref.watch(hapticsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final navTabs = ref.watch(navTabsProvider);

    Widget section(String title, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: text.titleMedium),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          section('화면', [
            ListTile(
              title: const Text('테마'),
              subtitle: Text(_themeLabel(themeMode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickTheme(context, ref, themeMode),
            ),
            ListTile(
              title: const Text('하단 메뉴'),
              subtitle: Text(
                ['홈', for (final i in navTabs) i.label, '마이'].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NavTabsScreen()),
              ),
            ),
          ]),
          section('뽑기', [
            SwitchListTile(
              title: const Text('진동'),
              subtitle: const Text('뽑을 때 살짝 진동이 울려요'),
              value: haptics,
              onChanged: (on) => ref.read(hapticsProvider.notifier).set(on),
            ),
          ]),
          section('기록', [
            ListTile(
              title: const Text('저장 기록 전체 삭제'),
              subtitle: const Text('타로 · 로또 · 오늘의 뽑기 · 해몽뽑기 저장 기록을 모두 지워요'),
              onTap: () => _confirmClear(context, ref),
            ),
          ]),
          section('정보', [
            const ListTile(title: Text('앱 버전'), trailing: Text(appVersion)),
            ListTile(
              title: const Text('오픈소스 라이선스'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _Licenses()),
              ),
            ),
            const ListTile(
              title: Text('카드 그림 출처'),
              subtitle: Text('1909년 라이더-웨이트-스미스 덱 (퍼블릭 도메인)'),
            ),
            ListTile(
              title: const Text('개인정보처리방침'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => '휴대폰 설정 따라가기',
    ThemeMode.light => '라이트',
    ThemeMode.dark => '다크',
  };

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (m) => Navigator.pop(context, m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in ThemeMode.values)
                RadioListTile<ThemeMode>(value: m, title: Text(_themeLabel(m))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await ref.read(themeModeProvider.notifier).set(picked);
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록을 모두 지울까요?'),
        content: const Text(
          '타로 · 로또 · 오늘의 뽑기 · 해몽뽑기 저장 기록이\n모두 지워지고 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Future.wait([
      ref.read(savedReadingsProvider.notifier).clear(),
      ref.read(savedLottoProvider.notifier).clear(),
      ref.read(savedPhrasesProvider.notifier).clear(),
      ref.read(savedDreamsProvider.notifier).clear(),
    ]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('저장 기록을 모두 지웠어요')));
  }
}

/// 라이선스 목록은 길어서 이 화면만 글자와 줄 간격을 줄여 스크롤을 줄인다.
class _Licenses extends StatelessWidget {
  const _Licenses();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(media.textScaler.scale(1) * 0.85),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: const VisualDensity(vertical: -4),
          listTileTheme: const ListTileThemeData(
            dense: true,
            minVerticalPadding: 2,
          ),
        ),
        child: const LicensePage(
          applicationName: '오늘의 뽑기',
          applicationVersion: appVersion,
        ),
      ),
    );
  }
}
