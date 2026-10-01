// On-phone parity test for the LSD photo model (spec 10.6).
// Runs the real TFLite model through the app's own preprocessing on the
// fixture photos and checks every probability is within 0.02 of what the
// TensorFlow reference pipeline gave (ml/src/verify_tflite.py).
//
// Run with the phone connected:
//   flutter test integration_test/parity_test.dart -d <device id>
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pashusetu/features/triage/engine/image_classifier.dart';

import 'parity_fixtures.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone model matches the Python reference within 0.02', (tester) async {
    final classifier = await LsdImageClassifier.load(rootBundle);
    expect(classifier.labels, ['healthy', 'lsd']);
    final timings = <int>[];
    for (final fixture in parityFixtures) {
      final watch = Stopwatch()..start();
      final probs = await classifier.classify(base64Decode(fixture.base64));
      timings.add(watch.elapsedMilliseconds);
      // Printed so the run log shows the actual numbers, not just pass/fail.
      debugPrint('${fixture.name}: lsd ${probs['lsd']!.toStringAsFixed(4)} '
          '(python ${fixture.lsd.toStringAsFixed(4)}), ${timings.last} ms');
      expect(probs['lsd']!, closeTo(fixture.lsd, 0.02), reason: fixture.name);
      expect(probs['healthy']!, closeTo(fixture.healthy, 0.02), reason: fixture.name);
    }
    debugPrint('timings ms: $timings');
  });

  testWidgets('which-part heatmap runs on the phone: 36 cells, 0..1', (tester) async {
    final classifier = await LsdImageClassifier.load(rootBundle);
    final lsd = parityFixtures.firstWhere((f) => f.lsd > 0.9);
    final watch = Stopwatch()..start();
    final cells = await classifier.occlusionMap(base64Decode(lsd.base64));
    debugPrint('heatmap for ${lsd.name}: ${watch.elapsedMilliseconds} ms, cells $cells');
    expect(cells.length, 36);
    expect(cells.every((c) => c >= 0 && c <= 1), isTrue);
    expect(cells.reduce((a, b) => a > b ? a : b), 1.0); // at least one cell mattered
  });
}
