import 'package:flutter/material.dart';

import 'phrases.dart';

/// 카테고리마다 다른 은은한 배경 색.
List<Color> phraseCardColors(PhraseCategory c) => switch (c) {
  PhraseCategory.quote => const [Color(0xFFEDE7FF), Color(0xFFD9CCFF)],
  PhraseCategory.cheer => const [Color(0xFFFFF1DC), Color(0xFFFFD9B8)],
  PhraseCategory.caution => const [Color(0xFFDDF3F0), Color(0xFFBFE3F2)],
};

/// 문구 결과 카드. 캡처해서 공유하기 좋게 글자는 가운데, 아래에 날짜와 앱 이름.
class PhraseCard extends StatelessWidget {
  const PhraseCard({
    super.key,
    required this.category,
    required this.text,
    required this.date,
  });

  final PhraseCategory category;

  /// null이면 뽑기 전 안내 문구를 보여준다.
  final String? text;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    const ink = Color(0xFF2E2648);
    final colors = phraseCardColors(category);
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          children: [
            Text(
              category.label,
              style: theme.labelLarge?.copyWith(
                color: ink.withValues(alpha: 0.7),
                letterSpacing: 1,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  text ?? '뽑기 버튼을 누르면\n오늘의 문구가 나와요',
                  textAlign: TextAlign.center,
                  style: (text == null ? theme.bodyLarge : theme.titleLarge)
                      ?.copyWith(
                        color: text == null ? ink.withValues(alpha: 0.5) : ink,
                        height: 1.6,
                        fontWeight: text == null ? null : FontWeight.w600,
                      ),
                ),
              ),
            ),
            Text(
              '${date.year}.${date.month}.${date.day} · 오늘의 뽑기',
              style: theme.bodySmall?.copyWith(
                color: ink.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
