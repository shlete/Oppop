import 'package:flutter/material.dart';

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
            icon: Icons.donut_large,
            color: scheme.surfaceContainerLowest,
            builder: (_) => const RouletteScreen(),
          ),
          const SizedBox(height: 12),
          _Entry(
            title: '사다리타기',
            subtitle: '친구들과 누가 뭘 할지 정하기',
            icon: Icons.stairs_outlined,
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
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: builder)),
      ),
    );
  }
}
