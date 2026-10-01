import 'dart:convert';

/// Reads one file from the shared folder, given its path relative to it
/// (e.g. `disease_rules/lsd.json`). The app passes a rootBundle reader,
/// tests pass a dart:io File reader, so this file stays pure Dart.
typedef SharedFileReader = Future<String> Function(String relativePath);

/// The shared/ JSON contracts, loaded once. Same files the backend uses.
class SharedData {
  SharedData({
    required this.species,
    required this.symptoms,
    required this.syndromes,
    required this.rules,
    required this.triageConfig,
    required this.actions,
    this.geo = const {},
    this.advisoryTemplates = const {},
    this.lexicon = const {},
  });

  /// species id -> entry from symptoms.json
  final Map<String, Map<String, dynamic>> species;

  /// symptom id -> entry from symptoms.json
  final Map<String, Map<String, dynamic>> symptoms;
  final List<Map<String, dynamic>> syndromes;

  /// rule id -> rule file content
  final Map<String, Map<String, dynamic>> rules;
  final Map<String, dynamic> triageConfig;

  /// action id -> entry from actions.json
  final Map<String, Map<String, dynamic>> actions;

  /// Demo district, blocks and villages (geo/demo_district.json), so the
  /// village picker works with no signal.
  final Map<String, dynamic> geo;

  /// template id -> advisory template (advisories/templates.json).
  final Map<String, Map<String, dynamic>> advisoryTemplates;

  /// Spoken phrases -> symptom, species and number (symptom_lexicon.json), for voice input.
  final Map<String, dynamic> lexicon;

  /// Rules sorted by id, the order both engines score them in.
  List<Map<String, dynamic>> get rulesInOrder =>
      (rules.keys.toList()..sort()).map((id) => rules[id]!).toList();

  static Future<SharedData> load(SharedFileReader read) async {
    Future<Map<String, dynamic>> readJson(String path) async =>
        jsonDecode(await read(path)) as Map<String, dynamic>;

    final config = await readJson('triage_config.json');
    final ruleIds = List<String>.from(config['rule_ids'] as List);
    final rules = <String, Map<String, dynamic>>{};
    for (final id in ruleIds) {
      rules[id] = await readJson('disease_rules/$id.json');
    }
    final symptomsFile = await readJson('symptoms.json');
    return SharedData(
      species: _byId(symptomsFile['species']),
      symptoms: _byId(symptomsFile['symptoms']),
      syndromes: _maps((await readJson('syndromes.json'))['syndromes']),
      rules: rules,
      triageConfig: config,
      actions: _byId((await readJson('actions.json'))['actions']),
      geo: await readJson('geo/demo_district.json'),
      advisoryTemplates: _byId((await readJson('advisories/templates.json'))['templates']),
      lexicon: await readJson('symptom_lexicon.json'),
    );
  }

  static List<Map<String, dynamic>> _maps(Object? list) =>
      (list as List).cast<Map<String, dynamic>>();

  static Map<String, Map<String, dynamic>> _byId(Object? list) =>
      {for (final item in _maps(list)) item['id'] as String: item};
}
