import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oneul_ppopgi/features/tarot/ai_reading.dart';
import 'package:oneul_ppopgi/features/tarot/tarot_cards.dart';
import 'package:oneul_ppopgi/features/tarot/tarot_logic.dart';
import 'package:oneul_ppopgi/features/tarot/tarot_state.dart';

const _cards = [
  DrawnCard('major-00', reversed: false),
  DrawnCard('major-01', reversed: true),
  DrawnCard('major-02', reversed: false),
];

const _good = {
  'flow': '흐름',
  'positions': ['과거 글', '현재 글', '미래 글'],
  'advice': '조언',
  'code': 'A3F9K2',
};

AiReadingClient _client(int status, Object body, {List<Object?>? sent}) =>
    AiReadingClient(
      endpoint: 'https://example.test/reading',
      client: MockClient((req) async {
        sent?.add(jsonDecode(req.body));
        return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
      }),
    );

void main() {
  test('주소가 없으면 부르지 않고 null', () async {
    expect(
      await const AiReadingClient(endpoint: '').fetch(TarotTopic.love, _cards),
      isNull,
    );
  });

  test('주제와 카드를 보내고 점괘를 받는다', () async {
    final sent = <Object?>[];
    final ai = await _client(
      200,
      _good,
      sent: sent,
    ).fetch(TarotTopic.money, _cards);
    expect(ai!.positions, ['과거 글', '현재 글', '미래 글']);
    expect(sent.single, {
      'topic': 'money',
      'cards': [
        {'id': 'major-00', 'reversed': false},
        {'id': 'major-01', 'reversed': true},
        {'id': 'major-02', 'reversed': false},
      ],
    });
  });

  test('실패하거나 모양이 틀리면 null', () async {
    expect(await _client(500, _good).fetch(TarotTopic.love, _cards), isNull);
    expect(
      await _client(200, {
        'flow': '흐름',
        'positions': ['하나'],
        'advice': '',
      }).fetch(TarotTopic.love, _cards),
      isNull,
    );
  });

  test('저장한 결과에 AI 점괘가 남는다', () {
    final r = SavedReading(
      id: 'x',
      cards: _cards,
      savedAt: DateTime(2026, 10, 11),
      topic: TarotTopic.love,
      ai: AiReading.tryParse(_good),
    );
    final back = SavedReading.fromJson(
      jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
    );
    expect(back.ai!.advice, '조언');
    expect(back.ai!.positions[2], '미래 글');
    expect(back.ai!.code, 'A3F9K2');
  });
}
