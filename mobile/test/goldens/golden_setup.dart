import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/theme/app_theme.dart';
import 'package:pashusetu/l10n/app_localizations.dart';

/// Flutter tests draw text with a placeholder font (boxes), so goldens load
/// the real bundled fonts first; otherwise they would prove nothing about
/// Hindi rendering (spec 9.10).
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Mukta', [
    'assets/fonts/Mukta-Regular.ttf',
    'assets/fonts/Mukta-Medium.ttf',
    'assets/fonts/Mukta-SemiBold.ttf',
    'assets/fonts/Mukta-Bold.ttf',
  ]);
  await load('AnekDevanagari', ['assets/fonts/AnekDevanagari-Variable.ttf']);
  await load('packages/lucide_icons_flutter/Lucide', ['packages/lucide_icons_flutter/assets/lucide.ttf']);
}

/// Phone sizes from spec 9.10 (logical pixels).
const goldenSizes = {'360x800': Size(360, 800), '412x915': Size(412, 915)};

/// Wraps a widget in the app theme and locale, like the real app.
Widget goldenApp(Widget child, {required String language, double textScale = 1.0}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(devanagari: language != 'en'),
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: child,
  );
}

Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// SVG pictograms decode asynchronously; give them real time to finish.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}
