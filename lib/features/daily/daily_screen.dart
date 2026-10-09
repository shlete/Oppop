import 'package:flutter/material.dart';

import '../placeholder.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ComingSoon(title: '오늘의 뽑기', items: ['좋은 글귀', '응원 한마디', '오늘 주의할 점']);
}
