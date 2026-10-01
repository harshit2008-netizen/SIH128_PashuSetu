import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../home/formatting.dart';
import 'advisory_composer_screen.dart';
import 'map_widgets.dart';
import 'officer_data.dart';

/// One alert: where, the plain-language explanation, linked cases, and the
/// officer's next steps (acknowledge, send advisory).
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final alerts = ref.watch(alertsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabAlerts)),
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: '$e'),
        data: (list) {
          final alert = list.where((a) => a['id'] == alertId).firstOrNull;
          return alert == null ? EmptyState(message: l10n.noAlerts) : _AlertBody(alert: alert);
        },
      ),
    );
  }
}

class _AlertBody extends ConsumerStatefulWidget {
  const _AlertBody({required this.alert});

  final Json alert;

  @override
  ConsumerState<_AlertBody> createState() => _AlertBodyState();
}

class _AlertBodyState extends ConsumerState<_AlertBody> {
  bool _busy = false;

  Future<void> _acknowledge() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/alerts/${widget.alert['id']}/acknowledge');
      ref
        ..invalidate(alertsProvider)
        ..invalidate(dashboardSummaryProvider);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _sendAdvisory() {
    final shared = ref.read(sharedDataProvider).value;
    final explanation = widget.alert['explanation'] as Json;
    final center = widget.alert['center'] as Json;
    final villageEn = (explanation['village_names'] as List?)?.cast<String>().firstOrNull;
    // Cover the alert area plus a margin: neighbours need the warning most.
    final radius = (((explanation['radius_km'] as num?) ?? 0) + 5).clamp(5, 30).roundToDouble();
    context.push('/advisories/new', extra: AdvisoryDraft(
      templateId: shared == null ? null : templateForDisease(shared, widget.alert['disease'] as String?),
      center: LatLng((center['lat'] as num).toDouble(), (center['lng'] as num).toDouble()),
      radiusKm: radius,
      villageNames: shared == null || villageEn == null ? null : villageNamesByEnglish(shared, villageEn),
      disease: widget.alert['disease'] as String?,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final alert = widget.alert;
    final explanation = alert['explanation'] as Json;
    final area = ringOf(alert['area'] as Json);
    final caseIds = (alert['case_ids'] as List).cast<String>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxxl),
      children: [
        Wrap(spacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SeverityBadge(SeverityStyle.parse(alert['severity'] as String?), large: true),
          Text(alertTypeLabel(l10n, alert['type'] as String), style: text.titleMedium),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(localized(explanation['summary'], language), style: text.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text([
          ...((explanation['village_names'] as List?)?.cast<String>() ?? const []),
          timeAgo(l10n, DateTime.parse(alert['created_at'] as String)),
        ].join(', '), style: text.bodyLarge),
        // Shown only after the human health system accepted the webhook (never assumed).
        if (alert['one_health_notified_at'] != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            const Icon(LucideIcons.hospital, size: 18, color: AppColors.ink),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(l10n.oneHealthNotified(timeAgo(l10n, DateTime.parse(alert['one_health_notified_at'] as String))),
                  style: text.titleMedium),
            ),
          ]),
        ],
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.listGroup),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                  initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(area), padding: const EdgeInsets.all(24))),
              children: [
                osmTiles(),
                PolygonLayer(polygons: [alertPolygon({'geometry': alert['area'], 'properties': alert})]),
                osmAttribution(),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
          if (alert['status'] == 'open')
            FilledButton.icon(
              onPressed: _busy ? null : _acknowledge,
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink, minimumSize: const Size(0, AppTouch.minTarget)),
              icon: const Icon(LucideIcons.circleCheckBig, size: 18),
              label: Text(l10n.acknowledge),
            )
          else
            Chip(avatar: const Icon(LucideIcons.circleCheckBig, size: 18), label: Text(l10n.acknowledged)),
          OutlinedButton.icon(
            onPressed: _sendAdvisory,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.ink), minimumSize: const Size(0, AppTouch.minTarget)),
            icon: const Icon(LucideIcons.megaphone, size: 18),
            label: Text(l10n.sendAdvisory),
          ),
        ]),
        SectionHeader(l10n.casesInAlert),
        ListGroup(children: [for (final id in caseIds) _LinkedCase(caseId: id)]),
      ],
    );
  }
}

class _LinkedCase extends ConsumerWidget {
  const _LinkedCase({required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final c = ref.watch(caseDetailProvider(caseId)).value;
    if (c == null) return const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator());
    return AlertRow(
      severity: SeverityStyle.parse(c['severity'] as String?),
      summary: diseaseName(shared, c['suspected_disease'] as String?, language, l10n),
      meta: '${localized(c['village']?['name'], language)}. ${statusLabel(l10n, c['status'] as String)}',
      onTap: () => context.push('/cases/$caseId'),
    );
  }
}
