import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api/api_client.dart';
import '../../core/shared_data/shared_data.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../auth/language_screen.dart' show PrimaryButton, languageNames;
import 'map_widgets.dart';

/// Pre-filled values when the composer opens from an alert.
class AdvisoryDraft {
  const AdvisoryDraft({this.templateId, this.center, this.radiusKm = 10, this.villageNames, this.disease});

  final String? templateId;
  final LatLng? center;
  final double radiusKm;
  final Map<String, dynamic>? villageNames;
  final String? disease;
}

/// Choose a message, drag the circle, see who it reaches, send (spec 9.8).
class AdvisoryComposerScreen extends ConsumerStatefulWidget {
  const AdvisoryComposerScreen({super.key, this.draft = const AdvisoryDraft()});

  final AdvisoryDraft draft;

  @override
  ConsumerState<AdvisoryComposerScreen> createState() => _AdvisoryComposerScreenState();
}

class _AdvisoryComposerScreenState extends ConsumerState<AdvisoryComposerScreen> {
  String? _template;
  LatLng? _center;
  late double _radius = widget.draft.radiusKm;
  Map<String, dynamic>? _preview;
  String? _error;
  bool _sending = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _template = widget.draft.templateId;
    _center = widget.draft.center;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _villages(SharedData shared) => [
        for (final b in (shared.geo['blocks'] as List))
          for (final v in (b['villages'] as List)) (v as Map).cast<String, dynamic>(),
      ];

  /// The village named in the message: the one given, else the nearest to the centre.
  Map<String, dynamic> _villageNames(SharedData shared, LatLng centre) {
    if (widget.draft.villageNames != null && centre == widget.draft.center) return widget.draft.villageNames!;
    const distance = Distance();
    final nearest = _villages(shared).reduce((a, b) =>
        distance(centre, LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble())) <=
                distance(centre, LatLng((b['lat'] as num).toDouble(), (b['lng'] as num).toDouble()))
            ? a
            : b);
    return (nearest['name'] as Map).cast<String, dynamic>();
  }

  Map<String, dynamic> _body(SharedData shared) => {
        'template_id': _template,
        'center': {'lat': _center!.latitude, 'lng': _center!.longitude},
        'radius_km': _radius,
        'disease': widget.draft.disease ?? shared.advisoryTemplates[_template]?['disease'],
        'variables': {'village': _villageNames(shared, _center!)},
      };

  void _schedulePreview(SharedData shared) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (_template == null || _center == null) return;
      try {
        final preview = await ref.read(apiClientProvider).post('/advisories/preview', body: _body(shared)) as Map<String, dynamic>;
        if (mounted) setState(() { _preview = preview; _error = null; });
      } on ApiException catch (e) {
        if (mounted) setState(() => _error = e.message);
      }
    });
  }

  Future<void> _send(SharedData shared) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      final result = await ref.read(apiClientProvider).post('/advisories', body: _body(shared)) as Map<String, dynamic>;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.advisorySentTo(result['farmers'] as int)}. ${l10n.inAppOnly}')));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    if (shared == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final centroid = shared.geo['district']?['centroid'] as Map?;
    _center ??= centroid == null ? const LatLng(18.9, 74.0)
        : LatLng((centroid['lat'] as num).toDouble(), (centroid['lng'] as num).toDouble());
    final templates = shared.advisoryTemplates.values.where((t) => t['disease'] != null).toList();
    _template ??= templates.first['id'] as String;
    if (_preview == null && _error == null) _schedulePreview(shared);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendAdvisory)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxxl),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _template,
            decoration: InputDecoration(labelText: l10n.messageLabel, border: const OutlineInputBorder()),
            items: [
              for (final t in templates)
                DropdownMenuItem(
                    value: t['id'] as String,
                    child: Text('${localized(shared.rules[t['disease']]?['name'], language)} (${t['id']})', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (value) {
              setState(() { _template = value; _preview = null; });
              _schedulePreview(shared);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.listGroup),
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _center!,
                  initialZoom: 11 - math.log(_radius / 5) / math.ln2,
                  onTap: (_, point) {
                    setState(() { _center = point; _preview = null; });
                    _schedulePreview(shared);
                  },
                ),
                children: [
                  osmTiles(),
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _center!,
                      radius: _radius * 1000,
                      useRadiusInMeter: true,
                      color: AppColors.ink.withValues(alpha: 0.12),
                      borderColor: AppColors.ink,
                      borderStrokeWidth: 2,
                    ),
                  ]),
                  MarkerLayer(markers: [
                    Marker(point: _center!, width: 20, height: 20, child: const SeverityMarker(severity: Severity.routine, size: 16)),
                  ]),
                  osmAttribution(),
                ],
              ),
            ),
          ),
          Text(l10n.tapMapToMove, style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.radiusKm(_radius.round().toString()), style: text.titleMedium),
          Slider(
            value: _radius,
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: AppColors.ink,
            label: '${_radius.round()} km',
            onChanged: (value) => setState(() => _radius = value),
            onChangeEnd: (_) {
              setState(() => _preview = null);
              _schedulePreview(shared);
            },
          ),
          Text('${l10n.villageInMessage}: ${localized(_villageNames(shared, _center!), language)}', style: text.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          if (_preview != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: SeverityColors.routine.background, borderRadius: BorderRadius.circular(AppRadius.input)),
              child: Text(l10n.willReach(_preview!['farmers'] as int, _preview!['villages'] as int),
                  style: text.titleMedium?.copyWith(color: SeverityColors.routine.foreground)),
            ),
            SectionHeader(l10n.advisoryPreview),
            ListGroup(children: [
              for (final entry in languageNames.entries)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.value, style: text.labelMedium),
                    Text(_preview!['text'][entry.key] as String, style: text.bodyLarge),
                  ]),
                ),
            ]),
          ] else if (_error == null)
            const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: text.bodyLarge?.copyWith(color: SeverityColors.emergency.foreground)),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: l10n.sendAdvisory, busy: _sending, onPressed: _preview == null ? null : () => _send(shared)),
        ],
      ),
    );
  }
}
