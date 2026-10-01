// Golden screenshots of the Phase 10 screens (risk tab, herds) from real API
// replies saved in test/fixtures/phase10, in English and Hindi at 360 px.
// Update after an intended visual change: flutter test --update-goldens test/goldens
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/settings/app_settings.dart';
import 'package:pashusetu/core/shared_data/shared_data.dart';
import 'package:pashusetu/core/shared_data/shared_data_provider.dart';
import 'package:pashusetu/features/animals/herd_screens.dart';
import 'package:pashusetu/features/officer/officer_data.dart';
import 'package:pashusetu/features/officer/risk_list.dart';

import 'golden_setup.dart';

dynamic fixture(String name) => jsonDecode(File('test/fixtures/phase10/$name.json').readAsStringSync());

void main() {
  late SharedData shared;
  setUpAll(() async {
    await loadAppFonts();
    shared = await SharedData.load((path) => File('assets/shared/$path').readAsString());
  });

  List<Override> overrides(String language, String role) => [
        initialSettingsProvider.overrideWithValue(
            AppSettings(language: language, token: 't', user: {'role': role, 'name': 'Test'})),
        sharedDataProvider.overrideWith((ref) async => shared),
        dashboardSummaryProvider.overrideWith((ref) async => fixture('summary') as Map<String, dynamic>),
        riskProvider.overrideWith((ref, disease) async => fixture('risk_lsd') as Map<String, dynamic>),
        herdsProvider.overrideWith((ref) async => (fixture('herds') as List).cast<Map<String, dynamic>>()),
      ];

  for (final language in ['en', 'hi']) {
    testWidgets('risk tab $language', (tester) async {
      await setSurface(tester, const Size(360, 1400));
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(language, 'district_officer'),
        child: goldenApp(
          Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: RiskList(disease: 'lsd', onDisease: (_) {}))),
          language: language,
        ),
      ));
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/risk_tab_$language.png'));
    });

    testWidgets('herds screen $language', (tester) async {
      await setSurface(tester, const Size(360, 1100));
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(language, 'pashu_sevak'),
        child: goldenApp(const HerdsScreen(), language: language),
      ));
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/herds_$language.png'));
    });
  }
}
