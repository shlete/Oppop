import 'package:flutter/material.dart';

/// 항목 추가·삭제·수정 목록. [min]개 미만으로는 지울 수 없고 [max]개까지 추가할 수 있다.
class ItemListEditor extends StatefulWidget {
  const ItemListEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.min = 2,
    this.max = 20,
    this.hint = '항목',
  });

  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final int min;
  final int max;
  final String hint;

  @override
  State<ItemListEditor> createState() => _ItemListEditorState();
}

class _ItemListEditorState extends State<ItemListEditor> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final s in widget.items) TextEditingController(text: s),
    ];
  }

  @override
  void didUpdateWidget(ItemListEditor old) {
    super.didUpdateWidget(old);
    final current = [for (final c in _controllers) c.text];
    if (!_sameList(current, widget.items)) {
      for (final c in _controllers) {
        c.dispose();
      }
      _controllers = [
        for (final s in widget.items) TextEditingController(text: s),
      ];
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged([for (final c in _controllers) c.text]);

  void _add() {
    setState(() => _controllers.add(TextEditingController()));
    _emit();
  }

  void _remove(int i) {
    setState(() => _controllers.removeAt(i).dispose());
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final canRemove = _controllers.length > widget.min;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllers[i],
                    maxLength: 12,
                    decoration: InputDecoration(
                      hintText: '${widget.hint} ${i + 1}',
                      counterText: '',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  tooltip: '삭제',
                  onPressed: canRemove ? () => _remove(i) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          ),
        if (_controllers.length < widget.max)
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text('${widget.hint} 추가'),
          ),
      ],
    );
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 빈칸을 "항목 N"으로 채운 목록.
List<String> fillBlanks(List<String> items, String hint) => [
  for (var i = 0; i < items.length; i++)
    items[i].trim().isEmpty ? '$hint ${i + 1}' : items[i].trim(),
];
