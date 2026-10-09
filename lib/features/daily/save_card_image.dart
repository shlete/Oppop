import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/image_save/image_save.dart';

bool _saving = false;

/// [cardKey]가 붙은 카드를 찍어 사진첩(웹은 파일)에 저장하고 결과를 스낵바로 알린다.
/// 카드를 꾹 눌렀을 때 쓴다.
Future<void> saveCardImage(BuildContext context, GlobalKey cardKey) async {
  if (_saving) return;
  _saving = true;
  try {
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await captureBoundary(cardKey);
    final result = bytes == null
        ? ImageSaveResult.failed
        : await savePng(
            bytes,
            name: 'oneul-ppopgi-${DateTime.now().millisecondsSinceEpoch}',
          );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            ImageSaveResult.saved => '이미지를 저장했어요',
            ImageSaveResult.denied => '사진 저장 권한을 허용하면 저장할 수 있어요',
            ImageSaveResult.failed => '이미지를 저장하지 못했어요',
          }),
        ),
      );
  } finally {
    _saving = false;
  }
}
