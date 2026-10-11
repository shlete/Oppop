import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/firebase/app_check.dart';

/// AI가 쓴 해몽뽑기. 저장할 때 같이 남겨서 다시 만들지 않는다.
class DreamAi {
  const DreamAi({
    required this.title,
    required this.reading,
    required this.advice,
  });

  /// 꿈을 한 줄로 요약한 해몽 제목.
  final String title;

  /// 본문 해몽.
  final String reading;

  /// 오늘 해 볼 만한 한마디.
  final String advice;

  Map<String, Object> toJson() => {
    'title': title,
    'reading': reading,
    'advice': advice,
  };

  /// 모양이 맞지 않으면 null.
  static DreamAi? tryParse(Object? json) {
    if (json is! Map) return null;
    final title = json['title'];
    final reading = json['reading'];
    final advice = json['advice'];
    if (title is! String || reading is! String || advice is! String) {
      return null;
    }
    if (reading.trim().isEmpty) return null;
    return DreamAi(title: title, reading: reading, advice: advice);
  }
}

/// 해몽뽑기 서버 (functions/의 dreamReading). 빌드할 때
/// `--dart-define=DREAM_READING_URL=...`로 바꾸거나 빈 값으로 끌 수 있다.
/// 실패하면 null을 돌려주고, 화면은 키워드 해몽을 보여준다.
class DreamAiClient {
  const DreamAiClient({
    this.client,
    this.endpoint = url,
    this.appCheckToken = AppCheck.token,
  });

  static const url = String.fromEnvironment(
    'DREAM_READING_URL',
    defaultValue:
        'https://asia-northeast3-oppop-34243.cloudfunctions.net/dreamReading',
  );
  static const timeout = Duration(seconds: 15);

  /// 꿈 이야기 글자 수 제한. 서버도 같은 값으로 자른다.
  static const maxLength = 300;

  final http.Client? client;
  final String endpoint;
  final Future<String?> Function() appCheckToken;

  static bool get enabled => url.isNotEmpty;

  Future<DreamAi?> fetch(List<String> symbolIds, String story) async {
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
            body: jsonEncode({'symbols': symbolIds, 'story': story}),
          )
          .timeout(timeout);
      if (res.statusCode != 200) return null;
      return DreamAi.tryParse(jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
