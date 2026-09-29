import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/theme/app_theme.dart';
import 'package:pashusetu/core/theme/tokens.dart';
import 'package:pashusetu/core/theme/typography.dart';

void main() {
  group('AppTheme', () {
    final theme = AppTheme.light();

    test('uses bundled fonts, never the platform default', () {
      expect(theme.textTheme.bodyLarge!.fontFamily, AppFonts.text);
      expect(theme.textTheme.displayLarge!.fontFamily, AppFonts.display);
      expect(theme.textTheme.bodyLarge!.fontFamilyFallback, AppFonts.fallback);
    });

    test('is built from tokens, not a seed colour', () {
      expect(theme.scaffoldBackgroundColor, AppColors.limewash);
      expect(theme.colorScheme.primary, AppColors.ink);
      expect(theme.colorScheme.surface, AppColors.paper);
    });

    test('Devanagari styles get line height of at least 1.5', () {
      final hindi = AppTypography.textTheme(devanagari: true);
      for (final style in [hindi.bodyMedium, hindi.bodySmall, hindi.displayLarge]) {
        expect(style!.height, greaterThanOrEqualTo(1.5));
      }
    });
  });
}
