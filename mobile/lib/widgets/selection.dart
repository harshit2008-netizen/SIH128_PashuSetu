import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import 'foundation.dart';

/// A picture tile that can be switched on and off: symptoms and species.
/// Selected = ink background, white strokes and a check mark (spec 9.6).
class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.label,
    required this.pictogram,
    required this.selected,
    required this.onTap,
    this.pictogramSize = 48,
    this.onHelp,
  });

  final String label;
  final String pictogram;
  final bool selected;
  final VoidCallback onTap;
  final double pictogramSize;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final foreground = selected ? AppColors.paper : AppColors.ink;
    final text = FarmerMode.of(context)
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.ink : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.listGroup),
          side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.listGroup),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: FarmerMode.minTarget(context) * 2),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pictogram(pictogram, size: pictogramSize, color: foreground),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: EdgeInsets.only(right: onHelp != null ? 28 : 0),
                        child: Text(label,
                            style: text?.copyWith(color: foreground), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.paper,
                      child: Icon(LucideIcons.check, size: 16, color: AppColors.ink),
                    ),
                  ),
                if (onHelp != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton(
                      tooltip: l10n.whatDoesThisMean,
                      onPressed: onHelp,
                      constraints: BoxConstraints.tight(Size.square(FarmerMode.minTarget(context))),
                      icon: Icon(LucideIcons.circleHelp, size: 22, color: foreground),
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

class SymptomTile extends StatelessWidget {
  const SymptomTile({
    super.key,
    required this.label,
    required this.pictogram,
    required this.selected,
    required this.onTap,
    this.onHelp,
  });

  final String label;
  final String pictogram;
  final bool selected;
  final VoidCallback onTap;

  /// Shows the one-sentence help ("?") for this sign.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) => _PictureTile(
      label: label, pictogram: pictogram, selected: selected, onTap: onTap, onHelp: onHelp);
}

/// Grid of symptom tiles: 2 columns in farmer mode, 3 for a pashu sevak when
/// there is room. Below [minTileWidth] a label like "Drooling" would break
/// mid-word, so small phones get 2 columns for everyone.
class SymptomGrid extends StatelessWidget {
  const SymptomGrid({super.key, required this.children});

  final List<Widget> children;

  static const minTileWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double widthFor(int columns) => (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      final wanted = FarmerMode.of(context) ? 2 : 3;
      final columns = widthFor(wanted) >= minTileWidth ? wanted : 2;
      final width = widthFor(columns);
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    });
  }
}

class SpeciesOption {
  const SpeciesOption({required this.id, required this.label, required this.pictogram});

  final String id;
  final String label;
  final String pictogram;
}

class SpeciesPicker extends StatelessWidget {
  const SpeciesPicker({super.key, required this.options, required this.selectedId, required this.onSelected});

  final List<SpeciesOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const columns = 3;
      final width = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final option in options)
            SizedBox(
              width: width,
              child: _PictureTile(
                label: option.label,
                pictogram: option.pictogram,
                pictogramSize: 56,
                selected: option.id == selectedId,
                onTap: () => onSelected(option.id),
              ),
            ),
        ],
      );
    });
  }
}

/// Big minus / plus buttons around a number, for sick and dead counts.
class CountStepper extends StatelessWidget {
  const CountStepper({super.key, required this.label, required this.value, required this.onChanged, this.min = 0});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = FarmerMode.minTarget(context).clamp(56.0, 64.0);
    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) => SizedBox.square(
          dimension: size,
          child: IconButton.outlined(
            tooltip: tooltip,
            onPressed: onPressed,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.ink),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
            ),
            icon: Icon(icon, size: 28),
          ),
        );
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
        button(LucideIcons.minus, '${l10n.decrease} $label', value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 72,
          child: Semantics(
            liveRegion: true,
            label: '$label $value',
            excludeSemantics: true,
            child: Text('$value', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium),
          ),
        ),
        button(LucideIcons.plus, '${l10n.increase} $label', () => onChanged(value + 1)),
      ],
    );
  }
}
