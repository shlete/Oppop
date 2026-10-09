import 'dart:math';

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
      builder: (context, child) => PhoneFrame(child: child!),
      home: const MainShell(),
    );
  }
}

/// 태블릿·PC처럼 넓은 화면에서는 앱을 가운데 폰 너비로 제한한다.
/// 폰에서는 화면이 [maxWidth]보다 좁아서 아무 변화가 없다.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  static const maxWidth = 480.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth) return child;

    final width = min(media.size.width, maxWidth);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Container(
          width: width,
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(blurRadius: 24, color: Color(0x22000000))],
          ),
          child: ClipRect(
            child: MediaQuery(
              data: media.copyWith(size: Size(width, media.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
