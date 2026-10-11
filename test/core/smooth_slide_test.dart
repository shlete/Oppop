import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneul_ppopgi/core/widgets/smooth_slide.dart';

void main() {
  testWidgets('애니메이션 줄이기를 켜도 정해진 시간 동안 미끄러진다', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    Widget slide(Offset o) => MaterialApp(
      home: SmoothSlide(offset: o, child: const SizedBox(width: 10)),
    );
    double now() => tester
        .widget<FractionalTranslation>(
          find.descendant(
            of: find.byType(SmoothSlide),
            matching: find.byType(FractionalTranslation),
          ),
        )
        .translation
        .dx;

    await tester.pumpWidget(slide(Offset.zero));
    await tester.pumpWidget(slide(const Offset(1, 0)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(now(), greaterThan(0.1));
    expect(now(), lessThan(0.9));
    await tester.pumpAndSettle();
    expect(now(), 1);
  });
}
