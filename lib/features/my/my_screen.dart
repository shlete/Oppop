import 'package:flutter/material.dart';

import '../placeholder.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ComingSoon(title: '마이', items: ['히스토리', '설정', '문의하기']);
}
