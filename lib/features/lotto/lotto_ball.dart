import 'package:flutter/material.dart';

import 'lotto_logic.dart';

class LottoBall extends StatelessWidget {
  const LottoBall(this.number, {super.key, this.size = 40});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = lottoBallColor(number);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.45)!, color],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 3,
            offset: Offset(0, 1),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
          shadows: const [Shadow(blurRadius: 2, color: Color(0x66000000))],
        ),
      ),
    );
  }
}
