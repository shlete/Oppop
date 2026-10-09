import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daily_state.dart';
import 'saved_phrase_view.dart';
import 'phrase_card.dart';

class SavedPhrasesScreen extends ConsumerWidget {
  const SavedPhrasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phrases = ref.watch(savedPhrasesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('저장한 문구')),
      body: phrases.isEmpty
          ? const Center(child: Text('아직 저장한 문구가 없어요'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: phrases.length,
              itemBuilder: (context, i) => _SavedCard(phrase: phrases[i]),
            ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.phrase});

  final SavedPhrase phrase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final d = phrase.savedAt;
    return Card(
      color: phraseCardColors(phrase.category).first,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SavedPhraseView(phrase: phrase)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${phrase.category.label} · ${d.year}.${d.month}.${d.day}',
                      style: text.bodySmall,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '더보기',
                    onSelected: (v) => _onMenu(context, ref, v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'copy', child: Text('문구 복사')),
                      PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  phrase.textWithSource,
                  style: text.bodyLarge?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (value) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: phrase.textWithSource));
        messenger.showSnackBar(const SnackBar(content: Text('문구를 복사했어요')));
      case 'delete':
        final notifier = ref.read(savedPhrasesProvider.notifier);
        await notifier.remove(phrase.id);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('삭제했어요'),
            action: SnackBarAction(
              label: '되돌리기',
              onPressed: () => notifier.restore(phrase),
            ),
          ),
        );
    }
  }
}
