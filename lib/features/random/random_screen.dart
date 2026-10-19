import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_icons.dart';
import 'ladder/ladder_screen.dart';
import 'roulette/roulette_screen.dart';

class RandomScreen extends StatelessWidget {
  const RandomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('랜덤')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Entry(
            title: '룰렛',
            subtitle: '항목을 넣고 돌려서 하나 뽑기',
            icon: const Icon(LucideIcons.loaderPinwheel),
            color: scheme.surfaceContainerLowest,
            builder: (_) => const RouletteScreen(),
          ),
          const SizedBox(height: 12),
          _Entry(
            title: '사다리타기',
            subtitle: '친구들과 누가 뭘 할지 정하기',
            icon: const AppGlyph(AppGlyph.ladder),
            color: scheme.surfaceContainerLowest,
            builder: (_) => const LadderScreen(),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final Color color;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: IconTheme.merge(
          data: const IconThemeData(size: 32),
          child: icon,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(subtitle),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: builder)),
      ),
    );
  }
}
