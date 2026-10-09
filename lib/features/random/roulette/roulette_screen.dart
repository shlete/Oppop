import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../palette.dart';
import '../presets.dart';
import '../widgets/item_list_editor.dart';
import '../widgets/preset_buttons.dart';
import 'roulette_logic.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key, this.random});

  /// 테스트에서 결과를 고정할 때 넘긴다.
  final Random? random;

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  late final Random _random = widget.random ?? Random();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );
  List<String> _items = List.of(builtInPresets.first.items);
  double _rotation = 0;
  Animation<double>? _spin;

  bool get _spinning => _controller.isAnimating;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_spinning) return;
    final index = _random.nextInt(_items.length);
    final target = RouletteLogic.targetRotation(
      current: _rotation,
      index: index,
      count: _items.length,
      jitter: _random.nextDouble() * 2 - 1,
    );
    _spin = Tween(
      begin: _rotation,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    setState(() {});
    await _controller.forward(from: 0);
    if (!mounted) return;
    setState(() => _rotation = target % (2 * pi));
    _spin = null;
    HapticFeedback.mediumImpact();
    await _showResult(index);
  }

  Future<void> _showResult(int index) async {
    final winner = _items[index];
    final again = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결과'),
        content: Text(
          winner,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          if (_items.length > 2)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('이 항목 빼고 다시'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (again == true && mounted) {
      setState(() => _items = List.of(_items)..removeAt(index));
      _start();
    }
  }

  Future<void> _edit() async {
    var draft = List.of(_items);
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '항목 편집',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    PresetButtons(
                      current: () => fillBlanks(draft, '항목'),
                      onLoad: (items) => setSheet(() => draft = items),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ItemListEditor(
                  items: draft,
                  onChanged: (items) => draft = items,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (done == true && mounted) {
      setState(() => _items = fillBlanks(draft, '항목'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('룰렛'),
        actions: [
          IconButton(
            tooltip: '항목 편집',
            onPressed: _spinning ? null : _edit,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) => CustomPaint(
                              size: Size.infinite,
                              painter: WheelPainter(
                                _items,
                                rotation: _spin?.value ?? _rotation,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _spinning ? null : _start,
                  child: const Text('돌리기', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 0번 칸이 12시 방향에서 시계 방향으로 시작하는 원판을 [rotation]만큼 돌려 그린다.
/// 칸은 함께 돌지만 글자는 어느 위치에서든 똑바로 서 있도록 가로로 그린다.
class WheelPainter extends CustomPainter {
  WheelPainter(this.items, {this.rotation = 0});

  final List<String> items;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final seg = 2 * pi / items.length;
    final fontSize = items.length > 10 ? 12.0 : 16.0;
    final labelRadius = radius * 0.62;
    // 칸 안에 들어가는 가로 폭 (칸이 좁을수록 줄어듦).
    final labelWidth = items.length < 3
        ? radius * 0.6
        : min(radius * 0.6, 2.2 * labelRadius * sin(seg / 2));

    for (var i = 0; i < items.length; i++) {
      final start = -pi / 2 + rotation + i * seg;
      canvas.drawArc(rect, start, seg, true, Paint()..color = paletteAt(i));
      canvas.drawArc(
        rect,
        start,
        seg,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final label = TextPainter(
        text: TextSpan(
          text: items[i],
          style: TextStyle(
            color: Colors.black87,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: labelWidth);

      final mid = start + seg / 2;
      final at = center + Offset(cos(mid), sin(mid)) * labelRadius;
      label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
    }
    canvas.drawCircle(center, radius * 0.08, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(WheelPainter old) =>
      old.items != items || old.rotation != rotation;
}
