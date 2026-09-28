import 'package:flutter/painting.dart';

/// Design tokens from spec Section 9.3 and 9.5. Screens read colours and
/// spacing from here only, so the "field instrument" look stays consistent.
abstract final class AppColors {
  static const ink = Color(0xFF1C2541);
  static const inkMuted = Color(0xFF56607A);
  static const limewash = Color(0xFFEEF1EC);
  static const paper = Color(0xFFFFFFFF);
  static const line = Color(0xFFD6DCD3);

  /// Only for ear-tag chips, the app mark and the one primary Report action.
  /// Never for warnings, so it is never confused with "urgent".
  static const tagYellow = Color(0xFFF6C400);
  static const indigoTint = Color(0xFFD9DEF0);
}

/// Severity colours always appear with an icon and a word, never alone.
class SeverityColors {
  const SeverityColors({
    required this.background,
    required this.foreground,
    required this.edge,
  });

  final Color background;
  final Color foreground;
  final Color edge;

  static const emergency = SeverityColors(
    background: Color(0xFFFDE8E6),
    foreground: Color(0xFFB42318),
    edge: Color(0xFFB42318),
  );
  static const urgent = SeverityColors(
    background: Color(0xFFFFF0E0),
    foreground: Color(0xFF9A4A00),
    edge: Color(0xFFD9730D),
  );
  static const routine = SeverityColors(
    background: Color(0xFFE8F0F8),
    foreground: Color(0xFF24507A),
    edge: Color(0xFF3A6EA5),
  );

  /// Resolved cases, synced reports and other "all good" states.
  static const ok = SeverityColors(
    background: Color(0xFFE6F2EA),
    foreground: Color(0xFF1E6B3D),
    edge: Color(0xFF2F7D4E),
  );
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  static const screenPadding = 16.0;
  static const farmerScreenPadding = 20.0;
}

/// Radius follows hierarchy (Section 9.5) instead of one radius everywhere.
abstract final class AppRadius {
  static const severityBadge = 6.0;
  static const input = 10.0;
  static const listGroup = 12.0;
  static const primaryAction = 16.0;
  static const sheetTop = 20.0;
}

abstract final class AppTouch {
  static const minTarget = 48.0;
  static const farmerMinTarget = 64.0;
}
