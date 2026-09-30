import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api/api_client.dart';
import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../auth/language_screen.dart' show PrimaryButton;
import '../home/home_screens.dart' show HomeShell;
import '../officer/officer_data.dart';

final _codePattern = RegExp(r'PS-S-[A-Z0-9]{6}');

/// Camera scanner for sample QR codes, with a typed-code fallback (for a
/// code shown on another phone, or when the camera is not allowed).
/// Returns the code.
class ScanSampleScreen extends StatefulWidget {
  const ScanSampleScreen({super.key});

  @override
  State<ScanSampleScreen> createState() => _ScanSampleScreenState();
}

class _ScanSampleScreenState extends State<ScanSampleScreen> {
  final _typed = TextEditingController(text: 'PS-S-');
  bool _done = false;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _finish(String code) {
    if (_done) return;
    _done = true;
    context.pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanSample)),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.screenPadding), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.listGroup),
          child: SizedBox(
            height: 320,
            child: MobileScanner(
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final match = _codePattern.firstMatch(barcode.rawValue ?? '');
                  if (match != null) return _finish(match.group(0)!);
                }
              },
              errorBuilder: (context, _) => Center(
                child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(l10n.cameraNotAllowed, textAlign: TextAlign.center)),
              ),
            ),
          ),
        ),
        SectionHeader(l10n.typeCodeInstead),
        TextField(
          controller: _typed,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')), LengthLimitingTextInputFormatter(11)],
          style: Theme.of(context).textTheme.titleLarge,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'PS-S-XXXXXX'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: l10n.continueButton2,
          onPressed: _codePattern.hasMatch(_typed.text.toUpperCase()) ? () => _finish(_typed.text.toUpperCase()) : null,
        ),
      ]),
    );
  }
}

/// Scan, then advance the sample (sevak: collected, lab: received). Shows the
/// outcome; for the lab it offers the result form straight away.
Future<void> scanAndAdvance(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final code = await context.push<String>('/scan');
  if (code == null || !context.mounted) return;
  try {
    final sample = await ref.read(apiClientProvider).post('/samples/$code/scan') as Json;
    ref.invalidate(samplesProvider);
    if (!context.mounted) return;
    final received = sample['status'] == 'received';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$code: ${received ? l10n.sampleReceived : l10n.sampleCollected}')));
    if (received) await showResultForm(context, ref, sample);
  } on ApiException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

Future<void> showResultForm(BuildContext context, WidgetRef ref, Json sample) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ResultForm(sample: sample),
      ),
    );

class _ResultForm extends ConsumerStatefulWidget {
  const _ResultForm({required this.sample});

  final Json sample;

  @override
  ConsumerState<_ResultForm> createState() => _ResultFormState();
}

class _ResultFormState extends ConsumerState<_ResultForm> {
  String _result = 'positive';
  String? _disease;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _disease = widget.sample['case']?['suspected_disease'] as String?;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/samples/${widget.sample['qr_code']}/result', body: {
        'result': _result,
        'disease': _result == 'positive' ? _disease : null,
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
      });
      ref.invalidate(samplesProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resultSaved)));
    } on ApiException catch (e) {
      setState(() { _error = e.message; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    return SafeArea(
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(AppSpacing.lg), children: [
        Text('${l10n.enterResult}: ${widget.sample['qr_code']}', style: text.titleLarge),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'positive', label: Text(l10n.resultPositive)),
            ButtonSegment(value: 'negative', label: Text(l10n.resultNegative)),
            ButtonSegment(value: 'inconclusive', label: Text(l10n.resultInconclusive)),
          ],
          selected: {_result},
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.ink, selectedForegroundColor: AppColors.paper, minimumSize: const Size(0, AppTouch.minTarget)),
          onSelectionChanged: (v) => setState(() => _result = v.first),
        ),
        if (_result == 'positive') ...[
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _disease,
            decoration: InputDecoration(labelText: l10n.whichDisease, border: const OutlineInputBorder()),
            items: [
              for (final id in shared?.rules.keys ?? const <String>[])
                DropdownMenuItem(value: id, child: Text(localized(shared!.rules[id]!['name'], language))),
            ],
            onChanged: (v) => setState(() => _disease = v),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextField(controller: _note, decoration: InputDecoration(labelText: l10n.noteOptional, border: const OutlineInputBorder())),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(_error!, style: TextStyle(color: SeverityColors.emergency.foreground))),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: l10n.saveResult, busy: _busy, onPressed: _result == 'positive' && _disease == null ? null : _save),
      ]),
    );
  }
}

/// Samples list for the sevak (to collect) and the lab (on the way / waiting).
class SampleList extends ConsumerWidget {
  const SampleList({super.key, required this.emptyMessage});

  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final isLab = ref.watch(settingsProvider).role == 'lab';
    final samples = ref.watch(samplesProvider);
    return samples.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => EmptyState(message: '$e'),
      data: (list) => ListGroup(children: [
        if (list.isEmpty) EmptyState(message: emptyMessage),
        for (final s in list)
          AlertRow(
            severity: SeverityStyle.parse(s['case']?['severity'] as String?),
            summary: '${s['qr_code']}  ${sampleTypeLabel(l10n, s['sample_type'] as String)}',
            meta: '${diseaseName(shared, s['case']?['suspected_disease'] as String?, language, l10n)}, '
                '${localized(s['case']?['village']?['name'], language)}. ${sampleStatusLabel(l10n, s['status'] as String)}',
            onTap: isLab && s['status'] == 'received' ? () => showResultForm(context, ref, s) : () => context.push('/cases/${s['case_id']}'),
          ),
      ]),
    );
  }
}

class ScanButton extends ConsumerWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FilledButton.icon(
        onPressed: () => scanAndAdvance(context, ref),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(AppTouch.farmerMinTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction)),
        ),
        icon: const Icon(LucideIcons.scanQrCode),
        label: Text(AppLocalizations.of(context).scanSample),
      );
}

/// Lab home: scan incoming samples, enter results.
class LabHome extends ConsumerWidget {
  const LabHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    return HomeShell(
      onRefresh: () => ref.refresh(samplesProvider.future),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.screenPadding), children: [
        Text(l10n.greeting(settings.user?['name'] as String? ?? ''), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        const ScanButton(),
        SectionHeader(l10n.samplesAtLab),
        SampleList(emptyMessage: l10n.noSamples),
      ]),
    );
  }
}
