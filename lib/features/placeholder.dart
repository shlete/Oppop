import 'package:flutter/material.dart';

/// 아직 구현 전인 화면용 자리 표시.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in items)
            Card(
              child: ListTile(title: Text(item), trailing: const Text('준비 중')),
            ),
        ],
      ),
    );
  }
}
