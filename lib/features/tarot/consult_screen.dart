import 'dart:math';

import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ads/interstitial.dart';
import '../../core/widgets/primary_button.dart';
import 'consult_result_screen.dart';
import 'tarot_card_view.dart';
import 'tarot_cards.dart';
import 'tarot_logic.dart';

/// 고민상담: 주제를 고르고, 펼친 카드 중 3장을 직접 고른다.
class ConsultScreen extends ConsumerStatefulWidget {
  const ConsultScreen({super.key, this.random});

  /// 테스트에서 결과를 고정할 때 넘긴다.
  final Random? random;

  @override
  ConsumerState<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends ConsumerState<ConsultScreen> {
  late final Random _random = widget.random ?? Random();
  TarotTopic? _topic;
  List<DrawnCard> _spread = const [];
  final List<int> _picked = [];
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    InterstitialGate.instance.preload();
  }

  void _start(TarotTopic topic, TarotDeck deck) {
    setState(() {
      _topic = topic;
      _spread = shuffledSpread([for (final c in deck.cards) c.id], _random);
      _picked.clear();
    });
  }

  void _tapCard(int i) {
    setState(() {
      if (_picked.contains(i)) {
        _picked.remove(i);
      } else if (_picked.length < 3) {
        _picked.add(i);
        // 결과 화면에서 뒤집을 때 그림이 늦게 뜨지 않게 미리 불러 둔다.
        final card = ref.read(tarotDeckProvider).value?.byId(_spread[i].cardId);
        if (card != null) precacheImage(AssetImage(card.image), context);
      }
    });
  }

  Future<void> _showResult() async {
    if (_opening) return;
    _opening = true;
    try {
      await InterstitialGate.instance.show();
      if (!mounted) return;
      final cards = [for (final i in _picked) _spread[i]];
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConsultResultScreen(topic: _topic!, cards: cards),
        ),
      );
      // 결과를 보고 돌아오면 주제 고르기부터 다시.
      if (mounted) setState(() => _topic = null);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(tarotDeckProvider).value;
    final topic = _topic;
    return PopScope(
      canPop: topic == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _topic = null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(topic == null ? '고민상담' : '고민상담 · ${topic.label}'),
        ),
        body: SafeArea(
          child: deck == null
              ? const Center(child: CircularProgressIndicator())
              : topic == null
              ? _TopicPicker(onPick: (t) => _start(t, deck))
              : _CardPicker(
                  spread: _spread,
                  picked: _picked,
                  onTap: _tapCard,
                  onShowResult: _picked.length == 3 ? _showResult : null,
                ),
        ),
      ),
    );
  }
}

class _TopicPicker extends StatelessWidget {
  const _TopicPicker({required this.onPick});

  final ValueChanged<TarotTopic> onPick;

  static const _icons = {
    TarotTopic.love: Icons.favorite_outline,
    TarotTopic.study: Icons.menu_book_outlined,
    TarotTopic.career: Icons.explore_outlined,
    TarotTopic.money: Icons.savings_outlined,
    TarotTopic.health: Icons.spa_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('어떤 고민이 있나요?', style: text.titleLarge),
        const SizedBox(height: 4),
        Text('주제를 고르면 카드 3장으로 과거 · 현재 · 미래를 봐요.', style: text.bodyMedium),
        const SizedBox(height: 16),
        for (final t in TarotTopic.values) ...[
          Card(
            color: scheme.surfaceContainerLowest,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Icon(_icons[t], size: 28),
              title: Text(t.label, style: text.titleMedium),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onPick(t),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CardPicker extends StatelessWidget {
  const _CardPicker({
    required this.spread,
    required this.picked,
    required this.onTap,
    required this.onShowResult,
  });

  final List<DrawnCard> spread;
  final List<int> picked;
  final ValueChanged<int> onTap;
  final VoidCallback? onShowResult;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // 펼친 카드는 화면 양끝까지 닿게 하고, 나머지만 좌우 여백을 둔다.
    const side = EdgeInsets.symmetric(horizontal: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: side,
            child: Text(
              picked.length < 3
                  ? '고민을 떠올리며 카드 ${3 - picked.length}장을 더 골라주세요'
                  : '카드를 다 골랐어요',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final pos in SpreadPosition.values) ...[
                if (pos.index > 0) const SizedBox(width: 16),
                _Slot(position: pos, filled: picked.length > pos.index),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => _Fan(
                key: ObjectKey(spread),
                size: box.biggest,
                count: spread.length,
                picked: picked,
                onTap: onTap,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: side,
            child: PrimaryButton(label: '결과 보기', onPressed: onShowResult),
          ),
          const SizedBox(height: 8),
          Text('옆으로 넘기며 78장 중에서 골라요 · 다시 누르면 취소', style: text.bodySmall),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.position, required this.filled});

  final SpreadPosition position;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        SizedBox(
          width: 56,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: filled
                ? const TarotCardBack(key: ValueKey('back'))
                : AspectRatio(
                    key: const ValueKey('empty'),
                    aspectRatio: tarotAspect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: scheme.outlineVariant),
                        color: scheme.surfaceContainerLow,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(position.label, style: text.labelLarge),
        Text(position.meaning, style: text.labelSmall),
      ],
    );
  }
}

/// 78장을 한 줄 부채꼴로 길게 펼친다. 옆으로 넘기면 화면 가운데 카드가 가장 높이 오고
/// 양옆으로 갈수록 기울며 내려간다. 카드가 겹쳐 있어 왼쪽 일부가 보이고, 그 부분을 눌러 고른다.
class _Fan extends StatefulWidget {
  const _Fan({
    super.key,
    required this.size,
    required this.count,
    required this.picked,
    required this.onTap,
  });

  final Size size;
  final int count;
  final List<int> picked;
  final ValueChanged<int> onTap;

  @override
  State<_Fan> createState() => _FanState();
}

class _FanState extends State<_Fan> {
  /// 화면 끝 카드의 기울기 (라디안).
  static const _edgeAngle = 0.4;

  /// 고른 카드가 위로 올라오는 거리.
  static const _lift = 24.0;

  /// 옆 카드와의 간격 (카드 폭 대비).
  static const _step = 0.36;

  late double _cw;
  late double _ch;
  late double _pad;
  late double _radius;
  late double _top;
  ScrollController? _scroll;

  void _layout() {
    final size = widget.size;
    _radius = size.width / 2 / _edgeAngle;
    final sag = _radius * (1 - cos(_edgeAngle));
    _cw = min(size.width * 0.26, (size.height - sag - _lift - 8) * tarotAspect);
    _ch = _cw / tarotAspect;
    // 부채꼴(들림 + 카드 + 처짐)이 세로 가운데 오게.
    _top = (size.height - _lift - _ch - sag) / 2 + _lift;
    // 첫 장과 마지막 장도 화면 가운데까지 끌어올 수 있게 양옆 여백.
    _pad = (size.width - _cw) / 2;
  }

  double get _contentWidth => _pad * 2 + (widget.count - 1) * _cw * _step + _cw;

  @override
  void initState() {
    super.initState();
    _layout();
    // 처음에는 가운데 카드들이 보이게.
    _scroll = ScrollController(
      initialScrollOffset: max(0, (_contentWidth - widget.size.width) / 2),
    );
  }

  @override
  void didUpdateWidget(_Fan old) {
    super.didUpdateWidget(old);
    if (old.size != widget.size) _layout();
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// 스크롤 위치 [offset]에서 [i]번째 카드의 중심과 기울기 (펼친 줄 기준 좌표).
  ({Offset center, double angle}) _place(int i, double offset) {
    final x = _pad + i * _cw * _step + _cw / 2;
    final d = x - offset - widget.size.width / 2;
    final angle = (d / _radius).clamp(-0.9, 0.9);
    return (
      center: Offset(x, _top + _ch / 2 + _radius * (1 - cos(angle))),
      angle: angle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = widget.picked;
    // 웹 미리보기에서 마우스로 끌어도 넘어가게.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context)
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: AnimatedBuilder(
          animation: _scroll!,
          builder: (context, _) {
            final offset = _scroll!.hasClients
                ? _scroll!.offset
                : _scroll!.initialScrollOffset;
            // 화면에 보이는 카드만 그린다.
            final first = max(
              0,
              ((offset - _pad - _cw) / (_cw * _step)).floor() - 2,
            );
            final last = min(
              widget.count - 1,
              ((offset + widget.size.width - _pad) / (_cw * _step)).ceil() + 2,
            );
            final cards = [
              for (var i = first; i <= last; i++)
                (index: i, p: _place(i, offset)),
            ];

            // 겹친 카드 중 눌린 곳이 보이는 카드(위에 그려진 카드부터)를 고른다.
            // 위젯마다 따로 누르게 하면 웹에서 기울어진 카드 끝이 잘 안 눌려서 직접 계산한다.
            int? cardAt(Offset p) {
              for (final c in cards.reversed) {
                final d = p - c.p.center;
                final a = -c.p.angle;
                final x = d.dx * cos(a) - d.dy * sin(a);
                var y = d.dx * sin(a) + d.dy * cos(a);
                if (picked.contains(c.index)) y += _lift;
                if (x.abs() <= _cw / 2 && y.abs() <= _ch / 2) return c.index;
              }
              return null;
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final i = cardAt(d.localPosition);
                if (i != null) widget.onTap(i);
              },
              child: SizedBox(
                width: _contentWidth,
                height: widget.size.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final c in cards)
                      Positioned(
                        key: ValueKey('spread-${c.index}'),
                        left: c.p.center.dx - _cw / 2,
                        top: c.p.center.dy - _ch / 2,
                        width: _cw,
                        height: _ch,
                        child: Transform.rotate(
                          angle: c.p.angle,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 150),
                            offset: picked.contains(c.index)
                                ? Offset(0, -_lift / _ch)
                                : Offset.zero,
                            child: TarotCardBack(
                              highlight: picked.contains(c.index),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
