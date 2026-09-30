import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/features/home/formatting.dart';

void main() {
  test('photo percent never claims certainty', () {
    expect(photoPercent(0.999), 99);
    expect(photoPercent(0.0004), 1);
    expect(photoPercent(0.845), 85);
  });
}
