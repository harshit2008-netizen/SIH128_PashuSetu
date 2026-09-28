import 'package:flutter/material.dart';

import 'tokens.dart';

/// Font families bundled in assets/fonts (no runtime download: the app must
/// work offline). Names must match pubspec.yaml.
abstract final class AppFonts {
  /// Body, UI and forms. Covers Latin and Devanagari.
  static const text = 'Mukta';

  /// Headings, big numbers and ear-tag numbers. Variable font (wght, wdth).
  static const display = 'AnekDevanagari';

  /// Every style falls back through these so Devanagari always renders and
  /// the platform default (Roboto) never shows up.
  static const fallback = [text, display];
}

/// Type scale from spec Section 9.4 (size / line height in logical px).
abstract final class AppTypography {
  /// Devanagari matras need extra vertical room.
  static const devanagariMinHeight = 1.5;

  static const _tabular = [FontFeature.tabularFigures()];

  /// Anek is a variable font, so weight and width are set through its axes.
  /// A slightly narrower width keeps big numbers and tags compact.
  static List<FontVariation> _anek(double weight, {double width = 100}) => [
        FontVariation.weight(weight),
        FontVariation('wdth', width),
      ];

  static TextStyle _style({
    required String family,
    required double size,
    required double lineHeight,
    FontWeight weight = FontWeight.w400,
    List<FontVariation>? variations,
    List<FontFeature>? features,
    Color color = AppColors.ink,
    required bool devanagari,
  }) {
    var height = lineHeight / size;
    if (devanagari && height < devanagariMinHeight) {
      height = devanagariMinHeight;
    }
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: AppFonts.fallback,
      fontSize: size,
      height: height,
      fontWeight: weight,
      fontVariations: variations,
      fontFeatures: features,
      color: color,
    );
  }

  /// [devanagari] is true when the UI language is Hindi or Marathi.
  static TextTheme textTheme({required bool devanagari}) {
    TextStyle display(double size, double lh, double wght, {double wdth = 100}) =>
        _style(
          family: AppFonts.display,
          size: size,
          lineHeight: lh,
          weight: FontWeight.values[(wght ~/ 100) - 1],
          variations: _anek(wght, width: wdth),
          features: _tabular,
          devanagari: devanagari,
        );
    TextStyle text(double size, double lh, FontWeight weight, {Color color = AppColors.ink}) =>
        _style(
          family: AppFonts.text,
          size: size,
          lineHeight: lh,
          weight: weight,
          color: color,
          devanagari: devanagari,
        );

    return TextTheme(
      displayLarge: display(40, 44, 700, wdth: 90),
      displayMedium: display(40, 44, 600, wdth: 90),
      headlineMedium: display(26, 34, 600),
      titleLarge: display(20, 28, 600),
      titleMedium: text(16, 24, FontWeight.w600),
      bodyLarge: text(16, 24, FontWeight.w400),
      bodyMedium: text(14, 20, FontWeight.w400),
      bodySmall: text(13, 18, FontWeight.w400, color: AppColors.inkMuted),
      labelLarge: text(16, 24, FontWeight.w600),
      labelMedium: text(14, 20, FontWeight.w500),
      labelSmall: text(13, 18, FontWeight.w500),
    );
  }

  /// Larger body text for farmer mode (18/28).
  static TextStyle farmerBody({required bool devanagari}) => _style(
        family: AppFonts.text,
        size: 18,
        lineHeight: 28,
        devanagari: devanagari,
      );
}
