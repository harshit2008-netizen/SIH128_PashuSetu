import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class PashuSetuApp extends ConsumerWidget {
  const PashuSetuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(settingsProvider).languageOrDefault;
    // Keeps the outbox sync running (start, network change, every 60 s).
    ref.watch(syncControllerProvider);
    return MaterialApp.router(
      title: 'PashuSetu',
      debugShowCheckedModeBanner: false,
      // Hindi and Marathi need taller line heights for matras.
      theme: AppTheme.light(devanagari: language != 'en'),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
