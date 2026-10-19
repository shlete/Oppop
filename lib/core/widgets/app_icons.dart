import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lucide에 없는 아이콘과, 하단 메뉴에서 고른 칸에 쓰는 '채운' 아이콘.
/// 모두 Lucide와 같은 24 격자, 선 굵기 2로 그렸다.
/// 그림 안의 `{c}`는 아이콘 색, `{cut}`은 채운 면 안쪽 무늬 색(뒤 배경색)으로 바뀐다.
class AppGlyph extends StatelessWidget {
  const AppGlyph(this.body, {super.key, this.size, this.color, this.cut});

  final String body;
  final double? size;
  final Color? color;

  /// 채운 아이콘의 안쪽 무늬 색. 없으면 하단 메뉴 고른 칸 배경색.
  final Color? cut;

  // 타로: 기울어진 카드 두 장 + 반짝이 (앱 아이콘과 같은 구성).
  static const tarot =
      '<clipPath id="f"><path clip-rule="evenodd" d="M0 0H24V24H0Z'
      'M10.18 0.20L24.36 2.71L20.82 22.80L6.64 20.29Z"/></clipPath>'
      '<g clip-path="url(#f)"><rect x="2.6" y="3.6" width="11" height="17" '
      'rx="2.2" transform="rotate(-12 8.1 12.1)"/></g>'
      '<g transform="rotate(10 15.5 11.5)">'
      '<rect x="10" y="3" width="11" height="17" rx="2.2"/>'
      '<path transform="translate(11.6 7.6) scale(0.33)" d="$_sparkle"/></g>';

  static const tarotFilled =
      '<rect x="2.6" y="3.6" width="11" height="17" rx="2.2" '
      'transform="rotate(-12 8.1 12.1)" fill="{c}"/>'
      '<g transform="rotate(10 15.5 11.5)">'
      '<rect x="10" y="3" width="11" height="17" rx="2.2" fill="{c}" '
      'stroke="{cut}" stroke-width="1.6"/>'
      '<path transform="translate(11.6 7.6) scale(0.33)" d="$_sparkle" '
      'fill="{cut}" stroke="none"/></g>';

  // 사다리타기: 세로줄 세 개와 엇갈린 가로줄.
  static const ladder =
      '<path d="M5 3v18"/><path d="M12 3v18"/><path d="M19 3v18"/>'
      '<path d="M5 7h7"/><path d="M12 11h7"/><path d="M5 15h7"/>'
      '<path d="M12 18h7"/>';

  // 아래는 Lucide 모양 그대로 안을 칠한 것 (하단 메뉴 고른 칸).
  static const houseFilled =
      '<path d="M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 '
      '21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" fill="{c}"/>'
      '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8" stroke="{cut}"/>';

  static const userFilled =
      '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2z" fill="{c}"/>'
      '<circle cx="12" cy="7" r="4" fill="{c}"/>';

  static const dicesFilled =
      '<path d="m17.92 14 3.5-3.5a2.24 2.24 0 0 0 0-3l-5-4.92a2.24 2.24 0 0 '
      '0-3 0L10 6z" fill="{c}"/>'
      '<rect width="12" height="12" x="2" y="10" rx="2" fill="{c}" '
      'stroke="{cut}" stroke-width="1.6"/>'
      '<g stroke="{cut}"><path d="M6 18h.01"/><path d="M10 14h.01"/>'
      '<path d="M15 6h.01"/><path d="M18 9h.01"/></g>';

  static const sparklesFilled =
      '<path d="$_sparkle" fill="{c}"/>'
      '<path d="M20 2v4"/><path d="M22 4h-4"/>'
      '<circle cx="4" cy="20" r="2" fill="{c}"/>';

  static const moonStarFilled =
      '<path d="M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 '
      '6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401" fill="{c}"/>'
      '<path d="M18 5h4"/><path d="M20 3v4"/>';

  // 칠할 면이 없는 화살표 모양은 굵은 선으로.
  static const shuffleBold =
      '<g stroke-width="2.75"><path d="m18 14 4 4-4 4"/><path d="m18 2 4 4-4 4"/>'
      '<path d="M2 18h1.973a4 4 0 0 0 3.3-1.7l5.454-8.6a4 4 0 0 1 3.3-1.7H22"/>'
      '<path d="M2 6h1.972a4 4 0 0 1 3.6 2.2"/>'
      '<path d="M22 18h-6.041a4 4 0 0 1-3.3-1.8l-.359-.45"/></g>';

  static const _sparkle =
      'M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 '
      '1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 '
      '5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 '
      '1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z';

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final s = size ?? icon.size ?? 24;
    final c = color ?? icon.color ?? Colors.black;
    final k =
        cut ??
        NavigationBarTheme.of(context).indicatorColor ??
        Theme.of(context).colorScheme.secondaryContainer;
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="{c}" stroke-width="2" stroke-linecap="round" '
        'stroke-linejoin="round" opacity="${c.a}">$body</svg>';
    return SizedBox.square(
      dimension: s,
      child: SvgPicture.string(
        svg.replaceAll('{c}', _hex(c)).replaceAll('{cut}', _hex(k)),
        width: s,
        height: s,
      ),
    );
  }
}
