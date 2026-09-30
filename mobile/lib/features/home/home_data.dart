import 'dart:convert';

import 'package:drift/drift.dart' show Insertable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/db/app_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/sync/sync_service.dart';
import '../../widgets/widgets.dart';

typedef Json = Map<String, dynamic>;

/// What the farmer / sevak home shows, and whether it came from the phone's cache.
class PullData {
  const PullData({
    required this.cases,
    required this.advisories,
    required this.animals,
    required this.vaccinationsDue,
    required this.fromCache,
  });

  final List<Json> cases;
  final List<Json> advisories;
  final List<Json> animals;
  final List<Json> vaccinationsDue;
  final bool fromCache;
}

List<Json> _list(Object? value) => (value as List? ?? const []).cast<Json>();

Future<void> _saveCache(AppDatabase db, Json body) async {
  await db.replaceCache<$CachedCasesTable, CachedCase>(db.cachedCases, [
    for (final c in _list(body['cases']))
      CachedCasesCompanion.insert(id: c['id'] as String, json: jsonEncode(c), updatedAt: DateTime.parse(c['updated_at'] as String))
  ]);
  await db.replaceCache<$CachedAdvisoriesTable, CachedAdvisory>(db.cachedAdvisories, [
    for (final a in _list(body['advisories']))
      CachedAdvisoriesCompanion.insert(id: a['id'] as String, json: jsonEncode(a), sentAt: DateTime.parse(a['sent_at'] as String))
  ]);
  await db.replaceCache<$CachedAnimalsTable, CachedAnimal>(db.cachedAnimals, [
    for (final a in _list(body['animals'])) CachedAnimalsCompanion.insert(id: a['id'] as String, json: jsonEncode(a))
  ]);
  await db.replaceCache<$CachedVaccinationsDueTable, CachedVaccinationsDueData>(db.cachedVaccinationsDue, <Insertable<CachedVaccinationsDueData>>[
    for (final v in _list(body['vaccinations_due']))
      CachedVaccinationsDueCompanion.insert(id: '${v['animal_id']}-${v['vaccine']}', json: jsonEncode(v))
  ]);
}

Future<PullData> _readCache(AppDatabase db) async {
  List<Json> decode(Iterable<String> rows) => [for (final row in rows) jsonDecode(row) as Json];
  final cases = await (db.select(db.cachedCases)).get();
  cases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return PullData(
    cases: decode(cases.map((r) => r.json)),
    advisories: decode((await db.select(db.cachedAdvisories).get()).map((r) => r.json)),
    animals: decode((await db.select(db.cachedAnimals).get()).map((r) => r.json)),
    vaccinationsDue: decode((await db.select(db.cachedVaccinationsDue).get()).map((r) => r.json)),
    fromCache: true,
  );
}

/// Farmer / sevak data: from the server when reachable, else from the phone.
final pullDataProvider = FutureProvider<PullData>((ref) async {
  // After the outbox sends something, fetch again so the new case shows up.
  ref.listen(syncControllerProvider, (_, summary) {
    if ((summary?.sent ?? 0) > 0) ref.invalidateSelf();
  });
  final api = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  try {
    final body = await api.get('/sync/pull') as Json;
    await _saveCache(db, body);
    return PullData(
      cases: _list(body['cases']),
      advisories: _list(body['advisories']),
      animals: _list(body['animals']),
      vaccinationsDue: _list(body['vaccinations_due']),
      fromCache: false,
    );
  } on ApiException catch (error) {
    if (!error.isNetwork && error.code != 'no_signal') rethrow;
    return _readCache(db);
  }
});

/// Vet / officer case queue (open cases, emergency first).
final caseQueueProvider = FutureProvider<(List<Json>, bool)>((ref) async {
  final api = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  try {
    final cases = _list(await api.get('/cases'));
    await db.replaceCache<$CachedCasesTable, CachedCase>(db.cachedCases, [
      for (final c in cases)
        CachedCasesCompanion.insert(id: c['id'] as String, json: jsonEncode(c), updatedAt: DateTime.parse(c['updated_at'] as String))
    ]);
    return (cases, false);
  } on ApiException catch (error) {
    if (!error.isNetwork && error.code != 'no_signal') rethrow;
    return ((await _readCache(db)).cases, true);
  }
});

final unsentCountProvider = StreamProvider<int>((ref) => ref.watch(databaseProvider).watchUnsentCount());

final outboxProvider = StreamProvider<List<OutboxReport>>((ref) => ref.watch(databaseProvider).watchOutbox());

/// The sync pill: offline beats everything, then "waiting", then "all sent".
final syncStatusProvider = Provider<(SyncState, int)>((ref) {
  final online = ref.watch(serverOnlineProvider).value ?? true;
  final unsent = ref.watch(unsentCountProvider).value ?? 0;
  if (!online) return (SyncState.offline, unsent);
  if (unsent > 0) return (SyncState.waiting, unsent);
  return (SyncState.allSent, 0);
});
