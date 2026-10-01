import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api/api_client.dart';
import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../home/formatting.dart';
import '../home/home_data.dart' show caseQueueProvider;
import '../officer/officer_data.dart';

const _sampleTypes = ['skin_scab', 'blood', 'nasal_swab', 'oral_swab', 'tissue', 'carcass_swab', 'other'];

/// One case: what was reported, why the app suspected it, the timeline,
/// samples, and only the actions this role may take now (spec 9.8).
class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(caseDetailProvider(caseId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabCases)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: '$e', actionLabel: l10n.tryAgain, onAction: () => ref.invalidate(caseDetailProvider(caseId))),
        data: (c) => RefreshIndicator(
          onRefresh: () => ref.refresh(caseDetailProvider(caseId).future),
          child: _CaseBody(data: c),
        ),
      ),
    );
  }
}

class _CaseBody extends ConsumerWidget {
  const _CaseBody({required this.data});

  final Json data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final settings = ref.watch(settingsProvider);
    final severity = SeverityStyle.parse(data['severity'] as String?);
    final report = (data['reports'] as List).cast<Json>().first;
    final triage = data['triage'] as Json?;
    final samples = (data['samples'] as List).cast<Json>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxxl),
      children: [
        Text(
          data['suspected_disease'] == null
              ? l10n.notMatched
              : l10n.suspectedDisease(diseaseName(shared, data['suspected_disease'] as String?, language, l10n)),
          style: text.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SeverityBadge(severity, large: true),
          Text(statusLabel(l10n, data['status'] as String), style: text.titleMedium),
        ]),
        // Nobody responded within the SLA, so the case moved up a level (spec 8.6).
        if ((data['escalation_level'] as int? ?? 0) > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(data['escalation_level'] == 1 ? l10n.escalatedToBlock : l10n.escalatedToDistrict,
              style: text.titleMedium?.copyWith(color: SeverityColors.emergency.foreground)),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text('${localized(data['village']?['name'], language)}, ${localized(data['block']?['name'], language)}. '
            '${timeAgo(l10n, DateTime.parse(report['created_on_device_at'] as String))}', style: text.bodyLarge),
        if (data['reporter'] != null) Text(l10n.reportedBy(data['reporter']['name'] as String), style: text.bodySmall),
        if (data['assigned_vet'] != null) Text(l10n.assignedTo(data['assigned_vet']['name'] as String), style: text.bodySmall),
        if (data['confirmed_disease'] != null) ...[
          const SizedBox(height: AppSpacing.md),
          _Banner(colors: SeverityColors.ok, icon: LucideIcons.flaskConical,
              text: l10n.labConfirmed(diseaseName(shared, data['confirmed_disease'] as String?, language, l10n))),
        ],
        if (triage?['safety_note'] != null) ...[
          const SizedBox(height: AppSpacing.md),
          SafetyBanner(text: localized(triage!['safety_note'], language)),
        ],
        _Actions(data: data, role: settings.role ?? ''),
        if (report['has_photo'] == true) ...[
          SectionHeader(l10n.reportPhoto),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.listGroup),
            child: Image.network('${settings.apiBaseUrl}/api/v1/reports/${report['id']}/photo',
                headers: {'Authorization': 'Bearer ${settings.token}'}, height: 240, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        ],
        if (triage != null && shared != null) ...[
          SectionHeader(l10n.whyAppSuspected),
          ..._candidateBars(triage, shared, language),
          WhyChips(matched: [
            for (final id in (report['symptoms'] as List).cast<String>())
              WhyChip(label: localized(shared.symptoms[id]?['label'], language), pictogram: shared.symptoms[id]?['pictogram'] as String?),
          ]),
          if (triage['photo'] case {'p_lsd': final num p, 'unclear': final bool unclear})
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(unclear ? l10n.photoUnclear : l10n.photoResultLine(photoPercent(p)), style: text.bodyLarge),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.notDiagnosis, style: text.bodySmall),
        ],
        if (samples.isNotEmpty) ...[
          SectionHeader(l10n.samplesTitle),
          for (final s in samples) _SampleCard(sample: s),
        ],
        SectionHeader(l10n.timelineTitle),
        CaseTimeline(severity: severity, steps: [
          for (final (i, e) in (data['timeline'] as List).cast<Json>().indexed)
            TimelineStep(
              label: timelineLabel(l10n, e),
              state: i == (data['timeline'] as List).length - 1 ? TimelineState.current : TimelineState.done,
              detail: [
                if (e['actor'] != null) e['actor']['name'],
                timeAgo(l10n, DateTime.parse(e['at'] as String)),
              ].join(', '),
            ),
        ]),
      ],
    );
  }

  List<Widget> _candidateBars(Json triage, SharedData shared, String language) => [
        for (final c in (triage['candidates'] as List).cast<Json>())
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ConfidenceBar(
              label: localized(shared.rules[c['disease_id']]?['name'], language),
              score: (c['score'] as num).toDouble(),
              confidence: c['confidence'] as String,
            ),
          ),
      ];
}

class _Banner extends StatelessWidget {
  const _Banner({required this.colors, required this.icon, required this.text});

  final SeverityColors colors;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.listGroup),
          border: Border(left: BorderSide(color: colors.edge, width: 6)),
        ),
        child: Row(children: [
          Icon(icon, color: colors.foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.foreground))),
        ]),
      );
}

class _SampleCard extends ConsumerWidget {
  const _SampleCard({required this.sample});

  final Json sample;

  /// The vet (or sevak) who took the sample marks it collected here, no scanner needed.
  Future<void> _markCollected(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiClientProvider).post('/samples/${sample['qr_code']}/scan');
      messenger.showSnackBar(SnackBar(content: Text('${sample['qr_code']}: ${l10n.sampleCollected}')));
      ref
        ..invalidate(caseDetailProvider(sample['case_id'] as String))
        ..invalidate(samplesProvider);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(settingsProvider).role;
    final text = Theme.of(context).textTheme;
    final code = sample['qr_code'] as String;
    final waiting = sample['status'] == 'requested';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListGroup(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${sampleTypeLabel(l10n, sample['sample_type'] as String)}: ${sampleStatusLabel(l10n, sample['status'] as String)}',
                style: text.titleMedium),
            if (sample['result'] != null)
              Text(switch (sample['result']) {
                'positive' => l10n.resultPositive,
                'negative' => l10n.resultNegative,
                _ => l10n.resultInconclusive,
              }, style: text.bodyLarge),
            if (waiting) ...[
              const SizedBox(height: AppSpacing.md),
              // Big QR for the sevak to scan off this screen, plus the code in words.
              Center(child: QrImageView(data: code, size: 200, backgroundColor: AppColors.paper, semanticsLabel: code)),
              Center(child: Text(code, style: text.displayMedium?.copyWith(fontSize: 28))),
              Text(l10n.showQrHint, style: text.bodySmall, textAlign: TextAlign.center),
              if (role == 'vet' || role == 'pashu_sevak') ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => _markCollected(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.ink),
                    minimumSize: const Size.fromHeight(AppTouch.minTarget),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction)),
                  ),
                  icon: const Icon(LucideIcons.packageCheck),
                  label: Text(l10n.markCollected),
                ),
              ],
            ] else
              Text(code, style: text.bodySmall),
          ]),
        ),
      ]),
    );
  }
}

/// Only the actions this role may take for the case's current status.
class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.data, required this.role});

  final Json data;
  final String role;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  bool _busy = false;

  String get _id => widget.data['id'] as String;
  String get _status => widget.data['status'] as String;

  Future<void> _run(Future<void> Function(ApiClient api) call) async {
    setState(() => _busy = true);
    try {
      await call(ref.read(apiClientProvider));
      ref
        ..invalidate(caseDetailProvider(_id))
        ..invalidate(caseQueueProvider)
        ..invalidate(dashboardSummaryProvider)
        ..invalidate(dashboardMapProvider);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestSample() async {
    final l10n = AppLocalizations.of(context);
    final type = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
      builder: (context) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(l10n.chooseSampleType, style: Theme.of(context).textTheme.titleLarge)),
          for (final t in _sampleTypes)
            ListTile(minTileHeight: AppTouch.minTarget + 8, title: Text(sampleTypeLabel(l10n, t)), onTap: () => Navigator.pop(context, t)),
        ]),
      ),
    );
    if (type != null) await _run((api) => api.post('/cases/$_id/samples', body: {'sample_type': type}));
  }

  Future<void> _assignVet() async {
    final l10n = AppLocalizations.of(context);
    final language = ref.read(languageProvider);
    final vets = await ref.read(vetsProvider.future);
    if (!mounted) return;
    final vetId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      // Keep tall sheets below the status bar.
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scroll) => ListView(controller: scroll, children: [
          Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(l10n.chooseVet, style: Theme.of(context).textTheme.titleLarge)),
          for (final v in vets)
            ListTile(
              minTileHeight: AppTouch.minTarget + 8,
              title: Text(v['name'] as String),
              subtitle: Text(localized(v['block']['name'], language)),
              onTap: () => Navigator.pop(context, v['id'] as String),
            ),
        ]),
      ),
    );
    if (vetId != null) await _run((api) => api.post('/cases/$_id/assign', body: {'vet_id': vetId}));
  }

  Future<void> _transition(String to) => _run((api) => api.post('/cases/$_id/transition', body: {'to_status': to}));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final closed = _status == 'resolved' || _status == 'closed_ruled_out';
    if (closed || !(widget.role == 'vet' || widget.role == 'district_officer')) return const SizedBox.shrink();
    final buttons = <(String, IconData, VoidCallback, bool)>[
      if (widget.role == 'vet' && _status == 'triaged') (l10n.assignToMe, LucideIcons.userCheck, () => _run((api) => api.post('/cases/$_id/assign', body: {})), true),
      if (widget.role == 'district_officer') (l10n.assignVet, LucideIcons.userCheck, _assignVet, _status == 'triaged'),
      if (widget.role == 'vet' && const {'triaged', 'vet_assigned', 'under_treatment'}.contains(_status))
        (l10n.requestSample, LucideIcons.flaskConical, _requestSample, _status != 'triaged'),
      if (const {'vet_assigned', 'lab_result'}.contains(_status)) (l10n.markUnderTreatment, LucideIcons.stethoscope, () => _transition('under_treatment'), false),
      if (const {'lab_result', 'under_treatment'}.contains(_status)) (l10n.resolveCase, LucideIcons.circleCheckBig, () => _transition('resolved'), false),
      if (const {'triaged', 'vet_assigned', 'sample_requested', 'lab_result', 'under_treatment'}.contains(_status))
        (l10n.ruleOut, LucideIcons.ban, () => _transition('closed_ruled_out'), false),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        for (final (label, icon, onPressed, primary) in buttons)
          primary
              ? FilledButton.icon(
                  onPressed: _busy ? null : onPressed,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.ink, minimumSize: const Size(0, AppTouch.minTarget)),
                  icon: Icon(icon, size: 18),
                  label: Text(label))
              : OutlinedButton.icon(
                  onPressed: _busy ? null : onPressed,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.ink), minimumSize: const Size(0, AppTouch.minTarget)),
                  icon: Icon(icon, size: 18),
                  label: Text(label)),
      ]),
    );
  }
}
