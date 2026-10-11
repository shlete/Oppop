import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/firebase/app_check.dart';

import 'tarot_cards.dart';
import 'tarot_logic.dart';

/// AI가 쓴 고민상담 통합 점괘. 저장할 때 같이 남겨서 다시 만들지 않는다.
class AiReading {
  const AiReading({
    required this.flow,
    required this.positions,
    required this.advice,
    this.code,
  });

  /// 세 장을 잇는 한 줄 요약.
  final String flow;

  /// 과거·현재·미래 순 자리별 해석.
  final List<String> positions;

  /// 마무리 조언.
  final String advice;

  /// 점괘 번호. 문의할 때 이 번호로 서버 기록을 찾는다.
  final String? code;

  Map<String, Object> toJson() => {
    'flow': flow,
    'positions': positions,
    'advice': advice,
    'code': ?code,
  };

  /// 모양이 맞지 않으면 null.
  static AiReading? tryParse(Object? json) {
    if (json is! Map) return null;
    final flow = json['flow'];
    final positions = json['positions'];
    final advice = json['advice'];
    if (flow is! String || advice is! String || positions is! List) {
      return null;
    }
    if (positions.length != SpreadPosition.values.length ||
        positions.any((p) => p is! String || p.trim().isEmpty)) {
      return null;
    }
    return AiReading(
      flow: flow,
      positions: positions.cast<String>(),
      advice: advice,
      code: json['code'] is String ? json['code'] as String : null,
    );
  }
}

/// 통합 점괘 서버 (functions/의 tarotReading). 빌드할 때
/// `--dart-define=AI_READING_URL=...`로 바꾸거나 빈 값으로 끌 수 있다.
/// 실패하면 null을 돌려주고, 화면은 미리 써 둔 점괘를 보여준다.
class AiReadingClient {
  const AiReadingClient({
    this.client,
    this.endpoint = url,
    this.appCheckToken = AppCheck.token,
  });

  static const url = String.fromEnvironment(
    'AI_READING_URL',
    defaultValue:
        'https://asia-northeast3-oppop-34243.cloudfunctions.net/tarotReading',
  );
  static const timeout = Duration(seconds: 12);

  /// 테스트에서 바꿔 끼우는 HTTP 클라이언트.
  final http.Client? client;
  final String endpoint;

  /// 서버가 우리 앱인지 확인하는 App Check 토큰.
  final Future<String?> Function() appCheckToken;

  static bool get enabled => url.isNotEmpty;

  Future<AiReading?> fetch(TarotTopic topic, List<DrawnCard> cards) async {
    if (endpoint.isEmpty) return null;
    final c = client ?? http.Client();
    try {
      final token = await appCheckToken();
      final res = await c
          .post(
            Uri.parse(endpoint),
            headers: {
              'content-type': 'application/json',
              'x-firebase-appcheck': ?token,
            },
            body: jsonEncode({
              'topic': topic.name,
              'cards': [for (final c in cards) c.toJson()],
            }),
          )
          .timeout(timeout);
      if (res.statusCode != 200) return null;
      return AiReading.tryParse(jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
