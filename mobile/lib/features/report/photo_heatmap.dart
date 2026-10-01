import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import 'report_draft.dart' show lsdClassifierProvider;

/// "Which part of the photo mattered" (P2): on request, covers each cell of a
/// 6x6 grid and shows in red where covering lowered the LSD probability most.
/// Drawn over the central square, which is exactly what the model sees.
class PhotoHeatmap extends ConsumerStatefulWidget {
  const PhotoHeatmap({super.key, required this.photoPath});

  final String photoPath;

  @override
  ConsumerState<PhotoHeatmap> createState() => _PhotoHeatmapState();
}

class _PhotoHeatmapState extends ConsumerState<PhotoHeatmap> {
  static const _grid = 6;
  List<double>? _cells;
  bool _working = false;

  Future<void> _compute() async {
    setState(() => _working = true);
    try {
      final classifier = await ref.read(lsdClassifierProvider.future);
      final cells = await classifier.occlusionMap(await File(widget.photoPath).readAsBytes(), grid: _grid);
      if (mounted) setState(() => _cells = cells);
    } catch (_) {
      // Leave the button; the photo check itself already worked.
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void didUpdateWidget(PhotoHeatmap old) {
    super.didUpdateWidget(old);
    if (old.photoPath != widget.photoPath) _cells = null; // a new photo needs a new map
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (_working) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.whichPartWorking, style: text.bodyLarge)),
        ]),
      );
    }
    if (_cells == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _compute,
          style: TextButton.styleFrom(foregroundColor: AppColors.ink, minimumSize: Size(0, FarmerMode.minTarget(context))),
          icon: const Icon(LucideIcons.scanEye),
          label: Text(l10n.whichPartButton),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.listGroup),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(fit: StackFit.expand, children: [
              Image.file(File(widget.photoPath), fit: BoxFit.cover), // the central square, like the model
              CustomPaint(painter: _HeatPainter(_cells!, _grid)),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.whichPartCaption, style: text.bodyMedium),
      ]),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.cells, this.grid);

  final List<double> cells;
  final int grid;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / grid, h = size.height / grid;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] <= 0) continue;
      final paint = Paint()..color = SeverityColors.emergency.edge.withValues(alpha: 0.6 * cells[i]);
      canvas.drawRect(Rect.fromLTWH((i % grid) * w, (i ~/ grid) * h, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) => old.cells != cells;
}
