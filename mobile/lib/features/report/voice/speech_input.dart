import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Why listening could not start.
enum SpeechProblem { unavailable, noPermission }

/// The phone's own speech recogniser (spec 10.5), in the app language:
/// hi_IN, mr_IN or en_IN. If that language is not installed on the phone,
/// it listens in English and says so; the parser then uses English phrases.
class SpeechInput {
  final _speech = SpeechToText();

  /// The language actually used ('hi', 'mr' or 'en'), after [prepare].
  String? language;
  String? _localeId;

  /// True when the app language was missing on the phone and English is used.
  bool fellBack = false;

  static const _wanted = {'hi': 'hi_IN', 'mr': 'mr_IN', 'en': 'en_IN'};

  /// Starts the recogniser (Android asks for the microphone the first time).
  Future<SpeechProblem?> prepare(String appLanguage) async {
    var permissionDenied = false;
    final ready = await _speech.initialize(onError: (SpeechRecognitionError e) {
      if (e.errorMsg.contains('permission')) permissionDenied = true;
    });
    if (!ready) {
      return permissionDenied || !(await _speech.hasPermission) ? SpeechProblem.noPermission : SpeechProblem.unavailable;
    }
    final locales = [for (final l in await _speech.locales()) l.localeId.replaceAll('-', '_').toLowerCase()];
    String? pick(String lang) {
      final exact = _wanted[lang]!.toLowerCase();
      if (locales.contains(exact)) return exact;
      return locales.where((l) => l.startsWith('${lang}_')).firstOrNull;
    }

    language = appLanguage;
    fellBack = false;
    // Some phones list no locales at all but still recognise the app language.
    if (locales.isEmpty) {
      _localeId = _wanted[appLanguage];
      return null;
    }
    _localeId = pick(appLanguage);
    if (_localeId == null && appLanguage != 'en') {
      _localeId = pick('en') ?? _wanted['en'];
      language = 'en';
      fellBack = true;
    }
    _localeId ??= _wanted[appLanguage];
    return null;
  }

  /// Listens once. [onWords] gets the words so far, [onDone] the final sentence.
  /// [hints] are lexicon phrases; recognisers that support it hear them more reliably.
  Future<void> listen({
    required void Function(String words) onWords,
    required void Function(String sentence) onDone,
    List<String> hints = const [],
  }) =>
      _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          contextualPhrases: hints,
        ),
        onResult: (SpeechRecognitionResult result) {
          onWords(result.recognizedWords);
          if (result.finalResult) onDone(result.recognizedWords);
        },
      );

  bool get isListening => _speech.isListening;

  /// Also covers the recogniser stopping by itself (silence, error).
  void onStatus(void Function(String status) callback) => _speech.statusListener = callback;

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
