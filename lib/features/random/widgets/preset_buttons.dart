import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presets.dart';

/// 프리셋 불러오기 / 현재 목록을 프리셋으로 저장.
class PresetButtons extends ConsumerWidget {
  const PresetButtons({super.key, required this.current, required this.onLoad});

  /// 저장 버튼을 누른 시점의 목록.
  final List<String> Function() current;
  final ValueChanged<List<String>> onLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => _pick(context, ref),
          icon: const Icon(Icons.folder_open),
          label: const Text('불러오기'),
        ),
        TextButton.icon(
          onPressed: () => _save(context, ref),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('저장'),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<Preset>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final presets = ref.watch(presetsProvider);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in presets)
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      p.items.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, p),
                    trailing: p.builtIn
                        ? null
                        : IconButton(
                            tooltip: '프리셋 삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                ref.read(presetsProvider.notifier).remove(p),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (picked != null) onLoad(List.of(picked.items));
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _PresetNameDialog(),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(presetsProvider.notifier).save(name, current());
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('"$name" 저장했어요')));
    }
  }
}

class _PresetNameDialog extends StatefulWidget {
  const _PresetNameDialog();

  @override
  State<_PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<_PresetNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('프리셋 이름'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(hintText: '예: 커피 내기'),
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
