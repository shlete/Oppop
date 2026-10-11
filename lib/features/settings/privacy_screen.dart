import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 설정 > 개인정보처리방침. 본문은 assets/legal/privacy_ko.md 하나에서만 고친다.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  static const asset = 'assets/legal/privacy_ko.md';

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final Future<String> _body = rootBundle.loadString(PrivacyScreen.asset);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보처리방침')),
      body: FutureBuilder<String>(
        future: _body,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              for (final line in snap.data!.split('\n')) _line(context, line),
            ],
          );
        },
      ),
    );
  }

  /// 마크다운 중 쓰는 것만 그린다: 제목(#, ##), 목록(-), 문단.
  Widget _line(BuildContext context, String line) {
    final text = Theme.of(context).textTheme;
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(line.substring(2), style: text.titleLarge),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(line.substring(3), style: text.titleSmall),
      );
    }
    final indent = line.length - line.trimLeft().length;
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('- ')) {
      return Padding(
        padding: EdgeInsets.only(left: 4.0 + indent * 6, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('·  ', style: text.bodyMedium),
            Expanded(child: Text(trimmed.substring(2), style: text.bodyMedium)),
          ],
        ),
      );
    }
    if (trimmed.isEmpty) return const SizedBox(height: 6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(trimmed, style: text.bodyMedium),
    );
  }
}
