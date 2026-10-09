import 'package:flutter/material.dart';

/// 화면 아래쪽의 큰 실행 버튼(돌리기·사다리 만들기·뽑기 등).
/// 모든 화면이 같은 모양을 쓰도록 크기와 글씨는 여기서만 정한다.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed});

  final String label;

  /// null이면 비활성화된다.
  final VoidCallback? onPressed;

  static const width = 220.0;
  static const height = 52.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: FilledButton(
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 17)),
        ),
      ),
    );
  }
}
