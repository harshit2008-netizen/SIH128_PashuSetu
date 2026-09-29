import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/app_database.dart';
import 'core/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Settings are read before the first frame so the router knows at once
  // whether to show the language picker, the login or the role home.
  final db = AppDatabase.onDevice();
  final settings = AppSettings.fromStore(await db.readSettings());
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(settings),
    ],
    child: const PashuSetuApp(),
  ));
}
