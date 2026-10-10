import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/balanced_text.dart';
import 'phrases.dart';

/// 카테고리마다 다른 배경 그라데이션 (위 → 아래).
List<Color> phraseCardColors(PhraseCategory c) => switch (c) {
  PhraseCategory.quote => const [
    Color(0xFFF3EEFF),
    Color(0xFFE2D6FF),
    Color(0xFFF6D9F0),
  ],
  PhraseCategory.cheer => const [
    Color(0xFFFFF6E6),
    Color(0xFFFFE0C2),
    Color(0xFFFFC9C2),
  ],
  PhraseCategory.caution => const [
    Color(0xFFEAF8F4),
    Color(0xFFCDEDEA),
    Color(0xFFC6DFF6),
  ],
};

/// 카테고리 포인트 색 (반짝이, 따옴표, 구분선).
Color phraseCardAccent(PhraseCategory c) => switch (c) {
  PhraseCategory.quote => const Color(0xFF8A6CFF),
  PhraseCategory.cheer => const Color(0xFFFF8A5C),
  PhraseCategory.caution => const Color(0xFF2E9FA6),
};

/// 문구 결과 카드. 이미지로 저장·공유되므로 카드 하나만으로 완성된 그림이 되게 꾸민다.
class PhraseCard extends StatelessWidget {
  const PhraseCard({
    super.key,
    required this.category,
    required this.text,
    required this.date,
    this.by,
  });

  final PhraseCategory category;

  /// 명언의 출처. 있으면 문구 아래에 작게 붙인다.
  final String? by;

  /// null이면 뽑기 전 안내 문구를 보여준다.
  final String? text;
  final DateTime date;

  static const _ink = Color(0xFF2E2648);

  /// 카드를 그리는 기준 너비. 실제 크기는 FittedBox가 맞춘다.
  static const designWidth = 320.0;

  @override
  Widget build(BuildContext context) {
    final colors = phraseCardColors(category);
    final accent = phraseCardAccent(category);
    final empty = text == null;
    // 늘 같은 크기로 그린 뒤 화면에 맞게 줄이고 늘린다.
    // 기기 크기와 상관없이 글자 줄바꿈과 저장 이미지 모양이 똑같다.
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: FittedBox(
        child: SizedBox(
          width: designWidth,
          height: designWidth * 5 / 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(
                painter: _CardBackgroundPainter(colors: colors, accent: accent),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                      child: Column(
                        children: [
                          _CategoryPill(label: category.label, accent: accent),
                          Expanded(
                            child: Center(
                              child: empty
                                  ? Text(
                                      '뽑기 버튼을 누르면\n오늘의 문구가 나와요',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                        color: _ink.withValues(alpha: 0.45),
                                      ),
                                    )
                                  : _PhraseBody(
                                      text: text!,
                                      by: by,
                                      accent: accent,
                                    ),
                            ),
                          ),
                          _Footer(date: date, accent: accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Color.lerp(accent, PhraseCard._ink, 0.35),
        ),
      ),
    );
  }
}

class _PhraseBody extends StatelessWidget {
  const _PhraseBody({required this.text, this.by, required this.accent});

  final String text;
  final String? by;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '“',
          style: TextStyle(
            fontSize: 56,
            height: 0.9,
            fontWeight: FontWeight.w800,
            color: accent.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        BalancedText(
          keepWords(text),
          style: const TextStyle(
            fontSize: 21,
            height: 1.65,
            fontWeight: FontWeight.w600,
            color: PhraseCard._ink,
          ),
        ),
        if (by != null) ...[
          const SizedBox(height: 12),
          Text(
            '— $by',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.lerp(accent, PhraseCard._ink, 0.45),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.date, required this.accent});

  final DateTime date;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = PhraseCard._ink.withValues(alpha: 0.5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.year}.${date.month}.${date.day}',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomPaint(
            size: const Size(8, 8),
            painter: _SparklePainter(accent.withValues(alpha: 0.7)),
          ),
        ),
        Text(
          '오늘의 뽑기',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: PhraseCard._ink.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

/// 그라데이션 배경 위에 흐릿한 동그라미와 반짝이를 그린다.
/// 아이콘 폰트에 기대지 않고 직접 그려서 어느 기기에서나 똑같이 보인다.
class _CardBackgroundPainter extends CustomPainter {
  _CardBackgroundPainter({required this.colors, required this.accent});

  final List<Color> colors;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );

    final w = size.width, h = size.height;
    final blob = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(
      Offset(w * 0.92, h * 0.08),
      w * 0.38,
      blob..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      Offset(w * 0.05, h * 0.95),
      w * 0.42,
      blob..color = Colors.white.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset(w * 0.0, h * 0.3),
      w * 0.18,
      blob..color = accent.withValues(alpha: 0.12),
    );

    // (가로 비율, 세로 비율, 크기, 투명도)
    const sparkles = [
      (0.15, 0.16, 14.0, 0.55),
      (0.22, 0.24, 7.0, 0.4),
      (0.84, 0.30, 10.0, 0.45),
      (0.88, 0.74, 16.0, 0.5),
      (0.78, 0.82, 7.0, 0.35),
      (0.12, 0.68, 9.0, 0.35),
    ];
    for (final (x, y, s, a) in sparkles) {
      _drawSparkle(
        canvas,
        Offset(w * x, h * y),
        s,
        Paint()..color = accent.withValues(alpha: a),
      );
    }
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.30, h * 0.12), 2.5, dot);
    canvas.drawCircle(Offset(w * 0.72, h * 0.88), 2, dot);
    canvas.drawCircle(Offset(w * 0.90, h * 0.46), 1.8, dot);
  }

  @override
  bool shouldRepaint(_CardBackgroundPainter old) =>
      old.colors != colors || old.accent != accent;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => _drawSparkle(
    canvas,
    size.center(Offset.zero),
    size.shortestSide,
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// 네 갈래 반짝이. [size]는 위아래 끝 사이 길이.
void _drawSparkle(Canvas canvas, Offset c, double size, Paint paint) {
  final r = size / 2;
  final k = r * 0.22;
  final path = Path()..moveTo(c.dx, c.dy - r);
  for (var i = 1; i <= 4; i++) {
    final a = -math.pi / 2 + i * math.pi / 2;
    final mid = a - math.pi / 4;
    path.quadraticBezierTo(
      c.dx + k * math.cos(mid),
      c.dy + k * math.sin(mid),
      c.dx + r * math.cos(a),
      c.dy + r * math.sin(a),
    );
  }
  canvas.drawPath(path..close(), paint);
}

/// 한글은 글자 단위로 줄이 바뀌어 "풍/경도"처럼 단어가 잘린다.
/// 단어 안 글자 사이에 줄바꿈 금지 문자(U+2060)를 넣어 띄어쓰기에서만 줄이 바뀌게 한다.
String keepWords(String text) =>
    text.split(' ').map((w) => w.characters.join('\u2060')).join(' ');
