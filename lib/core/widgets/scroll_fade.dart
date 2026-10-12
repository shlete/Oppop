import 'package:flutter/material.dart';

/// 스크롤 영역 아래쪽 글이 뚝 잘리지 않고 서서히 흐려지게 한다.
/// 끝까지 내리면 흐림이 사라져 마지막 줄이 또렷하게 보인다.
/// [child]는 SingleChildScrollView나 ListView 같은 스크롤 위젯.
class ScrollFade extends StatefulWidget {
  const ScrollFade({super.key, required this.child, this.fade = 56});

  final Widget child;

  /// 흐려지는 구간 높이.
  final double fade;

  @override
  State<ScrollFade> createState() => _ScrollFadeState();
}

class _ScrollFadeState extends State<ScrollFade> {
  late double _fadeNow = widget.fade;

  bool _update(ScrollMetrics m) {
    final next = (m.maxScrollExtent - m.pixels).clamp(0.0, widget.fade);
    if (next != _fadeNow) setState(() => _fadeNow = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => n.depth == 0 && _update(n.metrics),
      child: NotificationListener<ScrollNotification>(
        // 안쪽 스크롤(가로 카드 넘기기, 여러 줄 입력칸 등)은 무시한다.
        onNotification: (n) => n.depth == 0 && _update(n.metrics),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0, (1 - _fadeNow / bounds.height).clamp(0.0, 1.0), 1],
          ).createShader(bounds),
          child: widget.child,
        ),
      ),
    );
  }
}
