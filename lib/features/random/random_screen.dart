import 'package:flutter/material.dart';

import '../placeholder.dart';

class RandomScreen extends StatelessWidget {
  const RandomScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ComingSoon(title: '랜덤', items: ['룰렛', '사다리타기']);
}
