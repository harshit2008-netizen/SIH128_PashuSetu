import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../auth/language_screen.dart';
import '../home/home_data.dart';

const appVersion = '0.1.0';
const _tapsToUnlockDeveloperMenu = 7;

final engineVersionProvider = FutureProvider<String>((ref) async {
  final shared = await ref.watch(sharedDataProvider.future);
  final versions = shared.rules.values.map((r) => r['version'] as int);
  return 'rules-${versions.reduce((a, b) => a > b ? a : b)}';
});

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.icon, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouch.minTarget + 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, color: AppColors.ink), const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: text.titleMedium),
                if (subtitle != null) Text(subtitle!, style: text.bodySmall),
              ]),
            ),
            ?trailing,
          ]),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTaps = 0;

  Future<void> _tapVersion() async {
    final l10n = AppLocalizations.of(context);
    _versionTaps++;
    if (_versionTaps == _tapsToUnlockDeveloperMenu) {
      await ref.read(settingsProvider.notifier).enableDeveloperMenu();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.developerOptionsOn)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final engine = ref.watch(engineVersionProvider).value ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          SectionHeader(l10n.language),
          ListGroup(children: [
            for (final entry in languageNames.entries)
              LanguageRow(
                label: entry.value,
                selected: settings.language == entry.key,
                onTap: () => controller.setLanguage(entry.key),
              ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          ListGroup(children: [
            _Row(
              title: l10n.simulateNoSignal,
              subtitle: l10n.simulateNoSignalHelp,
              icon: LucideIcons.wifiOff,
              trailing: Switch(
                value: settings.simulateNoSignal,
                activeThumbColor: AppColors.paper,
                activeTrackColor: AppColors.ink,
                onChanged: controller.setSimulateNoSignal,
              ),
            ),
            if (settings.loggedIn) ...[
              _Row(title: l10n.changeRole, icon: LucideIcons.user, onTap: controller.logOut),
              _Row(title: l10n.logOut, icon: LucideIcons.logOut, onTap: controller.logOut),
            ],
            if (settings.developerMenu)
              _Row(
                title: l10n.developerOptions,
                icon: LucideIcons.server,
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => context.push('/settings/developer'),
              ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          // Tapping the version 7 times opens the developer options (spec 10.9).
          GestureDetector(
            onTap: _tapVersion,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.appVersion(appVersion), style: Theme.of(context).textTheme.bodyMedium),
                Text(l10n.engineVersion(engine), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  late final _url = TextEditingController(text: ref.read(settingsProvider).apiBaseUrl);
  String? _status;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _say(String message) => setState(() => _status = message);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.developerOptions)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.apiBaseUrl,
              helperText: l10n.apiBaseUrlHelp,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink, minimumSize: const Size(0, 48)),
              onPressed: () async {
                await controller.setApiBaseUrl(_url.text);
                ref.invalidate(serverOnlineProvider);
                _say(l10n.saved);
              },
              child: Text(l10n.save),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), foregroundColor: AppColors.ink),
              onPressed: () async {
                final ok = await ref.read(apiClientProvider).isServerReachable();
                _say(ok ? l10n.connectionOk : l10n.connectionFailed);
              },
              child: Text(l10n.testConnection),
            ),
          ]),
          if (_status != null)
            Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(_status!, style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: AppSpacing.xl),
          ListGroup(children: [
            _Row(
              title: l10n.showOutbox,
              icon: LucideIcons.inbox,
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/settings/outbox'),
            ),
            _Row(
              title: l10n.clearLocalData,
              icon: LucideIcons.trash2,
              onTap: () async {
                await ref.read(databaseProvider).clearLocalData();
                ref.invalidate(pullDataProvider);
                ref.invalidate(caseQueueProvider);
                _say(l10n.clearLocalDataDone);
              },
            ),
          ]),
        ],
      ),
    );
  }
}

/// Reports saved on the phone and their send status.
class OutboxScreen extends ConsumerWidget {
  const OutboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(unsentCountProvider); // rebuild when the outbox changes
    return Scaffold(
      appBar: AppBar(title: Text(l10n.showOutbox)),
      body: FutureBuilder(
        future: ref.read(databaseProvider).allOutbox(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              ListGroup(children: [
                if (rows.isEmpty) EmptyState(message: l10n.outboxEmpty),
                for (final row in rows)
                  _Row(
                    title: '${(jsonDecode(row.payload) as Map)['species']}: ${row.status}',
                    subtitle: '${row.createdAt.toLocal()}${row.lastError == null ? '' : '. ${row.lastError}'}',
                    icon: LucideIcons.cloudUpload,
                  ),
              ]),
            ],
          );
        },
      ),
    );
  }
}
