import 'package:flutter/material.dart';

/// 앱바 오른쪽의 '저장 목록' 버튼. 저장한 개수가 있으면 함께 보여준다.
/// 아이콘만 두면 눈에 잘 안 띄어서 글자 버튼으로 둔다.
class SavedListButton extends StatelessWidget {
  const SavedListButton({
    super.key,
    required this.count,
    required this.onPressed,
    this.tooltip = '저장 목록',
  });

  final int count;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(count > 0 ? '저장 목록 $count' : '저장 목록'),
        ),
      ),
    );
  }
}
