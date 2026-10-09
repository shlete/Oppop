import 'package:flutter/material.dart';

import '../placeholder.dart';

class TarotScreen extends StatelessWidget {
  const TarotScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ComingSoon(title: '타로', items: ['오늘의 운세 (1장)', '고민상담 (3장)']);
}
