// Outbox sync (spec 10.3): offline reports are sent exactly once when the
// phone comes back online, and a retry after a timeout never duplicates.
import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/sync/sync_worker.dart';

class MemoryStore implements OutboxStore {
  final items = <String, _Row>{};

  void add(String uuid, {String? photo}) =>
      items[uuid] = _Row(uuid, {'client_uuid': uuid, 'species': 'cattle'}, photo, DateTime(2026, 9, 28, 9, items.length));

  int get unsent => items.values.where((r) => !r.sent).length;

  @override
  Future<List<OutboxItem>> dueForSending(DateTime now, int limit) async {
    final due = items.values.where((r) => !r.sent && !(r.nextAttemptAt?.isAfter(now) ?? false)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return due.take(limit).map((r) => r.toItem()).toList();
  }

  @override
  Future<List<OutboxItem>> photosToUpload() async =>
      items.values.map((r) => r.toItem()).where((i) => i.needsPhotoUpload).toList();

  @override
  Future<void> markSending(List<String> uuids) async {}

  @override
  Future<void> markSent(String uuid, {required String reportId, required String caseId}) async =>
      items[uuid]!
        ..sent = true
        ..reportId = reportId;

  @override
  Future<void> markFailed(String uuid, String error, DateTime nextAttemptAt) async => items[uuid]!
    ..attempts += 1
    ..nextAttemptAt = nextAttemptAt;

  @override
  Future<void> markPhotoUploaded(String uuid) async => items[uuid]!.photoUploaded = true;

  @override
  Future<void> clearBackoff() async {
    for (final row in items.values) {
      row.nextAttemptAt = null;
    }
  }
}

class _Row {
  _Row(this.uuid, this.payload, this.photo, this.createdAt);

  final String uuid;
  final Map<String, dynamic> payload;
  final String? photo;
  final DateTime createdAt;
  bool sent = false;
  bool photoUploaded = false;
  int attempts = 0;
  DateTime? nextAttemptAt;
  String? reportId;

  OutboxItem toItem() => OutboxItem(
      clientUuid: uuid, payload: payload, attempts: attempts, photoPath: photo,
      serverReportId: reportId, sent: sent, photoUploaded: photoUploaded);
}

/// Stores reports by client_uuid like the real server (upsert, "duplicate" on repeat).
class FakeServer implements SyncServer {
  bool online = true;

  /// Save the batch, then fail as if the answer was lost on the way back.
  bool loseNextAnswer = false;
  final stored = <String, String>{};
  final photos = <String>[];

  @override
  Future<List<PushResult>> push(List<Map<String, dynamic>> reports) async {
    if (!online) throw Exception('no signal');
    final results = [
      for (final r in reports)
        PushResult(
          clientUuid: r['client_uuid'] as String,
          status: stored.containsKey(r['client_uuid']) ? 'duplicate' : 'created',
          reportId: stored.putIfAbsent(r['client_uuid'] as String, () => 'report-${stored.length}'),
          caseId: 'case-${r['client_uuid']}',
        ),
    ];
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw Exception('timeout');
    }
    return results;
  }

  @override
  Future<void> uploadPhoto(String reportId, String photoPath) async {
    if (!online) throw Exception('no signal');
    photos.add(reportId);
  }
}

void main() {
  late MemoryStore store;
  late FakeServer server;
  late DateTime now;
  late SyncWorker worker;

  setUp(() {
    store = MemoryStore();
    server = FakeServer();
    now = DateTime(2026, 9, 28, 10);
    worker = SyncWorker(store: store, server: server, clock: () => now);
  });

  test('3 reports made offline are all sent, once, when back online', () async {
    server.online = false;
    for (final id in ['a', 'b', 'c']) {
      store.add(id);
    }
    final offline = await worker.runOnce();
    expect(offline.offline, isTrue);
    expect(store.unsent, 3);

    server.online = true;
    now = now.add(const Duration(seconds: 6)); // past the first backoff
    final summary = await worker.runOnce();
    expect(summary.sent, 3);
    expect(store.unsent, 0);
    expect(server.stored.length, 3);
  });

  test('a retry after a lost answer comes back as duplicate, not a second report', () async {
    store.add('x');
    server.loseNextAnswer = true;
    await worker.runOnce();
    expect(server.stored.length, 1, reason: 'the server saved it');
    expect(store.unsent, 1, reason: 'but the phone does not know yet');

    now = now.add(const Duration(seconds: 6));
    await worker.runOnce();
    expect(store.unsent, 0);
    expect(server.stored.length, 1, reason: 'still exactly one report on the server');
  });

  test('backoff waits 5 s, 15 s, 60 s, then 5 minutes', () async {
    expect(SyncWorker.delayAfter(1), const Duration(seconds: 5));
    expect(SyncWorker.delayAfter(2), const Duration(seconds: 15));
    expect(SyncWorker.delayAfter(3), const Duration(seconds: 60));
    expect(SyncWorker.delayAfter(9), const Duration(minutes: 5));

    server.online = false;
    store.add('y');
    await worker.runOnce();
    server.online = true;
    await worker.runOnce(); // too early: still inside the 5 s wait
    expect(store.unsent, 1);
  });

  test('a forced run (signal back on, new report) skips the backoff wait', () async {
    server.online = false;
    store.add('f');
    await worker.runOnce();
    server.online = true;
    await worker.runOnce(force: true); // still inside the 5 s wait, but forced
    expect(store.unsent, 0);
  });

  test('photos upload after their report is on the server', () async {
    store.add('p', photo: '/photos/p.jpg');
    await worker.runOnce();
    expect(server.photos, ['report-0']);
    expect(store.items['p']!.photoUploaded, isTrue);
  });

  test('overlapping runs do not send the same report twice', () async {
    store.add('z');
    final results = await Future.wait([worker.runOnce(), worker.runOnce()]);
    expect(results.map((r) => r.sent).reduce((a, b) => a + b), 1);
    expect(server.stored.length, 1);
  });
}
