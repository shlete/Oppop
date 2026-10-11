import 'package:flutter/widgets.dart';

/// [offset]이 바뀌면 그 자리로 부드럽게 미끄러지는 [FractionalTranslation].
/// AnimatedSlide와 같지만 기기의 '애니메이션 줄이기' 설정에도 빨라지지 않는다.
class SmoothSlide extends StatefulWidget {
  const SmoothSlide({
    super.key,
    required this.offset,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
    this.curve = Curves.easeOutCubic,
  });

  /// 자기 크기 대비 이동 거리.
  final Offset offset;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<SmoothSlide> createState() => _SmoothSlideState();
}

class _SmoothSlideState extends State<SmoothSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    animationBehavior: AnimationBehavior.preserve,
    value: 1,
  );
  late Offset _from = widget.offset;
  late Offset _to = widget.offset;

  Offset get _now => Offset.lerp(_from, _to, widget.curve.transform(_c.value))!;

  @override
  void didUpdateWidget(SmoothSlide old) {
    super.didUpdateWidget(old);
    if (widget.offset != _to) {
      _from = _now;
      _to = widget.offset;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) =>
        FractionalTranslation(translation: _now, child: child),
    child: widget.child,
  );
}
