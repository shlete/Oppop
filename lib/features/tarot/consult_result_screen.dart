import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/image_save/image_save.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/small_action_button.dart';
import '../daily/save_card_image.dart';
import 'saved_readings_screen.dart';
import 'tarot_card_view.dart';
import 'tarot_cards.dart';
import 'tarot_logic.dart';
import 'tarot_state.dart';

/// 고민상담 결과: 과거·현재·미래 3장을 차례로 뒤집고 주제별 해석을 보여준다.
class ConsultResultScreen extends ConsumerStatefulWidget {
  const ConsultResultScreen({
    super.key,
    required this.topic,
    required this.cards,
  });

  final TarotTopic topic;

  /// 과거·현재·미래 순 3장.
  final List<DrawnCard> cards;

  @override
  ConsumerState<ConsultResultScreen> createState() =>
      _ConsultResultScreenState();
}

class _ConsultResultScreenState extends ConsumerState<ConsultResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
    // 결과 연출이라 '애니메이션 줄이기' 설정에서도 정해진 시간 그대로 재생한다.
    animationBehavior: AnimationBehavior.preserve,
  )..forward();
  final _shotKey = GlobalKey();
  late final String _id = 'consult-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  /// [i]번째 카드의 뒤집기 진행도. 한 장씩 조금씩 늦게 뒤집힌다.
  double _cardT(int i) {
    final start = i * 0.25;
    return Curves.easeInOut.transform(
      ((_flip.value - start) / 0.5).clamp(0.0, 1.0),
    );
  }

  Future<void> _toggleSave() async {
    final saved = ref.read(savedReadingsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (saved.contains(_id)) {
      await saved.remove(_id);
      messenger.showSnackBar(const SnackBar(content: Text('저장을 취소했어요')));
      return;
    }
    await saved.add(
      SavedReading(
        id: _id,
        cards: widget.cards,
        topic: widget.topic,
        savedAt: DateTime.now(),
      ),
    );
    messenger.showSnackBar(
      SnackBar(
        content: const Text('상담 결과를 저장했어요'),
        action: SnackBarAction(
          label: '보기',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SavedReadingsScreen()),
          ),
        ),
      ),
    );
  }

  Future<void> _share(TarotDeck deck) async {
    final bytes = await captureBoundary(_shotKey);
    if (bytes == null) return;
    final lines = [
      for (final pos in SpreadPosition.values)
        '${pos.label}: ${deck.byId(widget.cards[pos.index].cardId)!.name}'
            '${widget.cards[pos.index].reversed ? ' (역방향)' : ''}',
    ];
    await SharePlus.instance.share(
      ShareParams(
        text:
            '타로 고민상담 · ${widget.topic.label}\n${lines.join('\n')}'
            '\n\n- 오늘의 뽑기',
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'oneul-ppopgi-tarot.png',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(tarotDeckProvider).value;
    final isSaved = ref.watch(savedReadingsProvider).any((r) => r.id == _id);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('고민상담 · ${widget.topic.label}')),
      body: SafeArea(
        child: deck == null
            ? const Center(child: CircularProgressIndicator())
            : AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final done = _flip.value == 1;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: GestureDetector(
                            onLongPress: done
                                ? () => saveCardImage(context, _shotKey)
                                : null,
                            child: RepaintBoundary(
                              key: _shotKey,
                              child: ColoredBox(
                                color: Theme.of(context).colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ConsultReading(
                                    deck: deck,
                                    topic: widget.topic,
                                    cards: widget.cards,
                                    flipT: _cardT,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 36,
                              child: done
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SmallActionButton(
                                          label: isSaved ? '저장됨' : '저장',
                                          filled: isSaved,
                                          tooltip: isSaved ? '저장 취소' : '저장',
                                          onPressed: _toggleSave,
                                        ),
                                        const SizedBox(width: 12),
                                        SmallActionButton(
                                          label: '공유',
                                          tooltip: '이미지로 공유',
                                          onPressed: () => _share(deck),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: '다시 상담하기',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '결과를 꾹 누르면 이미지 저장 · 재미로 즐겨주세요',
                              textAlign: TextAlign.center,
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// 3장 펼침 + 자리별 해석. 결과 화면과 저장 목록 상세에서 같이 쓴다.
class ConsultReading extends StatelessWidget {
  const ConsultReading({
    super.key,
    required this.deck,
    required this.topic,
    required this.cards,
    this.flipT,
  });

  final TarotDeck deck;
  final TarotTopic topic;
  final List<DrawnCard> cards;

  /// 카드별 뒤집기 진행도. null이면 모두 앞면.
  final double Function(int i)? flipT;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    double t(int i) => flipT?.call(i) ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final pos in SpreadPosition.values) ...[
              if (pos.index > 0) const SizedBox(width: 12),
              Column(
                children: [
                  SizedBox(
                    width: 96,
                    child: FlippingCard(
                      t: t(pos.index),
                      card: deck.byId(cards[pos.index].cardId)!,
                      reversed: cards[pos.index].reversed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(pos.label, style: text.labelLarge),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        for (final pos in SpreadPosition.values)
          Opacity(
            opacity: ((t(pos.index) - 0.6) / 0.4).clamp(0.0, 1.0),
            child: Builder(
              builder: (context) {
                final drawn = cards[pos.index];
                final card = deck.byId(drawn.cardId)!;
                final reading = card.reading(drawn.reversed);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pos.label} · ${pos.meaning}',
                        style: text.labelLarge?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(card.name, style: text.titleMedium),
                          ),
                          const SizedBox(width: 8),
                          OrientationBadge(reversed: drawn.reversed),
                        ],
                      ),
                      const SizedBox(height: 8),
                      KeywordRow(keywords: reading.keywords, center: false),
                      const SizedBox(height: 10),
                      Text(
                        reading.topics[topic]!,
                        style: text.bodyLarge?.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
