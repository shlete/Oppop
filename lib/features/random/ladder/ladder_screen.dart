import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../palette.dart';
import '../widgets/item_list_editor.dart';
import '../widgets/preset_buttons.dart';
import 'ladder.dart';

class LadderScreen extends StatefulWidget {
  const LadderScreen({super.key, this.random});

  /// 테스트에서 사다리 모양을 고정할 때 넘긴다.
  final Random? random;

  @override
  State<LadderScreen> createState() => _LadderScreenState();
}

class _LadderScreenState extends State<LadderScreen>
    with TickerProviderStateMixin {
  late final Random _random = widget.random ?? Random();

  /// 사다리 가로줄이 위에서부터 하나씩 그어지는 연출.
  late final AnimationController _drawing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
    animationBehavior: AnimationBehavior.preserve,
  );

  /// 참가자 경로가 아래로 채워지며 내려가는 연출.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
    // 이 애니메이션이 곧 결과 연출이라, 기기의 '애니메이션 줄이기' 설정에서도
    // 20배 빨라지지 않고 정해진 시간 그대로 재생한다.
    animationBehavior: AnimationBehavior.preserve,
  );

  List<String> _players = ['A', 'B', 'C', 'D'];
  List<String> _results = ['당첨', '꽝', '꽝', '꽝'];

  /// null이면 입력 화면, 있으면 사다리 화면.
  Ladder? _ladder;
  List<String> _shownPlayers = const [];
  List<String> _shownResults = const [];
  final Set<int> _revealed = {};

  /// 지금 경로가 그려지고 있는 참가자들.
  final Set<int> _tracing = {};

  bool get _busy => _drawing.isAnimating || _controller.isAnimating;

  @override
  void dispose() {
    _drawing.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setPlayers(List<String> players) {
    setState(() {
      _players = players;
      _results = [
        for (var i = 0; i < players.length; i++)
          i < _results.length ? _results[i] : '꽝',
      ];
    });
  }

  void _build() {
    setState(() {
      _shownPlayers = fillBlanks(_players, '참가자');
      _shownResults = [
        for (final r in _results) r.trim().isEmpty ? '꽝' : r.trim(),
      ];
      _ladder = Ladder.random(_players.length, random: _random);
      _revealed.clear();
      _tracing.clear();
    });
    _controller.stop();
    _drawing.forward(from: 0);
  }

  /// [players]의 경로를 동시에 그린 뒤 결과를 공개한다.
  Future<void> _trace(Iterable<int> players) async {
    setState(() => _tracing.addAll(players));
    await _controller.forward(from: 0);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _revealed.addAll(_tracing);
      _tracing.clear();
    });
  }

  Future<void> _reveal(int player) async {
    if (_busy || _revealed.contains(player)) return;
    await _trace([player]);
  }

  Future<void> _revealAll() async {
    if (_busy) return;
    final ladder = _ladder!;
    final rest = [
      for (var i = 0; i < ladder.columns; i++)
        if (!_revealed.contains(i)) i,
    ];
    if (rest.isNotEmpty) await _trace(rest);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 결과'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < ladder.columns; i++)
              ListTile(
                dense: true,
                leading: CircleAvatar(backgroundColor: paletteAt(i), radius: 8),
                title: Text(_shownPlayers[i]),
                trailing: Text(
                  _shownResults[ladder.destination(i)],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사다리타기')),
      body: SafeArea(child: _ladder == null ? _setup() : _play(_ladder!)),
    );
  }

  Widget _setup() {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('참가자 (2~8명)', style: text.titleMedium),
            const Spacer(),
            PresetButtons(
              current: () => fillBlanks(_players, '참가자'),
              onLoad: (items) => _setPlayers(items.take(8).toList()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ItemListEditor(
          items: _players,
          min: 2,
          max: 8,
          hint: '참가자',
          onChanged: _setPlayers,
        ),
        const SizedBox(height: 24),
        Text('결과', style: text.titleMedium),
        Text('빈칸은 "꽝"이 돼요', style: text.bodySmall),
        const SizedBox(height: 8),
        ItemListEditor(
          items: _results,
          min: _players.length,
          max: _players.length,
          hint: '결과',
          onChanged: (r) => _results = r,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _build,
            child: const Text('사다리 만들기', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _play(Ladder ladder) {
    final reached = {for (final p in _revealed) ladder.destination(p): p};
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '이름을 눌러 결과를 확인하세요',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < ladder.columns; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ActionChip(
                      label: Text(
                        _shownPlayers[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      backgroundColor: paletteAt(i),
                      onPressed: () => _reveal(i),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([_drawing, _controller]),
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: LadderPainter(
                  ladder: ladder,
                  revealed: _revealed,
                  tracing: _tracing,
                  drawProgress: _drawing.value,
                  progress: _controller.value,
                  lineColor: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var d = 0; d < ladder.columns; d++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: reached.containsKey(d)
                          ? paletteAt(reached[d]!)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reached.containsKey(d) ? _shownResults[d] : '?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _ladder = null),
                  child: const Text('편집'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _build,
                  child: const Text('다시 섞기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _revealAll,
                  child: const Text('전체 결과'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LadderPainter extends CustomPainter {
  LadderPainter({
    required this.ladder,
    required this.revealed,
    required this.tracing,
    required this.drawProgress,
    required this.progress,
    required this.lineColor,
  });

  final Ladder ladder;
  final Set<int> revealed;
  final Set<int> tracing;

  /// 가로줄이 그어진 정도 (0~1). 위쪽 줄부터 차례로 그어진다.
  final double drawProgress;

  /// [tracing] 경로가 채워진 정도 (0~1).
  final double progress;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final colWidth = size.width / ladder.columns;
    Offset toPx(Offset p) =>
        Offset((p.dx + 0.5) * colWidth, p.dy * size.height);

    final base = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var c = 0; c < ladder.columns; c++) {
      canvas.drawLine(
        toPx(Offset(c.toDouble(), 0)),
        toPx(Offset(c.toDouble(), 1)),
        base,
      );
    }
    for (var r = 0; r < ladder.rows; r++) {
      final t = (drawProgress * ladder.rows - r).clamp(0.0, 1.0);
      if (t == 0) continue;
      final y = (r + 1) / (ladder.rows + 1);
      for (final c in ladder.rungs[r]) {
        canvas.drawLine(
          toPx(Offset(c.toDouble(), y)),
          toPx(Offset(c + t, y)),
          base,
        );
      }
    }

    Path pathOf(int player) {
      final points = ladder.path(player).map(toPx).toList();
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    Color colorOf(int player) =>
        Color.lerp(paletteAt(player), Colors.black, 0.25)!;

    Paint stroke(int player) => Paint()
      ..color = colorOf(player)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final p in revealed) {
      canvas.drawPath(pathOf(p), stroke(p));
    }
    for (final p in tracing) {
      final metric = pathOf(p).computeMetrics().first;
      final length = metric.length * progress;
      canvas.drawPath(metric.extractPath(0, length), stroke(p));
      final head = metric.getTangentForOffset(length)?.position;
      if (head != null) {
        canvas.drawCircle(head, 8, Paint()..color = colorOf(p));
        canvas.drawCircle(head, 4, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(LadderPainter old) => true;
}
