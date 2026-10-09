import 'package:flutter/material.dart';

import '../daily/daily_screen.dart';

/// 홈: 오늘의 뽑기를 가장 크게, 그 아래 타로·로또·랜덤 바로가기.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// 하단 탭 인덱스로 이동 (1 타로, 2 로또, 3 랜덤).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 뽑기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            title: '오늘의 뽑기',
            subtitle: '좋은 글귀 · 응원 한마디 · 오늘 주의할 점',
            icon: Icons.auto_awesome,
            color: scheme.primaryContainer,
            height: 160,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DailyScreen())),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: '타로',
            subtitle: '오늘의 운세 1장 · 고민상담 3장',
            icon: Icons.style,
            color: scheme.secondaryContainer,
            onTap: () => onOpenTab(1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MenuCard(
                  title: '로또',
                  subtitle: '랜덤 번호',
                  icon: Icons.casino,
                  color: scheme.tertiaryContainer,
                  onTap: () => onOpenTab(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuCard(
                  title: '랜덤',
                  subtitle: '룰렛 · 사다리',
                  icon: Icons.shuffle,
                  color: scheme.surfaceContainerHighest,
                  onTap: () => onOpenTab(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.height = 120,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28),
                const Spacer(),
                Text(title, style: text.titleLarge),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
