import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ads/interstitial.dart';
import 'lotto_ball.dart';
import 'lotto_logic.dart';
import 'saved_lotto.dart';
import 'saved_lotto_screen.dart';
import '../../core/widgets/primary_button.dart';

class LottoScreen extends ConsumerStatefulWidget {
  const LottoScreen({super.key, this.random});

  /// 테스트에서 번호를 고정할 때 넘긴다.
  final Random? random;

  @override
  ConsumerState<LottoScreen> createState() => _LottoScreenState();
}

class _LottoScreenState extends ConsumerState<LottoScreen>
    with SingleTickerProviderStateMixin {
  late final Random _random = widget.random ?? Random();

  /// 공이 하나씩 튀어나오는 연출.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    // 결과 연출이라 기기의 '애니메이션 줄이기' 설정에서도 그대로 재생한다.
    animationBehavior: AnimationBehavior.preserve,
  );

  int _gameCount = 1;
  List<List<int>> _games = const [];
  bool _drawing = false;

  @override
  void initState() {
    super.initState();
    InterstitialGate.instance.preload();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _draw() async {
    if (_drawing) return;
    setState(() => _drawing = true);
    await InterstitialGate.instance.show();
    if (!mounted) return;
    setState(() {
      _games = [for (var i = 0; i < _gameCount; i++) drawLotto(_random)];
    });
    await _reveal.forward(from: 0);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _drawing = false);
  }

  Future<void> _toggleSave(List<int> numbers) async {
    final saved = ref.read(savedLottoProvider.notifier);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (saved.contains(numbers)) {
      await saved.remove(numbers);
      messenger.showSnackBar(const SnackBar(content: Text('저장을 취소했어요')));
    } else {
      await saved.add(numbers);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('번호를 저장했어요'),
          action: SnackBarAction(label: '보기', onPressed: _openSaved),
        ),
      );
    }
  }

  void _openSaved() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SavedLottoScreen()));

  @override
  Widget build(BuildContext context) {
    final savedCount = ref.watch(savedLottoProvider).length;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('로또'),
        actions: [
          IconButton(
            tooltip: '저장한 번호',
            onPressed: _openSaved,
            icon: Badge(
              isLabelVisible: savedCount > 0,
              label: Text('$savedCount'),
              child: const Icon(Icons.bookmarks_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1게임')),
                  ButtonSegment(value: 5, label: Text('5게임')),
                ],
                selected: {_gameCount},
                onSelectionChanged: _drawing
                    ? null
                    : (s) => setState(() => _gameCount = s.first),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _games.isEmpty
                    ? Center(
                        child: Text(
                          '아래 버튼을 눌러 번호를 뽑아보세요',
                          style: text.bodyMedium,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _reveal,
                        builder: (context, _) => ListView(
                          children: [
                            for (var i = 0; i < _games.length; i++)
                              _GameRow(
                                label: String.fromCharCode(65 + i),
                                numbers: _games[i],
                                progress: _reveal.value,
                                saved: ref
                                    .read(savedLottoProvider.notifier)
                                    .contains(_games[i]),
                                onSave: _drawing
                                    ? null
                                    : () => _toggleSave(_games[i]),
                              ),
                          ],
                        ),
                      ),
              ),
              PrimaryButton(
                label: _games.isEmpty ? '번호 뽑기' : '다시 뽑기',
                onPressed: _drawing ? null : _draw,
              ),
              const SizedBox(height: 8),
              Text(
                '재미로 뽑는 랜덤 번호예요. 당첨을 보장하지 않아요.',
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

class _GameRow extends StatelessWidget {
  const _GameRow({
    required this.label,
    required this.numbers,
    required this.progress,
    required this.saved,
    required this.onSave,
  });

  final String label;
  final List<int> numbers;

  /// 0~1. 공은 왼쪽부터 차례로 튀어나온다.
  final double progress;
  final bool saved;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        // A 글자 왼쪽과 저장 버튼 오른쪽 여백을 똑같이 맞춘다.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  // 공은 A와 저장 버튼 사이에 같은 간격으로 고르게 펼친다.
                  const minGap = 6.0;
                  final size = min(40.0, (box.maxWidth - 7 * minGap) / 6);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var b = 0; b < numbers.length; b++)
                        Transform.scale(
                          scale: Curves.elasticOut.transform(
                            (progress * numbers.length - b).clamp(0.0, 1.0),
                          ),
                          child: LottoBall(numbers[b], size: size),
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              width: 40,
              child: Tooltip(
                message: saved ? '저장 취소' : '저장',
                child: _SaveChip(saved: saved, onPressed: onSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 줄 오른쪽의 작은 저장 버튼. 저장하면 같은 크기로 색만 채워진다.
class _SaveChip extends StatelessWidget {
  const _SaveChip({required this.saved, required this.onPressed});

  final bool saved;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Material(
      color: saved ? scheme.primary : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: saved
              ? scheme.primary
              : scheme.outline.withValues(alpha: enabled ? 1 : 0.4),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            textAlign: TextAlign.center,
            '저장',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: saved
                  ? scheme.onPrimary
                  : scheme.primary.withValues(alpha: enabled ? 1 : 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
