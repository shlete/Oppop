import 'dart:typed_data';

import 'package:gal/gal.dart';

import 'image_save.dart';

Future<ImageSaveResult> savePng(Uint8List bytes, {required String name}) async {
  try {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      return ImageSaveResult.denied;
    }
    await Gal.putImageBytes(bytes, name: name);
    return ImageSaveResult.saved;
  } on GalException catch (e) {
    return e.type == GalExceptionType.accessDenied
        ? ImageSaveResult.denied
        : ImageSaveResult.failed;
  }
}
