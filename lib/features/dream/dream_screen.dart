import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/primary_button.dart';
import '../../core/widgets/saved_list_button.dart';
import 'dream_ai.dart';
import 'dream_book.dart';
import 'dream_result_screen.dart';
import 'dream_state.dart';
import 'saved_dreams_screen.dart';

/// 해몽뽑기: 꿈 속 장면을 고르거나 꿈 이야기를 직접 적는다. 둘 중 하나만 해도 된다.
class DreamScreen extends ConsumerStatefulWidget {
  const DreamScreen({super.key});

  /// 고를 수 있는 키워드 수.
  static const maxPicks = 3;

  @override
  ConsumerState<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends ConsumerState<DreamScreen> {
  final _story = TextEditingController();
  final List<String> _picked = [];

  @override
  void initState() {
    super.initState();
    _story.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _story.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else if (_picked.length < DreamScreen.maxPicks) {
        _picked.add(id);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('키워드는 3개까지 고를 수 있어요')));
      }
    });
  }

  bool get _ready => _picked.isNotEmpty || _story.text.trim().isNotEmpty;

  void _show() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DreamResultScreen(
          symbolIds: List.of(_picked),
          story: _story.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(dreamBookProvider).value;
    final saved = ref.watch(savedDreamsProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('해몽뽑기'),
        actions: [
          SavedListButton(
            count: saved.length,
            tooltip: '저장한 해몽',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedDreamsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: book == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        Text('어떤 꿈을 꾸셨나요?', style: text.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          '꿈 이야기를 적거나 꿈에 나온 장면 ${DreamScreen.maxPicks}가지를 골라주세요. 하나만 해도 돼요.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _story,
                          minLines: 3,
                          maxLines: 6,
                          maxLength: DreamAiClient.maxLength,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: '예) 맑은 바다에서 커다란 물고기를 두 손으로 잡았어요',
                            helperText: '이름이나 연락처 같은 개인정보는 적지 말아 주세요',
                            filled: true,
                            fillColor: scheme.surfaceContainerLowest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('꿈 속 장면', style: text.titleMedium),
                            const SizedBox(width: 8),
                            Text(
                              '${_picked.length}/${DreamScreen.maxPicks}',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                        for (final group in book.groups) ...[
                          const SizedBox(height: 12),
                          Text(
                            group,
                            style: text.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in book.inGroup(group))
                                FilterChip(
                                  label: Text(s.name),
                                  selected: _picked.contains(s.id),
                                  showCheckmark: false,
                                  onSelected: (_) => _toggle(s.id),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  PrimaryButton(
                    label: '해몽 보기',
                    onPressed: _ready ? _show : null,
                  ),
                  const SizedBox(height: 6),
                  Text('재미로 보는 해몽이에요. 가볍게 즐겨주세요.', style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
