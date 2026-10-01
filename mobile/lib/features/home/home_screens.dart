import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/db/app_database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data.dart';
import '../../core/sync/sync_service.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../lab/lab_screens.dart' show SampleList, ScanButton;
import '../triage/ui/triage_result_screen.dart' show speak;
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
        // With the sync pill there is no room for the name next to the mark.
        title: AppMark(showName: !showSyncPill),
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
    final unsent = (ref.watch(outboxProvider).value ?? const []).where((r) => r.status != 'sent').toList();

    String diseaseName(String? id) =>
        id == null ? l10n.notMatched : localized(shared?.rules[id]?['name'], language);

    final padding = sevak ? AppSpacing.screenPadding : AppSpacing.farmerScreenPadding;
    return FarmerMode(
      enabled: !sevak,
      child: HomeShell(
        showSyncPill: true,
        onRefresh: () async {
          await ref.read(syncControllerProvider.notifier).syncNow(force: true);
          ref.invalidate(pullDataProvider);
          await ref.read(pullDataProvider.future);
        },
        body: ListView(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.xxxl),
          children: [
            Text(l10n.greeting(_firstName(settings.user)), style: text.headlineMedium),
            if (_place(settings.user, language).isNotEmpty) Text(_place(settings.user, language), style: text.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            ReportActionButton(onPressed: () => context.push('/report')),
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
                      severity: shared?.rules[advisory['disease']]?['severity_floor'] == 'emergency'
                          ? Severity.emergency
                          : Severity.urgent,
                      summary: advisory['text'] as String,
                      meta: timeAgo(l10n, DateTime.parse(advisory['sent_at'] as String)),
                      onListen: () => speak(advisory['text'] as String, language),
                    ),
                ]),
                if (sevak) ...[
                  SectionHeader(l10n.samplesToCollect),
                  const ScanButton(),
                  const SizedBox(height: AppSpacing.sm),
                  SampleList(emptyMessage: l10n.noSamplesToCollect),
                  SectionHeader(l10n.vaccinationsDue),
                  _VaccinationsDue(data.vaccinationsDue, language),
                  const _OpenHerds(),
                ] else ...[
                  SectionHeader(l10n.myAnimals),
                  _AnimalList(animals: data.animals, due: data.vaccinationsDue, language: language),
                  const _OpenHerds(),
                ],
                SectionHeader(l10n.myReports),
                ListGroup(children: [
                  // Reports still on the phone come first; tap to see their result again.
                  for (final row in unsent)
                    AlertRow(
                      severity: SeverityStyle.parse((jsonDecode(row.deviceTriage ?? '{}') as Map)['severity'] as String?),
                      summary: _outboxTitle(row, shared, language, l10n),
                      meta: '${timeAgo(l10n, row.createdAt)}. ${l10n.syncWaiting(1)}',
                      onTap: () => context.push('/triage/${row.clientUuid}'),
                    ),
                  if (data.cases.isEmpty && unsent.isEmpty) EmptyState(message: l10n.noReports),
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

String _outboxTitle(OutboxReport row, SharedData? shared, String language, AppLocalizations l10n) {
  final candidates = ((jsonDecode(row.deviceTriage ?? '{}') as Map)['candidates'] as List? ?? const []);
  if (candidates.isEmpty || ((candidates.first as Map)['score'] as num) < 0.4) return l10n.notMatched;
  return localized(shared?.rules[(candidates.first as Map)['disease_id']]?['name'], language);
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

/// Opens the herd list: animal profiles, vaccination history, "Vaccinated today".
class _OpenHerds extends StatelessWidget {
  const _OpenHerds();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.push('/herds'),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: Size(0, FarmerMode.minTarget(context))),
          icon: const Icon(LucideIcons.listChecks),
          label: Text(AppLocalizations.of(context).openHerds),
        ),
      );
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

/// Where each role lands after login.
String homeFor(String? role) => switch (role) {
      'farmer' => '/farmer',
      'pashu_sevak' => '/sevak',
      'vet' => '/vet',
      'lab' => '/lab',
      'district_officer' => '/officer',
      _ => '/login',
    };

