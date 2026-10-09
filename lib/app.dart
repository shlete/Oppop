import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'shell/main_shell.dart';

class OneulPpopgiApp extends StatelessWidget {
  const OneulPpopgiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오늘의 뽑기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
