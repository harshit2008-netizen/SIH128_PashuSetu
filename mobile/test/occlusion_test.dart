// Occlusion heatmap helpers (P2): covering a cell, and turning drops into 0..1.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/features/triage/engine/image_classifier.dart';

void main() {
  test('occlude greys exactly one cell and leaves the original untouched', () {
    const size = 12, grid = 6; // 2x2-pixel cells
    final input = Float32List(size * size * 3)..fillRange(0, size * size * 3, 10);
    final covered = occlude(input, size, grid, 1, 2); // rows 2-3, columns 4-5
    int index(int y, int x) => (y * size + x) * 3;
    expect(covered[index(2, 4)], 127.5);
    expect(covered[index(3, 5) + 2], 127.5);
    expect(covered[index(2, 6)], 10); // next cell
    expect(covered[index(1, 4)], 10); // row above
    expect(input[index(2, 4)], 10);
    expect(covered.where((v) => v == 127.5).length, 2 * 2 * 3);
  });

  test('drops are scaled to the biggest; a rise counts as zero', () {
    expect(normaliseDrops([0.4, 0.1, -0.2, 0.0]), [1.0, 0.25, 0.0, 0.0]);
    expect(normaliseDrops([-0.1, 0.0]), [0.0, 0.0]);
  });
}
