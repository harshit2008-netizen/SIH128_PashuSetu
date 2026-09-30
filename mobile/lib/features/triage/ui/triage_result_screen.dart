import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home/formatting.dart';
import '../../../core/db/app_database.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/shared_data/shared_data.dart';
import '../../../core/shared_data/shared_data_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import '../../auth/language_screen.dart' show PrimaryButton;

/// Animal husbandry helpline used in many states (spec 8.9). Check it for the
/// demo state; the server's HELPLINE_NUMBER setting is used in advisories.
const helplineNumber = '1962';

/// Minimum score for "Suspected: X"; below it the screen says there is no clear match.
const _suspectedMinScore = 0.40;

final _outboxItemProvider = StreamProvider.family<OutboxReport?, String>(
    (ref, clientUuid) => ref.watch(databaseProvider).watchOutboxItem(clientUuid));

/// Reads text aloud in the user's language with the phone's text-to-speech.
Future<void> speak(String text, String language) async {
  final tts = FlutterTts();
  await tts.setLanguage({'hi': 'hi-IN', 'mr': 'mr-IN'}[language] ?? 'en-IN');
  await tts.speak(text);
}

/// The on-phone triage result (spec 9.8). Works fully offline: it reads the
/// result the phone computed and saved with the report.
class TriageResultScreen extends ConsumerStatefulWidget {
  const TriageResultScreen({super.key, required this.clientUuid});

  final String clientUuid;

  @override
  ConsumerState<TriageResultScreen> createState() => _TriageResultScreenState();
}

class _TriageResultScreenState extends ConsumerState<TriageResultScreen> with SingleTickerProviderStateMixin {
  // The one orchestrated motion moment (spec 9.9): bars fill top to bottom
  // over ~600 ms, then "Do this now" appears.
  late final _motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  static const _barsEnd = 0.67; // 600 of 900 ms

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _motion.value = 1; // "reduce motion": show everything at once
    } else if (!_motion.isAnimating && _motion.value == 0) {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  double _barFill(int index, int count) {
    final slot = _barsEnd / count;
    final start = index * slot * 0.6;
    final t = ((_motion.value - start) / (slot * 1.4 + 0.0001)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(_outboxItemProvider(widget.clientUuid)).value;
    final shared = ref.watch(sharedDataProvider).value;
    final language = ref.watch(languageProvider);
    final farmer = ref.watch(settingsProvider).role == 'farmer';
    if (item == null || shared == null || item.deviceTriage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final result = jsonDecode(item.deviceTriage!) as Map<String, dynamic>;
    final padding = farmer ? AppSpacing.farmerScreenPadding : AppSpacing.screenPadding;
    return FarmerMode(
      enabled: farmer,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const AppMark()),
        body: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => ListView(
            padding: EdgeInsets.fromLTRB(padding, AppSpacing.sm, padding, AppSpacing.xxxl),
            children: [
              ..._headline(context, result, shared, language),
              ..._safety(context, result, language),
              ..._candidates(context, result, shared, language),
              Opacity(
                opacity: ((_motion.value - _barsEnd) / (1 - _barsEnd)).clamp(0.0, 1.0),
                child: _DoThisNow(actions: List<String>.from(result['actions'] as List), shared: shared, language: language),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.notDiagnosis, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _SyncLine(item: item),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: l10n.done, onPressed: () => context.go('/')),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _headline(BuildContext context, Map<String, dynamic> result, SharedData shared, String language) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final candidates = (result['candidates'] as List).cast<Map<String, dynamic>>();
    final top = candidates.isEmpty ? null : candidates.first;
    final String headline;
    String? help;
    if (result['unknown_syndrome'] == true) {
      headline = l10n.noClearMatch;
      help = l10n.unknownSyndrome;
    } else if (top != null && (top['score'] as num) >= _suspectedMinScore) {
      headline = l10n.suspectedDisease(localized(shared.rules[top['disease_id']]?['name'], language));
    } else {
      headline = l10n.noClearMatch;
      help = l10n.noClearMatchHelp;
    }
    return [
      Semantics(header: true, child: Text(headline, style: text.displayMedium?.copyWith(fontSize: 32, height: 1.3))),
      const SizedBox(height: AppSpacing.sm),
      Align(alignment: Alignment.centerLeft, child: SeverityBadge(SeverityStyle.parse(result['severity'] as String?), large: true)),
      if (help != null) ...[const SizedBox(height: AppSpacing.md), Text(help, style: text.bodyLarge)],
    ];
  }

  List<Widget> _safety(BuildContext context, Map<String, dynamic> result, String language) {
    final l10n = AppLocalizations.of(context);
    final note = result['safety_note'];
    final widgets = <Widget>[];
    if (note != null) {
      final textValue = localized(note, language);
      widgets.addAll([const SizedBox(height: AppSpacing.lg), SafetyBanner(text: textValue, onListen: () => speak(textValue, language))]);
    } else if (result['zoonotic_flag'] == true) {
      widgets.addAll([const SizedBox(height: AppSpacing.lg), SafetyBanner(text: l10n.zoonoticWarning)]);
    }
    return widgets;
  }

  List<Widget> _candidates(BuildContext context, Map<String, dynamic> result, SharedData shared, String language) {
    final l10n = AppLocalizations.of(context);
    final candidates = (result['candidates'] as List).cast<Map<String, dynamic>>();
    if (candidates.isEmpty) return const [];
    final top = candidates.first;
    final hasPhoto = (top['sources'] as Map?)?.containsKey('image') ?? false;
    String signLabel(String id) => localized(shared.symptoms[id]?['label'], language);
    return [
      SectionHeader(l10n.mostLikely),
      for (var i = 0; i < candidates.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ConfidenceBar(
            label: localized(shared.rules[candidates[i]['disease_id']]?['name'], language),
            score: (candidates[i]['score'] as num).toDouble(),
            confidence: candidates[i]['confidence'] as String,
            fill: _barFill(i, candidates.length),
          ),
        ),
      SectionHeader(l10n.whyResult),
      WhyChips(
        matched: [
          for (final id in (top['matched_signs'] as List).cast<String>())
            WhyChip(label: signLabel(id), pictogram: shared.symptoms[id]?['pictogram'] as String?),
        ],
        missing: [for (final id in (top['missing_key_signs'] as List).cast<String>()) signLabel(id)],
        photo: hasPhoto,
      ),
      if (result['photo'] case {'p_lsd': final num p, 'unclear': final bool unclear})
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(unclear ? l10n.photoUnclear : l10n.photoResultLine(photoPercent(p)),
              style: Theme.of(context).textTheme.bodyLarge),
        ),
    ];
  }
}

/// Ordered steps, so numbered (spec 9.8). Call steps get a Call button.
class _DoThisNow extends StatelessWidget {
  const _DoThisNow({required this.actions, required this.shared, required this.language});

  final List<String> actions;
  final SharedData shared;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(l10n.doThisNow),
      ListGroup(children: [
        for (var i = 0; i < actions.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              SizedBox(width: 28, child: Text('${i + 1}', style: text.headlineMedium?.copyWith(fontSize: 22))),
              Expanded(child: Text(localized(shared.actions[actions[i]]?['text'], language), style: text.titleMedium)),
              if (shared.actions[actions[i]]?['call'] == true)
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: helplineNumber)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    minimumSize: Size(0, FarmerMode.minTarget(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                  ),
                  icon: const Icon(LucideIcons.phoneCall, size: 18),
                  label: Text(l10n.callNumber(helplineNumber)),
                ),
            ]),
          ),
      ]),
    ]);
  }
}

/// Whether this report has reached the server yet.
class _SyncLine extends StatelessWidget {
  const _SyncLine({required this.item});

  final OutboxReport item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sent = item.status == 'sent';
    final colors = sent ? SeverityColors.ok : SeverityColors.routine;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(AppRadius.input)),
      child: Row(children: [
        Icon(sent ? LucideIcons.circleCheck : LucideIcons.cloudUpload, color: colors.foreground),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(sent ? l10n.reportSent : l10n.savedOnPhone,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.foreground)),
        ),
      ]),
    );
  }
}
