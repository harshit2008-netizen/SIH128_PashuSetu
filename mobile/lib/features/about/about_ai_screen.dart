import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../triage/engine/image_classifier.dart';

/// The bundled model card (written by train.py on Kaggle), or null when this
/// build has no photo model. Every number on the About screen comes from it.
final modelCardProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    return jsonDecode(await rootBundle.loadString(LsdImageClassifier.cardAsset)) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

/// "About the AI" (spec 9.8): the three layers in plain words, rule versions,
/// and the photo model's real test results and known limits. Works offline.
class AboutAiScreen extends ConsumerWidget {
  const AboutAiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final shared = ref.watch(sharedDataProvider).value;
    final language = ref.watch(languageProvider);
    final card = ref.watch(modelCardProvider);
    if (shared == null || card.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final fusion = shared.triageConfig['fusion'] as Map<String, dynamic>;
    int percent(Object? value) => ((value as num) * 100).round();

    Widget layer(String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(body, style: text.bodyLarge),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutAi)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxxl),
        children: [
          Text(l10n.aboutAiIntro, style: text.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          ListGroup(children: [
            layer(l10n.aboutRulesTitle, l10n.aboutRulesBody(shared.rules.length)),
            layer(l10n.aboutPhotoTitle,
                l10n.aboutPhotoBody(percent(fusion['image_weight']), percent(fusion['rules_weight']))),
            layer(l10n.aboutDistrictTitle, l10n.aboutDistrictBody),
          ]),
          ..._modelCard(context, card.value),
          SectionHeader(l10n.aboutVersions),
          ListGroup(children: [
            for (final rule in shared.rulesInOrder)
              _Row(label: localized(rule['name'], language), value: 'v${rule['version']}'),
            if (card.value != null)
              _Row(
                  label: l10n.photoChip,
                  value: '${card.value!['model_version']}, ${(card.value!['date'] as String).substring(0, 10)}'),
          ]),
        ],
      ),
    );
  }

  List<Widget> _modelCard(BuildContext context, Map<String, dynamic>? card) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (card == null) return [const SizedBox(height: AppSpacing.lg), Text(l10n.aboutNoModel, style: text.bodyLarge)];
    // The phone runs the TFLite file, so show the TFLite model's own test results.
    final metrics = (card['tflite_test_metrics'] ?? card['test_metrics']) as Map<String, dynamic>;
    final dataset = card['dataset'] as Map<String, dynamic>;
    String percent(Object? value) => '${((value as num) * 100).toStringAsFixed(1)}%';
    return [
      SectionHeader(l10n.aboutTestResults),
      ListGroup(children: [
        _Row(label: l10n.aboutAccuracy, value: percent(metrics['accuracy'])),
        _Row(label: l10n.aboutPrecision, value: percent(metrics['precision_lsd'])),
        _Row(label: l10n.aboutRecall, value: percent(metrics['recall_lsd'])),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.aboutTestedOn(metrics['n'] as int), style: text.bodyMedium),
      Text(l10n.aboutDataset(dataset['name'] as String, dataset['licence'] as String), style: text.bodyMedium),
      SectionHeader(l10n.aboutLimits),
      ListGroup(children: [
        for (final limit in (card['known_limitations'] as List).cast<String>())
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Text(limit, style: text.bodyLarge),
          ),
      ]),
    ];
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(children: [
          Expanded(child: Text(label, style: text.bodyLarge)),
          const SizedBox(width: AppSpacing.md),
          Text(value, style: text.titleMedium),
        ]),
      ),
    );
  }
}
