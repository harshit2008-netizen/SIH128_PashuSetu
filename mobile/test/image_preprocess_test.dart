// The phone must feed the LSD model what train.py fed it (spec 10.6).
// ml/src/verify_tflite.py saved, for each fixture photo, TensorFlow's decoded
// pixels (.decoded.png) and its 224x224 model input (.tensor.png).
//  1. Resize: from the same decoded pixels, Dart must match TensorFlow to
//     within the 0.5 rounding of the saved PNG. This proves the crop and
//     bilinear maths are identical.
//  2. Whole path: from the JPEG, through the engine's decoder. Two JPEG
//     decoders differ by about a grey level, so the check is on the average.
// The on-phone test (integration_test/parity_test.dart) then checks the model's
// probabilities within 0.02 of Python's.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pashusetu/features/triage/engine/image_classifier.dart';

Uint8List rgbOf(String path) =>
    img.decodePng(File('test/fixtures/$path').readAsBytesSync())!.getBytes(order: img.ChannelOrder.rgb);

({double mean, double max}) difference(Float32List actual, Uint8List expected) {
  var sum = 0.0, max = 0.0;
  for (var i = 0; i < actual.length; i++) {
    final d = (actual[i] - expected[i]).abs();
    sum += d;
    if (d > max) max = d;
  }
  return (mean: sum / actual.length, max: max);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final document = jsonDecode(File('test/fixtures/parity_fixtures.json').readAsStringSync()) as Map<String, dynamic>;
  final fixtures = (document['fixtures'] as List).cast<Map<String, dynamic>>();

  for (final fixture in fixtures) {
    final name = '${fixture['file']} (${fixture['width']}x${fixture['height']})';
    final expected = rgbOf(fixture['tensor_png'] as String);

    test('$name: crop and resize match TensorFlow exactly', () {
      final decoded = rgbOf(fixture['decoded_png'] as String);
      final width = fixture['width'] as int, height = fixture['height'] as int;
      final side = width < height ? width : height;
      final input = resizeBilinear(decoded, width, 3, (width - side) ~/ 2, (height - side) ~/ 2, side, 224);
      final diff = difference(input, expected);
      expect(diff.max, lessThanOrEqualTo(0.501), reason: 'max |dart - tensorflow| = ${diff.max}');
    });

    testWidgets('$name: whole path from the JPEG stays close', (tester) async {
      final input = await tester.runAsync(
          () => preprocessForModel(File('test/fixtures/${fixture['file']}').readAsBytesSync()));
      expect(input!.length, 224 * 224 * 3);
      final diff = difference(input, expected);
      expect(diff.mean, lessThan(1.5), reason: 'mean |dart - tensorflow| = ${diff.mean}');
    });
  }

  testWidgets('a file that is not a photo is rejected with a clear error', (tester) async {
    await tester.runAsync(() async {
      await expectLater(preprocessForModel(utf8.encode('not a photo')), throwsFormatException);
    });
  });
}
