import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../daily/daily_screen.dart';

/// 홈: 오늘의 뽑기를 가장 크게, 그 아래 타로·로또·랜덤 바로가기.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// 하단 탭 인덱스로 이동 (1 타로, 2 로또, 3 랜덤).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 뽑기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DailyHero(
            today: DateTime.now(),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DailyScreen())),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MenuTile(
                  title: '타로',
                  icon: Icons.style,
                  onTap: () => onOpenTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuTile(
                  title: '로또',
                  icon: Icons.casino,
                  onTap: () => onOpenTab(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuTile(
                  title: '랜덤',
                  icon: Icons.shuffle,
                  onTap: () => onOpenTab(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 오늘의 뽑기 큰 칸: 날짜, 안내 문구, 금색 버튼, 둥둥 떠 있는 뒤집힌 카드.
class _DailyHero extends StatefulWidget {
  const _DailyHero({required this.today, required this.onTap});

  final DateTime today;
  final VoidCallback onTap;

  @override
  State<_DailyHero> createState() => _DailyHeroState();
}

class _DailyHeroState extends State<_DailyHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
    // '애니메이션 줄이기' 설정에서 20배 빨라지지 않게 정해진 속도로 재생한다.
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 화면이 위에 덮여 있으면 멈춘다.
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (current && !_float.isAnimating) {
      _float.repeat();
    } else if (!current && _float.isAnimating) {
      _float.stop();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.today;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Ink(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF221A6E), Color(0xFF3A2DA6)],
            ),
          ),
          child: AnimatedBuilder(
            animation: _float,
            builder: (context, _) {
              final t = _float.value * 2 * pi;
              return Stack(
                children: [
                  _Twinkle(left: 150, top: 20, size: 12, phase: t),
                  _Twinkle(right: 24, bottom: 24, size: 10, phase: t + 2),
                  _Twinkle(left: 196, bottom: 34, size: 7, phase: t + 4),
                  Positioned(
                    right: 22,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, sin(t) * 6),
                        child: Transform.rotate(
                          angle: sin(t + 1) * 0.05,
                          child: const _CardStack(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d.month}월 ${d.day}일 ${_weekdays[d.weekday - 1]}요일',
                          style: text.bodySmall?.copyWith(
                            color: const Color(0xFFF6E2B3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '오늘의 뽑기',
                          style: text.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '오늘의 한마디가\n기다리고 있어요',
                          style: text.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.point,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '뽑으러 가기 ›',
                            style: text.labelLarge?.copyWith(
                              color: const Color(0xFF2A1E00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 뒤집힌 카드 두 장. 앞 카드에 물음표.
class _CardStack extends StatelessWidget {
  const _CardStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 6,
            child: Transform.rotate(
              angle: 0.17,
              child: _card(const [
                Color(0xFFE9E6FA),
                Color(0xFFC5C0EF),
              ], opacity: 0.55),
            ),
          ),
          Positioned(
            left: 4,
            top: 7,
            child: Transform.rotate(
              angle: -0.1,
              child: _card(
                const [Colors.white, Color(0xFFE9E6FA)],
                shadow: true,
                child: Text(
                  '?',
                  style: TextStyle(
                    fontFamily: AppFonts.heading,
                    fontSize: 40,
                    color: AppColors.main,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    List<Color> colors, {
    double opacity = 1,
    bool shadow = false,
    Widget? child,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 92,
        height: 136,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// 천천히 밝아졌다 어두워지는 별.
class _Twinkle extends StatelessWidget {
  const _Twinkle({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.size,
    required this.phase,
  });

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Opacity(
        opacity: 0.35 + 0.65 * (0.5 + 0.5 * sin(phase)),
        child: Icon(
          Icons.auto_awesome,
          size: size * 1.6,
          color: const Color(0xFFF6E2B3),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: const Color(0xFFD3CEF4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
