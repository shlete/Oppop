import 'package:flutter/widgets.dart';

/// 여러 줄로 나뉠 때 줄 길이가 고르게 되도록 너비를 좁혀 그리는 글자.
/// "오늘 하루도 반짝반짝 빛날 / 거예요."처럼 마지막 줄에 한 단어만
/// 남는 걸 막는다. 줄 수는 그대로 두고, 그 줄 수를 지키는 가장 좁은 너비를 찾는다.
class BalancedText extends StatelessWidget {
  const BalancedText(
    this.data, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  final String data;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // 웹에서는 한글 글꼴이 나중에 내려받아지므로, 글꼴이 바뀌면 다시 잰다.
    return ListenableBuilder(
      listenable: PaintingBinding.instance.systemFonts,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final text = Text(data, textAlign: textAlign, style: style);
          if (!maxWidth.isFinite) return text;

          final painter = TextPainter(
            text: TextSpan(text: data, style: effective),
            textDirection: direction,
            textAlign: textAlign,
            textScaler: scaler,
          );
          int linesAt(double w) {
            painter.layout(maxWidth: w);
            return painter.computeLineMetrics().length;
          }

          final lines = linesAt(maxWidth);
          if (lines < 2) {
            painter.dispose();
            return text;
          }
          var lo = 0.0, hi = maxWidth;
          for (var i = 0; i < 14; i++) {
            final mid = (lo + hi) / 2;
            if (linesAt(mid) > lines) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
          painter.dispose();
          return Center(
            widthFactor: 1,
            child: SizedBox(width: hi.ceilToDouble() + 1, child: text),
          );
        },
      ),
    );
  }
}
