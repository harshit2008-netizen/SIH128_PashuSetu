import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/shared_data/shared_data.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../l10n/app_localizations.dart';

typedef Json = Map<String, dynamic>;

List<Json> _list(Object? value) => (value as List? ?? const []).cast<Json>();

final dashboardSummaryProvider =
    FutureProvider<Json>((ref) async => await ref.watch(apiClientProvider).get('/dashboard/summary') as Json);

final dashboardMapProvider =
    FutureProvider<Json>((ref) async => await ref.watch(apiClientProvider).get('/dashboard/map') as Json);

final alertsProvider = FutureProvider<List<Json>>((ref) async => _list(await ref.watch(apiClientProvider).get('/alerts')));

final caseDetailProvider = FutureProvider.family<Json, String>(
    (ref, id) async => await ref.watch(apiClientProvider).get('/cases/$id') as Json);

/// Block risk estimate for one disease (officer only), highest first.
final riskProvider = FutureProvider.autoDispose.family<Json, String>(
    (ref, disease) async => await ref.watch(apiClientProvider).get('/risk', query: {'disease': disease}) as Json);

final vetsProvider = FutureProvider<List<Json>>((ref) async => _list(await ref.watch(apiClientProvider).get('/vets')));

/// Sevak: samples to collect. Lab: samples on the way or waiting for a result.
final samplesProvider =
    FutureProvider<List<Json>>((ref) async => _list(await ref.watch(apiClientProvider).get('/samples')));

String diseaseName(SharedData? shared, String? id, String language, AppLocalizations l10n) =>
    id == null ? l10n.notMatched : localized(shared?.rules[id]?['name'], language);

String sampleTypeLabel(AppLocalizations l10n, String type) => switch (type) {
      'skin_scab' => l10n.sampleSkinScab,
      'blood' => l10n.sampleBlood,
      'nasal_swab' => l10n.sampleNasalSwab,
      'oral_swab' => l10n.sampleOralSwab,
      'tissue' => l10n.sampleTissue,
      'carcass_swab' => l10n.sampleCarcassSwab,
      _ => l10n.sampleOther,
    };

String sampleStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'requested' => l10n.sampleStatusRequested,
      'collected' => l10n.sampleStatusCollected,
      'received' => l10n.sampleStatusReceived,
      _ => l10n.sampleStatusResulted,
    };

String alertTypeLabel(AppLocalizations l10n, String type) => switch (type) {
      'zoonotic' => l10n.alertZoonotic,
      'mortality' => l10n.alertMortality,
      'spike' => l10n.alertSpike,
      _ => l10n.alertCluster,
    };

/// The advisory template that matches a disease (lsd -> lsd_nearby, hs -> hs_season, ...).
String? templateForDisease(SharedData shared, String? disease) => disease == null
    ? null
    : shared.rules[disease]?['advisory_template'] as String?;

/// Finds a village's {en, hi, mr} names in the bundled geography by its English name.
Map<String, dynamic>? villageNamesByEnglish(SharedData shared, String english) {
  for (final block in (shared.geo['blocks'] as List? ?? const [])) {
    for (final v in (block['villages'] as List)) {
      if (v['name']['en'] == english) return (v['name'] as Map).cast<String, dynamic>();
    }
  }
  return null;
}
