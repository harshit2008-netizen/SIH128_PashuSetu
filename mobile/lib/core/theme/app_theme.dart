import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Light theme built by hand from the tokens. ColorScheme.fromSeed is not
/// used on purpose: its tonal palette gives the generic Material look.
abstract final class AppTheme {
  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.paper,
    primaryContainer: AppColors.indigoTint,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.inkMuted,
    onSecondary: AppColors.paper,
    secondaryContainer: AppColors.indigoTint,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.tagYellow,
    onTertiary: AppColors.ink,
    error: Color(0xFFB42318),
    onError: AppColors.paper,
    errorContainer: Color(0xFFFDE8E6),
    onErrorContainer: Color(0xFFB42318),
    surface: AppColors.paper,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    surfaceContainerLowest: AppColors.paper,
    surfaceContainerLow: AppColors.paper,
    surfaceContainer: AppColors.paper,
    surfaceContainerHigh: AppColors.paper,
    surfaceContainerHighest: AppColors.limewash,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
    shadow: AppColors.ink,
    scrim: AppColors.ink,
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.paper,
    inversePrimary: AppColors.indigoTint,
    surfaceTint: Colors.transparent,
  );

  static ThemeData light({bool devanagari = false}) {
    final textTheme = AppTypography.textTheme(devanagari: devanagari);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppFonts.text,
      fontFamilyFallback: AppFonts.fallback,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.limewash,
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      // Depth comes from borders and grouping, not shadows (Section 9.5).
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.limewash,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.line),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.listGroup)),
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
