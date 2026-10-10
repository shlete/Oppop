import 'package:flutter/material.dart';

/// 결과 아래의 작은 글자 버튼 (저장·공유).
/// [filled]이면 눌린 상태(저장됨)처럼 채워서 보여준다.
class SmallActionButton extends StatelessWidget {
  const SmallActionButton({
    super.key,
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
