import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ads/ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Ads.init();
  runApp(const ProviderScope(child: OneulPpopgiApp()));
}
