import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tarot_cards.dart';

/// 카드 그림 비율 (1909 라이더-웨이트 스캔 기준).
const tarotAspect = 0.578;

const tarotInk = Color(0xFF15132E);
const tarotGold = Color(0xFFE9C46A);

/// 카드 뒷면. 덱 펼치기와 뒤집기 전에 보인다.
class TarotCardBack extends StatelessWidget {
  const TarotCardBack({super.key, this.highlight = false});

  /// 고른 카드처럼 테두리를 밝게.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: tarotAspect,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final radius = w * 0.08;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF221A6E),
                  Color(0xFF3A2DA6),
                  Color(0xFF16114A),
                ],
              ),
              border: Border.all(
                color: highlight ? tarotGold : const Color(0x55FFFFFF),
                width: highlight
                    ? math.max(2, w * 0.03)
                    : math.max(1, w * 0.015),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3315132E),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: CustomPaint(painter: _BackPainter(radius)),
          );
        },
      ),
    );
  }
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final inset = w * 0.09;
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, size.height - inset * 2),
      Radius.circular(radius * 0.6),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, w * 0.012)
      ..color = tarotGold.withValues(alpha: 0.7);
    canvas.drawRRect(inner, line);

    final c = size.center(Offset.zero);
    // 가운데 달과 별.
    final moonR = w * 0.18;
    final gold = Paint()..color = tarotGold;
    canvas.saveLayer(Rect.fromCircle(center: c, radius: moonR * 1.2), Paint());
    canvas.drawCircle(c, moonR, gold);
    canvas.drawCircle(
      c + Offset(moonR * 0.45, -moonR * 0.25),
      moonR * 0.85,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    void star(Offset at, double r) {
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final a = -math.pi / 2 + i * math.pi / 4;
        final rr = i.isEven ? r : r * 0.35;
        final p = at + Offset(math.cos(a) * rr, math.sin(a) * rr);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gold);
    }

    star(c + Offset(w * 0.2, -w * 0.22), w * 0.07);
    star(c + Offset(-w * 0.22, w * 0.26), w * 0.05);
    star(Offset(w / 2, inset + w * 0.16), w * 0.05);
    star(Offset(w / 2, size.height - inset - w * 0.16), w * 0.05);
  }

  @override
  bool shouldRepaint(_BackPainter old) => old.radius != radius;
}

/// 카드 앞면 그림. 역방향이면 뒤집어서 보여준다.
class TarotCardFace extends StatelessWidget {
  const TarotCardFace({super.key, required this.card, required this.reversed});

  final TarotCard card;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: tarotAspect,
      child: LayoutBuilder(
        builder: (context, box) {
          final radius = box.maxWidth * 0.06;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3315132E),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: RotatedBox(
                quarterTurns: reversed ? 2 : 0,
                child: Image.asset(
                  card.image,
                  fit: BoxFit.cover,
                  semanticLabel: card.name,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: const Color(0xFFF3EEFF),
                    child: Center(
                      child: Text(card.name, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// [t]가 0이면 뒷면, 1이면 앞면. 그 사이에서는 세로축으로 돌아간다.
class FlippingCard extends StatelessWidget {
  const FlippingCard({
    super.key,
    required this.t,
    required this.card,
    required this.reversed,
  });

  final double t;
  final TarotCard card;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final angle = t * math.pi;
    final showFace = t >= 0.5;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(showFace ? angle - math.pi : angle),
      child: showFace
          ? TarotCardFace(card: card, reversed: reversed)
          : const TarotCardBack(),
    );
  }
}

/// '정방향' / '역방향' 작은 표시.
class OrientationBadge extends StatelessWidget {
  const OrientationBadge({super.key, required this.reversed});

  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: reversed ? scheme.tertiaryContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        reversed ? '역방향' : '정방향',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// 키워드 3개를 작은 알약 모양으로.
class KeywordRow extends StatelessWidget {
  const KeywordRow({super.key, required this.keywords, this.center = true});

  final List<String> keywords;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: center ? WrapAlignment.center : WrapAlignment.start,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final k in keywords)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('#$k', style: Theme.of(context).textTheme.labelMedium),
          ),
      ],
    );
  }
}
