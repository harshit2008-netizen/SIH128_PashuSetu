import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/app.dart';
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

  testWidgets('setup screen shows the app name in Hindi and English', (tester) async {
    await tester.pumpWidget(const PashuSetuApp());
    expect(find.text('पशुसेतु'), findsOneWidget);
    expect(find.text('PashuSetu'), findsOneWidget);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull,
        reason: 'background must come from the theme (limewash)');
  });
}
