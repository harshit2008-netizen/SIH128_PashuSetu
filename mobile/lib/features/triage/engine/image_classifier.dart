import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// On-device LSD photo model (spec 10.6). Loads the TFLite file once and
/// returns label probabilities for a photo.
///
/// Preprocessing must match ml/kaggle/lsd_image_classifier/train.py exactly
/// (the model card says what): central square crop, bilinear resize to
/// 224x224 with half-pixel centres (tf.image.resize), RGB float32 in 0-255.
/// Scaling to the network's range happens inside the model.
class LsdImageClassifier {
  LsdImageClassifier._(this._interpreter, this.labels, this.card, this.inputSize);

  static const modelAsset = 'assets/models/lsd_classifier.tflite';
  static const labelsAsset = 'assets/models/lsd_labels.txt';
  static const cardAsset = 'assets/models/lsd_model_card.json';

  final Interpreter _interpreter;
  final List<String> labels;
  final Map<String, dynamic> card;
  final int inputSize;

  String get modelVersion => card['model_version'] as String;

  static Future<LsdImageClassifier> load(AssetBundle bundle) async {
    final card = jsonDecode(await bundle.loadString(cardAsset)) as Map<String, dynamic>;
    final labels = const LineSplitter()
        .convert(await bundle.loadString(labelsAsset))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final model = await bundle.load(modelAsset);
    final interpreter = Interpreter.fromBuffer(model.buffer.asUint8List(model.offsetInBytes, model.lengthInBytes),
        options: InterpreterOptions()..threads = 2);
    final shape = (card['input'] as Map<String, dynamic>)['shape'] as List;
    return LsdImageClassifier._(interpreter, labels, card, shape[1] as int);
  }

  /// Label -> probability for one photo file's bytes.
  Future<Map<String, double>> classify(Uint8List photoBytes) async {
    final input = await preprocessForModel(photoBytes, size: inputSize);
    final output = Float32List(labels.length);
    _interpreter.run(input.buffer.asUint8List(), output.buffer.asUint8List());
    return {for (var i = 0; i < labels.length; i++) labels[i]: output[i].toDouble()};
  }
}

/// Photo bytes -> model input: [size * size * 3] float32, RGB, 0-255.
///
/// Decoding uses the engine's image decoder (libjpeg-turbo, like TensorFlow's
/// decode_image), so pixels match training closely, it is fast, and the model
/// sees exactly the picture the preview shows. The resize runs in a background
/// isolate so the screen never stutters.
Future<Float32List> preprocessForModel(Uint8List photoBytes, {int size = 224}) async {
  final ({Uint8List rgba, int width, int height}) decoded;
  try {
    decoded = await decodeRgba(photoBytes);
  } on Exception {
    throw const FormatException('Not an image the phone can read');
  }
  final rgba = decoded.rgba, width = decoded.width, height = decoded.height;
  // Central square, same integer maths as train.py's center_square.
  final side = width < height ? width : height;
  final top = (height - side) ~/ 2, left = (width - side) ~/ 2;
  return Isolate.run(() => resizeBilinear(rgba, width, 4, left, top, side, size));
}

Future<({Uint8List rgba, int width, int height})> decodeRgba(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  final result = (rgba: data!.buffer.asUint8List(), width: image.width, height: image.height);
  image.dispose();
  codec.dispose();
  return result;
}

/// tf.image.resize(method=bilinear, antialias=False) on the square
/// [left, top, side x side] of an image with `channels` bytes per pixel
/// (RGB or RGBA) and `stride` pixels per row. Returns RGB float32.
/// TF2 uses half-pixel centres: source = (out + 0.5) * scale - 0.5.
Float32List resizeBilinear(Uint8List pixels, int stride, int channels, int left, int top, int side, int size) {
  final out = Float32List(size * size * 3);
  final scale = side / size;
  // The two source columns and the weight for every output column.
  final x0s = Int32List(size), x1s = Int32List(size), xws = Float64List(size);
  for (var x = 0; x < size; x++) {
    final source = (x + 0.5) * scale - 0.5;
    final floor = source.floor();
    x0s[x] = floor.clamp(0, side - 1);
    x1s[x] = source.ceil().clamp(0, side - 1);
    xws[x] = source - floor;
  }
  var o = 0;
  for (var y = 0; y < size; y++) {
    final source = (y + 0.5) * scale - 0.5;
    final floor = source.floor();
    final y0 = floor.clamp(0, side - 1), y1 = source.ceil().clamp(0, side - 1);
    final yw = source - floor;
    // Byte offsets of the two source rows.
    final row0 = (top + y0) * stride * channels, row1 = (top + y1) * stride * channels;
    for (var x = 0; x < size; x++) {
      final c0 = (left + x0s[x]) * channels, c1 = (left + x1s[x]) * channels;
      final xw = xws[x];
      for (var ch = 0; ch < 3; ch++) {
        final upper = pixels[row0 + c0 + ch] + (pixels[row0 + c1 + ch] - pixels[row0 + c0 + ch]) * xw;
        final lower = pixels[row1 + c0 + ch] + (pixels[row1 + c1 + ch] - pixels[row1 + c0 + ch]) * xw;
        out[o++] = upper + (lower - upper) * yw;
      }
    }
  }
  return out;
}
