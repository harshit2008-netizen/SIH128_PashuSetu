import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';

/// Each language is written in its own script, so anyone can find theirs.
const languageNames = {'hi': 'हिंदी', 'mr': 'मराठी', 'en': 'English'};

/// First launch: pick the language. The whole app, including symptom
/// labels from shared/, switches to it.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider).language;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.farmerScreenPadding),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const AppMark(size: 48),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.chooseLanguage, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            ListGroup(children: [
              for (final entry in languageNames.entries)
                LanguageRow(
                  label: entry.value,
                  selected: current == entry.key,
                  onTap: () => ref.read(settingsProvider.notifier).setLanguage(entry.key),
                ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.continueButton,
              onPressed: current == null ? null : () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageRow extends StatelessWidget {
  const LanguageRow({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouch.farmerMinTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleLarge)),
              Icon(selected ? LucideIcons.circleCheck : LucideIcons.circle,
                  color: selected ? AppColors.ink : AppColors.line, size: 28),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Full-width ink button for the main action of a screen (not the Report
/// action, which is tag yellow).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        disabledBackgroundColor: AppColors.line,
        minimumSize: const Size.fromHeight(AppTouch.farmerMinTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction)),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ink))
          : Text(label),
    );
  }
}
