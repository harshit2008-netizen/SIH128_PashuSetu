import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import 'shared_data.dart';

/// The bundled shared/ contracts (symptoms, rules, ...) loaded once.
final sharedDataProvider = FutureProvider<SharedData>(
    (ref) => SharedData.load((path) => rootBundle.loadString('assets/shared/$path')));

/// Picks the user's language from a {en, hi, mr} map, falling back to English.
String localized(Object? names, String language) {
  if (names is! Map) return '';
  return (names[language] ?? names['en'] ?? '') as String;
}

final languageProvider = Provider<String>((ref) => ref.watch(settingsProvider).languageOrDefault);
