import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import 'foundation.dart';

/// The one primary action on the home screen. Tag yellow is used here and
/// nowhere else except ear tags and the app mark.
class ReportActionButton extends StatelessWidget {
  const ReportActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.tagYellow,
      borderRadius: BorderRadius.circular(AppRadius.primaryAction),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.primaryAction),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(AppRadius.listGroup),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Pictogram('species_cattle.svg', size: 52),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.mic, size: 16, color: AppColors.paper),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.reportActionTitle, style: text.headlineMedium),
                      Text(l10n.reportActionSubtitle, style: text.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Short instruction plus at most one action, for lists that are empty.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, FarmerMode.minTarget(context)),
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.ink),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Red-edged safety note for anthrax and bird flu, with a Listen button that
/// reads it aloud (the caller wires text-to-speech).
class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key, required this.text, this.onListen});

  final String text;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context) {
    final colors = SeverityColors.emergency;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.listGroup),
        border: Border(left: BorderSide(color: colors.edge, width: 6)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.octagonAlert, color: colors.foreground, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.foreground)),
          ),
          if (onListen != null)
            TextButton.icon(
              onPressed: onListen,
              style: TextButton.styleFrom(
                  foregroundColor: colors.foreground, minimumSize: Size(0, FarmerMode.minTarget(context))),
              icon: const Icon(LucideIcons.volume2),
              label: Text(l10n.listen),
            ),
        ],
      ),
    );
  }
}
