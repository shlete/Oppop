# 타로 통합 점괘 서버 (Firebase Functions)

앱이 주제와 카드 3장(id, 역방향 여부)을 보내면 Claude Haiku 5.5가 통합 점괘를 써서 돌려준다.
카드 뜻은 `assets/tarot/cards.json`을 빌드 때 복사해 서버가 직접 읽는다.
서버가 없거나 실패하면 앱은 미리 써 둔 점괘를 그대로 보여준다.

## 처음 한 번

1. Firebase 콘솔에서 프로젝트를 만들고 요금제를 Blaze로 바꾼다. 예산 알림을 꼭 걸어 둔다.
2. Anthropic Console(platform.claude.com)에서 API 키를 만들고 크레딧을 충전한다.
3. 컴퓨터에서:

```sh
npm install -g firebase-tools
firebase login
firebase use --add            # 만든 프로젝트 고르기
cd functions && npm install && cd ..
firebase functions:secrets:set ANTHROPIC_API_KEY   # 키 붙여넣기
firebase deploy --only functions
```

배포가 끝나면 `tarotReading` 함수 주소가 나온다.

## 앱에 연결

```sh
flutter run --dart-define=AI_READING_URL=<함수 주소>
flutter build appbundle --dart-define=AI_READING_URL=<함수 주소>
```

## 나중에 할 일

- 출시 전에 App Check를 붙여서 우리 앱만 부를 수 있게 한다.
- `package.json`의 버전이 `latest`라서 첫 `npm install` 뒤 생기는 `package-lock.json`을 커밋해 고정한다.
