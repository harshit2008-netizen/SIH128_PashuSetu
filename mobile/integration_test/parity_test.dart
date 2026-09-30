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
}
