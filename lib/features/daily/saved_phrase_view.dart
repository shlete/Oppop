import 'package:flutter/material.dart';

import 'daily_state.dart';
import 'phrase_card.dart';
import 'save_card_image.dart';

/// 저장한 문구를 카드로 크게 보여준다. 카드를 꾹 누르면 이미지로 저장.
class SavedPhraseView extends StatefulWidget {
  const SavedPhraseView({super.key, required this.phrase});

  final SavedPhrase phrase;

  @override
  State<SavedPhraseView> createState() => _SavedPhraseViewState();
}

class _SavedPhraseViewState extends State<SavedPhraseView> {
  final _cardKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrase;
    return Scaffold(
      appBar: AppBar(title: Text(phrase.category.label)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            children: [
              GestureDetector(
                onLongPress: () => saveCardImage(context, _cardKey),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: PhraseCard(
                    category: phrase.category,
                    text: phrase.text,
                    by: phrase.by,
                    date: phrase.savedAt,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '카드를 꾹 누르면 이미지로 저장돼요',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
