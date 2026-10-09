import 'package:flutter/material.dart';

/// 룰렛 칸·사다리 경로에 돌려 쓰는 색.
const randomPalette = [
  Color(0xFFFF8A80),
  Color(0xFFFFD180),
  Color(0xFFA5D6A7),
  Color(0xFF80D8FF),
  Color(0xFFB39DDB),
  Color(0xFFF48FB1),
  Color(0xFFFFF59D),
  Color(0xFF80CBC4),
];

Color paletteAt(int i) => randomPalette[i % randomPalette.length];
