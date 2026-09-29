import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import 'formatting.dart';
import 'home_data.dart';

/// App bar shared by every role: app mark, sync pill (farmer and sevak), settings.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.body, required this.onRefresh, this.showSyncPill = false});

  final Widget body;
  final Future<void> Function() onRefresh;
  final bool showSyncPill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final (syncState, waiting) = ref.watch(syncStatusProvider);
    return Scaffold(
      appBar: AppBar(
        title: const AppMark(),
        titleSpacing: AppSpacing.lg,
        actions: [
          if (showSyncPill)
            SyncStatusPill(state: syncState, waitingCount: waiting, onTap: () => context.push('/settings/outbox')),
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => context.push('/settings'),
            icon: const Icon(LucideIcons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: onRefresh, child: body),
    );
  }
}

String _firstName(Map<String, dynamic>? user) => ((user?['name'] as String?) ?? '').split(' ').first;

String _place(Map<String, dynamic>? user, String language) {
  final village = localized(user?['village']?['name'], language);
  final block = localized(user?['block']?['name'], language);
  return [village, block].where((part) => part.isNotEmpty).join(', ');
}

/// Farmer home (spec 9.8 wireframe), in farmer mode: big targets and text.
class FarmerHome extends ConsumerWidget {
  const FarmerHome({super.key, this.sevak = false});

  /// A pashu sevak gets the same home without farmer-mode sizing, plus the
  /// vaccinations due across their block.
  final bool sevak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final language = ref.watch(languageProvider);
    final pull = ref.watch(pullDataProvider);
    final shared = ref.watch(sharedDataProvider).value;

    String diseaseName(String? id) =>
        id == null ? l10n.notMatched : localized(shared?.rules[id]?['name'], language);

    final padding = sevak ? AppSpacing.screenPadding : AppSpacing.farmerScreenPadding;
    return FarmerMode(
      enabled: !sevak,
      child: HomeShell(
        showSyncPill: true,
        onRefresh: () => ref.refresh(pullDataProvider.future),
        body: ListView(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.xxxl),
          children: [
            Text(l10n.greeting(_firstName(settings.user)), style: text.headlineMedium),
            if (_place(settings.user, language).isNotEmpty) Text(_place(settings.user, language), style: text.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            ReportActionButton(onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.reportComingNext)))),
            ...pull.when(
              loading: () => [const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))],
              error: (error, _) => [EmptyState(message: '$error', actionLabel: l10n.tryAgain, onAction: () => ref.invalidate(pullDataProvider))],
              data: (data) => [
                if (data.fromCache) Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(l10n.showingSavedData, style: text.bodySmall),
                ),
                SectionHeader(l10n.alertsNearYou),
                ListGroup(children: [
                  if (data.advisories.isEmpty) EmptyState(message: l10n.noAlertsNearYou),
                  for (final advisory in data.advisories)
                    AlertRow(
                      severity: Severity.urgent,
                      summary: advisory['text'] as String,
                      meta: timeAgo(l10n, DateTime.parse(advisory['sent_at'] as String)),
                    ),
                ]),
                if (sevak) ...[
                  SectionHeader(l10n.vaccinationsDue),
                  _VaccinationsDue(data.vaccinationsDue, language),
                ] else ...[
                  SectionHeader(l10n.myAnimals),
                  _AnimalList(animals: data.animals, due: data.vaccinationsDue, language: language),
                ],
                SectionHeader(l10n.myReports),
                ListGroup(children: [
                  if (data.cases.isEmpty) EmptyState(message: l10n.noReports),
                  for (final c in data.cases.take(10))
                    AlertRow(
                      severity: SeverityStyle.parse(c['severity'] as String?),
                      summary: diseaseName(c['suspected_disease'] as String?),
                      meta: '${localized(c['village']?['name'], language)}, '
                          '${timeAgo(l10n, DateTime.parse(c['created_at'] as String))}. '
                          '${statusLabel(l10n, c['status'] as String)}',
                    ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalList extends StatelessWidget {
  const _AnimalList({required this.animals, required this.due, required this.language});

  final List<Json> animals;
  final List<Json> due;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (animals.isEmpty) return ListGroup(children: [EmptyState(message: l10n.noAnimals)]);
    final nextDue = <String, Json>{};
    for (final v in due) {
      nextDue.putIfAbsent(v['animal_id'] as String, () => v);
    }
    return ListGroup(children: [
      for (final animal in animals.where((a) => a['ear_tag'] != null).take(8))
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EarTagChip(animal['ear_tag'] as String),
                Text([animal['name'], animal['breed']].whereType<String>().join(', '), style: text.titleMedium),
              ],
            ),
            if (nextDue[animal['id']] case final v?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(l10n.vaccineDueOn(v['vaccine'] as String, shortDate(v['due_on'] as String, language)),
                    style: text.bodyLarge),
              ),
          ]),
        ),
    ]);
  }
}

class _VaccinationsDue extends StatelessWidget {
  const _VaccinationsDue(this.due, this.language);

  final List<Json> due;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (due.isEmpty) return ListGroup(children: [EmptyState(message: l10n.noVaccinationsDue)]);
    return ListGroup(children: [
      for (final v in due.take(8))
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            if (v['ear_tag'] != null) ...[EarTagChip(v['ear_tag'] as String), const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Text(l10n.vaccineDueOn(v['vaccine'] as String, shortDate(v['due_on'] as String, language)),
                  style: text.bodyLarge),
            ),
          ]),
        ),
    ]);
  }
}

/// Vet and district officer: the case queue with a compact KPI strip.
class ResponderHome extends ConsumerWidget {
  const ResponderHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final settings = ref.watch(settingsProvider);
    final queue = ref.watch(caseQueueProvider);
    final shared = ref.watch(sharedDataProvider).value;

    return HomeShell(
      onRefresh: () => ref.refresh(caseQueueProvider.future),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxxl),
        children: [
          Text(l10n.greeting(settings.user?['name'] as String? ?? ''), style: text.headlineMedium),
          Text(_place(settings.user, language).isEmpty
                  ? localized(settings.user?['district']?['name'], language)
                  : _place(settings.user, language),
              style: text.bodyLarge),
          ...queue.when(
            loading: () => [const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))],
            error: (error, _) => [EmptyState(message: '$error', actionLabel: l10n.tryAgain, onAction: () => ref.invalidate(caseQueueProvider))],
            data: (result) {
              final (cases, fromCache) = result;
              int count(bool Function(Json) test) => cases.where(test).length;
              return [
                const SizedBox(height: AppSpacing.lg),
                KpiStrip(items: [
                  KpiItem(value: '${cases.length}', label: l10n.kpiOpenCases),
                  KpiItem(value: '${count((c) => c['severity'] == 'emergency')}', label: l10n.kpiEmergency),
                  KpiItem(value: '${count((c) => c['severity'] == 'urgent')}', label: l10n.kpiUrgent),
                  KpiItem(value: '${count((c) => c['assigned_vet'] == null)}', label: l10n.kpiWaitingForVet),
                ]),
                if (fromCache) Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(l10n.showingSavedData, style: text.bodySmall),
                ),
                SectionHeader(l10n.caseQueue),
                ListGroup(children: [
                  if (cases.isEmpty) EmptyState(message: l10n.noCases),
                  for (final c in cases)
                    AlertRow(
                      severity: SeverityStyle.parse(c['severity'] as String?),
                      summary: c['suspected_disease'] == null
                          ? l10n.notMatched
                          : localized(shared?.rules[c['suspected_disease']]?['name'], language),
                      meta: '${localized(c['village']?['name'], language)}, '
                          '${localized(c['block']?['name'], language)}. '
                          '${timeAgo(l10n, DateTime.parse(c['created_at'] as String))}. '
                          '${c['assigned_vet'] == null ? l10n.waitingForVet : l10n.assignedTo(c['assigned_vet']['name'] as String)}',
                    ),
                ]),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// Lab staff: samples arrive here once vets request them (lab QR flow).
class LabHome extends ConsumerWidget {
  const LabHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    return HomeShell(
      onRefresh: () async {},
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(l10n.greeting(settings.user?['name'] as String? ?? ''), style: Theme.of(context).textTheme.headlineMedium),
          SectionHeader(l10n.labSamples),
          ListGroup(children: [EmptyState(message: l10n.noSamples)]),
        ],
      ),
    );
  }
}

/// Where each role lands after login.
String homeFor(String? role) => switch (role) {
      'farmer' => '/farmer',
      'pashu_sevak' => '/sevak',
      'vet' => '/vet',
      'lab' => '/lab',
      'district_officer' => '/officer',
      _ => '/login',
    };

