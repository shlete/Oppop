import 'dart:math';

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
            color: scheme.secondaryContainer.withValues(alpha: 0.6),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            picked.length < 3
                ? '고민을 떠올리며 카드 ${3 - picked.length}장을 더 골라주세요'
                : '카드를 다 골랐어요',
            style: text.titleMedium,
            textAlign: TextAlign.center,
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
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => _Fan(
                size: box.biggest,
                count: spread.length,
                picked: picked,
                onTap: onTap,
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: '결과 보기', onPressed: onShowResult),
          const SizedBox(height: 8),
          Text('고른 카드를 다시 누르면 취소돼요', style: text.bodySmall),
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

/// 덱을 부채꼴 두 줄로 펼친다. 카드가 겹쳐 있어 왼쪽 일부가 보이고, 그 부분을 눌러 고른다.
class _Fan extends StatelessWidget {
  const _Fan({
    required this.size,
    required this.count,
    required this.picked,
    required this.onTap,
  });

  final Size size;
  final int count;
  final List<int> picked;
  final ValueChanged<int> onTap;

  /// 가장 바깥 카드의 기울기 (라디안).
  static const _spread = 0.42;

  /// 고른 카드가 위로 올라오는 거리.
  static const _lift = 16.0;

  @override
  Widget build(BuildContext context) {
    final top = (count / 2).ceil();
    final rows = [
      [for (var i = 0; i < top; i++) i],
      [for (var i = top; i < count; i++) i],
    ];
    final rowHeight = size.height / 2;
    final cw = min(size.width * 0.2, (rowHeight - _lift - 12) * tarotAspect);
    final ch = cw / tarotAspect;
    // 양 끝 카드 중심이 화면 안쪽에 오도록 반지름을 정한다.
    final radius = (size.width - cw * 1.3) / 2 / sin(_spread);
    final sag = radius * (1 - cos(_spread));
    final cards = <({int index, Offset center, double angle})>[];
    for (var r = 0; r < rows.length; r++) {
      final ids = rows[r];
      // 줄마다 부채꼴(카드 + 처짐 + 들림)이 가운데 오게.
      final rowTop = r * rowHeight + (rowHeight - ch - sag - _lift) / 2 + _lift;
      for (var k = 0; k < ids.length; k++) {
        final t = ids.length == 1 ? 0.5 : k / (ids.length - 1);
        final angle = (t * 2 - 1) * _spread;
        cards.add((
          index: ids[k],
          center: Offset(
            size.width / 2 + radius * sin(angle),
            rowTop + ch / 2 + radius * (1 - cos(angle)),
          ),
          angle: angle,
        ));
      }
    }

    // 겹친 카드 중 눌린 곳이 보이는 카드(위에 그려진 카드부터)를 고른다.
    // 위젯마다 따로 누르게 하면 웹에서 기울어진 카드 끝이 잘 안 눌려서 직접 계산한다.
    int? cardAt(Offset p) {
      for (final c in cards.reversed) {
        final d = p - c.center;
        final x = d.dx * cos(-c.angle) - d.dy * sin(-c.angle);
        var y = d.dx * sin(-c.angle) + d.dy * cos(-c.angle);
        if (picked.contains(c.index)) y += _lift;
        if (x.abs() <= cw / 2 && y.abs() <= ch / 2) return c.index;
      }
      return null;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final i = cardAt(d.localPosition);
        if (i != null) onTap(i);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final c in cards)
            Positioned(
              key: ValueKey('spread-${c.index}'),
              left: c.center.dx - cw / 2,
              top: c.center.dy - ch / 2,
              width: cw,
              height: ch,
              child: Transform.rotate(
                angle: c.angle,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: picked.contains(c.index)
                      ? Offset(0, -_lift / ch)
                      : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: picked.contains(c.index) ? 0.55 : 1,
                    child: TarotCardBack(highlight: picked.contains(c.index)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
