import 'dart:math' as math;

import 'rule_engine.dart';

/// Combine rule scores with the LSD photo model (spec 7.9).
///
/// Step-for-step copy of backend/app/services/triage/fusion.py: the server
/// re-runs this with the probability the phone sends, and the shared golden
/// vectors (those with `image_p_lsd`) prove both give the same result.
/// Weights and cut-offs come from triage_config.json ("fusion").
class FusionEngine {
  FusionEngine(this.rules);

  final RuleEngine rules;

  Map<String, dynamic> get _cfg => rules.data.triageConfig['fusion'] as Map<String, dynamic>;

  static double _num(Object? value) => (value as num).toDouble();

  String get imageModel => _cfg['image_model'] as String;

  /// The photo only counts for species the photo's disease affects (cattle, buffalo).
  bool speciesUsesPhoto(String? species) =>
      species != null && (rules.data.rules[_cfg['disease']]!['species'] as List).contains(species);

  bool imageApplies(TriageInput report, double? imagePLsd) => imagePLsd != null && speciesUsesPhoto(report.species);

  /// What the photo alone says: {p_lsd, unclear, ask_about_skin_nodules}.
  /// The report's photo step shows the same flags before triage runs.
  Map<String, dynamic> photoFlags(double p, Set<String> symptoms) => {
        'p_lsd': RuleEngine.round3(p),
        'unclear': math.max(p, 1 - p) < _num(_cfg['clear_photo_min_p']),
        'ask_about_skin_nodules': p >= _num(_cfg['ask_min_p']) && !symptoms.contains(_cfg['ask_sign']),
      };

  String get askSign => _cfg['ask_sign'] as String;

  /// Replace the LSD candidate with 0.6 * rules + 0.4 * image, then re-rank.
  List<TriageCandidate> fuseLsd(TriageInput report, List<TriageCandidate> candidates, double imagePLsd) {
    final disease = _cfg['disease'] as String;
    final lsd = rules.scoreRule(rules.data.rules[disease]!, report); // even if its rule score is 0
    final fused =
        RuleEngine.round3(_num(_cfg['rules_weight']) * lsd.score + _num(_cfg['image_weight']) * imagePLsd);
    final fusedLsd = TriageCandidate(
      diseaseId: lsd.diseaseId,
      score: fused,
      confidence: rules.confidenceLabel(fused),
      matchedSigns: lsd.matchedSigns,
      missingKeySigns: lsd.missingKeySigns,
      requiredSignsMet: lsd.requiredSignsMet,
      sources: {'rules': lsd.score, 'image': RuleEngine.round3(imagePLsd)},
    );
    final ranked = [
      ...candidates.where((c) => c.diseaseId != disease),
      fusedLsd,
    ].where((c) => c.score > 0).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.diseaseId.compareTo(b.diseaseId);
      });
    return ranked;
  }

  /// Rules, plus the photo when there is one. Without a photo this equals RuleEngine.evaluate.
  TriageResult evaluate(TriageInput report, {double? imagePLsd}) {
    rules.validate(report);
    var candidates = rules.scoreAllRules(report);
    var version = rules.engineVersion;
    Map<String, dynamic>? photo;
    if (imageApplies(report, imagePLsd)) {
      final p = imagePLsd!;
      candidates = fuseLsd(report, candidates, p);
      version = '$version+$imageModel';
      photo = photoFlags(p, report.symptoms);
    }
    return rules.buildResult(report, candidates, version, photo: photo);
  }
}
