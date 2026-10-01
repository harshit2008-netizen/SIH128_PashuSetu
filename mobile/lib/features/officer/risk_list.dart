import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import 'officer_data.dart';

/// Risk level -> the severity palette: high red, medium amber, low blue-grey.
SeverityColors riskColors(String level) => switch (level) {
      'high' => SeverityColors.emergency,
      'medium' => SeverityColors.urgent,
      _ => SeverityColors.routine,
    };

/// Officer's Risk tab (spec 8.8, 10.7): blocks ranked by the rule-based risk
/// estimate for one disease, each with a plain "why".
class RiskList extends ConsumerWidget {
  const RiskList({super.key, required this.disease, required this.onDisease});

  final String disease;
  final ValueChanged<String> onDisease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final coverage = ref.watch(dashboardSummaryProvider).value?['vaccination_coverage'] as num?;
    final risk = ref.watch(riskProvider(disease));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        for (final rule in shared?.rulesInOrder ?? const <Map<String, dynamic>>[])
          ChoiceChip(
            label: Text(localized(rule['name'], language)),
            selected: rule['id'] == disease,
            showCheckmark: false,
            selectedColor: AppColors.ink,
            backgroundColor: AppColors.paper,
            labelStyle: text.labelLarge?.copyWith(color: rule['id'] == disease ? AppColors.paper : AppColors.ink),
            side: const BorderSide(color: AppColors.line),
            onSelected: (_) => onDisease(rule['id'] as String),
          ),
      ]),
      const SizedBox(height: AppSpacing.md),
      if (coverage != null) Text(l10n.districtCoverage((coverage * 100).round()), style: text.titleMedium),
      ...risk.when(
        loading: () => [const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))],
        error: (e, _) => [EmptyState(message: '$e')],
        data: (body) => [
          Text(localized(body['label'], language), style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          ListGroup(children: [
            for (final block in (body['blocks'] as List).cast<Json>()) _RiskRow(block: block, language: language),
          ]),
        ],
      ),
    ]);
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.block, required this.language});

  final Json block;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final level = block['level'] as String;
    final colors = riskColors(level);
    final score = (block['score'] as num).toDouble();
    final factors = (block['factors'] as Map).cast<String, dynamic>();
    // The two biggest contributions, as a share of the score.
    final ranked = factors.entries.toList()
      ..sort((a, b) => (b.value['contribution'] as num).compareTo(a.value['contribution'] as num));
    String reason(String key, int percent) => switch (key) {
          'season' => l10n.riskFactorSeason(percent),
          'weather' => l10n.riskFactorWeather(percent),
          'nearby' => l10n.riskFactorNearby(percent),
          _ => l10n.riskFactorImmunity(percent),
        };
    final reasons = [
      for (final f in ranked.take(2))
        if (score > 0) reason(f.key, ((f.value['contribution'] as num) / score * 100).round()),
    ];
    final weather = factors['weather'] as Map;
    final coverage = factors['immunity_gap']['coverage'] as num?;
    final details = [
      l10n.riskNearbyCases(factors['nearby']['cases'] as int, factors['nearby']['radius_km'] as int, factors['nearby']['days'] as int),
      if (coverage != null) l10n.riskCoverage((coverage * 100).round()),
      if (weather['modelled'] == false) l10n.riskWeatherNotModelled,
      if ((weather['source'] as List?)?.contains('seeded') ?? false) l10n.riskWeatherSeeded,
    ];
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: colors.edge, width: 4))),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(localized(block['name'], language), style: text.titleMedium)),
          Text('${(score * 100).round()}%', style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
        ]),
        Text(switch (level) { 'high' => l10n.riskHigh, 'medium' => l10n.riskMedium, _ => l10n.riskLow },
            style: text.titleMedium?.copyWith(color: colors.foreground)),
        if (reasons.isNotEmpty) Text(l10n.riskWhy(reasons.join(', ')), style: text.bodyLarge),
        Text(details.join('. '), style: text.bodySmall),
      ]),
    );
  }
}
