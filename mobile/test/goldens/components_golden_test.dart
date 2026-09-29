// Golden screenshots of every design-system component (spec 9.7), in English
// and Hindi, at both phone widths and at text scale 1.0 and 1.3.
// Update after an intended visual change: flutter test --update-goldens test/goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/theme/tokens.dart';
import 'package:pashusetu/l10n/app_localizations.dart';
import 'package:pashusetu/widgets/widgets.dart';

import 'golden_setup.dart';

/// Real labels from shared/symptoms.json and the rule files, per language.
const _labels = {
  'en': {
    'lumps': 'Lumps on the skin', 'fever': 'Fever, body feels hot', 'drool': 'Drooling',
    'feet': 'Wounds between the hooves', 'lsd': 'Lumpy skin disease', 'fmd': 'Foot-and-mouth disease',
    'cow': 'Cow', 'buffalo': 'Buffalo', 'goat': 'Goat', 'sick': 'Sick', 'dead': 'Dead',
    'alert': 'Lumpy skin disease suspected', 'place': 'Garewadi, Junnar',
    'safety': 'Do not cut or open the body. Keep people and animals away. Report now.',
    'vet': 'Dr. Anil Deshmukh',
  },
  'hi': {
    'lumps': 'त्वचा पर गांठें', 'fever': 'बुखार, शरीर गरम', 'drool': 'मुंह से लार टपकना',
    'feet': 'खुर के बीच घाव', 'lsd': 'लम्पी स्किन रोग', 'fmd': 'खुरपका-मुंहपका रोग',
    'cow': 'गाय', 'buffalo': 'भैंस', 'goat': 'बकरी', 'sick': 'बीमार', 'dead': 'मरे',
    'alert': 'लम्पी स्किन रोग की आशंका', 'place': 'गारेवाडी, जुन्नर',
    'safety': 'शव को न काटें, न खोलें। लोगों और पशुओं को दूर रखें। तुरंत सूचना दें।',
    'vet': 'डॉ. अनिल देशमुख',
  },
};

class ComponentGallery extends StatelessWidget {
  const ComponentGallery({super.key, required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    final t = _labels[language]!;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FarmerMode(
          enabled: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const AppMark(),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 8, runSpacing: 8, children: const [
              SyncStatusPill(state: SyncState.allSent),
              SyncStatusPill(state: SyncState.waiting, waitingCount: 2),
              SyncStatusPill(state: SyncState.offline),
            ]),
            const SizedBox(height: AppSpacing.md),
            ReportActionButton(onPressed: () {}),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: const [
              EarTagChip('123456789012'),
              EarTagChip('223344556677', size: EarTagSize.large),
            ]),
            const SizedBox(height: AppSpacing.md),
            SymptomGrid(children: [
              SymptomTile(label: t['lumps']!, pictogram: 'skin_nodules.svg', selected: true, onTap: () {}, onHelp: () {}),
              SymptomTile(label: t['fever']!, pictogram: 'fever.svg', selected: false, onTap: () {}, onHelp: () {}),
              SymptomTile(label: t['drool']!, pictogram: 'excessive_salivation.svg', selected: false, onTap: () {}),
              SymptomTile(label: t['feet']!, pictogram: 'foot_lesions.svg', selected: true, onTap: () {}),
            ]),
            const SizedBox(height: AppSpacing.md),
            SpeciesPicker(
              options: [
                SpeciesOption(id: 'cattle', label: t['cow']!, pictogram: 'species_cattle.svg'),
                SpeciesOption(id: 'buffalo', label: t['buffalo']!, pictogram: 'species_buffalo.svg'),
                SpeciesOption(id: 'goat', label: t['goat']!, pictogram: 'species_goat.svg'),
              ],
              selectedId: 'cattle',
              onSelected: (_) {},
            ),
            const SizedBox(height: AppSpacing.md),
            CountStepper(label: t['sick']!, value: 2, onChanged: (_) {}),
            CountStepper(label: t['dead']!, value: 0, onChanged: (_) {}),
            const SizedBox(height: AppSpacing.md),
            const Wrap(spacing: 8, runSpacing: 8, children: [
              SeverityBadge(Severity.emergency),
              SeverityBadge(Severity.urgent),
              SeverityBadge(Severity.routine),
            ]),
            const SizedBox(height: AppSpacing.md),
            ConfidenceBar(label: t['lsd']!, score: 0.82, confidence: 'high'),
            const SizedBox(height: AppSpacing.sm),
            ConfidenceBar(label: t['fmd']!, score: 0.12, confidence: 'low'),
            const SizedBox(height: AppSpacing.md),
            WhyChips(
              matched: [
                WhyChip(label: t['lumps']!, pictogram: 'skin_nodules.svg'),
                WhyChip(label: t['fever']!, pictogram: 'fever.svg'),
              ],
              missing: [t['feet']!],
              photo: true,
            ),
            const SizedBox(height: AppSpacing.md),
            SafetyBanner(text: t['safety']!, onListen: () {}),
            const SizedBox(height: AppSpacing.md),
            ListGroup(children: [
              AlertRow(severity: Severity.urgent, summary: t['alert']!,
                  meta: '${l10n.kmAway('4')}, ${l10n.hoursAgo(2)}', onListen: () {}),
              AlertRow(severity: Severity.emergency, summary: t['alert']!, meta: t['place']!),
            ]),
            const SizedBox(height: AppSpacing.md),
            KpiStrip(items: [
              KpiItem(value: '14', label: l10n.kpiOpenCases),
              KpiItem(value: '2', label: l10n.kpiEmergency),
              KpiItem(value: '5', label: l10n.kpiUrgent),
              KpiItem(value: '3', label: l10n.kpiWaitingForVet),
            ]),
            const SizedBox(height: AppSpacing.md),
            CaseTimeline(severity: Severity.urgent, steps: [
              TimelineStep(label: l10n.statusReported, state: TimelineState.done, detail: t['place']),
              TimelineStep(label: l10n.statusTriaged, state: TimelineState.done),
              TimelineStep(label: l10n.statusVetAssigned, state: TimelineState.current, detail: t['vet']),
              TimelineStep(label: l10n.statusResolved, state: TimelineState.future),
            ]),
            EmptyState(message: l10n.noReports, actionLabel: l10n.tryAgain, onAction: () {}),
          ]),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  for (final language in ['en', 'hi']) {
    for (final size in goldenSizes.entries) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('components $language ${size.key} x$scale', (tester) async {
          // Tall surface so the whole gallery fits in one image.
          await setSurface(tester, Size(size.value.width, 2600));
          await tester.pumpWidget(goldenApp(ComponentGallery(language: language), language: language, textScale: scale));
          await settle(tester);
          await expectLater(
            find.byType(ComponentGallery),
            matchesGoldenFile('images/components_${language}_${size.key}_x$scale.png'),
          );
          expect(tester.takeException(), isNull, reason: 'no overflow or layout errors');
        });
      }
    }
  }
}
