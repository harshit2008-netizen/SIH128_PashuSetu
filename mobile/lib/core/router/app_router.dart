import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/language_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/cases/case_detail_screen.dart';
import '../../features/home/home_screens.dart';
import '../../features/lab/lab_screens.dart';
import '../../features/officer/advisory_composer_screen.dart';
import '../../features/officer/alert_detail_screen.dart';
import '../../features/officer/dashboard_screen.dart';
import '../../features/report/report_flow_screen.dart';
import '../../features/settings/settings_screens.dart';
import '../../features/triage/ui/triage_result_screen.dart';
import '../settings/app_settings.dart';

const _roleHomes = {'/farmer', '/sevak', '/vet', '/lab', '/officer'};

/// Language first, then login, then the home for the user's role.
/// Settings stay reachable before login so the API address can be set.
String? redirectFor(AppSettings settings, String location) {
  if (settings.language == null) return location == '/language' ? null : '/language';
  if (!settings.loggedIn) {
    final open = location == '/language' || location == '/login' || location.startsWith('/settings');
    return open ? null : '/login';
  }
  final home = homeFor(settings.role);
  if (location == '/' || location == '/login' || (_roleHomes.contains(location) && location != home)) return home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router re-runs redirects when this notifier fires (login, logout, language).
  final refresh = ValueNotifier<int>(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(ref.read(settingsProvider), state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => homeFor(ref.read(settingsProvider).role)),
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/farmer', builder: (_, _) => const FarmerHome()),
      GoRoute(path: '/sevak', builder: (_, _) => const FarmerHome(sevak: true)),
      GoRoute(path: '/vet', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/officer', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/cases/:id', builder: (_, state) => CaseDetailScreen(caseId: state.pathParameters['id']!)),
      GoRoute(path: '/alerts/:id', builder: (_, state) => AlertDetailScreen(alertId: state.pathParameters['id']!)),
      GoRoute(
          path: '/advisories/new',
          builder: (_, state) => AdvisoryComposerScreen(draft: state.extra as AdvisoryDraft? ?? const AdvisoryDraft())),
      GoRoute(path: '/scan', builder: (_, _) => const ScanSampleScreen()),
      GoRoute(path: '/lab', builder: (_, _) => const LabHome()),
      GoRoute(path: '/report', builder: (_, _) => const ReportFlowScreen()),
      GoRoute(
          path: '/triage/:clientUuid',
          builder: (_, state) => TriageResultScreen(clientUuid: state.pathParameters['clientUuid']!)),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen(), routes: [
        GoRoute(path: 'developer', builder: (_, _) => const DeveloperScreen()),
        GoRoute(path: 'outbox', builder: (_, _) => const OutboxScreen()),
      ]),
    ],
  );
});
