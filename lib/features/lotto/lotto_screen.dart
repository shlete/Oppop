import 'package:flutter/material.dart';

import '../placeholder.dart';

class LottoScreen extends StatelessWidget {
  const LottoScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ComingSoon(title: '로또', items: ['번호 뽑기', '저장한 번호']);
}
