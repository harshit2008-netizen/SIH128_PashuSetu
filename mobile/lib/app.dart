import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';

/// Root widget. Routing, locales and role homes arrive in Phase 3; for now
/// it shows one screen that proves the theme and bundled fonts load.
class PashuSetuApp extends StatelessWidget {
  const PashuSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PashuSetu',
      debugShowCheckedModeBanner: false,
      // Hindi is shown on this screen, so use the Devanagari line heights.
      theme: AppTheme.light(devanagari: true),
      home: const ScaffoldCheckScreen(),
    );
  }
}

class ScaffoldCheckScreen extends StatelessWidget {
  const ScaffoldCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.farmerScreenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text('पशुसेतु', style: text.displayLarge),
              Text('PashuSetu', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              Text('पशु बीमार हो तो तुरंत बताएं, सही सलाह पाएं।', style: text.bodyLarge),
              Text('Report a sick animal early and get the right advice.', style: text.bodyLarge),
              const Spacer(),
              _SetupCheck(style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small honest footer: this is a setup screen, not a real feature yet.
class _SetupCheck extends StatelessWidget {
  const _SetupCheck({this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.listGroup),
      ),
      child: Text(
        'Setup check (Phase 0): fonts Mukta and Anek Devanagari, theme tokens loaded.',
        style: style,
      ),
    );
  }
}
