import 'package:flutter/material.dart';

import 'small_action_button.dart';

/// 결과 화면의 저장·공유 버튼 줄. 스크롤하는 결과 화면에서는 스크롤 맨 끝에 둬서
/// 끝까지 내려야 보이게 하고, 고정 버튼은 맨 아래 큰 버튼 하나만 둔다.
/// [visible]이 false여도 자리는 차지해서 결과가 나올 때 화면이 움직이지 않는다.
class SaveShareRow extends StatelessWidget {
  const SaveShareRow({
    super.key,
    required this.visible,
    required this.saved,
    required this.onSave,
    required this.onShare,
    this.shareTooltip = '이미지로 공유',
    this.leading,
  });

  /// 높이. 바로 아래 큰 버튼이 올 때의 간격은 [gap].
  static const height = 36.0;
  static const gap = 10.0;

  final bool visible;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final String shareTooltip;

  /// 저장 앞에 붙는 버튼 (주의할 점의 별자리 고르기). 결과 전에도 보인다.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            if (visible) const SizedBox(width: 12),
          ],
          if (visible) ...[
            SmallActionButton(
              label: saved ? '저장됨' : '저장',
              filled: saved,
              tooltip: saved ? '저장 취소' : '저장',
              onPressed: onSave,
            ),
            const SizedBox(width: 12),
            SmallActionButton(
              label: '공유',
              tooltip: shareTooltip,
              onPressed: onShare,
            ),
          ],
        ],
      ),
    );
  }
}
