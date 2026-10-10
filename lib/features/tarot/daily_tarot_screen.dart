import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/image_save/image_save.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/small_action_button.dart';
import '../../core/widgets/balanced_text.dart';
import '../daily/phrase_card.dart' show keepWords;
import '../daily/save_card_image.dart';
import 'consult_screen.dart';
import 'saved_readings_screen.dart';
import 'tarot_card_view.dart';
import 'tarot_cards.dart';
import 'tarot_logic.dart';
import 'tarot_state.dart';

/// 오늘의 운세: 하루 한 장. 같은 날 다시 들어와도 같은 카드가 나온다.
class DailyTarotScreen extends ConsumerStatefulWidget {
  const DailyTarotScreen({super.key, this.now});

  /// 테스트에서 날짜를 고정할 때 넘긴다.
  final DateTime? now;

  @override
  ConsumerState<DailyTarotScreen> createState() => _DailyTarotScreenState();
}

class _DailyTarotScreenState extends ConsumerState<DailyTarotScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _now = widget.now ?? DateTime.now();
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    // 결과 연출이라 '애니메이션 줄이기' 설정에서도 정해진 시간 그대로 재생한다.
    animationBehavior: AnimationBehavior.preserve,
  );
  final _shotKey = GlobalKey();
  bool _synced = false;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _doFlip() {
    if (_flip.isAnimating || _flip.value == 1) return;
    ref.read(dailyFlippedProvider.notifier).flip();
    _flip.forward(from: 0);
  }

  String get _savedId => 'daily-${dayKey(_now)}';

  Future<void> _toggleSave(DailyFortune f) async {
    final saved = ref.read(savedReadingsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (saved.contains(_savedId)) {
      await saved.remove(_savedId);
      messenger.showSnackBar(const SnackBar(content: Text('저장을 취소했어요')));
      return;
    }
    await saved.add(
      SavedReading(
        id: _savedId,
        cards: [f.card],
        savedAt: DateTime.now(),
        luckyColor: f.luckyColor.$1,
        luckyNumber: f.luckyNumber,
      ),
    );
    messenger.showSnackBar(
      SnackBar(
        content: const Text('오늘의 운세를 저장했어요'),
        action: SnackBarAction(
          label: '보기',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SavedReadingsScreen()),
          ),
        ),
      ),
    );
  }

  Future<void> _share(TarotCard card, DailyFortune f) async {
    final bytes = await captureBoundary(_shotKey);
    if (bytes == null) return;
    final reading = card.reading(f.card.reversed);
    await SharePlus.instance.share(
      ShareParams(
        text:
            '오늘의 타로: ${card.name} (${f.card.reversed ? '역방향' : '정방향'})'
            '\n${reading.today}\n\n- 오늘의 뽑기',
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
    final seed = ref.watch(tarotSeedProvider).value;
    final flipped = ref.watch(dailyFlippedProvider);
    final savedList = ref.watch(savedReadingsProvider);
    final text = Theme.of(context).textTheme;

    if (deck == null || seed == null || flipped == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('오늘의 운세')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // 오늘 이미 뒤집어 봤으면 바로 앞면으로.
    if (!_synced) {
      _synced = true;
      if (flipped) _flip.value = 1;
    }

    final fortune = dailyFortune(
      cardIds: [for (final c in deck.cards) c.id],
      date: _now,
      deviceSeed: seed,
    );
    final card = deck.byId(fortune.card.cardId)!;
    final reading = card.reading(fortune.card.reversed);
    final isSaved = savedList.any((r) => r.id == _savedId);

    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 운세')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_flip.value);
            final done = _flip.value == 1;
            // 앞면이 보이기 시작한 뒤 해석이 서서히 나타난다.
            final infoOpacity = ((_flip.value - 0.6) / 0.4).clamp(0.0, 1.0);
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Text(
                                  '${_now.month}월 ${_now.day}일 오늘의 카드',
                                  style: text.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _doFlip,
                                  child: SizedBox(
                                    // 해석이 나타나면서 카드는 조금 작아져 한 화면에 다 보이게.
                                    width: 150 - 30 * infoOpacity,
                                    child: FlippingCard(
                                      t: t,
                                      card: card,
                                      reversed: fortune.card.reversed,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Opacity(
                                  opacity: infoOpacity,
                                  child: _DailyInfo(
                                    card: card,
                                    reading: reading,
                                    fortune: fortune,
                                  ),
                                ),
                              ],
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SmallActionButton(
                                    label: isSaved ? '저장됨' : '저장',
                                    filled: isSaved,
                                    tooltip: isSaved ? '저장 취소' : '저장',
                                    onPressed: () => _toggleSave(fortune),
                                  ),
                                  const SizedBox(width: 12),
                                  SmallActionButton(
                                    label: '공유',
                                    tooltip: '이미지로 공유',
                                    onPressed: () => _share(card, fortune),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: done ? '고민상담 하러 가기' : '카드 뒤집기',
                        onPressed: _flip.isAnimating
                            ? null
                            : done
                            ? () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ConsultScreen(),
                                ),
                              )
                            : _doFlip,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        done
                            ? '오늘의 카드는 내일 바뀌어요 · 꾹 누르면 이미지 저장'
                            : '카드를 눌러도 뒤집혀요',
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

class _DailyInfo extends StatelessWidget {
  const _DailyInfo({
    required this.card,
    required this.reading,
    required this.fortune,
  });

  final TarotCard card;
  final CardReading reading;
  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.name, style: text.headlineSmall),
            const SizedBox(width: 8),
            OrientationBadge(reversed: fortune.card.reversed),
          ],
        ),
        const SizedBox(height: 2),
        Text(card.nameEn, style: text.bodySmall),
        const SizedBox(height: 12),
        KeywordRow(keywords: reading.keywords),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: BalancedText(
            keepWords(reading.today),
            style: text.bodyLarge!.copyWith(height: 1.6),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('행운의 색', style: text.bodyMedium),
            const SizedBox(width: 6),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: fortune.luckyColor.$2,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 4),
            Text(fortune.luckyColor.$1, style: text.titleSmall),
            const SizedBox(width: 20),
            Text('행운의 숫자', style: text.bodyMedium),
            const SizedBox(width: 6),
            Text('${fortune.luckyNumber}', style: text.titleSmall),
          ],
        ),
      ],
    );
  }
}
