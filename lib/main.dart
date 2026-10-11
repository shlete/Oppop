import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ads/ads.dart';
import 'core/haptics.dart';
import 'core/theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Ads.init();
  await AppHaptics.load();
  await AppThemeMode.load();
  // 설정 > 오픈소스 라이선스에 앱 글꼴 라이선스도 보이게.
  LicenseRegistry.addLicense(() async* {
    for (final (name, path) in [
      ('SUIT', 'assets/fonts/suit/OFL.txt'),
      ('IBM Plex Sans KR', 'assets/fonts/ibmplexsanskr/OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(path));
    }
  });
  runApp(const ProviderScope(child: OneulPpopgiApp()));
}
