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
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
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
