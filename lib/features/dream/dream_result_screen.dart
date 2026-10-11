import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/balanced_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/small_action_button.dart';
import '../daily/phrase_card.dart' show keepWords;
import 'dream_ai.dart';
import 'dream_book.dart';
import 'dream_state.dart';
import 'saved_dreams_screen.dart';

/// 꿈해몽 결과. 꿈 이야기를 적었으면 AI 해몽을 받아 오고, 고른 키워드의 해몽을 함께 보여준다.
/// [saved]를 넘기면 저장해 둔 결과를 다시 연다 (서버를 다시 부르지 않는다).
class DreamResultScreen extends ConsumerStatefulWidget {
  const DreamResultScreen({
    super.key,
    required this.symbolIds,
    required this.story,
    this.saved,
    this.client = const DreamAiClient(),
  });

  DreamResultScreen.saved(SavedDream dream, {super.key})
    : symbolIds = dream.symbolIds,
      story = dream.story,
      saved = dream,
      client = const DreamAiClient();

  final List<String> symbolIds;
  final String story;
  final SavedDream? saved;
  final DreamAiClient client;

  @override
  ConsumerState<DreamResultScreen> createState() => _DreamResultScreenState();
}

class _DreamResultScreenState extends ConsumerState<DreamResultScreen> {
  late final String _id =
      widget.saved?.id ?? 'dream-${DateTime.now().millisecondsSinceEpoch}';
  late DreamAi? _ai = widget.saved?.ai;
  late bool _pending =
      widget.saved == null && widget.story.isNotEmpty && DreamAiClient.enabled;

  @override
  void initState() {
    super.initState();
    if (_pending) {
      widget.client.fetch(widget.symbolIds, widget.story).then((ai) {
        if (mounted) {
          setState(() {
            _ai = ai;
            _pending = false;
          });
        }
      });
    }
  }

  SavedDream get _record => SavedDream(
    id: _id,
    symbolIds: widget.symbolIds,
    story: widget.story,
    savedAt: widget.saved?.savedAt ?? DateTime.now(),
    ai: _ai,
  );

  Future<void> _toggleSave() async {
    final saved = ref.read(savedDreamsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (saved.contains(_id)) {
      await saved.remove(_id);
      messenger.showSnackBar(const SnackBar(content: Text('저장을 취소했어요')));
      return;
    }
    await saved.add(_record);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('꿈해몽을 저장했어요'),
        action: SnackBarAction(
          label: '보기',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SavedDreamsScreen())),
        ),
      ),
    );
  }

  Future<void> _share(List<DreamSymbol> picked) async {
    final ai = _ai;
    final lines = [
      '꿈해몽 · ${ai?.title ?? DreamBook.summary(picked)}',
      if (ai != null) ai.reading,
      for (final s in picked) '${s.name}: ${s.meaning}',
      ai?.advice ?? DreamBook.advice(picked),
    ];
    await SharePlus.instance.share(
      ShareParams(text: '${lines.join('\n\n')}\n\n- 오늘의 뽑기'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(dreamBookProvider).value;
    final isSaved = ref.watch(savedDreamsProvider).any((d) => d.id == _id);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final picked = book == null
        ? const <DreamSymbol>[]
        : [for (final id in widget.symbolIds) ?book.byId(id)];
    final ai = _ai;
    // 글만 적었는데 AI 해몽을 못 받으면 보여줄 해몽이 없다.
    final empty = !_pending && ai == null && picked.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('꿈해몽')),
      body: SafeArea(
        child: book == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (widget.story.isNotEmpty) ...[
                    Text('내 꿈', style: text.labelLarge),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(widget.story, style: text.bodyMedium),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_pending)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('꿈을 읽고 있어요', style: text.bodyMedium),
                        ],
                      ),
                    )
                  else if (empty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        '지금은 꿈 이야기를 읽지 못했어요.\n잠시 뒤 다시 해 보거나, 꿈 속 장면을 골라 보세요.',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium,
                      ),
                    )
                  else ...[
                    BalancedText(
                      keepWords(ai?.title ?? DreamBook.summary(picked)),
                      style: text.titleLarge!.copyWith(color: scheme.primary),
                    ),
                    if (ai != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        ai.reading,
                        style: text.bodyLarge?.copyWith(height: 1.7),
                      ),
                    ],
                    if (picked.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      if (ai != null) ...[
                        Text('키워드로 보는 해몽', style: text.titleSmall),
                        const SizedBox(height: 8),
                      ],
                      for (final s in picked) _SymbolCard(symbol: s),
                    ],
                    const SizedBox(height: 20),
                    BalancedText(
                      keepWords(ai?.advice ?? DreamBook.advice(picked)),
                      style: text.bodyLarge!.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          tooltip: '글로 공유',
                          onPressed: () => _share(picked),
                        ),
                      ],
                    ),
                  ],
                  if (widget.saved == null && !_pending) ...[
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: '다른 꿈 해몽하기',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '재미로 보는 해몽이에요. 가볍게 즐겨주세요.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

class _SymbolCard extends StatelessWidget {
  const _SymbolCard({required this.symbol});

  final DreamSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              symbol.name,
              style: text.titleSmall?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 6),
            Text(symbol.meaning, style: text.bodyMedium?.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }
}
