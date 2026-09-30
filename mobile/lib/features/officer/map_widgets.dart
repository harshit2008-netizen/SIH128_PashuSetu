import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'officer_data.dart' show Json;

/// OSM tiles need internet; markers and alert areas still draw without them.
TileLayer osmTiles() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'in.pashusetu.pashusetu',
    );

/// OSM data and tiles are ODbL: attribution must stay visible.
Widget osmAttribution() => RichAttributionWidget(attributions: [
      TextSourceAttribution('OpenStreetMap contributors',
          onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'))),
    ]);

List<LatLng> ringOf(Json geometry) {
  final coordinates = geometry['coordinates'] as List;
  final ring = (geometry['type'] == 'MultiPolygon' ? coordinates.first.first : coordinates.first) as List;
  return [for (final p in ring) LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble())];
}

LatLng pointOf(Json geometry) {
  final c = geometry['coordinates'] as List;
  return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
}

LatLngBounds? boundsOf(Json? bounds) => bounds == null
    ? null
    : LatLngBounds(LatLng((bounds['south'] as num).toDouble(), (bounds['west'] as num).toDouble()),
        LatLng((bounds['north'] as num).toDouble(), (bounds['east'] as num).toDouble()));

Polygon alertPolygon(Json feature) {
  final colors = SeverityStyle.parse(feature['properties']['severity'] as String?).colors;
  return Polygon(
    points: ringOf(feature['geometry'] as Json),
    color: colors.edge.withValues(alpha: 0.18),
    borderColor: colors.edge,
    borderStrokeWidth: 2.5,
  );
}

/// Case pin. Shape differs by severity too (circle routine, diamond urgent,
/// triangle emergency), so colour-blind users can still tell them apart.
class SeverityMarker extends StatelessWidget {
  const SeverityMarker({super.key, required this.severity, this.size = 20});

  final Severity severity;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkerPainter(severity));
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter(this.severity);

  final Severity severity;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = severity.colors;
    final fill = Paint()..color = colors.edge;
    final stroke = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final w = size.width, h = size.height;
    final path = switch (severity) {
      Severity.emergency => Path()
        ..moveTo(w / 2, 1)
        ..lineTo(w - 1, h - 1)
        ..lineTo(1, h - 1)
        ..close(),
      Severity.urgent => Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close(),
      _ => Path()..addOval(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: math.min(w, h) / 2 - 1)),
    };
    canvas
      ..drawPath(path, fill)
      ..drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_MarkerPainter oldDelegate) => oldDelegate.severity != severity;
}

Marker caseMarker(Json feature, {VoidCallback? onTap}) {
  final severity = SeverityStyle.parse(feature['properties']['severity'] as String?);
  return Marker(
    point: pointOf(feature['geometry'] as Json),
    width: 36,
    height: 36,
    child: Semantics(
      button: onTap != null,
      label: severity.name,
      child: GestureDetector(onTap: onTap, child: Center(child: SeverityMarker(severity: severity))),
    ),
  );
}
