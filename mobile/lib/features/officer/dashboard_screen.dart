import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../home/formatting.dart';
import '../home/home_data.dart' show caseQueueProvider;
import 'map_widgets.dart';
import 'officer_data.dart';
import 'risk_list.dart';

/// Vet and district officer home: district map, KPIs, alerts and cases.
/// Polls every 10 s while visible (fine for the demo; no push service yet).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

enum _Tab { alerts, cases, risk }

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _refreshEvery = Duration(seconds: 10);
  Timer? _timer;
  DateTime _updatedAt = DateTime.now();
  _Tab _tab = _Tab.alerts;
  String _riskDisease = 'lsd';
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_refreshEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    ref
      ..invalidate(dashboardSummaryProvider)
      ..invalidate(dashboardMapProvider)
      ..invalidate(alertsProvider)
      ..invalidate(caseQueueProvider)
      ..invalidate(riskProvider);
    setState(() => _updatedAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final map = ref.watch(dashboardMapProvider).value;
    final bounds = boundsOf(map?['bounds'] as Json?);
    final features = ((map?['features'] as List?) ?? const []).cast<Json>();
    final isOfficer = ref.watch(settingsProvider).role == 'district_officer';
    final risk = _tab == _Tab.risk ? ref.watch(riskProvider(_riskDisease)).value : null;
    return Scaffold(
      appBar: AppBar(
        title: const AppMark(),
        actions: [
          IconButton(
            tooltip: l10n.sendAdvisory,
            onPressed: () => context.push('/advisories/new'),
            icon: const Icon(LucideIcons.megaphone),
          ),
          IconButton(
              tooltip: l10n.settings,
              onPressed: () => context.push('/settings'),
              icon: const Icon(LucideIcons.settings)),
        ],
      ),
      body: Stack(children: [
        if (bounds != null)
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.fromLTRB(24, 140, 24, 320)),
            ),
            children: [
              osmTiles(),
              // Risk: a circle at each block centre (no invented boundaries, spec 10.7).
              if (risk != null)
                CircleLayer(circles: [
                  for (final b in (risk['blocks'] as List).cast<Json>())
                    CircleMarker(
                      point: LatLng((b['centroid']['lat'] as num).toDouble(), (b['centroid']['lng'] as num).toDouble()),
                      radius: 6000,
                      useRadiusInMeter: true,
                      color: riskColors(b['level'] as String).edge.withValues(alpha: 0.35),
                      borderColor: riskColors(b['level'] as String).edge,
                      borderStrokeWidth: 2,
                    ),
                ]),
              PolygonLayer(polygons: [
                for (final f in features)
                  if (f['properties']['kind'] == 'alert') alertPolygon(f),
              ]),
              MarkerLayer(markers: [
                for (final f in features)
                  if (f['properties']['kind'] == 'case')
                    caseMarker(f, onTap: () => context.push('/cases/${f['properties']['id']}')),
              ]),
              osmAttribution(),
            ],
          )
        else
          const Center(child: CircularProgressIndicator()),
        Positioned(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.sm,
          child: _Kpis(updatedAt: _updatedAt),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.16,
          maxChildSize: 0.92,
          builder: (context, scroll) => Material(
            elevation: 3,
            color: AppColors.limewash,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxxl),
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<_Tab>(
                  segments: [
                    ButtonSegment(value: _Tab.alerts, label: Text(l10n.tabAlerts), icon: const Icon(LucideIcons.siren)),
                    ButtonSegment(value: _Tab.cases, label: Text(l10n.tabCases), icon: const Icon(LucideIcons.inbox)),
                    if (isOfficer)
                      ButtonSegment(value: _Tab.risk, label: Text(l10n.tabRisk), icon: const Icon(LucideIcons.gauge)),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.ink,
                    selectedForegroundColor: AppColors.paper,
                    backgroundColor: AppColors.paper,
                    minimumSize: const Size(0, AppTouch.minTarget),
                  ),
                  onSelectionChanged: (value) => setState(() => _tab = value.first),
                ),
                const SizedBox(height: AppSpacing.md),
                switch (_tab) {
                  _Tab.alerts => const _AlertList(),
                  _Tab.cases => const _CaseList(),
                  _Tab.risk => RiskList(
                      disease: _riskDisease, onDisease: (d) => setState(() => _riskDisease = d)),
                },
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _Kpis extends ConsumerWidget {
  const _Kpis({required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(dashboardSummaryProvider).value;
    final median = summary?['median_minutes_to_first_response'] as int?;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      KpiStrip(items: [
        KpiItem(value: '${summary?['open_cases'] ?? '–'}', label: l10n.kpiOpenCases),
        KpiItem(value: '${summary?['active_alerts'] ?? '–'}', label: l10n.kpiActiveAlerts),
        KpiItem(value: median == null ? '–' : _duration(l10n, median), label: l10n.kpiMedianResponse),
        KpiItem(value: '${summary?['samples_pending'] ?? '–'}', label: l10n.kpiSamplesPending),
      ]),
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.paper.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
          child: Text(l10n.updatedAt(timeAgo(l10n, updatedAt)), style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    ]);
  }
}

/// "45 min" under 1.5 hours, otherwise "22 h", so the KPI stays one short word.
String _duration(AppLocalizations l10n, int minutes) =>
    minutes < 90 ? l10n.minutesShort(minutes) : l10n.hoursShort((minutes / 60).round());

class _AlertList extends ConsumerWidget {
  const _AlertList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final alerts = ref.watch(alertsProvider);
    return alerts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: '$e'),
      data: (list) => ListGroup(children: [
        if (list.isEmpty) EmptyState(message: l10n.noAlerts),
        for (final alert in list)
          AlertRow(
            severity: SeverityStyle.parse(alert['severity'] as String?),
            summary: localized(alert['explanation']['summary'], language),
            meta: '${alertTypeLabel(l10n, alert['type'] as String)}. '
                '${timeAgo(l10n, DateTime.parse(alert['updated_at'] as String))}'
                '${alert['status'] == 'acknowledged' ? '. ${l10n.acknowledged}' : ''}',
            onTap: () => context.push('/alerts/${alert['id']}'),
          ),
      ]),
    );
  }
}

class _CaseList extends ConsumerWidget {
  const _CaseList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final queue = ref.watch(caseQueueProvider);
    final isVet = ref.watch(settingsProvider).role == 'vet';
    final escalated = ref.watch(dashboardSummaryProvider).value?['escalated'] as int? ?? 0;
    return queue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: '$e'),
      data: (result) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (escalated > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(l10n.escalatedCount(escalated),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SeverityColors.emergency.foreground)),
          ),
        ListGroup(children: [
        if (result.$1.isEmpty) EmptyState(message: l10n.noCases),
        for (final c in result.$1)
          AlertRow(
            severity: SeverityStyle.parse(c['severity'] as String?),
            summary: diseaseName(shared, c['suspected_disease'] as String?, language, l10n),
            meta: '${localized(c['village']?['name'], language)}${isVet ? '' : ', ${localized(c['block']?['name'], language)}'}. '
                '${timeAgo(l10n, DateTime.parse(c['created_at'] as String))}. ${statusLabel(l10n, c['status'] as String)}'
                '${(c['escalation_level'] as int? ?? 0) > 0 ? '. ${l10n.escalatedBadge}' : ''}',
            onTap: () => context.push('/cases/${c['id']}'),
          ),
        ]),
      ]),
    );
  }
}
