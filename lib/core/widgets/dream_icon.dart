import 'package:flutter/material.dart';

/// 해몽뽑기 아이콘: 침대에서 자는 사람 머리 위로 생각구름이 뭉게뭉게 피어오른다.
/// 평소에는 구름이 다 피어난 모습으로 멈춰 있고, [animate]가 켜진 동안만
/// (홈 타일에 마우스를 올렸을 때) 점과 구름이 차례로 피어오르기를 되풀이한다.
/// 바깥 크기는 [size] 정사각형이고, 구름은 그 위쪽으로 조금 넘친다.
class DreamIcon extends StatefulWidget {
  const DreamIcon({
    super.key,
    required this.color,
    this.size = 28,
    this.animate = false,
  });

  final Color color;
  final double size;
  final bool animate;

  @override
  State<DreamIcon> createState() => _DreamIconState();
}

class _DreamIconState extends State<DreamIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
    // '애니메이션 줄이기' 설정에서 20배 빨라지지 않게 정해진 속도로 재생한다.
    animationBehavior: AnimationBehavior.preserve,
  );

  /// 다 피어난 채로 멈춰 있을 때의 값.
  static const _rest = 0.6;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(DreamIcon old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate) _sync();
  }

  void _sync() {
    if (widget.animate) {
      _c.value = 0;
      _c.repeat();
    } else {
      _c.stop();
      _c.value = _rest;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// [start]~[end] 사이에 0→1로 피어나고, 끝 무렵 다 함께 사라진다.
  double _bloom(double t, double start, double end) {
    if (t >= 0.86) return (1 - (t - 0.86) / 0.14).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(
      ((t - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.5,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          Widget puff(double left, double top, double d, double v) =>
              Positioned(
                left: left,
                top: top,
                child: Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * v,
                    child: Container(
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                      ),
                    ),
                  ),
                ),
              );
          final cloud = _bloom(t, 0.36, 0.56);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                bottom: -s * 0.08,
                child: Icon(Icons.hotel, size: s, color: widget.color),
              ),
              puff(s * 0.40, s * 0.12, s * 0.12, _bloom(t, 0.0, 0.16)),
              puff(s * 0.56, -s * 0.06, s * 0.18, _bloom(t, 0.16, 0.32)),
              Positioned(
                left: s * 0.68,
                top: -s * 0.34,
                child: Opacity(
                  opacity: cloud.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.5 + 0.5 * cloud,
                    alignment: Alignment.bottomLeft,
                    child: Icon(
                      Icons.cloud,
                      size: s * 0.62,
                      color: widget.color,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
