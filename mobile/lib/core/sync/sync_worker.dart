/// Sends the outbox to the server (spec 10.3). Pure Dart, so it can be unit
/// tested with a fake store and a fake server.
library;

/// One report waiting on the phone.
class OutboxItem {
  const OutboxItem({
    required this.clientUuid,
    required this.payload,
    required this.attempts,
    this.photoPath,
    this.serverReportId,
    this.sent = false,
    this.photoUploaded = false,
  });

  final String clientUuid;
  final Map<String, dynamic> payload;
  final int attempts;
  final String? photoPath;
  final String? serverReportId;
  final bool sent;
  final bool photoUploaded;

  bool get needsPhotoUpload => sent && photoPath != null && !photoUploaded && serverReportId != null;
}

/// Where outbox items live (drift on the phone, a list in tests).
abstract class OutboxStore {
  /// Unsent items whose backoff has passed, oldest first.
  Future<List<OutboxItem>> dueForSending(DateTime now, int limit);
  Future<List<OutboxItem>> photosToUpload();
  Future<void> markSending(List<String> clientUuids);
  Future<void> markSent(String clientUuid, {required String reportId, required String caseId});
  Future<void> markFailed(String clientUuid, String error, DateTime nextAttemptAt);
  Future<void> markPhotoUploaded(String clientUuid);

  /// Makes every unsent item due now (see SyncWorker.runOnce force).
  Future<void> clearBackoff();
}

class PushResult {
  const PushResult({required this.clientUuid, required this.status, this.message, this.reportId, this.caseId});

  final String clientUuid;

  /// "created", "duplicate" or "error".
  final String status;
  final String? message;
  final String? reportId;
  final String? caseId;
}

/// The server calls the worker needs (POST /sync/push, photo upload).
abstract class SyncServer {
  Future<List<PushResult>> push(List<Map<String, dynamic>> reports);
  Future<void> uploadPhoto(String reportId, String photoPath);
}

class SyncSummary {
  const SyncSummary({this.sent = 0, this.failed = 0, this.photos = 0, this.offline = false});

  final int sent;
  final int failed;
  final int photos;

  /// True when the server could not be reached at all.
  final bool offline;
}

class SyncWorker {
  SyncWorker({required this.store, required this.server, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final OutboxStore store;
  final SyncServer server;
  final DateTime Function() _clock;
  bool _running = false;

  /// The server accepts at most 50 reports per push.
  static const batchSize = 50;

  /// Wait before retry number n (spec: 5 s, 15 s, 60 s, then every 5 min).
  static const backoff = [Duration(seconds: 5), Duration(seconds: 15), Duration(seconds: 60), Duration(minutes: 5)];

  static Duration delayAfter(int attempts) => backoff[(attempts - 1).clamp(0, backoff.length - 1)];

  /// Sends everything that is due. Runs one at a time: a second call while
  /// one is running returns at once, so a report can never be pushed twice
  /// in parallel from this phone.
  ///
  /// [force] clears the backoff first, for when the person acted and expects
  /// the report to go now; timers and network changes still respect it.
  Future<SyncSummary> runOnce({bool force = false}) async {
    if (_running) return const SyncSummary();
    _running = true;
    try {
      if (force) await store.clearBackoff();
      return await _run();
    } finally {
      _running = false;
    }
  }

  Future<SyncSummary> _run() async {
    var sent = 0, failed = 0;
    while (true) {
      final batch = await store.dueForSending(_clock(), batchSize);
      if (batch.isEmpty) break;
      await store.markSending([for (final item in batch) item.clientUuid]);
      final List<PushResult> results;
      try {
        results = await server.push([for (final item in batch) item.payload]);
      } catch (error) {
        // No answer (offline, timeout): every item waits and tries again.
        // If the server did save them, the retry comes back as "duplicate".
        for (final item in batch) {
          await store.markFailed(item.clientUuid, '$error', _clock().add(delayAfter(item.attempts + 1)));
        }
        return SyncSummary(sent: sent, failed: failed + batch.length, offline: true);
      }
      final byUuid = {for (final r in results) r.clientUuid: r};
      for (final item in batch) {
        final result = byUuid[item.clientUuid];
        if (result != null && (result.status == 'created' || result.status == 'duplicate')) {
          await store.markSent(item.clientUuid, reportId: result.reportId!, caseId: result.caseId!);
          sent++;
        } else {
          await store.markFailed(item.clientUuid, result?.message ?? 'No result from server',
              _clock().add(delayAfter(item.attempts + 1)));
          failed++;
        }
      }
      if (batch.length < batchSize) break;
    }
    final photos = await _uploadPhotos();
    return SyncSummary(sent: sent, failed: failed, photos: photos);
  }

  /// Photos go after their reports, so a slow photo never holds back a report.
  Future<int> _uploadPhotos() async {
    var uploaded = 0;
    for (final item in await store.photosToUpload()) {
      try {
        await server.uploadPhoto(item.serverReportId!, item.photoPath!);
        await store.markPhotoUploaded(item.clientUuid);
        uploaded++;
      } catch (_) {
        // Tried again on the next run.
      }
    }
    return uploaded;
  }
}
