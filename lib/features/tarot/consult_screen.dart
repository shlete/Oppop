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

  static const _columns = 7;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = (spread.length / _columns).ceil();
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
              builder: (context, box) {
                final byWidth =
                    (box.maxWidth - _gap * (_columns - 1)) / _columns;
                final byHeight =
                    (box.maxHeight - _gap * (rows - 1)) / rows * tarotAspect;
                final w = min(byWidth, byHeight);
                return Center(
                  child: Wrap(
                    spacing: _gap,
                    runSpacing: _gap,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < spread.length; i++)
                        _PickableCard(
                          key: ValueKey('spread-$i'),
                          width: w,
                          picked: picked.contains(i),
                          onTap: () => onTap(i),
                        ),
                    ],
                  ),
                );
              },
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

class _PickableCard extends StatelessWidget {
  const _PickableCard({
    super.key,
    required this.width,
    required this.picked,
    required this.onTap,
  });

  final double width;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 150),
        offset: picked ? const Offset(0, -0.06) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: picked ? 0.45 : 1,
          child: SizedBox(
            width: width,
            child: TarotCardBack(highlight: picked),
          ),
        ),
      ),
    );
  }
}
