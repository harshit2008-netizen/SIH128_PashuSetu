import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import 'foundation.dart';

/// Icon + word in the severity colours. Never colour alone.
class SeverityBadge extends StatelessWidget {
  const SeverityBadge(this.severity, {super.key, this.large = false});

  final Severity severity;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = severity.colors;
    final text = large ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.labelMedium;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.severityBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(severity.icon, size: large ? 20 : 16, color: colors.foreground),
          const SizedBox(width: 6),
          Text(severity.word(AppLocalizations.of(context)), style: text?.copyWith(color: colors.foreground)),
        ],
      ),
    );
  }
}

/// Disease name, a bar (ink on a line-coloured track), and the score in words
/// plus percent. [fill] lets the triage screen animate the bar (0..1).
class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({super.key, required this.label, required this.score, required this.confidence, this.fill = 1});

  final String label;
  final double score;

  /// "high", "moderate" or "low" from the engine.
  final String confidence;
  final double fill;

  static String word(AppLocalizations l10n, String confidence) => switch (confidence) {
        'high' => l10n.confidenceHigh,
        'moderate' => l10n.confidenceModerate,
        _ => l10n.confidenceLow,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final percent = (score * 100).round();
    return Semantics(
      label: '$label, ${word(l10n, confidence)}, $percent%',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(label, style: text.titleMedium)),
              Text('${word(l10n, confidence)} ', style: text.titleMedium),
              Text('$percent%', style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: AppColors.line),
                  FractionallySizedBox(
                    widthFactor: (score * fill).clamp(0.0, 1.0),
                    child: Container(color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WhyChip {
  const WhyChip({required this.label, this.pictogram});

  final String label;
  final String? pictogram;
}

/// "Why this result": matched signs as filled chips, missing key signs as
/// outlined "Not reported" chips, and a Photo chip when the photo counted.
class WhyChips extends StatelessWidget {
  const WhyChips({super.key, required this.matched, this.missing = const [], this.photo = false});

  final List<WhyChip> matched;
  final List<String> missing;
  final bool photo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelMedium;
    Widget chip({required Widget child, required bool filled}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: filled ? AppColors.indigoTint : AppColors.paper,
            border: Border.all(color: filled ? AppColors.indigoTint : AppColors.inkMuted),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: child,
        );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final sign in matched)
          chip(
            filled: true,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (sign.pictogram != null) ...[Pictogram(sign.pictogram!, size: 24), const SizedBox(width: 6)],
              Text(sign.label, style: style),
            ]),
          ),
        if (photo)
          chip(
            filled: true,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.camera, size: 18, color: AppColors.ink),
              const SizedBox(width: 6),
              Text(l10n.photoChip, style: style),
            ]),
          ),
        for (final sign in missing)
          chip(filled: false, child: Text(l10n.notReported(sign), style: style?.copyWith(color: AppColors.inkMuted))),
      ],
    );
  }
}

enum SyncState { allSent, waiting, offline }

/// Always in the app bar for farmer and sevak, so they know whether their
/// reports have reached the vet.
class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({super.key, required this.state, this.waitingCount = 0, this.onTap});

  final SyncState state;
  final int waitingCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (colors, icon, text) = switch (state) {
      SyncState.allSent => (SeverityColors.ok, LucideIcons.circleCheck, l10n.syncAllSent),
      SyncState.waiting => (SeverityColors.routine, LucideIcons.cloudUpload, l10n.syncWaiting(waitingCount)),
      SyncState.offline => (SeverityColors.routine, LucideIcons.cloudOff, l10n.syncOffline),
    };
    return Semantics(
      button: onTap != null,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: colors.background,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: colors.foreground),
                  const SizedBox(width: 6),
                  Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
