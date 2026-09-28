// Golden triage vectors (spec 7.8). The Python engine runs the same file,
// so passing here proves the phone and the server triage identically.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/shared_data/shared_data.dart';
import 'package:pashusetu/features/triage/engine/rule_engine.dart';

/// Tests read the bundled copy made by `make sync-shared`.
Future<String> readSharedFile(String path) => File('assets/shared/$path').readAsString();

TriageInput toInput(Map<String, dynamic> raw) => TriageInput(
      species: raw['species'] as String,
      symptoms: Set<String>.from(raw['symptoms'] as List),
      sickCount: raw['sick_count'] as int,
      deadCount: raw['dead_count'] as int,
      totalAtRisk: raw['total_at_risk'] as int?,
      reportMonth: raw['report_month'] as int,
    );

Map<String, dynamic> goldenFor(TriageResult result) => {
      'candidates': [
        for (final c in result.candidates) [c.diseaseId, c.score]
      ],
      'primary_syndrome': result.primarySyndrome,
      'severity': result.severity,
      'zoonotic_flag': result.zoonoticFlag,
      'unknown_syndrome': result.unknownSyndrome,
      'actions': result.actions,
      'has_safety_note': result.safetyNote != null,
    };

void checkExpectations(TriageResult result, Map<String, dynamic> expected) {
  final ids = [for (final c in result.candidates) c.diseaseId];
  if (expected.containsKey('top')) expect(ids.first, expected['top']);
  if (expected.containsKey('top_confidence')) {
    expect(result.candidates.first.confidence, expected['top_confidence']);
  }
  if (expected.containsKey('severity')) expect(result.severity, expected['severity']);
  if (expected.containsKey('zoonotic_flag')) expect(result.zoonoticFlag, expected['zoonotic_flag']);
  if (expected.containsKey('unknown_syndrome')) {
    expect(result.unknownSyndrome, expected['unknown_syndrome']);
  }
  for (final disease in (expected['in_top3'] as List? ?? [])) {
    expect(ids, contains(disease));
  }
  for (final disease in (expected['not_in_candidates'] as List? ?? [])) {
    expect(ids, isNot(contains(disease)));
  }
  for (final pair in (expected['ranked_above'] as List? ?? [])) {
    expect(ids.indexOf(pair[0] as String), lessThan(ids.indexOf(pair[1] as String)));
  }
  for (final disease in (expected['gated'] as List? ?? [])) {
    expect(result.candidates.firstWhere((c) => c.diseaseId == disease).requiredSignsMet, isFalse);
  }
}

Future<void> main() async {
  final data = await SharedData.load(readSharedFile);
  final engine = RuleEngine(data);
  final vectors = (jsonDecode(await readSharedFile('triage_test_vectors.json'))['vectors'] as List)
      .cast<Map<String, dynamic>>();

  group('golden vectors', () {
    for (final vector in vectors) {
      final result = engine.evaluate(toInput(vector['input'] as Map<String, dynamic>));

      test('v${vector['id']} meets spec expectations: ${vector['name']}', () {
        checkExpectations(result, vector['expect'] as Map<String, dynamic>);
      });

      test('v${vector['id']} matches the Python engine exactly', () {
        // Round-trip through JSON so ints and doubles compare the same way.
        expect(jsonDecode(jsonEncode(goldenFor(result))), vector['golden']);
      });
    }
  });

  test('round half up matches Python', () {
    expect(RuleEngine.round3(0.71875), 0.719);
    expect(RuleEngine.round3(0.0005), 0.001);
  });

  test('general signs only count when nothing else is present', () {
    expect(engine.primarySyndrome({'fever', 'skin_nodules'}), 'dermatological');
    expect(engine.primarySyndrome({'fever'}), 'general');
    expect(engine.primarySyndrome({}), 'general');
  });

  test('unknown species is rejected', () {
    expect(() => engine.evaluate(const TriageInput(species: 'camel', reportMonth: 1)),
        throwsArgumentError);
  });
}
