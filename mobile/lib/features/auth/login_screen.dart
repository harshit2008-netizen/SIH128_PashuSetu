import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import 'language_screen.dart' show PrimaryButton;

const roleOrder = ['farmer', 'pashu_sevak', 'vet', 'lab', 'district_officer'];

String roleName(AppLocalizations l10n, String role) => switch (role) {
      'farmer' => l10n.roleFarmer,
      'pashu_sevak' => l10n.rolePashuSevak,
      'vet' => l10n.roleVet,
      'lab' => l10n.roleLab,
      'district_officer' => l10n.roleDistrictOfficer,
      _ => role,
    };

/// The demo accounts come from the server (GET /auth/demo-accounts). An
/// empty list means the server is not in demo mode.
final demoAccountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final accounts = await ref.watch(apiClientProvider).get('/auth/demo-accounts') as List;
  return accounts.cast<Map<String, dynamic>>();
});

/// Pick a role (demo), phone is filled in, type the OTP, log in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String? _role;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _pickRole(Map<String, dynamic> account) => setState(() {
        _role = account['role'] as String;
        _phone.text = account['phone'] as String;
        _error = null;
      });

  Future<void> _logIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = await ref.read(apiClientProvider).post('/auth/otp/verify',
          body: {'phone': _phone.text.trim(), 'otp': _otp.text.trim()}) as Map<String, dynamic>;
      final user = body['user'] as Map<String, dynamic>;
      // Farmers and sevaks keep their own language choice; the profile's is a default.
      await ref.read(settingsProvider.notifier).logIn(body['access_token'] as String, user);
    } on ApiException catch (error) {
      setState(() => _error = error.isNetwork || error.code == 'no_signal' ? l10n.serverUnreachable : error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final accounts = ref.watch(demoAccountsProvider);
    final canSubmit = RegExp(r'^\d{10}$').hasMatch(_phone.text) && _otp.text.length >= 4;
    return Scaffold(
      appBar: AppBar(
        title: const AppMark(),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => context.push('/settings'),
            icon: const Icon(LucideIcons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.farmerScreenPadding),
          children: [
            Text(l10n.loginTitle, style: text.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            accounts.when(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : ListGroup(children: [
                      for (final account in [...list]..sort((a, b) => roleOrder.indexOf(a['role']).compareTo(roleOrder.indexOf(b['role']))))
                        _RoleRow(
                          role: roleName(l10n, account['role'] as String),
                          name: account['name'] as String,
                          selected: _role == account['role'],
                          onTap: () => _pickRole(account),
                        ),
                    ]),
              loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator())),
              error: (_, _) => EmptyState(
                message: l10n.serverUnreachable,
                actionLabel: l10n.tryAgain,
                onAction: () => ref.invalidate(demoAccountsProvider),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: text.titleLarge,
              decoration: _inputDecoration(l10n.loginPhoneLabel, LucideIcons.phone),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: text.titleLarge,
              decoration: _inputDecoration(l10n.loginOtpLabel, LucideIcons.keyRound),
            ),
            if (accounts.value?.isNotEmpty ?? false)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: SeverityColors.routine.background,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(children: [
                  Icon(LucideIcons.info, color: SeverityColors.routine.foreground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(l10n.demoOtpNote,
                          style: text.titleMedium?.copyWith(color: SeverityColors.routine.foreground))),
                ]),
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: text.bodyLarge?.copyWith(color: SeverityColors.emergency.foreground)),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: l10n.loginButton, busy: _busy, onPressed: canSubmit ? _logIn : null),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: '',
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.ink, width: 2)),
      );
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.role, required this.name, required this.selected, required this.onTap});

  final String role;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouch.farmerMinTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(role, style: text.titleMedium),
                  Text(name, style: text.bodySmall),
                ]),
              ),
              Icon(selected ? LucideIcons.circleCheck : LucideIcons.circle,
                  color: selected ? AppColors.ink : AppColors.line, size: 26),
            ]),
          ),
        ),
      ),
    );
  }
}

