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

/// 다크 모드 팔레트: 미드나잇 인디고와 블랙 퍼플 반반 (검정에 가까운 남보라).
/// 홈 히어로, 금색 포인트, 타로 카드, 문구 카드 색은 라이트와 같다.
abstract final class AppDarkColors {
  static const main = Color(0xFF9286F8);
  static const background = Color(0xFF100E1E);
  static const soft = Color(0xFF383263);
  static const surface = Color(0xFF1C1A32);
  static const ink = Color(0xFFECEAF8);
}

/// 테마마다 달라지는 앱 전용 색 (ColorScheme에 없는 것).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({required this.tile, required this.tileIcon});

  /// 홈·마이의 연보라 칸.
  final Color tile;

  /// 그 칸 안의 아이콘.
  final Color tileIcon;

  static const light = AppPalette(
    tile: Color(0xFFD3CEF4),
    tileIcon: AppColors.main,
  );
  static const dark = AppPalette(
    tile: Color(0xFF272444),
    tileIcon: Color(0xFFB6ACFF),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith({Color? tile, Color? tileIcon}) =>
      AppPalette(tile: tile ?? this.tile, tileIcon: tileIcon ?? this.tileIcon);

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      tile: Color.lerp(tile, other.tile, t)!,
      tileIcon: Color.lerp(tileIcon, other.tileIcon, t)!,
    );
  }
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
    return _build(
      scheme,
      background: AppColors.background,
      surface: AppColors.surface,
      soft: AppColors.soft,
      ink: AppColors.ink,
      palette: AppPalette.light,
    );
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppDarkColors.main,
          onPrimary: AppDarkColors.background,
          primaryContainer: AppDarkColors.soft,
          onPrimaryContainer: AppDarkColors.ink,
          secondary: AppDarkColors.main,
          secondaryContainer: AppDarkColors.soft,
          onSecondaryContainer: AppDarkColors.ink,
          tertiary: AppColors.point,
          tertiaryContainer: const Color(0xFF4A3A10),
          onTertiaryContainer: const Color(0xFFF6E2B3),
          surface: AppDarkColors.background,
          onSurface: AppDarkColors.ink,
          onSurfaceVariant: const Color(0xFFA6A2C4),
          surfaceContainerLowest: AppDarkColors.surface,
          surfaceContainerLow: const Color(0xFF18162A),
          surfaceContainer: AppDarkColors.surface,
          surfaceContainerHigh: const Color(0xFF24213E),
          surfaceContainerHighest: const Color(0xFF2C2949),
          outline: const Color(0xFF7A76A0),
          outlineVariant: const Color(0xFF3A365E),
        );
    return _build(
      scheme,
      background: AppDarkColors.background,
      surface: AppDarkColors.surface,
      soft: AppDarkColors.soft,
      ink: AppDarkColors.ink,
      palette: AppPalette.dark,
      navBar: const Color(0xFF18162A),
    );
  }

  static ThemeData _build(
    ColorScheme scheme, {
    required Color background,
    required Color surface,
    required Color soft,
    required Color ink,
    required AppPalette palette,
    Color? navBar,
  }) {
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
      extensions: [palette],
      scaffoldBackgroundColor: background,
      // 눌렀을 때 퍼지는 물결과 눌린 동안의 음영을 회색 대신 연보라로.
      splashColor: soft.withValues(alpha: 0.6),
      highlightColor: soft.withValues(alpha: 0.4),
      hoverColor: soft.withValues(alpha: 0.25),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBar ?? surface,
        indicatorColor: soft,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.primary),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
