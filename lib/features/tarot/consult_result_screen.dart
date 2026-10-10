import 'dart:math';

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

  /// 아래쪽이 흐려지는 높이. 끝까지 내리면 흐림이 사라져 저장·공유 버튼이 또렷이 보인다.
  static const _fade = 56.0;
  double _fadeNow = _fade;

  void _updateFade(ScrollMetrics m) {
    final next = (m.maxScrollExtent - m.pixels).clamp(0.0, _fade);
    if (next != _fadeNow) setState(() => _fadeNow = next);
  }

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
                        // 버튼 위에서 글이 뚝 잘리지 않고 아래로 갈수록 흐려지게.
                        child: NotificationListener<ScrollMetricsNotification>(
                          onNotification: (n) {
                            _updateFade(n.metrics);
                            return false;
                          },
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              _updateFade(n.metrics);
                              return false;
                            },
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (bounds) => LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: const [
                                  Colors.black,
                                  Colors.black,
                                  Colors.transparent,
                                ],
                                stops: [
                                  0,
                                  (1 - _fadeNow / bounds.height).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  1,
                                ],
                              ).createShader(bounds),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    GestureDetector(
                                      onLongPress: done
                                          ? () =>
                                                saveCardImage(context, _shotKey)
                                          : null,
                                      child: ConsultReading(
                                        deck: deck,
                                        topic: widget.topic,
                                        cards: widget.cards,
                                        flipT: _cardT,
                                        shotKey: _shotKey,
                                      ),
                                    ),
                                    // 통합 점괘 맨 끝. 이미지 저장에는 들어가지 않는다.
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: IgnorePointer(
                                        ignoring: !done,
                                        child: AnimatedOpacity(
                                          opacity: done ? 1 : 0,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SmallActionButton(
                                                label: isSaved ? '저장됨' : '저장',
                                                filled: isSaved,
                                                tooltip: isSaved
                                                    ? '저장 취소'
                                                    : '저장',
                                                onPressed: _toggleSave,
                                              ),
                                              const SizedBox(width: 12),
                                              SmallActionButton(
                                                label: '공유',
                                                tooltip: '이미지로 공유',
                                                onPressed: () => _share(deck),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
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
  /// 카드 패널 크기. 화면 폭과 상관없이 늘 같다.
  static const panelWidth = 204.0;
  static const panelHeight = 340.0;
  static const _gap = 16.0;

  PageController? _pages;
  int _page = 0;

  /// 패널 폭이 고정되도록 화면 폭에 맞춰 한 장이 차지하는 비율을 정한다.
  PageController _controllerFor(double width) {
    final fraction = ((panelWidth + _gap) / width).clamp(0.1, 1.0);
    final current = _pages;
    if (current != null && current.viewportFraction == fraction) {
      return current;
    }
    current?.dispose();
    return _pages = PageController(
      viewportFraction: fraction,
      initialPage: _page,
    );
  }

  @override
  void dispose() {
    _pages?.dispose();
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
        SizedBox(
          height: panelHeight,
          // 웹 미리보기에서 마우스로 끌어도 넘어가게.
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: LayoutBuilder(
              builder: (context, box) => PageView(
                controller: _controllerFor(box.maxWidth),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final pos in SpreadPosition.values)
                    Center(
                      child: SizedBox(
                        width: panelWidth,
                        child: _CardPanel(
                          position: pos,
                          deck: widget.deck,
                          drawn: widget.cards[pos.index],
                          t: _t(pos.index),
                        ),
                      ),
                    ),
                ],
              ),
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

  /// 카드 기울기 (라디안, 약 10도).
  static const _tilt = 0.17;

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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              // 카드를 살짝 비스듬히 기울여 놓는다.
              child: LayoutBuilder(
                builder: (context, box) {
                  // 기울인 카드의 귀퉁이가 상자 밖으로 살짝 나가 잘리도록
                  // 상자보다 조금 크게 그린다.
                  final tiltedWidth =
                      tarotAspect * cos(_tilt) + sin(_tilt); // 높이 1당 가로 폭
                  final h = min(
                    box.maxHeight * 1.02,
                    box.maxWidth * 1.08 / tiltedWidth,
                  );
                  return Center(
                    child: Transform.rotate(
                      angle: _tilt,
                      child: SizedBox(
                        width: h * tarotAspect,
                        height: h,
                        child: FlippingCard(
                          t: t,
                          card: card,
                          reversed: drawn.reversed,
                        ),
                      ),
                    ),
                  );
                },
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

/// 통합 점괘: 흐름 한 줄과 자리별 해석을 이어서 읽게 한다.
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
                      '${pos.label} · ${pos.meaning}  |  ${card.nameEn}'
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
