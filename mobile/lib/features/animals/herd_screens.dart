import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/settings/app_settings.dart';
import '../../core/shared_data/shared_data.dart';
import '../../core/shared_data/shared_data_provider.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../home/formatting.dart';
import '../home/home_data.dart' show Json, pullDataProvider;

/// Herds with their animals and next due vaccines (P1). Needs the server:
/// records change rarely and are entered by the pashu sevak on a visit.
final herdsProvider = FutureProvider.autoDispose<List<Json>>(
    (ref) async => ((await ref.watch(apiClientProvider).get('/herds')) as List).cast<Json>());

final animalProvider = FutureProvider.autoDispose.family<Json, String>(
    (ref, id) async => await ref.watch(apiClientProvider).get('/animals/$id') as Json);

String vaccineName(SharedData? shared, String id, String language) =>
    shared?.vaccines[id] == null ? id : localized(shared!.vaccines[id]!['name'], language);

/// "12 Oct", plus the year when it is not this year (vaccines run 6-36 months).
String dueDate(String isoDate, String language) {
  final date = DateTime.parse(isoDate);
  final text = shortDate(isoDate, language);
  return date.year == DateTime.now().year ? text : '$text ${date.year}';
}

/// The soonest next-due line for an animal, red when overdue.
Widget? nextDueText(BuildContext context, Json animal, SharedData? shared, String language) {
  final due = (animal['next_due'] as List).cast<Json>();
  if (due.isEmpty) return null;
  final l10n = AppLocalizations.of(context);
  final first = due.first;
  final name = vaccineName(shared, first['vaccine'] as String, language);
  final date = dueDate(first['due_on'] as String, language);
  final overdue = first['overdue'] == true;
  return Text(overdue ? l10n.overdueLine(name, date) : l10n.nextDueLine(name, date),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: overdue ? SeverityColors.emergency.foreground : null, fontWeight: overdue ? FontWeight.w600 : null));
}

class HerdsScreen extends ConsumerWidget {
  const HerdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final role = ref.watch(settingsProvider).role;
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final herds = ref.watch(herdsProvider);
    final padding = role == 'farmer' ? AppSpacing.farmerScreenPadding : AppSpacing.screenPadding;
    return FarmerMode(
      enabled: role == 'farmer',
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.herdsTitle)),
        body: herds.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              EmptyState(message: '$error', actionLabel: l10n.tryAgain, onAction: () => ref.invalidate(herdsProvider)),
          data: (list) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(herdsProvider),
            child: ListView(
              padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.xxxl),
              children: [
                if (list.isEmpty) EmptyState(message: l10n.noAnimals),
                for (final herd in list) ...[
                  SectionHeader(herd['name'] as String),
                  Text('${localized(herd['village'], language)}. ${l10n.animalCount((herd['animals'] as List).length)}',
                      style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (role == 'pashu_sevak' && (herd['animals'] as List).isNotEmpty) ...[
                    _VaccinatedTodayButton(herd: herd),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  ListGroup(children: [
                    for (final animal in (herd['animals'] as List).cast<Json>())
                      InkWell(
                        onTap: () => context.push('/animals/${animal['id']}'),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      if (animal['ear_tag'] != null) EarTagChip(animal['ear_tag'] as String),
                                      Text(_animalTitle(animal, shared, language), style: text.titleMedium),
                                    ]),
                                ?nextDueText(context, animal, shared, language),
                              ]),
                            ),
                            const Icon(LucideIcons.chevronRight, color: AppColors.inkMuted),
                          ]),
                        ),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _animalTitle(Json animal, SharedData? shared, String language) => [
      animal['name'] as String? ?? localized(shared?.species[animal['species']]?['name'], language),
      animal['breed'] as String?,
    ].whereType<String>().join(', ');

/// Tap 1 opens the vaccine choice, tap 2 records it for every animal in the herd it is for.
class _VaccinatedTodayButton extends ConsumerWidget {
  const _VaccinatedTodayButton({required this.herd});

  final Json herd;

  Future<void> _record(BuildContext context, WidgetRef ref, String vaccine) async {
    final l10n = AppLocalizations.of(context);
    final language = ref.read(languageProvider);
    final shared = ref.read(sharedDataProvider).value;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      final result =
          await ref.read(apiClientProvider).post('/herds/${herd['id']}/vaccinations', body: {'vaccine': vaccine}) as Json;
      messenger.showSnackBar(SnackBar(
          content: Text(l10n.vaccinationRecorded(vaccineName(shared, vaccine, language), result['animals'] as int,
              dueDate(result['next_due_on'] as String, language)))));
      ref
        ..invalidate(herdsProvider)
        ..invalidate(pullDataProvider);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.vaccinationFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final species = {for (final a in (herd['animals'] as List).cast<Json>()) a['species']};
    final vaccines = [
      for (final v in (shared?.vaccines.values ?? const <Map<String, dynamic>>[]))
        if ((v['species'] as List).any(species.contains)) v,
    ];
    if (vaccines.isEmpty) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        backgroundColor: AppColors.limewash,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.lg, AppSpacing.screenPadding, AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.chooseVaccine, style: Theme.of(sheetContext).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            ListGroup(children: [
              for (final v in vaccines)
                ListTile(
                  minTileHeight: AppTouch.minTarget + 8,
                  leading: const Icon(LucideIcons.syringe, color: AppColors.ink),
                  title: Text(localized(v['name'], language), style: Theme.of(sheetContext).textTheme.titleMedium),
                  onTap: () => _record(sheetContext, ref, v['id'] as String),
                ),
            ]),
          ]),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink),
        minimumSize: const Size.fromHeight(AppTouch.minTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction)),
      ),
      icon: const Icon(LucideIcons.syringe),
      label: Text(l10n.vaccinatedToday),
    );
  }
}

class AnimalScreen extends ConsumerWidget {
  const AnimalScreen({super.key, required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final role = ref.watch(settingsProvider).role;
    final language = ref.watch(languageProvider);
    final shared = ref.watch(sharedDataProvider).value;
    final animal = ref.watch(animalProvider(animalId));
    final padding = role == 'farmer' ? AppSpacing.farmerScreenPadding : AppSpacing.screenPadding;
    return FarmerMode(
      enabled: role == 'farmer',
      child: Scaffold(
        appBar: AppBar(),
        body: animal.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(message: '$error'),
          data: (a) {
            final history = (a['vaccinations'] as List).cast<Json>();
            final due = (a['next_due'] as List).cast<Json>();
            return ListView(
              padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.xxxl),
              children: [
                if (a['ear_tag'] != null) Align(alignment: Alignment.centerLeft, child: EarTagChip(a['ear_tag'] as String)),
                const SizedBox(height: AppSpacing.sm),
                Text(_animalTitle(a, shared, language), style: text.headlineMedium),
                Text([
                  localized(shared?.species[a['species']]?['name'], language),
                  if (a['age_months'] != null) l10n.ageMonths(a['age_months'] as int),
                ].join(', '), style: text.bodyLarge),
                if (due.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  for (final d in due)
                    Text(
                      d['overdue'] == true
                          ? l10n.overdueLine(vaccineName(shared, d['vaccine'] as String, language), dueDate(d['due_on'] as String, language))
                          : l10n.nextDueLine(vaccineName(shared, d['vaccine'] as String, language), dueDate(d['due_on'] as String, language)),
                      style: text.titleMedium?.copyWith(color: d['overdue'] == true ? SeverityColors.emergency.foreground : null),
                    ),
                ],
                SectionHeader(l10n.vaccinationHistory),
                ListGroup(children: [
                  if (history.isEmpty) EmptyState(message: l10n.noVaccinations),
                  for (final v in history)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(children: [
                        const Icon(LucideIcons.syringe, color: AppColors.ink),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(vaccineName(shared, v['vaccine'] as String, language), style: text.titleMedium)),
                        Text(l10n.givenOn(dueDate(v['given_on'] as String, language)), style: text.bodyMedium),
                      ]),
                    ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}
