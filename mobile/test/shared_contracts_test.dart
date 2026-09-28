// The app validates the bundled rule files against the same JSON Schema the
// backend uses, so a broken rule can never reach the phone unnoticed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';
import 'package:pashusetu/core/shared_data/shared_data.dart';

Future<String> readSharedFile(String path) => File('assets/shared/$path').readAsString();

Future<void> main() async {
  final data = await SharedData.load(readSharedFile);
  final schema = JsonSchema.create(jsonDecode(await readSharedFile('disease_rules/_schema.json')));

  test('every rule file validates against _schema.json', () {
    for (final rule in data.rules.values) {
      final result = schema.validate(rule);
      expect(result.isValid, isTrue, reason: '${rule['id']}: ${result.errors}');
    }
  });

  test('the schema rejects a broken rule', () {
    final broken = jsonDecode(jsonEncode(data.rules['lsd'])) as Map<String, dynamic>;
    (broken['signs'] as Map)['skin_nodules'] = 7;
    broken.remove('severity_floor');
    expect(schema.validate(broken).isValid, isFalse);
  });

  test('every id used by a rule exists', () {
    for (final rule in data.rules.values) {
      for (final sign in (rule['signs'] as Map).keys) {
        expect(data.symptoms, contains(sign), reason: '${rule['id']} uses $sign');
      }
      for (final action in rule['actions'] as List) {
        expect(data.actions, contains(action), reason: '${rule['id']} uses $action');
      }
    }
  });

  test('all six diseases and 28 symptoms are bundled', () {
    expect(data.rules.keys.toSet(), {'lsd', 'fmd', 'hs', 'anthrax', 'ppr', 'hpai'});
    expect(data.symptoms.length, 28);
  });
}
