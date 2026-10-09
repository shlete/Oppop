import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'image_save.dart';

Future<ImageSaveResult> savePng(Uint8List bytes, {required String name}) async {
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = '$name.png';
    anchor.click();
    Future<void>.delayed(
      const Duration(minutes: 1),
      () => web.URL.revokeObjectURL(url),
    );
    return ImageSaveResult.saved;
  } catch (_) {
    return ImageSaveResult.failed;
  }
}
