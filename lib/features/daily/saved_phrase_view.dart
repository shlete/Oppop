import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/image_save/image_save.dart';
import 'daily_state.dart';
import 'phrase_card.dart';

/// 저장한 문구를 카드로 크게 보여준다. 카드를 꾹 누르면 이미지로 저장.
class SavedPhraseView extends StatefulWidget {
  const SavedPhraseView({super.key, required this.phrase});

  final SavedPhrase phrase;

  @override
  State<SavedPhraseView> createState() => _SavedPhraseViewState();
}

class _SavedPhraseViewState extends State<SavedPhraseView> {
  final _cardKey = GlobalKey();
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await captureBoundary(_cardKey);
    final result = bytes == null
        ? ImageSaveResult.failed
        : await savePng(
            bytes,
            name: 'oneul-ppopgi-${DateTime.now().millisecondsSinceEpoch}',
          );
    _saving = false;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            ImageSaveResult.saved => '이미지를 저장했어요',
            ImageSaveResult.denied => '사진 저장 권한을 허용하면 저장할 수 있어요',
            ImageSaveResult.failed => '이미지를 저장하지 못했어요',
          }),
        ),
      );
  }

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
                onLongPress: _save,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: PhraseCard(
                    category: phrase.category,
                    text: phrase.text,
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
