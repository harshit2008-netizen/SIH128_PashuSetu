import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../db/app_database.dart';
import '../settings/app_settings.dart';
import 'sync_worker.dart';

/// The outbox in drift.
class DriftOutboxStore implements OutboxStore {
  DriftOutboxStore(this.db);

  final AppDatabase db;

  OutboxItem _item(OutboxReport row) => OutboxItem(
        clientUuid: row.clientUuid,
        payload: jsonDecode(row.payload) as Map<String, dynamic>,
        attempts: row.attempts,
        photoPath: row.photoPath,
        serverReportId: row.serverReportId,
        sent: row.status == 'sent',
        photoUploaded: row.photoUploaded,
      );

  $OutboxReportsTable get _t => db.outboxReports;

  @override
  Future<List<OutboxItem>> dueForSending(DateTime now, int limit) async {
    final rows = await (db.select(_t)
          ..where((t) =>
              t.status.isNotValue('sent') & (t.nextAttemptAt.isNull() | t.nextAttemptAt.isSmallerOrEqualValue(now)))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_item).toList();
  }

  @override
  Future<List<OutboxItem>> photosToUpload() async {
    final rows = await (db.select(_t)
          ..where((t) => t.status.equals('sent') & t.photoPath.isNotNull() & t.photoUploaded.equals(false)))
        .get();
    return rows.map(_item).toList();
  }

  @override
  Future<void> markSending(List<String> clientUuids) =>
      (db.update(_t)..where((t) => t.clientUuid.isIn(clientUuids)))
          .write(const OutboxReportsCompanion(status: Value('sending')));

  @override
  Future<void> markSent(String clientUuid, {required String reportId, required String caseId}) =>
      (db.update(_t)..where((t) => t.clientUuid.equals(clientUuid))).write(OutboxReportsCompanion(
          status: const Value('sent'),
          lastError: const Value(null),
          serverReportId: Value(reportId),
          serverCaseId: Value(caseId)));

  @override
  Future<void> markFailed(String clientUuid, String error, DateTime nextAttemptAt) async {
    final row = await (db.select(_t)..where((t) => t.clientUuid.equals(clientUuid))).getSingle();
    await (db.update(_t)..where((t) => t.clientUuid.equals(clientUuid))).write(OutboxReportsCompanion(
        status: const Value('failed'),
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
        nextAttemptAt: Value(nextAttemptAt)));
  }

  @override
  Future<void> clearBackoff() => (db.update(_t)..where((t) => t.status.isNotValue('sent')))
      .write(const OutboxReportsCompanion(nextAttemptAt: Value(null)));

  @override
  Future<void> markPhotoUploaded(String clientUuid) =>
      (db.update(_t)..where((t) => t.clientUuid.equals(clientUuid)))
          .write(const OutboxReportsCompanion(photoUploaded: Value(true)));
}

/// The two server calls, over the app's API client.
class ApiSyncServer implements SyncServer {
  ApiSyncServer(this.api);

  final ApiClient api;

  @override
  Future<List<PushResult>> push(List<Map<String, dynamic>> reports) async {
    final body = await api.post('/sync/push', body: {'reports': reports}) as Map<String, dynamic>;
    return [
      for (final r in (body['results'] as List).cast<Map<String, dynamic>>())
        PushResult(
          clientUuid: r['client_uuid'] as String,
          status: r['status'] as String,
          message: r['message'] as String?,
          reportId: r['report_id'] as String?,
          caseId: r['case_id'] as String?,
        ),
    ];
  }

  @override
  Future<void> uploadPhoto(String reportId, String photoPath) async {
    await api.post('/reports/$reportId/photo',
        body: FormData.fromMap({'photo': await MultipartFile.fromFile(photoPath, contentType: DioMediaType('image', 'jpeg'))}));
  }
}

/// Runs the sync worker at the right moments: app start, network change,
/// every 60 s while the app is open, pull-to-refresh, and right after a
/// new report (spec 10.3). The state is the last run's summary.
class SyncController extends Notifier<SyncSummary?> {
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  late SyncWorker _worker;

  @override
  SyncSummary? build() {
    // Built once for the whole session. Settings changes are *listened* to,
    // not watched: a rebuild would leave the worker holding a disposed ref.
    _worker = SyncWorker(store: DriftOutboxStore(ref.read(databaseProvider)), server: _LiveServer(ref));
    ref.listen(settingsProvider.select((s) => (s.token, s.apiBaseUrl, s.simulateNoSignal)),
        (_, _) => syncNow(force: true));
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => syncNow());
    _connectivity = Connectivity().onConnectivityChanged.listen((_) => syncNow());
    ref.onDispose(() {
      _timer?.cancel();
      _connectivity?.cancel();
    });
    Future.microtask(syncNow);
    return null;
  }

  /// [force] skips the backoff wait: used when the person acts (signal back
  /// on, new report, pull to refresh) and expects the send to happen now.
  Future<SyncSummary> syncNow({bool force = false}) async {
    if (!ref.read(settingsProvider).loggedIn) return const SyncSummary();
    final summary = await _worker.runOnce(force: force);
    state = summary;
    if (summary.sent > 0) ref.invalidate(serverOnlineProvider);
    return summary;
  }
}

/// Reads the current API client on every call, so a new token or API
/// address (developer menu) is used without rebuilding the worker.
class _LiveServer implements SyncServer {
  _LiveServer(this.ref);

  final Ref ref;

  ApiSyncServer get _server => ApiSyncServer(ref.read(apiClientProvider));

  @override
  Future<List<PushResult>> push(List<Map<String, dynamic>> reports) => _server.push(reports);

  @override
  Future<void> uploadPhoto(String reportId, String photoPath) => _server.uploadPhoto(reportId, photoPath);
}

final syncControllerProvider = NotifierProvider<SyncController, SyncSummary?>(SyncController.new);
