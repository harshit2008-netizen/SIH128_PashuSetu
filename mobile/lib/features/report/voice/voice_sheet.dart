import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/shared_data/shared_data.dart';
import '../../../core/shared_data/shared_data_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import '../report_draft.dart';
import 'lexicon_parser.dart';
import 'speech_input.dart';

/// "Speak instead" (spec 10.5): listen, then show what was heard as tiles the
/// reporter can untick. Only "Use these" changes the report; nothing is sent.
Future<void> showVoiceSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.limewash,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
      builder: (_) => const _VoiceSheet(),
    );

enum _Phase { preparing, listening, heard, problem }

class _VoiceSheet extends ConsumerStatefulWidget {
  const _VoiceSheet();

  @override
  ConsumerState<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends ConsumerState<_VoiceSheet> {
  final _speech = SpeechInput();
  var _phase = _Phase.preparing;
  var _words = '';
  String? _problem;
  VoiceParse? _heard;
  Set<String> _kept = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_start);
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final shared = await ref.read(sharedDataProvider.future);
    setState(() {
      _phase = _Phase.preparing;
      _words = '';
    });
    final problem = await _speech.prepare(ref.read(languageProvider));
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        _phase = _Phase.problem;
        _problem = problem == SpeechProblem.noPermission ? l10n.voiceNoPermission : l10n.voiceUnavailable;
      });
      return;
    }
    setState(() => _phase = _Phase.listening);
    // The recogniser can stop by itself (silence); treat that like the final result.
    _speech.onStatus((status) {
      if (status == 'done' || status == 'notListening') _finish(_words, shared);
    });
    await _speech.listen(
      onWords: (words) => mounted ? setState(() => _words = words) : null,
      onDone: (sentence) => _finish(sentence, shared),
      hints: _hints(shared, _speech.language!),
    );
  }

  /// Lexicon phrases for this language, to steer the recogniser.
  static List<String> _hints(SharedData shared, String language) => [
        for (final group in ['symptoms', 'species'])
          for (final item in (shared.lexicon[group] as Map<String, dynamic>).values)
            ...List<String>.from((item as Map<String, dynamic>)[language] as List? ?? const []),
      ];

  void _finish(String sentence, SharedData shared) {
    if (!mounted || _phase != _Phase.listening) return;
    final heard = LexiconParser(shared.lexicon, _speech.language!).parse(sentence);
    // Keep only signs that exist for the animal the report will be about.
    final species = heard.species ?? ref.read(reportDraftProvider).species;
    final valid = heard.symptoms.where((id) => (shared.symptoms[id]?['species'] as List? ?? const []).contains(species));
    setState(() {
      _heard = VoiceParse(
          transcript: sentence, symptoms: valid.toList(), species: heard.species, sick: heard.sick, dead: heard.dead, total: heard.total);
      _kept = valid.toSet();
      _phase = _Phase.heard;
    });
  }

  void _use() {
    final heard = _heard!;
    ref.read(reportDraftProvider.notifier).applyVoice(
          transcript: heard.transcript,
          symptoms: _kept,
          species: heard.species,
          sick: heard.sick,
          dead: heard.dead,
          total: heard.total,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final shared = ref.watch(sharedDataProvider).value;
    final language = ref.watch(languageProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.lg, AppSpacing.screenPadding, AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(LucideIcons.mic, color: AppColors.ink, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.speakInstead, style: text.headlineMedium)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        ...switch (_phase) {
          _Phase.preparing => [
              Row(children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.voicePreparing, style: text.bodyLarge),
              ]),
            ],
          _Phase.listening => _listening(l10n, text, language),
          _Phase.heard => _heardView(l10n, text, shared!, language),
          _Phase.problem => [
              Text(_problem!, style: text.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              _button(l10n.done, () => Navigator.pop(context), primary: true),
            ],
        },
      ]),
    );
  }

  List<Widget> _listening(AppLocalizations l10n, TextTheme text, String language) => [
        Text(l10n.voiceListening, style: text.titleLarge),
        if (_speech.fellBack) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.voiceFallback(language == 'mr' ? 'मराठी' : 'हिंदी'), style: text.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.voiceExample, style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
        const SizedBox(height: AppSpacing.md),
        Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.listGroup),
          ),
          child: Text(_words, style: text.titleMedium),
        ),
        const SizedBox(height: AppSpacing.lg),
        _button(l10n.voiceStop, _speech.stop, icon: LucideIcons.square),
      ];

  List<Widget> _heardView(AppLocalizations l10n, TextTheme text, SharedData shared, String language) {
    final heard = _heard!;
    final counts = [
      if (heard.sick != null) l10n.voiceSickCount(heard.sick!),
      if (heard.dead != null) l10n.voiceDeadCount(heard.dead!),
      if (heard.total != null) l10n.voiceTotalCount(heard.total!),
    ];
    final nothing = heard.symptoms.isEmpty && counts.isEmpty && heard.species == null;
    return [
      Text('"${heard.transcript}"', style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
      const SizedBox(height: AppSpacing.md),
      if (nothing)
        Text(l10n.voiceNothing, style: text.titleMedium)
      else ...[
        Text(l10n.voiceHeard, style: text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (heard.species != null)
          Text(l10n.voiceAnimal(localized(shared.species[heard.species]?['name'], language)), style: text.titleMedium),
        if (counts.isNotEmpty) Text(counts.join(', '), style: text.titleMedium),
        if (heard.symptoms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            for (final id in heard.symptoms)
              _HeardSign(
                label: localized(shared.symptoms[id]?['label'], language),
                pictogram: shared.symptoms[id]?['pictogram'] as String?,
                kept: _kept.contains(id),
                onTap: () => setState(() => _kept.contains(id) ? _kept.remove(id) : _kept.add(id)),
              ),
          ]),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(l10n.voiceCorrect, style: text.bodyLarge),
      ],
      const SizedBox(height: AppSpacing.lg),
      Row(children: [
        Expanded(child: _button(l10n.voiceAgain, _start, icon: LucideIcons.mic)),
        if (!nothing) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _button(l10n.voiceUse, _use, primary: true)),
        ],
      ]),
    ];
  }

  Widget _button(String label, VoidCallback onPressed, {bool primary = false, IconData? icon}) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.primaryAction));
    final size = Size.fromHeight(FarmerMode.minTarget(context));
    final child = Text(label, textAlign: TextAlign.center);
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: AppColors.ink, minimumSize: size, shape: shape),
        child: child,
      );
    }
    final style = OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.ink), minimumSize: size, shape: shape);
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 20), label: child);
  }
}

/// A heard sign; tap to untick it before using.
class _HeardSign extends StatelessWidget {
  const _HeardSign({required this.label, required this.pictogram, required this.kept, required this.onTap});

  final String label;
  final String? pictogram;
  final bool kept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: kept ? AppColors.ink : AppColors.inkMuted,
          decoration: kept ? null : TextDecoration.lineThrough,
        );
    return Semantics(
      checked: kept,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          constraints: BoxConstraints(minHeight: FarmerMode.minTarget(context) - 8),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: kept ? AppColors.indigoTint : AppColors.paper,
            border: Border.all(color: kept ? AppColors.indigoTint : AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(kept ? LucideIcons.circleCheck : LucideIcons.circle, size: 20, color: kept ? AppColors.ink : AppColors.inkMuted),
            const SizedBox(width: 6),
            if (pictogram != null) ...[Pictogram(pictogram!, size: 28), const SizedBox(width: 6)],
            Flexible(child: Text(label, style: style)),
          ]),
        ),
      ),
    );
  }
}
