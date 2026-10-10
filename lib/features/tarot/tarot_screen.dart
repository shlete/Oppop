import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/saved_list_button.dart';
import 'consult_screen.dart';
import 'daily_tarot_screen.dart';
import 'saved_readings_screen.dart';
import 'tarot_card_view.dart';
import 'tarot_state.dart';

/// 타로 메뉴: 오늘의 운세(1장) / 고민상담(3장).
class TarotScreen extends ConsumerWidget {
  const TarotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final saved = ref.watch(savedReadingsProvider);
    final flipped = ref.watch(dailyFlippedProvider) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('타로'),
        actions: [
          SavedListButton(
            count: saved.length,
            tooltip: '저장한 타로',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedReadingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Entry(
            title: '오늘의 운세',
            subtitle: flipped ? '오늘의 카드 다시 보기' : '하루 한 장, 오늘의 카드 뒤집기',
            cards: 1,
            color: scheme.surfaceContainerLowest,
            builder: (_) => const DailyTarotScreen(),
          ),
          const SizedBox(height: 12),
          _Entry(
            title: '고민상담',
            subtitle: '연애 · 학업 · 진로 · 금전 · 건강',
            cards: 3,
            color: scheme.surfaceContainerLowest,
            builder: (_) => const ConsultScreen(),
          ),
          const SizedBox(height: 16),
          Text(
            '카드 그림: 1909년 라이더-웨이트-스미스 덱 (퍼블릭 도메인)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
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
    required this.cards,
    required this.color,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final int cards;
  final Color color;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: builder)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < cards; i++)
                      Transform.translate(
                        offset: Offset((i - (cards - 1) / 2) * 16, 0),
                        child: Transform.rotate(
                          angle: (i - (cards - 1) / 2) * 0.18,
                          child: const SizedBox(
                            width: 36,
                            child: TarotCardBack(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: text.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
