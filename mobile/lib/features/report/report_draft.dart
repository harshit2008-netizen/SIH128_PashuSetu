import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/sync/sync_service.dart';
import '../triage/engine/rule_engine.dart';

/// "When did it start?" choices and how many days back each one means.
enum Onset {
  today(0),
  yesterday(1),
  fewDays(2),
  longer(4);

  const Onset(this.daysAgo);
  final int daysAgo;
}

class Village {
  const Village({required this.id, required this.code, required this.name, required this.lat, required this.lng});

  /// Server id is not in the shared file; the server resolves by location.
  final String? id;
  final String code;
  final Map<String, dynamic> name;
  final double lat;
  final double lng;
}

/// Everything chosen in the 5 report steps. Kept in one object so going back
/// a step never loses what was already chosen (spec 10.4).
class ReportDraft {
  const ReportDraft({
    this.species,
    this.animalId,
    this.herdId,
    this.symptoms = const {},
    this.photoPath,
    this.sick = 1,
    this.dead = 0,
    this.total,
    this.onset = Onset.today,
    this.village,
    this.gps,
    this.locating = false,
  });

  final String? species;
  final String? animalId;
  final String? herdId;
  final Set<String> symptoms;
  final String? photoPath;
  final int sick;
  final int dead;

  /// All animals at risk; null means "not given" (the engine then uses sick + dead + 1).
  final int? total;
  final Onset onset;
  final Village? village;

  /// Phone GPS fix, only kept when it lies inside the demo district.
  final ({double lat, double lng})? gps;
  final bool locating;

  ReportDraft copyWith({
    String? species,
    Value<String?>? animalId,
    Value<String?>? herdId,
    Set<String>? symptoms,
    Value<String?>? photoPath,
    int? sick,
    int? dead,
    Value<int?>? total,
    Onset? onset,
    Village? village,
    Value<({double lat, double lng})?>? gps,
    bool? locating,
  }) =>
      ReportDraft(
        species: species ?? this.species,
        animalId: animalId == null ? this.animalId : animalId.value,
        herdId: herdId == null ? this.herdId : herdId.value,
        symptoms: symptoms ?? this.symptoms,
        photoPath: photoPath == null ? this.photoPath : photoPath.value,
        sick: sick ?? this.sick,
        dead: dead ?? this.dead,
        total: total == null ? this.total : total.value,
        onset: onset ?? this.onset,
        village: village ?? this.village,
        gps: gps == null ? this.gps : gps.value,
        locating: locating ?? this.locating,
      );

  /// Validation from spec 10.4. Returns a problem key, or null when fine.
  String? get problem {
    if (symptoms.isEmpty && dead < 1) return 'needSignOrDeath';
    if (total != null && total! < sick + dead) return 'totalTooSmall';
    return null;
  }
}

/// Villages from the bundled geography, so the picker works with no signal.
List<Village> villagesFromShared(Map<String, dynamic> geo) => [
      for (final block in (geo['blocks'] as List).cast<Map<String, dynamic>>())
        for (final v in (block['villages'] as List).cast<Map<String, dynamic>>())
          Village(
            id: null,
            code: v['code'] as String,
            name: {...(v['name'] as Map<String, dynamic>), 'block': block['name']},
            lat: (v['lat'] as num).toDouble(),
            lng: (v['lng'] as num).toDouble(),
          ),
    ];

double _km(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final h = math.pow(math.sin(rad(lat2 - lat1) / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(rad(lng2 - lng1) / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

Village nearestVillage(List<Village> villages, double lat, double lng) =>
    villages.reduce((a, b) => _km(lat, lng, a.lat, a.lng) <= _km(lat, lng, b.lat, b.lng) ? a : b);

/// A phone GPS fix counts only within this distance of a demo village; the
/// laptop demo may run far from Pune, and a pin in another state would
/// break the district map and clustering.
const _maxGpsDistanceKm = 15.0;

class ReportDraftController extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  void start(List<Village> villages, String? homeVillageName) {
    final home = villages.where((v) => v.name['en'] == homeVillageName).firstOrNull;
    state = ReportDraft(village: home ?? villages.first, locating: true);
    _locate(villages);
  }

  Future<void> _locate(List<Village> villages) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(locating: false);
        return;
      }
      final fix = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)));
      final near = nearestVillage(villages, fix.latitude, fix.longitude);
      if (_km(fix.latitude, fix.longitude, near.lat, near.lng) <= _maxGpsDistanceKm) {
        state = state.copyWith(gps: Value((lat: fix.latitude, lng: fix.longitude)), village: near, locating: false);
      } else {
        state = state.copyWith(locating: false);
      }
    } catch (_) {
      // No fix within 10 s: the reporter picks the village instead.
      state = state.copyWith(locating: false);
    }
  }

  void setSpecies(String species) => state = state.copyWith(
      species: species, symptoms: species == state.species ? null : {}, animalId: const Value(null), herdId: const Value(null));

  void setAnimal(String? animalId, String? herdId) =>
      state = state.copyWith(animalId: Value(animalId), herdId: Value(herdId));

  void toggleSymptom(String id) {
    final next = {...state.symptoms};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(symptoms: next);
  }

  void setPhoto(String? path) => state = state.copyWith(photoPath: Value(path));
  void setSick(int value) => state = state.copyWith(sick: value);
  void setDead(int value) => state = state.copyWith(dead: value);
  void setTotal(int? value) => state = state.copyWith(total: Value(value));
  void setOnset(Onset onset) => state = state.copyWith(onset: onset);
  void setVillage(Village village) => state = state.copyWith(village: village, gps: const Value(null));

  /// Triage on the phone, then the outbox, then a sync attempt (spec 10.4).
  /// Returns the report's client_uuid, which the result screen uses.
  Future<String> submit() async {
    final draft = state;
    final shared = await ref.read(sharedDataProvider.future);
    final now = DateTime.now();
    final result = RuleEngine(shared).evaluate(TriageInput(
      species: draft.species!,
      symptoms: draft.symptoms,
      sickCount: draft.sick,
      deadCount: draft.dead,
      totalAtRisk: draft.total,
      reportMonth: now.month,
    ));
    final clientUuid = const Uuid().v4();
    final village = draft.village!;
    final location = draft.gps ?? (lat: village.lat, lng: village.lng);
    final top = result.candidates.isEmpty ? null : result.candidates.first;
    final payload = {
      'client_uuid': clientUuid,
      'location': {'lat': location.lat, 'lng': location.lng},
      'species': draft.species,
      'symptoms': draft.symptoms.toList()..sort(),
      'sick_count': draft.sick,
      'dead_count': draft.dead,
      'total_at_risk': draft.total,
      'onset_date': now.subtract(Duration(days: draft.onset.daysAgo)).toIso8601String().substring(0, 10),
      'herd_id': draft.herdId,
      'animal_id': draft.animalId,
      'device_triage': {'engine_version': result.engineVersion, 'top': top?.diseaseId, 'score': top?.score ?? 0},
      'created_on_device_at': isoWithOffset(now),
      'channel': 'app',
    };
    final db = ref.read(databaseProvider);
    // Written to the outbox first, always, even when online (spec 10.2).
    await db.into(db.outboxReports).insert(OutboxReportsCompanion.insert(
          clientUuid: clientUuid,
          payload: jsonEncode(payload),
          photoPath: Value(draft.photoPath),
          deviceTriage: Value(jsonEncode({
            ...result.toJson(),
            'species': draft.species,
            'symptoms': draft.symptoms.toList(),
            'has_photo': draft.photoPath != null,
          })),
          createdAt: now,
        ));
    // Do not wait: the result screen shows at once, sending happens behind it.
    ref.read(syncControllerProvider.notifier).syncNow(force: true);
    return clientUuid;
  }
}

final reportDraftProvider = NotifierProvider<ReportDraftController, ReportDraft>(ReportDraftController.new);

/// ISO time with the phone's UTC offset, e.g. 2026-09-28T09:41:00+05:30.
String isoWithOffset(DateTime time) {
  final offset = time.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  String two(int n) => n.abs().toString().padLeft(2, '0');
  final base = time.toIso8601String().split('.').first;
  return '$base$sign${two(offset.inHours)}:${two(offset.inMinutes % 60)}';
}
