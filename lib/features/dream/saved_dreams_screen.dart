import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dream_book.dart';
import 'dream_result_screen.dart';
import 'dream_state.dart';

/// 저장한 해몽 목록.
class SavedDreamsScreen extends ConsumerWidget {
  const SavedDreamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dreams = ref.watch(savedDreamsProvider);
    final book = ref.watch(dreamBookProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('저장한 해몽')),
      body: dreams.isEmpty
          ? const Center(child: Text('아직 저장한 해몽이 없어요'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dreams.length,
              itemBuilder: (context, i) =>
                  _SavedTile(dream: dreams[i], book: book),
            ),
    );
  }
}

/// 저장 목록과 마이 탭에서 쓰는 한 줄 제목.
String savedDreamTitle(SavedDream dream, DreamBook? book) {
  if (dream.ai != null) return dream.ai!.title;
  final picked = [for (final id in dream.symbolIds) ?book?.byId(id)];
  if (picked.isNotEmpty) return DreamBook.summary(picked);
  return '해몽뽑기';
}

/// 저장 목록과 마이 탭에서 쓰는 키워드 줄 (없으면 꿈 이야기 앞부분).
String? savedDreamDetail(SavedDream dream, DreamBook? book) {
  final names = [
    for (final id in dream.symbolIds)
      if (book?.byId(id) case final s?) s.name,
  ];
  if (names.isNotEmpty) return names.join(' · ');
  if (dream.story.isNotEmpty) return dream.story.replaceAll('\n', ' ');
  return null;
}

class _SavedTile extends ConsumerWidget {
  const _SavedTile({required this.dream, required this.book});

  final SavedDream dream;
  final DreamBook? book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final d = dream.savedAt;
    final detail = savedDreamDetail(dream, book);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DreamResultScreen.saved(dream)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(savedDreamTitle(dream, book), style: text.titleSmall),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: text.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${d.year}.${d.month}.${d.day}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '삭제',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final notifier = ref.read(savedDreamsProvider.notifier);
    await notifier.remove(dream.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('삭제했어요'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () => notifier.restore(dream),
        ),
      ),
    );
  }
}
