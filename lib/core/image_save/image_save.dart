import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'save_png_io.dart'
    if (dart.library.js_interop) 'save_png_web.dart'
    as platform;

/// 이미지 저장 결과.
enum ImageSaveResult { saved, denied, failed }

/// [key]가 붙은 RepaintBoundary를 PNG로 찍는다. 화면보다 3배 선명하게.
Future<Uint8List?> captureBoundary(GlobalKey key) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}

/// PNG를 폰 사진첩에 저장한다. 웹에서는 파일로 내려받는다.
Future<ImageSaveResult> savePng(Uint8List bytes, {required String name}) =>
    platform.savePng(bytes, name: name);
