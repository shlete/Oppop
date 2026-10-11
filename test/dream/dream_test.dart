import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oneul_ppopgi/features/dream/dream_ai.dart';
import 'package:oneul_ppopgi/features/dream/dream_book.dart';
import 'package:oneul_ppopgi/features/dream/dream_result_screen.dart';
import 'package:oneul_ppopgi/features/dream/dream_screen.dart';
import 'package:oneul_ppopgi/features/dream/dream_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

DreamBook _book() => DreamBook.fromJson(
  jsonDecode(File('assets/dream/symbols.json').readAsStringSync()) as List,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('키워드는 id가 겹치지 않고 모두 해몽 글이 있다', () {
    final book = _book();
    expect(book.symbols.length, greaterThanOrEqualTo(70));
    expect(book.symbols.map((s) => s.id).toSet().length, book.symbols.length);
    for (final s in book.symbols) {
      expect(s.meaning.length, greaterThan(30), reason: s.id);
    }
    expect(book.groups.first, '동물');
  });

  test('키워드 기운에 따라 총평이 달라진다', () {
    final book = _book();
    final good = [book.byId('pig')!, book.byId('dragon')!];
    final care = [book.byId('teeth')!, book.byId('chased')!];
    expect(DreamBook.summary(good), contains('길몽'));
    expect(DreamBook.summary(care), isNot(DreamBook.summary(good)));
    expect(DreamBook.advice(care), contains('무리하지'));
  });

  test('키워드와 꿈 이야기를 보내고 해몽을 받는다', () async {
    final sent = <Object?>[];
    final client = DreamAiClient(
      endpoint: 'https://example.test/dream',
      appCheckToken: () async => null,
      client: MockClient((req) async {
        sent.add(jsonDecode(req.body));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({'title': '제목', 'reading': '본문', 'advice': '조언'}),
          ),
          200,
        );
      }),
    );
    final ai = await client.fetch(['pig'], '돼지가 집에 들어왔어요');
    expect(ai!.title, '제목');
    expect(sent.single, {
      'symbols': ['pig'],
      'story': '돼지가 집에 들어왔어요',
    });
  });

  test('서버가 실패하거나 모양이 다르면 null', () async {
    DreamAiClient client(int status, Object body) => DreamAiClient(
      endpoint: 'https://example.test/dream',
      appCheckToken: () async => null,
      client: MockClient((_) async => http.Response(jsonEncode(body), status)),
    );
    expect(await client(502, {'error': 'upstream'}).fetch([], '꿈'), isNull);
    expect(await client(200, {'title': 'x'}).fetch([], '꿈'), isNull);
  });

  test('저장한 꿈해몽은 AI 해몽까지 되살아난다', () {
    final dream = SavedDream(
      id: 'dream-1',
      symbolIds: const ['snake'],
      story: '큰 뱀',
      savedAt: DateTime(2026, 10, 11),
      ai: const DreamAi(title: '제목', reading: '본문', advice: '조언'),
    );
    final back = SavedDream.fromJson(
      jsonDecode(jsonEncode(dream.toJson())) as Map<String, dynamic>,
    );
    expect(back.symbolIds, ['snake']);
    expect(back.story, '큰 뱀');
    expect(back.ai!.reading, '본문');
  });

  testWidgets('키워드만 고르면 미리 써 둔 해몽이 나오고 저장된다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [dreamBookProvider.overrideWith((ref) => _book())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DreamScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('돼지'));
    await tester.pump();
    await tester.tap(find.text('해몽 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('재물과 복을 부르는'), findsOneWidget);
    expect(find.text('좋은 기운이 가득한 길몽이에요'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(container.read(savedDreamsProvider).single.symbolIds, ['pig']);
  });

  testWidgets('꿈 이야기를 적고 AI가 실패하면 고른 키워드 해몽을 보여준다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dreamBookProvider.overrideWith((ref) => _book())],
        child: MaterialApp(
          home: DreamResultScreen(
            symbolIds: const ['fly'],
            story: '하늘을 날았어요',
            client: DreamAiClient(
              endpoint: 'https://example.test/dream',
              appCheckToken: () async => null,
              client: MockClient((_) async => http.Response('', 502)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('하늘을 날았어요'), findsOneWidget);
    expect(find.textContaining('자유와 성취'), findsOneWidget);
  });
}
