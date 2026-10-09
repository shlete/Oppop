import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lotto_ball.dart';
import 'lotto_logic.dart';
import 'saved_lotto.dart';

class SavedLottoScreen extends ConsumerWidget {
  const SavedLottoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(savedLottoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('저장한 번호')),
      body: games.isEmpty
          ? const Center(child: Text('아직 저장한 번호가 없어요'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: games.length,
              itemBuilder: (context, i) => _SavedCard(game: games[i]),
            ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.game});

  final SavedGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_formatDate(game.savedAt), style: text.bodySmall),
                ),
                PopupMenuButton<String>(
                  tooltip: '더보기',
                  onSelected: (v) => _onMenu(context, ref, v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'memo', child: Text('메모')),
                    PopupMenuItem(value: 'copy', child: Text('번호 복사')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final n in game.numbers) LottoBall(n, size: 38),
                ],
              ),
            ),
            if (game.memo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(game.memo, style: text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final store = ref.read(savedLottoProvider.notifier);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (value) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: formatLotto(game.numbers)));
        messenger.showSnackBar(const SnackBar(content: Text('번호를 복사했어요')));
      case 'delete':
        await store.remove(game.numbers);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('삭제했어요'),
            action: SnackBarAction(
              label: '되돌리기',
              onPressed: () => store.restore(game),
            ),
          ),
        );
      case 'memo':
        final memo = await showDialog<String>(
          context: context,
          builder: (_) => _MemoDialog(initial: game.memo),
        );
        if (memo != null) await store.setMemo(game, memo);
    }
  }
}

class _MemoDialog extends StatefulWidget {
  const _MemoDialog({required this.initial});

  final String initial;

  @override
  State<_MemoDialog> createState() => _MemoDialogState();
}

class _MemoDialogState extends State<_MemoDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('메모'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: const InputDecoration(hintText: '예: 꿈에서 본 번호'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

String _formatDate(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
