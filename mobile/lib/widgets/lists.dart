import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';
import 'foundation.dart';

enum TimelineState { done, current, future }

class TimelineStep {
  const TimelineStep({required this.label, required this.state, this.detail});

  final String label;
  final TimelineState state;

  /// Who and when, e.g. "Dr. Anil Deshmukh, 2 hours ago".
  final String? detail;
}

/// The case lifecycle as numbered steps: done = solid ink, current =
/// outlined in the case's severity colour, future = muted.
class CaseTimeline extends StatelessWidget {
  const CaseTimeline({super.key, required this.steps, required this.severity});

  final List<TimelineStep> steps;
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      _StepMarker(number: i + 1, state: steps[i].state, edge: severity.colors.edge),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: steps[i].state == TimelineState.done ? AppColors.ink : AppColors.line,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].label,
                            style: text.titleMedium?.copyWith(
                                color: steps[i].state == TimelineState.future ? AppColors.inkMuted : AppColors.ink)),
                        if (steps[i].detail != null) Text(steps[i].detail!, style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({required this.number, required this.state, required this.edge});

  final int number;
  final TimelineState state;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    final (fill, border, textColor) = switch (state) {
      TimelineState.done => (AppColors.ink, AppColors.ink, AppColors.paper),
      TimelineState.current => (AppColors.paper, edge, AppColors.ink),
      TimelineState.future => (AppColors.paper, AppColors.line, AppColors.inkMuted),
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: state == TimelineState.current ? 3 : 1.5),
      ),
      child: Text('$number', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor, height: 1)),
    );
  }
}

/// One alert or case in a list: severity edge bar, plain summary, place, time.
class AlertRow extends StatelessWidget {
  const AlertRow({
    super.key,
    required this.severity,
    required this.summary,
    required this.meta,
    this.onTap,
    this.onListen,
    this.trailing,
  });

  final Severity severity;
  final String summary;

  /// Place and time, e.g. "4 km away, 2 hours ago".
  final String meta;
  final VoidCallback? onTap;
  final VoidCallback? onListen;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: severity.colors.edge),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap keeps "Urgent  Lumpy skin disease suspected" on one line when it
                    // fits, and moves the summary below the badge when it does not
                    // (long Hindi text, large font settings).
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [SeverityBadgeInline(severity), Text(summary, style: text.titleMedium)],
                    ),
                    const SizedBox(height: 2),
                    Text(meta, style: text.bodySmall),
                  ],
                ),
              ),
            ),
            if (trailing != null) Center(child: trailing),
            if (onListen != null)
              IconButton(
                tooltip: AppLocalizations.of(context).listen,
                onPressed: onListen,
                constraints: BoxConstraints.tight(Size.square(FarmerMode.minTarget(context))),
                icon: const Icon(LucideIcons.volume2, color: AppColors.ink),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small severity word for dense rows (icon + word, severity colours).
class SeverityBadgeInline extends StatelessWidget {
  const SeverityBadgeInline(this.severity, {super.key});

  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final colors = severity.colors;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(severity.icon, size: 16, color: colors.foreground),
      const SizedBox(width: 4),
      Text(severity.word(AppLocalizations.of(context)),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.foreground)),
    ]);
  }
}

class KpiItem {
  const KpiItem({required this.value, required this.label});

  final String value;
  final String label;
}

/// A compact row of figures on paper, not big hero cards. When the columns
/// get too narrow for a label word (small phone, large text), it becomes a
/// 2 x 2 grid instead of breaking words in the middle.
class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.items});

  final List<KpiItem> items;

  /// Narrowest column (at text scale 1.0) that still fits a one-word label.
  static const _minColumnWidth = 84.0;

  Widget _cell(BuildContext context, KpiItem item) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${item.label}: ${item.value}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // One line always ("72 min"): shrink rather than wrap, so the strip keeps its height.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(item.value, style: text.headlineMedium, maxLines: 1, softWrap: false),
            ),
            Text(item.label, style: text.bodySmall, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, List<KpiItem> row) => IntrinsicHeight(
        child: Row(children: [
          for (var i = 0; i < row.length; i++) ...[
            if (i > 0) const VerticalDivider(width: 1, color: AppColors.line),
            Expanded(child: _cell(context, row[i])),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.listGroup),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final fitsOneRow = constraints.maxWidth / items.length >= _minColumnWidth * scale;
        if (fitsOneRow || items.length < 4) return _row(context, items);
        final half = (items.length / 2).ceil();
        return Column(children: [
          _row(context, items.sublist(0, half)),
          const Divider(),
          _row(context, items.sublist(half)),
        ]);
      }),
    );
  }
}
