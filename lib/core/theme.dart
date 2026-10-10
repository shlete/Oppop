import 'package:flutter/material.dart';

/// 앱 컬러 팔레트: 인디고 바이올렛 (밤하늘 퍼플 + 미드나잇 골드).
/// 오늘의 뽑기 문구 카드는 카테고리별 색을 따로 쓴다 (phrase_card.dart).
abstract final class AppColors {
  /// 메인: 버튼, 강조 글자, 선택 표시.
  static const main = Color(0xFF30258F);

  /// 포인트: 금색. 타로 카드 테두리, 작은 강조.
  static const point = Color(0xFFDFA220);

  /// 화면 배경.
  static const background = Color(0xFFE4E2F7);

  /// 연한 면: 칩, 해석 상자, 선택된 탭.
  static const soft = Color(0xFFC5C0EF);

  /// 카드 면.
  static const surface = Color(0xFFFFFFFF);

  /// 글자.
  static const ink = Color(0xFF15132E);
}

/// 앱 글꼴 이름 (pubspec.yaml에 등록).
abstract final class AppFonts {
  static const body = 'SUIT';
  static const heading = 'IBMPlexSansKR';
}

class AppTheme {
  static const seed = AppColors.main;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
      primary: AppColors.main,
      onPrimary: Colors.white,
      primaryContainer: AppColors.soft,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.main,
      secondaryContainer: AppColors.soft,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.point,
      tertiaryContainer: const Color(0xFFF6E2B3),
      onTertiaryContainer: const Color(0xFF3A2A00),
      surface: AppColors.background,
      onSurface: AppColors.ink,
      onSurfaceVariant: const Color(0xFF4A4668),
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: const Color(0xFFF4F3FC),
      surfaceContainer: const Color(0xFFEDEBFA),
      surfaceContainerHigh: const Color(0xFFDAD7F2),
      surfaceContainerHighest: const Color(0xFFD0CCEE),
      outline: const Color(0xFF7C78A0),
      outlineVariant: const Color(0xFFBDB8E0),
    );
    final base = ThemeData(
      // 본문 글꼴 SUIT. 무료 상업 이용 가능 (SIL OFL 1.1).
      fontFamily: AppFonts.body,
      colorScheme: scheme,
      useMaterial3: true,
    );
    final t = base.textTheme;
    TextStyle? heading(TextStyle? s) =>
        s?.copyWith(fontFamily: AppFonts.heading);
    return base.copyWith(
      // 큰 제목은 IBM Plex Sans KR (화면 제목, 큰 글씨 제목).
      textTheme: t.copyWith(
        displayLarge: heading(t.displayLarge),
        displayMedium: heading(t.displayMedium),
        displaySmall: heading(t.displaySmall),
        headlineLarge: heading(t.headlineLarge),
        headlineMedium: heading(t.headlineMedium),
        headlineSmall: heading(t.headlineSmall),
        titleLarge: heading(t.titleLarge),
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.soft,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.main),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
