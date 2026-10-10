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
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      // 0이면 오므린 상태, 1이면 다 펼친 상태.
                      child: _CardFan(open: 0.5 - 0.5 * cos(t)),
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

/// 뒤집힌 카드 두 장이 부채처럼 펼쳐졌다 오므려진다. 앞 카드에 물음표.
class _CardFan extends StatelessWidget {
  const _CardFan({required this.open});

  final double open;

  static const _w = 84.0;
  static const _h = 122.0;

  @override
  Widget build(BuildContext context) {
    // 두 장이 서로 반대쪽으로 벌어졌다 모인다.
    final angle = 0.04 + 0.2 * open;
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _fanned(angle, const [Color(0xFFD9D4F6), Color(0xFFB9B2EC)]),
          _fanned(
            -angle,
            const [Colors.white, Color(0xFFE9E6FA)],
            child: Text(
              '?',
              style: TextStyle(
                fontFamily: AppFonts.heading,
                fontSize: 38,
                color: AppColors.main,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 카드 아래쪽 바깥의 한 점을 축으로 돌려서 부채꼴로 벌어지게 한다.
  Widget _fanned(double angle, List<Color> colors, {Widget? child}) {
    return Transform.rotate(
      angle: angle,
      alignment: const Alignment(0, 1.8),
      child: Container(
        width: _w,
        height: _h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
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
