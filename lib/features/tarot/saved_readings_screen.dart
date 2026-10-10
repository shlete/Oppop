import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/balanced_text.dart';
import '../daily/phrase_card.dart' show keepWords;
import 'consult_result_screen.dart';
import 'tarot_card_view.dart';
import 'tarot_cards.dart';
import 'tarot_state.dart';

class SavedReadingsScreen extends ConsumerWidget {
  const SavedReadingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(savedReadingsProvider);
    final deck = ref.watch(tarotDeckProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('저장한 타로')),
      body: readings.isEmpty
          ? const Center(child: Text('아직 저장한 타로 결과가 없어요'))
          : deck == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: readings.length,
              itemBuilder: (context, i) =>
                  _SavedTile(reading: readings[i], deck: deck),
            ),
    );
  }
}

class _SavedTile extends ConsumerWidget {
  const _SavedTile({required this.reading, required this.deck});

  final SavedReading reading;
  final TarotDeck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final d = reading.savedAt;
    final names = [
      for (final c in reading.cards)
        // 카드 이름 중간에서 줄이 바뀌지 않게.
        keepWords(
          '${deck.byId(c.cardId)?.name ?? '?'}${c.reversed ? '(역)' : ''}',
        ),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _SavedReadingView(reading: reading, deck: deck),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              for (final c in reading.cards) ...[
                SizedBox(
                  width: 34,
                  child: TarotCardFace(
                    card: deck.byId(c.cardId)!,
                    reversed: c.reversed,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reading.title, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      names.join(' · '),
                      style: text.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.year}.${d.month}.${d.day}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '삭제',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final notifier = ref.read(savedReadingsProvider.notifier);
    await notifier.remove(reading.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('삭제했어요'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () => notifier.restore(reading),
        ),
      ),
    );
  }
}

/// 저장한 결과를 다시 펼쳐 보기.
class _SavedReadingView extends StatelessWidget {
  const _SavedReadingView({required this.reading, required this.deck});

  final SavedReading reading;
  final TarotDeck deck;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = reading.savedAt;
    return Scaffold(
      appBar: AppBar(title: Text(reading.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          // 상담 결과는 카드를 옆으로 넘겨 보므로 좌우 여백을 안쪽에서 둔다.
          padding: reading.isDaily
              ? const EdgeInsets.all(16)
              : const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${d.year}년 ${d.month}월 ${d.day}일',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: 12),
              if (reading.isDaily)
                Builder(
                  builder: (context) {
                    final drawn = reading.cards.single;
                    final card = deck.byId(drawn.cardId)!;
                    final r = card.reading(drawn.reversed);
                    return Column(
                      children: [
                        SizedBox(
                          width: 160,
                          child: TarotCardFace(
                            card: card,
                            reversed: drawn.reversed,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(card.name, style: text.titleLarge),
                            const SizedBox(width: 8),
                            OrientationBadge(reversed: drawn.reversed),
                          ],
                        ),
                        const SizedBox(height: 10),
                        KeywordRow(keywords: r.keywords),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: BalancedText(
                            keepWords(r.today),
                            style: text.bodyLarge!.copyWith(height: 1.6),
                          ),
                        ),
                        if (reading.luckyColor != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '행운의 색 ${reading.luckyColor} · '
                            '행운의 숫자 ${reading.luckyNumber}',
                            style: text.bodyMedium,
                          ),
                        ],
                      ],
                    );
                  },
                )
              else
                ConsultReading(
                  deck: deck,
                  topic: reading.topic!,
                  cards: reading.cards,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
