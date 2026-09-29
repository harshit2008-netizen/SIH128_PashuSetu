import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';

/// Farmer mode: bigger touch targets (64 dp) and bigger body text (18/28).
/// Farmers and pashu sevaks use the app outdoors, often with low literacy.
class FarmerMode extends InheritedWidget {
  const FarmerMode({super.key, required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FarmerMode>()?.enabled ?? false;

  static double minTarget(BuildContext context) =>
      of(context) ? AppTouch.farmerMinTarget : AppTouch.minTarget;

  @override
  bool updateShouldNotify(FarmerMode oldWidget) => oldWidget.enabled != enabled;
}

/// One of the custom SVG pictograms in assets/pictograms. Strokes follow
/// [color] (they use currentColor); the highlight fill stays indigo.
class Pictogram extends StatelessWidget {
  const Pictogram(this.fileName, {super.key, this.size = 48, this.color = AppColors.ink, this.label});

  /// File name as listed in shared/symptoms.json, e.g. `skin_nodules.svg`.
  final String fileName;
  final double size;
  final Color color;

  /// Screen-reader label; null when the text next to it already says it.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/pictograms/$fileName',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
      semanticsLabel: label,
      excludeFromSemantics: label == null,
    );
  }
}

/// Related rows inside one bordered paper block with dividers, instead of a
/// separate floating card per item (spec 9.5).
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.listGroup),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.listGroup),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

enum Severity { emergency, urgent, routine, ok }

extension SeverityStyle on Severity {
  static Severity parse(String? value) => switch (value) {
        'emergency' => Severity.emergency,
        'urgent' => Severity.urgent,
        'routine' => Severity.routine,
        _ => Severity.ok,
      };

  SeverityColors get colors => switch (this) {
        Severity.emergency => SeverityColors.emergency,
        Severity.urgent => SeverityColors.urgent,
        Severity.routine => SeverityColors.routine,
        Severity.ok => SeverityColors.ok,
      };

  IconData get icon => switch (this) {
        Severity.emergency => LucideIcons.octagonAlert,
        Severity.urgent => LucideIcons.triangleAlert,
        Severity.routine => LucideIcons.info,
        Severity.ok => LucideIcons.circleCheck,
      };

  /// The word shown next to the colour, so colour is never the only signal.
  String word(AppLocalizations l10n) => switch (this) {
        Severity.emergency => l10n.severityEmergency,
        Severity.urgent => l10n.severityUrgent,
        Severity.routine => l10n.severityRoutine,
        Severity.ok => l10n.statusResolved,
      };
}
