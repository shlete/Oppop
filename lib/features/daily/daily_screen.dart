import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/primary_button.dart';
import '../../core/widgets/saved_list_button.dart';
import 'daily_state.dart';
import 'phrase_card.dart';
import 'phrases.dart';
import 'saved_phrases_screen.dart';

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key, this.random});

  /// 테스트에서 결과를 고정할 때 넘긴다.
  final Random? random;

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen>
    with SingleTickerProviderStateMixin {
  late final Random _random = widget.random ?? Random();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    // 결과 연출이라 '애니메이션 줄이기' 설정에서도 정해진 시간 그대로 재생한다.
    animationBehavior: AnimationBehavior.preserve,
  );
  final _cardKey = GlobalKey();

  PhraseCategory _category = PhraseCategory.quote;
  Phrase? _phrase;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _draw() async {
    final book = await ref.read(phraseBookProvider.future);
    final phrase = book.pick(
      _category,
      sign: _category == PhraseCategory.caution
          ? ref.read(zodiacProvider)
          : null,
      seen: ref.read(seenPhrasesProvider),
      random: _random,
    );
    if (phrase == null || !mounted) return;
    await ref.read(seenPhrasesProvider.notifier).add(phrase.id);
    setState(() => _phrase = phrase);
    _reveal.forward(from: 0);
  }

  void _selectCategory(PhraseCategory c) {
    if (c == _category) return;
    setState(() {
      _category = c;
      _phrase = null;
    });
    _reveal.value = 0;
  }

  Future<void> _toggleSave(Phrase phrase) async {
    final saved = ref.read(savedPhrasesProvider.notifier);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (saved.contains(phrase.id)) {
      await saved.remove(phrase.id);
      messenger.showSnackBar(const SnackBar(content: Text('저장을 취소했어요')));
    } else {
      await saved.add(phrase);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('문구를 저장했어요'),
          action: SnackBarAction(label: '보기', onPressed: _openSaved),
        ),
      );
    }
  }

  /// 결과 카드를 이미지로 만들어 공유한다.
  Future<void> _share(Phrase phrase) async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: '${phrase.text}\n\n- 오늘의 뽑기',
        files: [
          XFile.fromData(
            bytes.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'oneul-ppopgi.png',
          ),
        ],
      ),
    );
  }

  void _openSaved() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SavedPhrasesScreen()));

  Future<void> _pickZodiac() async {
    final current = ref.read(zodiacProvider);
    final picked = await showModalBottomSheet<_ZodiacChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ZodiacSheet(current: current),
    );
    if (picked == null) return;
    await ref.read(zodiacProvider.notifier).set(picked.sign);
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedPhrasesProvider);
    final zodiac = ref.watch(zodiacProvider);
    final phrase = _phrase;
    final isSaved = phrase != null && saved.any((p) => p.id == phrase.id);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 뽑기'),
        actions: [
          SavedListButton(
            count: saved.length,
            onPressed: _openSaved,
            tooltip: '저장한 문구',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<PhraseCategory>(
                showSelectedIcon: false,
                segments: [
                  for (final c in PhraseCategory.values)
                    ButtonSegment(value: c, label: Text(c.label)),
                ],
                selected: {_category},
                onSelectionChanged: (s) => _selectCategory(s.first),
              ),
              if (_category == PhraseCategory.caution) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _pickZodiac,
                    child: Text(
                      zodiac == null
                          ? '내 별자리 고르기 (선택)'
                          : '내 별자리: ${zodiac.label} · 바꾸기',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _reveal,
                    builder: (context, child) {
                      final t = Curves.easeOutBack.transform(_reveal.value);
                      return Opacity(
                        opacity: phrase == null
                            ? 1
                            : _reveal.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: phrase == null ? 1 : 0.85 + 0.15 * t,
                          child: child,
                        ),
                      );
                    },
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: PhraseCard(
                        category: _category,
                        text: phrase?.text,
                        date: DateTime.now(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: phrase == null
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SmallButton(
                            label: isSaved ? '저장됨' : '저장',
                            filled: isSaved,
                            tooltip: isSaved ? '저장 취소' : '저장',
                            onPressed: () => _toggleSave(phrase),
                          ),
                          const SizedBox(width: 12),
                          _SmallButton(
                            label: '공유',
                            tooltip: '이미지로 공유',
                            onPressed: () => _share(phrase),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: phrase == null ? '뽑기' : '다시 뽑기',
                onPressed: _draw,
              ),
              const SizedBox(height: 8),
              Text(
                '재미로 보는 문구예요. 가볍게 즐겨주세요.',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 결과 아래의 작은 글자 버튼 (저장·공유).
class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      minimumSize: const WidgetStatePropertyAll(Size(72, 34)),
    );
    return Tooltip(
      message: tooltip,
      child: filled
          ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
          : OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            ),
    );
  }
}

/// 별자리 선택 결과. sign이 null이면 '선택 안 함'.
class _ZodiacChoice {
  const _ZodiacChoice(this.sign);

  final Zodiac? sign;
}

class _ZodiacSheet extends StatelessWidget {
  const _ZodiacSheet({required this.current});

  final Zodiac? current;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('내 별자리', style: text.titleMedium),
            const SizedBox(height: 4),
            Text('고르면 별자리 문구도 함께 나와요.', style: text.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final z in Zodiac.values)
                  ChoiceChip(
                    label: Text('${z.label} ${z.dates}'),
                    selected: z == current,
                    showCheckmark: false,
                    onSelected: (_) => Navigator.pop(context, _ZodiacChoice(z)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, const _ZodiacChoice(null)),
              child: const Text('선택 안 함'),
            ),
          ],
        ),
      ),
    );
  }
}
