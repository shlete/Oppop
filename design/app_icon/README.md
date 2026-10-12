# 앱 아이콘

- `icon.svg`: 전체 아이콘 (iOS, 웹, 안드로이드 예전 기기용). `icon-1024.png`는 그 1024px 그림.
- `foreground.svg`: 안드로이드 적응형 아이콘 전경 (배경 없이, 마스크 안쪽에 맞게 66%로 줄임). 배경은 `icon.svg`의 남색 그라디언트.
- "?"는 IBM Plex Sans KR Bold(`assets/fonts/ibmplexsanskr`, SIL OFL 1.1) 글꼴로 그린다. SVG를 열 때 이 글꼴이 깔려 있어야 같은 모양이 나온다.
- 안드로이드 `mipmap-*`, iOS `AppIcon.appiconset`, 웹 `web/icons`·`favicon.png`의 PNG는 이 SVG에서 크기별로 뽑았다.
