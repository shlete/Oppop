import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daily/daily_state.dart';
import '../daily/saved_phrase_view.dart';
import '../daily/saved_phrases_screen.dart';
import '../lotto/saved_lotto.dart';
import '../lotto/saved_lotto_screen.dart';
import '../tarot/saved_readings_screen.dart';
import '../tarot/tarot_cards.dart';
import '../tarot/tarot_state.dart';

/// 마이: 타로·로또·오늘의 뽑기에서 저장한 기록을 한곳에 모아 본다.
/// 지금은 이 기기에만 저장되고, 로그인이 생기면 계정으로 옮긴다.
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  /// 최근 기록에 보여줄 개수.
  static const recentCount = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final readings = ref.watch(savedReadingsProvider);
    final games = ref.watch(savedLottoProvider);
    final phrases = ref.watch(savedPhrasesProvider);
    final deck = ref.watch(tarotDeckProvider).value;

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    final recent = <_Record>[
      for (final r in readings)
        _Record(
          at: r.savedAt,
          icon: Icons.style,
          kind: '타로',
          title: r.title,
          detail: deck == null
              ? null
              : [
                  for (final c in r.cards)
                    '${deck.byId(c.cardId)?.name ?? '?'}${c.reversed ? '(역)' : ''}',
                ].join(' · '),
          onTap: deck == null
              ? null
              : () => open(SavedReadingView(reading: r, deck: deck)),
        ),
      for (final g in games)
        _Record(
          at: g.savedAt,
          icon: Icons.casino,
          kind: '로또',
          title: g.numbers.join('  '),
          detail: g.memo.isEmpty ? null : g.memo,
          onTap: () => open(const SavedLottoScreen()),
        ),
      for (final p in phrases)
        _Record(
          at: p.savedAt,
          icon: Icons.format_quote,
          kind: p.category.label,
          title: p.text.replaceAll('\n', ' '),
          detail: p.by == null ? null : '— ${p.by}',
          onTap: () => open(SavedPhraseView(phrase: p)),
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return Scaffold(
      appBar: AppBar(title: const Text('마이')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('내 기록', style: text.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CountTile(
                  icon: Icons.style,
                  label: '타로',
                  count: readings.length,
                  onTap: () => open(const SavedReadingsScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountTile(
                  icon: Icons.casino,
                  label: '로또',
                  count: games.length,
                  onTap: () => open(const SavedLottoScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountTile(
                  icon: Icons.format_quote,
                  label: '오늘의 뽑기',
                  count: phrases.length,
                  onTap: () => open(const SavedPhrasesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('최근 저장', style: text.titleMedium),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 28,
                ),
                child: Text(
                  '아직 저장한 기록이 없어요\n타로 · 로또 · 오늘의 뽑기에서 저장하면 여기에 모여요',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
              ),
            )
          else
            for (final r in recent.take(recentCount)) _RecordTile(record: r),
          const SizedBox(height: 24),
          Text('기타', style: text.titleMedium),
          const SizedBox(height: 8),
          for (final item in ['설정', '문의하기'])
            Card(
              child: ListTile(title: Text(item), trailing: const Text('준비 중')),
            ),
          const SizedBox(height: 12),
          Text(
            '기록은 지금 이 기기에만 저장돼요.\n로그인 기능이 생기면 계정으로 옮길 수 있어요.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Record {
  const _Record({
    required this.at,
    required this.icon,
    required this.kind,
    required this.title,
    required this.onTap,
    this.detail,
  });

  final DateTime at;
  final IconData icon;
  final String kind;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      // 홈의 메뉴 칸과 같은 연보라.
      color: const Color(0xFFD3CEF4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 108,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: scheme.primary),
              const SizedBox(height: 6),
              Text(label, style: text.labelLarge),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: text.titleLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final _Record record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final d = record.at;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: record.onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(record.icon, size: 20, color: scheme.primary),
        ),
        title: Text(
          record.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall,
        ),
        subtitle: Text(
          ['${record.kind} · ${d.month}월 ${d.day}일', ?record.detail].join('  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
