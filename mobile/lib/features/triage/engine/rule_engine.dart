import 'dart:math' as math;

import '../../../core/shared_data/shared_data.dart';

/// Rule-based triage (spec Sections 7.6-7.7), run on the phone so a
/// para-vet with no signal still gets an answer.
///
/// This file must stay step-for-step identical to the Python engine in
/// backend/app/services/triage/rule_engine.py: same order of arithmetic,
/// same rounding, same tie-breaks. Both run the golden vectors in
/// shared/triage_test_vectors.json, so any drift fails a test.
///
/// The result is a *suspected* disease list, never a diagnosis.

const severityOrder = ['routine', 'urgent', 'emergency'];

class TriageInput {
  const TriageInput({
    required this.species,
    this.symptoms = const {},
    this.sickCount = 0,
    this.deadCount = 0,
    this.totalAtRisk,
    required this.reportMonth,
  });

  final String species;
  final Set<String> symptoms;
  final int sickCount;
  final int deadCount;
  final int? totalAtRisk;

  /// 1-12. Season boosts depend on it.
  final int reportMonth;

  /// Spec default when the reporter did not give a herd size.
  int get herdSize => totalAtRisk ?? sickCount + deadCount + 1;
}

class TriageCandidate {
  const TriageCandidate({
    required this.diseaseId,
    required this.score,
    required this.confidence,
    required this.matchedSigns,
    required this.missingKeySigns,
    required this.requiredSignsMet,
    required this.sources,
  });

  final String diseaseId;
  final double score;

  /// "high", "moderate" or "low".
  final String confidence;
  final List<String> matchedSigns;
  final List<String> missingKeySigns;
  final bool requiredSignsMet;

  /// Score per source, e.g. {"rules": 0.72, "image": 0.97}, for "Why this result".
  final Map<String, double> sources;

  Map<String, dynamic> toJson() => {
        'disease_id': diseaseId,
        'score': score,
        'confidence': confidence,
        'matched_signs': matchedSigns,
        'missing_key_signs': missingKeySigns,
        'required_signs_met': requiredSignsMet,
        'sources': sources,
      };
}

class TriageResult {
  const TriageResult({
    required this.engineVersion,
    required this.candidates,
    required this.primarySyndrome,
    required this.severity,
    required this.zoonoticFlag,
    required this.unknownSyndrome,
    required this.actions,
    required this.safetyNote,
  });

  final String engineVersion;
  final List<TriageCandidate> candidates;
  final String primarySyndrome;

  /// "routine", "urgent" or "emergency".
  final String severity;
  final bool zoonoticFlag;
  final bool unknownSyndrome;

  /// Action ids from shared/actions.json, in order.
  final List<String> actions;

  /// Localised safety note ({en, hi, mr}) or null.
  final Map<String, dynamic>? safetyNote;

  Map<String, dynamic> toJson() => {
        'engine_version': engineVersion,
        'candidates': [for (final c in candidates) c.toJson()],
        'primary_syndrome': primarySyndrome,
        'severity': severity,
        'zoonotic_flag': zoonoticFlag,
        'unknown_syndrome': unknownSyndrome,
        'actions': actions,
        'safety_note': safetyNote,
      };
}

class RuleEngine {
  RuleEngine(this.data);

  final SharedData data;

  Map<String, dynamic> get _config => data.triageConfig;

  /// Round half up, same as the Python engine's round3.
  static double round3(double value) => (value * 1000 + 0.5).floorToDouble() / 1000;

  static double _clamp01(double value) => math.max(0.0, math.min(1.0, value));

  static double _num(Object? value) => (value as num).toDouble();

  static String higherSeverity(String a, String b) =>
      severityOrder.indexOf(a) >= severityOrder.indexOf(b) ? a : b;

  /// Heaviest sign first; ties by id so both engines give the same order.
  static List<String> _sortSigns(List<String> ids, Map<String, int> weights) =>
      ids..sort((a, b) {
        final byWeight = weights[b]!.compareTo(weights[a]!);
        return byWeight != 0 ? byWeight : a.compareTo(b);
      });

  String confidenceLabel(double score) {
    final levels = _config['confidence'] as Map<String, dynamic>;
    if (score >= _num(levels['high'])) return 'high';
    if (score >= _num(levels['moderate'])) return 'moderate';
    return 'low';
  }

  TriageCandidate scoreRule(Map<String, dynamic> rule, TriageInput report) {
    final signs = Map<String, int>.from(rule['signs'] as Map);
    final present = report.symptoms;
    final totalWeight = signs.values.fold<int>(0, (sum, w) => sum + w);
    final presentWeight = signs.entries
        .where((e) => present.contains(e.key))
        .fold<int>(0, (sum, e) => sum + e.value);
    var score = presentWeight / totalWeight;

    final groups = (rule['required'] as List).map((g) => List<String>.from(g as List));
    final requiredMet = groups.every((group) => group.any(present.contains));
    if (!requiredMet) {
      score = score * _num(rule['gate_fail_multiplier']);
    }
    final season = rule['season'] as Map<String, dynamic>;
    if ((season['high_risk_months'] as List).contains(report.reportMonth)) {
      score = score * _num(season['boost']);
    }
    final deathRate = math.min(report.deadCount / math.max(report.herdSize, 1), 1.0);
    score = score + deathRate * _num(rule['mortality_weight']);
    score = round3(_clamp01(score));

    return TriageCandidate(
      diseaseId: rule['id'] as String,
      score: score,
      confidence: confidenceLabel(score),
      matchedSigns: _sortSigns(signs.keys.where(present.contains).toList(), signs),
      missingKeySigns: _sortSigns(
          signs.keys.where((s) => signs[s]! >= 4 && !present.contains(s)).toList(), signs),
      requiredSignsMet: requiredMet,
      sources: {'rules': score},
    );
  }

  /// Every rule for this species with a score above zero, best first.
  List<TriageCandidate> scoreAllRules(TriageInput report) {
    final candidates = [
      for (final rule in data.rulesInOrder)
        if ((rule['species'] as List).contains(report.species)) scoreRule(rule, report),
    ].where((c) => c.score > 0).toList();
    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.diseaseId.compareTo(b.diseaseId);
    });
    return candidates;
  }

  String primarySyndrome(Set<String> symptoms) {
    final totals = <String, int>{};
    for (final syndrome in data.syndromes) {
      final weights = Map<String, int>.from(syndrome['symptoms'] as Map);
      final weight = weights.entries
          .where((e) => symptoms.contains(e.key))
          .fold<int>(0, (sum, e) => sum + e.value);
      if (weight > 0) totals[syndrome['id'] as String] = weight;
    }
    // 'general' (fever, not eating) only counts when nothing more specific is present.
    final specific = Map.of(totals)..remove('general');
    final pool = specific.isNotEmpty ? specific : totals;
    if (pool.isEmpty) return 'general';
    final ids = pool.keys.toList()
      ..sort((a, b) {
        final byWeight = pool[b]!.compareTo(pool[a]!);
        return byWeight != 0 ? byWeight : a.compareTo(b);
      });
    return ids.first;
  }

  bool isUnknownSyndrome(double topScore, TriageInput report) {
    final rule = _config['unknown_syndrome'] as Map<String, dynamic>;
    final looksSerious = report.sickCount >= (rule['min_sick'] as int) ||
        report.deadCount >= (rule['min_dead'] as int);
    return topScore < _num(rule['max_top_score']) && looksSerious;
  }

  String severityLevel(TriageInput report, TriageCandidate? top, bool unknown) {
    final cfg = _config['severity'] as Map<String, dynamic>;
    final isBird = data.species[report.species]!['group'] == 'bird';
    final topRule = top == null ? null : data.rules[top.diseaseId]!;
    final topScore = top?.score ?? 0.0;

    final manyDead = isBird
        ? report.deadCount >= (cfg['emergency_min_dead_poultry'] as int)
        : report.deadCount >= (cfg['emergency_min_dead_mammal'] as int);
    String level;
    if ((topRule != null &&
            topRule['severity_floor'] == 'emergency' &&
            topScore >= _num(cfg['emergency_floor_min_score'])) ||
        manyDead) {
      level = 'emergency';
    } else if ((topRule != null &&
            topRule['notifiable'] == true &&
            topScore >= _num(cfg['urgent_notifiable_min_score'])) ||
        report.sickCount >= (cfg['urgent_min_sick'] as int) ||
        report.deadCount >= (cfg['urgent_min_dead'] as int)) {
      level = 'urgent';
    } else {
      level = 'routine';
    }

    if (topRule != null && topScore >= _num(cfg['rule_floor_min_score'])) {
      level = higherSeverity(level, topRule['severity_floor'] as String);
    }
    if (unknown) level = higherSeverity(level, 'urgent');
    return level;
  }

  List<String> pickActions(TriageCandidate? top, bool unknown) {
    final cfg = _config['actions'] as Map<String, dynamic>;
    if (unknown) return List<String>.from(cfg['unknown_syndrome'] as List);
    if (top != null && top.score >= _num(cfg['disease_actions_min_score'])) {
      return List<String>.from(data.rules[top.diseaseId]!['actions'] as List);
    }
    return List<String>.from(cfg['low_confidence'] as List);
  }

  Map<String, dynamic>? pickSafetyNote(List<TriageCandidate> candidates) {
    final minScore = _num((_config['actions'] as Map)['safety_note_min_score']);
    for (final candidate in candidates) {
      final note = data.rules[candidate.diseaseId]!['safety_note'];
      if (note != null && candidate.score >= minScore) return note as Map<String, dynamic>;
    }
    return null;
  }

  String get engineVersion =>
      'rules-${data.rules.values.map((r) => r['version'] as int).reduce(math.max)}';

  void _validate(TriageInput report) {
    if (!data.species.containsKey(report.species)) {
      throw ArgumentError('Unknown species: ${report.species}');
    }
    if (report.reportMonth < 1 || report.reportMonth > 12) {
      throw ArgumentError('reportMonth must be 1-12, got ${report.reportMonth}');
    }
    if (report.sickCount < 0 || report.deadCount < 0) {
      throw ArgumentError('sickCount and deadCount must not be negative');
    }
  }

  /// Run triage for one report and return the shared response shape.
  TriageResult evaluate(TriageInput report) {
    _validate(report);
    final allCandidates = scoreAllRules(report);
    final top = allCandidates.isEmpty ? null : allCandidates.first;
    final unknown = isUnknownSyndrome(top?.score ?? 0.0, report);
    final zoonoticMin = _num(_config['zoonotic_min_score']);
    final zoonotic = allCandidates.any(
        (c) => data.rules[c.diseaseId]!['zoonotic'] == true && c.score >= zoonoticMin);
    final maxCandidates = _config['max_candidates'] as int;
    return TriageResult(
      engineVersion: engineVersion,
      candidates: allCandidates.take(maxCandidates).toList(),
      primarySyndrome: primarySyndrome(report.symptoms),
      severity: severityLevel(report, top, unknown),
      zoonoticFlag: zoonotic,
      unknownSyndrome: unknown,
      actions: pickActions(top, unknown),
      safetyNote: pickSafetyNote(allCandidates),
    );
  }
}
