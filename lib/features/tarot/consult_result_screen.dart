import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/image_save/image_save.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/small_action_button.dart';
import '../daily/phrase_card.dart' show keepWords;
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: GestureDetector(
                            onLongPress: done
                                ? () => saveCardImage(context, _shotKey)
                                : null,
                            child: ConsultReading(
                              deck: deck,
                              topic: widget.topic,
                              cards: widget.cards,
                              flipT: _cardT,
                              shotKey: _shotKey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                              '꾹 누르면 통합 점괘를 이미지로 저장 · 재미로 즐겨주세요',
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

/// 고민상담 결과 화면 본문. 큰 카드 3장을 옆으로 넘겨 보고, 아래에 통합 점괘를 보여준다.
/// 결과 화면과 저장 목록 상세에서 같이 쓴다.
class ConsultReading extends StatefulWidget {
  const ConsultReading({
    super.key,
    required this.deck,
    required this.topic,
    required this.cards,
    this.flipT,
    this.shotKey,
  });

  final TarotDeck deck;
  final TarotTopic topic;
  final List<DrawnCard> cards;

  /// 카드별 뒤집기 진행도. null이면 모두 앞면.
  final double Function(int i)? flipT;

  /// 이미지 저장·공유 때 찍을 통합 점괘 영역.
  final GlobalKey? shotKey;

  @override
  State<ConsultReading> createState() => _ConsultReadingState();
}

class _ConsultReadingState extends State<ConsultReading> {
  final _pages = PageController(viewportFraction: 0.8);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  double _t(int i) => widget.flipT?.call(i) ?? 1;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final allShown = _t(SpreadPosition.values.length - 1) == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '타로 결과',
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 430,
          // 웹 미리보기에서 마우스로 끌어도 넘어가게.
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: PageView(
              controller: _pages,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                for (final pos in SpreadPosition.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _CardPanel(
                      position: pos,
                      deck: widget.deck,
                      drawn: widget.cards[pos.index],
                      t: _t(pos.index),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < SpreadPosition.values.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          '통합 점괘',
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: allShown ? 1 : 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RepaintBoundary(
              key: widget.shotKey,
              child: _Summary(
                deck: widget.deck,
                topic: widget.topic,
                cards: widget.cards,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 넘겨 보는 카드 한 장: 자리 이름, 큰 카드, 이름, 키워드.
class _CardPanel extends StatelessWidget {
  const _CardPanel({
    required this.position,
    required this.deck,
    required this.drawn,
    required this.t,
  });

  final SpreadPosition position;
  final TarotDeck deck;
  final DrawnCard drawn;
  final double t;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final card = deck.byId(drawn.cardId)!;
    final reading = card.reading(drawn.reversed);
    final shown = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${position.label} · ${position.meaning}',
            style: text.labelLarge?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: tarotAspect,
                  child: FlippingCard(
                    t: t,
                    card: card,
                    reversed: drawn.reversed,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: shown,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        card.name,
                        style: text.titleMedium?.copyWith(
                          color: scheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    OrientationBadge(reversed: drawn.reversed),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reading.keywords.join(', '),
                  style: text.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 통합 점괘: 세 장을 작게 모아 보여주고 자리별 해석을 이어서 읽게 한다.
/// 이미지로 저장·공유할 때 이 영역을 찍는다.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.deck,
    required this.topic,
    required this.cards,
  });

  final TarotDeck deck;
  final TarotTopic topic;
  final List<DrawnCard> cards;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final flow = [
      for (final c in cards)
        deck.byId(c.cardId)!.reading(c.reversed).keywords.first,
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final pos in SpreadPosition.values) ...[
                if (pos.index > 0) const SizedBox(width: 10),
                Column(
                  children: [
                    SizedBox(
                      width: 56,
                      child: TarotCardFace(
                        card: deck.byId(cards[pos.index].cardId)!,
                        reversed: cards[pos.index].reversed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(pos.label, style: text.labelMedium),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            keepWords('${topic.label} 고민의 흐름: ${flow.join(' → ')}'),
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(color: scheme.primary),
          ),
          for (final pos in SpreadPosition.values) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final drawn = cards[pos.index];
                final card = deck.byId(drawn.cardId)!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pos.label} · ${pos.meaning}  |  ${card.name}'
                      '${drawn.reversed ? ' (역)' : ''}',
                      style: text.labelLarge?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      keepWords(card.reading(drawn.reversed).topics[topic]!),
                      style: text.bodyLarge?.copyWith(height: 1.55),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
