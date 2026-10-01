// Voice parser (spec 10.5): every sample sentence in shared/voice_test_sentences.json
// must give exactly the expected signs, species and counts.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/shared_data/shared_data.dart';
import 'package:pashusetu/features/report/voice/lexicon_parser.dart';

Future<String> readSharedFile(String path) => File('assets/shared/$path').readAsString();

Future<void> main() async {
  final data = await SharedData.load(readSharedFile);
  final sentences = jsonDecode(await readSharedFile('voice_test_sentences.json')) as Map<String, dynamic>;

  for (final language in ['hi', 'mr', 'en']) {
    final parser = LexiconParser(data.lexicon, language);
    final cases = (sentences[language] as List).cast<Map<String, dynamic>>();

    group('$language sentences', () {
      test('at least 10 samples', () => expect(cases.length, greaterThanOrEqualTo(10)));

      for (final sample in cases) {
        test(sample['text'] as String, () {
          final expected = sample['expect'] as Map<String, dynamic>;
          final heard = parser.parse(sample['text'] as String);
          expect(heard.symptoms.toSet(), Set<String>.from(expected['symptoms'] as List), reason: 'signs');
          expect(heard.species, expected['species'], reason: 'species');
          expect(heard.sick, expected['sick'], reason: 'sick');
          expect(heard.dead, expected['dead'], reason: 'dead');
          expect(heard.total, expected['total'], reason: 'total');
        });
      }
    });
  }

  test('expected ids exist in the shared symptom and species lists', () {
    for (final language in ['hi', 'mr', 'en']) {
      for (final sample in (sentences[language] as List).cast<Map<String, dynamic>>()) {
        final expected = sample['expect'] as Map<String, dynamic>;
        for (final id in expected['symptoms'] as List) {
          expect(data.symptoms, contains(id));
        }
        if (expected['species'] != null) expect(data.species, contains(expected['species']));
      }
    }
  });

  test('normalising unifies spellings the recogniser mixes up', () {
    expect(normaliseSpeech('गाँठ'), normaliseSpeech('गांठ'));
    expect(normaliseSpeech('बुख़ार!'), 'बुखार');
    expect(normaliseSpeech('२ गाय'), '2 गाय');
  });

  test('a sign said as absent is not heard', () {
    final parser = LexiconParser(data.lexicon, 'hi');
    expect(parser.parse('बुखार नहीं है').symptoms, isEmpty);
    expect(parser.parse('चारा नहीं खा रही').symptoms, ['anorexia']);
  });
}
