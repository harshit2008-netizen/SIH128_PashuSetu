import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../auth/language_screen.dart' show PrimaryButton;
import '../home/home_data.dart';
import '../triage/engine/fusion.dart';
import '../triage/engine/rule_engine.dart';
import 'report_draft.dart';
import 'voice/voice_sheet.dart';

/// The 5-step report (spec 9.8): 1 Animal, 2 Signs, 3 Photo, 4 How many, 5 Check and send.
class ReportFlowScreen extends ConsumerStatefulWidget {
  const ReportFlowScreen({super.key});

  @override
  ConsumerState<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class _ReportFlowScreenState extends ConsumerState<ReportFlowScreen> {
  int _step = 0;
  bool _sending = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final shared = await ref.read(sharedDataProvider.future);
      final home = ref.read(settingsProvider).user?['village']?['name']?['en'] as String?;
      ref.read(reportDraftProvider.notifier).start(villagesFromShared(shared.geo), home);
    });
  }

  bool _canGoOn(ReportDraft draft) => switch (_step) {
        0 => draft.species != null && draft.village != null,
        _ => true,
      };

  Future<void> _send() async {
    final draft = ref.read(reportDraftProvider);
    if (draft.problem != null) {
      setState(() => _problem = draft.problem);
      return;
    }
    setState(() => _sending = true);
    final clientUuid = await ref.read(reportDraftProvider.notifier).submit();
    ref.invalidate(pullDataProvider);
    if (mounted) context.pushReplacement('/triage/$clientUuid');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farmer = ref.watch(settingsProvider).role == 'farmer';
    final draft = ref.watch(reportDraftProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final steps = [l10n.stepAnimal, l10n.stepSigns, l10n.stepPhoto, l10n.stepCount, l10n.stepCheck];
    final padding = farmer ? AppSpacing.farmerScreenPadding : AppSpacing.screenPadding;
    final isLast = _step == steps.length - 1;
    return FarmerMode(
      enabled: farmer,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.reportActionTitle)),
        body: shared == null
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                _StepHeader(steps: steps, current: _step),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, AppSpacing.xl),
                    children: [
                      switch (_step) {
                        0 => _AnimalStep(shared: shared),
                        1 => _SignsStep(shared: shared),
                        2 => const _PhotoStep(),
                        3 => const _CountStep(),
                        _ => _CheckStep(shared: shared, problem: _problem),
                      },
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.md),
                    child: Row(children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _step--),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(AppTouch.farmerMinTarget),
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(color: AppColors.ink),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction)),
                            ),
                            child: Text(l10n.back),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: isLast ? l10n.sendReport : l10n.next,
                          busy: _sending,
                          onPressed: !_canGoOn(draft)
                              ? null
                              : isLast
                                  ? _send
                                  : () => setState(() {
                                        _step++;
                                        _problem = null;
                                      }),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
      ),
    );
  }
}

/// Numbered progress: a true sequence, so numbers are right here (spec 9.8).
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.steps, required this.current});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${current + 1} / ${steps.length}: ${steps[current]}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) Expanded(child: Container(height: 2, color: i <= current ? AppColors.ink : AppColors.line)),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current ? AppColors.ink : AppColors.paper,
                  border: Border.all(color: i <= current ? AppColors.ink : AppColors.line, width: i == current ? 2.5 : 1.5),
                ),
                child: Text('${i + 1}',
                    style: text.labelMedium?.copyWith(
                        height: 1, color: i < current ? AppColors.paper : (i == current ? AppColors.ink : AppColors.inkMuted))),
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text('${current + 1}. ${steps[current]}', style: text.titleLarge),
        ]),
      ),
    );
  }
}

class _AnimalStep extends ConsumerWidget {
  const _AnimalStep({required this.shared});

  final SharedData shared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final draft = ref.watch(reportDraftProvider);
    final controller = ref.read(reportDraftProvider.notifier);
    final animals = (ref.watch(pullDataProvider).value?.animals ?? const [])
        .where((a) => a['species'] == draft.species && a['ear_tag'] != null)
        .take(12)
        .toList();
    final village = draft.village;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.whichSpecies, style: text.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      SpeciesPicker(
        options: [
          for (final s in shared.species.values)
            SpeciesOption(id: s['id'] as String, label: localized(s['name'], language), pictogram: s['pictogram'] as String),
        ],
        selectedId: draft.species,
        onSelected: controller.setSpecies,
      ),
      if (animals.isNotEmpty) ...[
        SectionHeader(l10n.whichAnimal),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
          for (final a in animals)
            ChoiceChip(
              selected: draft.animalId == a['id'],
              showCheckmark: false,
              backgroundColor: AppColors.paper,
              selectedColor: AppColors.indigoTint,
              side: BorderSide(color: draft.animalId == a['id'] ? AppColors.ink : AppColors.line),
              onSelected: (_) => controller.setAnimal(a['id'] as String, a['herd_id'] as String),
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                EarTagChip(a['ear_tag'] as String),
                if (a['name'] != null) ...[const SizedBox(width: 6), Text(a['name'] as String, style: text.titleMedium)],
              ]),
            ),
          ChoiceChip(
            selected: draft.animalId == null,
            showCheckmark: false,
            backgroundColor: AppColors.paper,
            selectedColor: AppColors.indigoTint,
            onSelected: (_) => controller.setAnimal(null, null),
            label: Text(l10n.notRegistered, style: text.titleMedium),
          ),
        ]),
      ],
      SectionHeader(l10n.whereIsAnimal),
      ListGroup(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            Icon(draft.locating ? LucideIcons.locateFixed : LucideIcons.mapPin, color: AppColors.ink),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (village != null)
                  Text('${localized(village.name, language)}, ${localized(village.name['block'], language)}',
                      style: text.titleMedium),
                Text(
                    draft.locating
                        ? l10n.findingLocation
                        : draft.gps != null
                            ? l10n.usingPhoneLocation
                            : l10n.usingVillageLocation,
                    style: text.bodySmall),
              ]),
            ),
            TextButton(
              onPressed: () => _pickVillage(context, ref),
              style: TextButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: Size(0, FarmerMode.minTarget(context))),
              child: Text(l10n.changeVillage),
            ),
          ]),
        ),
      ]),
    ]);
  }

  Future<void> _pickVillage(BuildContext context, WidgetRef ref) async {
    final language = ref.read(languageProvider);
    final villages = villagesFromShared(shared.geo)
      ..sort((a, b) => localized(a.name, language).compareTo(localized(b.name, language)));
    final chosen = await showModalBottomSheet<Village>(
      context: context,
      isScrollControlled: true,
      // Keep tall sheets below the status bar.
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, scroll) => ListView(controller: scroll, children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(AppLocalizations.of(context).chooseVillage, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final v in villages)
            ListTile(
              minTileHeight: AppTouch.minTarget + 8,
              title: Text(localized(v.name, language)),
              subtitle: Text(localized(v.name['block'], language)),
              onTap: () => Navigator.pop(context, v),
            ),
        ]),
      ),
    );
    if (chosen != null) ref.read(reportDraftProvider.notifier).setVillage(chosen);
  }
}

class _SignsStep extends ConsumerWidget {
  const _SignsStep({required this.shared});

  final SharedData shared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final draft = ref.watch(reportDraftProvider);
    final controller = ref.read(reportDraftProvider.notifier);
    final signs = shared.symptoms.values.where((s) => (s['species'] as List).contains(draft.species));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.signsTitle, style: Theme.of(context).textTheme.headlineMedium),
      Text(l10n.signsHint, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: AppSpacing.md),
      // Voice fills the same tiles below; the reporter can still untick them.
      OutlinedButton.icon(
        onPressed: () => showVoiceSheet(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          minimumSize: const Size.fromHeight(AppTouch.farmerMinTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction)),
        ),
        icon: const Icon(LucideIcons.mic),
        label: Text(l10n.speakInstead),
      ),
      const SizedBox(height: AppSpacing.md),
      SymptomGrid(children: [
        for (final s in signs)
          SymptomTile(
            label: localized(s['label'], language),
            pictogram: s['pictogram'] as String,
            selected: draft.symptoms.contains(s['id']),
            onTap: () => controller.toggleSymptom(s['id'] as String),
            onHelp: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                icon: Pictogram(s['pictogram'] as String, size: 72),
                title: Text(localized(s['label'], language)),
                content: Text(localized(s['short_help'], language), style: Theme.of(context).textTheme.bodyLarge),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done))],
              ),
            ),
          ),
      ]),
    ]);
  }
}

class _PhotoStep extends ConsumerStatefulWidget {
  const _PhotoStep();

  @override
  ConsumerState<_PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends ConsumerState<_PhotoStep> {
  String? _error;

  /// Camera, or a photo already in the gallery (taken earlier, or sent by a
  /// farmer on WhatsApp). Both are shrunk (max 1280 px, JPEG 80) so they send
  /// on a weak signal.
  Future<void> _pickPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final XFile? shot;
    try {
      shot = await ImagePicker().pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 80);
    } catch (_) {
      setState(() => _error = l10n.cameraDenied);
      return;
    }
    if (shot == null) return;
    // Keep a copy in the app's own folder: the camera's temp file can vanish.
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'report_photos'));
    await dir.create(recursive: true);
    final saved = await File(shot.path).copy(p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg'));
    ref.read(reportDraftProvider.notifier).setPhoto(saved.path);
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final photo = ref.watch(reportDraftProvider).photoPath;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.photoTitle, style: text.headlineMedium),
      Text(l10n.photoHelp, style: text.bodyLarge),
      const SizedBox(height: AppSpacing.lg),
      if (photo != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.listGroup),
          child: Image.file(File(photo), height: 280, fit: BoxFit.cover),
        ),
      const _PhotoCheckPanel(),
      const SizedBox(height: AppSpacing.md),
      PrimaryButton(label: photo == null ? l10n.takePhoto : l10n.retakePhoto, onPressed: () => _pickPhoto(ImageSource.camera)),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        onPressed: () => _pickPhoto(ImageSource.gallery),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink),
          minimumSize: const Size.fromHeight(AppTouch.farmerMinTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction)),
        ),
        icon: const Icon(LucideIcons.image),
        label: Text(l10n.uploadPhoto),
      ),
      if (photo != null)
        TextButton.icon(
          onPressed: () => ref.read(reportDraftProvider.notifier).setPhoto(null),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: const Size.fromHeight(AppTouch.minTarget)),
          icon: const Icon(LucideIcons.trash2),
          label: Text(l10n.removePhoto),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(_error!, style: text.bodyLarge?.copyWith(color: SeverityColors.emergency.foreground)),
        ),
    ]);
  }
}

/// What the on-phone photo model saw, right under the photo (spec 7.9, 10.6):
/// a small inline progress line, then one plain sentence, and when the photo
/// shows lumps the reporter did not tick, the "Did you see lumps?" question.
class _PhotoCheckPanel extends ConsumerWidget {
  const _PhotoCheckPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final draft = ref.watch(reportDraftProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final check = draft.photoCheck;
    if (check == null || shared == null) return const SizedBox.shrink();
    final fusion = FusionEngine(RuleEngine(shared));

    Widget line(IconData icon, String message, SeverityColors colors) => Container(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(AppRadius.input)),
          child: Row(children: [
            Icon(icon, color: colors.foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: text.titleMedium?.copyWith(color: colors.foreground))),
          ]),
        );

    switch (check.status) {
      case PhotoCheckStatus.checking:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.photoChecking, style: text.bodyLarge)),
          ]),
        );
      case PhotoCheckStatus.failed:
        return line(LucideIcons.imageOff, l10n.photoCheckFailed, SeverityColors.routine);
      case PhotoCheckStatus.done:
        final flags = fusion.photoFlags(check.pLsd!, draft.symptoms);
        // Outside the "unclear" band one label clearly wins, so the larger side decides.
        final looksLsd = check.pLsd! >= 0.5;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (flags['unclear'] == true)
            line(LucideIcons.sunMedium, l10n.photoUnclear, SeverityColors.routine)
          else if (looksLsd)
            line(LucideIcons.scanSearch, l10n.photoLooksLsd, SeverityColors.urgent)
          else
            line(LucideIcons.circleCheck, l10n.photoLooksHealthy, SeverityColors.ok),
          if (flags['ask_about_skin_nodules'] == true && !check.lumpsAnswered)
            _AskAboutLumps(sign: fusion.askSign),
        ]);
    }
  }
}

class _AskAboutLumps extends ConsumerWidget {
  const _AskAboutLumps({required this.sign});

  final String sign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(reportDraftProvider.notifier);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction));
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.listGroup),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.askLumps, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => controller.answerLumps(seen: true, sign: sign),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink, minimumSize: Size.fromHeight(FarmerMode.minTarget(context)), shape: shape),
              child: Text(l10n.askLumpsYes),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton(
              onPressed: () => controller.answerLumps(seen: false, sign: sign),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.ink),
                minimumSize: Size.fromHeight(FarmerMode.minTarget(context)),
                shape: shape,
              ),
              child: Text(l10n.askLumpsNo),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _CountStep extends ConsumerWidget {
  const _CountStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final draft = ref.watch(reportDraftProvider);
    final controller = ref.read(reportDraftProvider.notifier);
    final total = draft.total ?? draft.sick + draft.dead;
    final onsets = {
      Onset.today: l10n.onsetToday,
      Onset.yesterday: l10n.onsetYesterday,
      Onset.fewDays: l10n.onsetFewDays,
      Onset.longer: l10n.onsetLonger,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.howManyTitle, style: text.headlineMedium),
      const SizedBox(height: AppSpacing.md),
      CountStepper(label: l10n.sickLabel, value: draft.sick, onChanged: controller.setSick),
      const SizedBox(height: AppSpacing.sm),
      CountStepper(label: l10n.deadLabel, value: draft.dead, onChanged: controller.setDead),
      const SizedBox(height: AppSpacing.sm),
      CountStepper(label: l10n.totalLabel, value: total, min: draft.sick + draft.dead, onChanged: controller.setTotal),
      SectionHeader(l10n.onsetTitle),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        for (final entry in onsets.entries)
          ChoiceChip(
            label: Text(entry.value,
                style: text.titleMedium?.copyWith(color: draft.onset == entry.key ? AppColors.paper : AppColors.ink)),
            selected: draft.onset == entry.key,
            showCheckmark: false,
            backgroundColor: AppColors.paper,
            selectedColor: AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            onSelected: (_) => controller.setOnset(entry.key),
          ),
      ]),
    ]);
  }
}

class _CheckStep extends ConsumerWidget {
  const _CheckStep({required this.shared, required this.problem});

  final SharedData shared;
  final String? problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final draft = ref.watch(reportDraftProvider);
    final species = shared.species[draft.species];
    Widget row(IconData icon, String value) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            Icon(icon, color: AppColors.ink),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(value, style: text.titleMedium)),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListGroup(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            if (species != null) Pictogram(species['pictogram'] as String, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(localized(species?['name'], language), style: text.titleLarge)),
          ]),
        ),
        if (draft.village != null)
          row(LucideIcons.mapPin, '${localized(draft.village!.name, language)}, ${localized(draft.village!.name['block'], language)}'),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: draft.symptoms.isEmpty
              ? Text(l10n.noSignsChosen, style: text.titleMedium)
              : WhyChips(matched: [
                  for (final id in draft.symptoms)
                    WhyChip(label: localized(shared.symptoms[id]?['label'], language), pictogram: shared.symptoms[id]?['pictogram'] as String?),
                ]),
        ),
        row(LucideIcons.camera, draft.photoPath == null ? l10n.noPhoto : l10n.photoAdded),
        row(LucideIcons.hash, l10n.countSummary(draft.sick, draft.dead, draft.total ?? draft.sick + draft.dead)),
      ]),
      if (problem != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(problem == 'needSignOrDeath' ? l10n.needSignOrDeath : l10n.totalTooSmall,
              style: text.titleMedium?.copyWith(color: SeverityColors.emergency.foreground)),
        ),
    ]);
  }
}
