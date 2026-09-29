import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';

/// Where the phone finds the laptop backend. Change it at run time in the
/// developer menu, or at build time with --dart-define=API_BASE_URL=...
/// The default suits a phone on USB with `adb reverse tcp:8000 tcp:8000`.
const defaultApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

/// Everything the phone remembers between launches (stored in kv_settings).
class AppSettings {
  const AppSettings({
    this.language,
    this.apiBaseUrl = defaultApiBaseUrl,
    this.simulateNoSignal = false,
    this.developerMenu = false,
    this.token,
    this.user,
  });

  /// "en", "hi" or "mr"; null until chosen on first launch.
  final String? language;
  final String apiBaseUrl;
  final bool simulateNoSignal;
  final bool developerMenu;
  final String? token;

  /// The logged-in user's profile from the server (/me), as JSON.
  final Map<String, dynamic>? user;

  bool get loggedIn => token != null && user != null;
  String? get role => user?['role'] as String?;
  String get languageOrDefault => language ?? 'hi';

  static AppSettings fromStore(Map<String, String> values) => AppSettings(
        language: values['language'],
        apiBaseUrl: values['api_base_url'] ?? defaultApiBaseUrl,
        simulateNoSignal: values['simulate_no_signal'] == 'true',
        developerMenu: values['developer_menu'] == 'true',
        token: values['token'],
        user: values['user'] == null ? null : jsonDecode(values['user']!) as Map<String, dynamic>,
      );
}

final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Set in main()'));
final initialSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> _save(String key, String? value) async {
    await _db.writeSetting(key, value);
    state = AppSettings.fromStore(await _db.readSettings());
  }

  Future<void> setLanguage(String code) => _save('language', code);
  Future<void> setApiBaseUrl(String url) => _save('api_base_url', url.trim().replaceAll(RegExp(r'/+$'), ''));
  Future<void> setSimulateNoSignal(bool on) => _save('simulate_no_signal', '$on');
  Future<void> enableDeveloperMenu() => _save('developer_menu', 'true');

  Future<void> logIn(String token, Map<String, dynamic> user) async {
    await _db.writeSetting('token', token);
    await _save('user', jsonEncode(user));
  }

  Future<void> logOut() async {
    await _db.writeSetting('token', null);
    await _save('user', null);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
