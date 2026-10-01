/// Turns one spoken sentence into symptom ids, a species and animal counts,
/// using shared/symptom_lexicon.json (spec 10.5). Pure Dart, no Flutter.
///
/// It only suggests: the report screen shows the result as tiles the user can
/// untick, and never sends anything on its own. So when in doubt it prefers
/// hearing a sign (easy to untick) over silently missing one.
library;

/// What was understood from one sentence.
class VoiceParse {
  const VoiceParse({
    required this.transcript,
    this.symptoms = const [],
    this.species,
    this.sick,
    this.dead,
    this.total,
  });

  final String transcript;

  /// Symptom ids in the order they were said.
  final List<String> symptoms;
  final String? species;
  final int? sick;
  final int? dead;

  /// All animals at risk ("2 out of 10 cows"), if said.
  final int? total;

  bool get isEmpty => symptoms.isEmpty && species == null && sick == null && dead == null && total == null;
}

/// Lowercase, Devanagari digits to ASCII, chandrabindu -> anusvara, nukta
/// dropped (ड़ -> ड), punctuation -> spaces. Speech recognisers and people
/// spell these differently, so both the lexicon and the transcript go
/// through this before matching.
String normaliseSpeech(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (rune >= 0x0966 && rune <= 0x096F) {
      out.writeCharCode(0x30 + rune - 0x0966); // Devanagari digit
    } else if (rune == 0x0901) {
      out.writeCharCode(0x0902); // chandrabindu -> anusvara
    } else if (rune == 0x093C) {
      // nukta: dropped
    } else if (_nuktaLetters.containsKey(rune)) {
      out.writeCharCode(_nuktaLetters[rune]!);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString().replaceAll(_notWordChars, ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Precomposed nukta letters (क़ ख़ ग़ ज़ ड़ ढ़ फ़ य़) -> the plain letter.
const _nuktaLetters = {
  0x0958: 0x0915, 0x0959: 0x0916, 0x095A: 0x0917, 0x095B: 0x091C,
  0x095C: 0x0921, 0x095D: 0x0922, 0x095E: 0x092B, 0x095F: 0x092F,
};
final _notWordChars = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

// Small closed word lists the lexicon file does not cover. Already normalised.
/// Negation after a sign (Hindi/Marathi: "बुखार नहीं है").
const _negationAfter = {'नहीं', 'नही', 'नाही', 'ना', 'न', 'नको'};

/// Negation before a sign (English: "no fever", "not coughing").
const _negationBefore = {'no', 'not', 'without', 'never', 'doesn', 'isn', 'didn', 'don', 'hasn'};
const _deadStems = ['मर', 'मौत', 'मृत', 'मेल', 'die', 'dead', 'death'];
const _sickWords = {'बीमार', 'bimar', 'beemar', 'आजारी', 'sick', 'ill', 'unwell', 'affected'};
const _totalBefore = {'कुल', 'एकूण', 'total'};

/// "दो दिन से" is two days, not two animals.
const _timeWords = {'दिन', 'दिनों', 'हफ्ते', 'हफ्ता', 'महीने', 'दिवस', 'दिवसांपासून', 'आठवडे', 'day', 'days', 'week', 'weeks'};

/// A phrase word may match the start of a longer spoken word (गांठ -> गांठें,
/// cough -> coughing), but only by this many extra characters. Animal words
/// take case endings (Marathi गायींपैकी, म्हशीच्या), so they may run longer.
const _maxSignSuffix = 4;
const _maxAnimalSuffix = 6;

class _Entry {
  _Entry(this.words, this.id) : length = words.join(' ').length;

  final List<String> words;
  final String id;
  final int length;
}

class LexiconParser {
  /// Uses the app language's phrases plus English, because recognisers often
  /// write English words ("fever") inside a Hindi sentence.
  LexiconParser(Map<String, dynamic> lexicon, this.language)
      : _symptoms = _entries(lexicon['symptoms'] as Map<String, dynamic>, language),
        _species = _entries(lexicon['species'] as Map<String, dynamic>, language),
        _numbers = {
          for (final lang in {language, 'en'})
            for (final e in ((lexicon['numbers'] as Map<String, dynamic>)[lang] as Map<String, dynamic>? ?? {}).entries)
              normaliseSpeech(e.key): e.value as int,
        };

  final String language;
  final List<_Entry> _symptoms;
  final List<_Entry> _species;
  final Map<String, int> _numbers;

  static List<_Entry> _entries(Map<String, dynamic> byId, String language) {
    final entries = <_Entry>[
      for (final item in byId.entries)
        for (final lang in {language, 'en'})
          for (final phrase in ((item.value as Map<String, dynamic>)[lang] as List? ?? const []))
            if (normaliseSpeech(phrase as String).isNotEmpty) _Entry(normaliseSpeech(phrase).split(' '), item.key),
    ];
    // Longest phrase first, so "नाक से खून" (bleeding) wins over "नाक".
    entries.sort((a, b) => b.length != a.length ? b.length.compareTo(a.length) : a.id.compareTo(b.id));
    return entries;
  }

  VoiceParse parse(String transcript) {
    final words = normaliseSpeech(transcript).split(' ').where((w) => w.isNotEmpty).toList();
    final symptoms = _match(words, _symptoms, maxSuffix: _maxSignSuffix, checkNegation: true);
    final species = _match(words, _species, maxSuffix: _maxAnimalSuffix, checkNegation: false);
    final counts = _counts(words);
    return VoiceParse(
      transcript: transcript,
      symptoms: symptoms.toSet().toList(), // a sign said twice counts once; order kept
      species: species.isEmpty ? null : species.first,
      sick: counts.sick,
      dead: counts.dead,
      total: counts.total,
    );
  }

  static bool _wordMatches(String spoken, String phraseWord, int maxSuffix) =>
      spoken.startsWith(phraseWord) && spoken.length - phraseWord.length <= maxSuffix;

  /// Ids of the phrases found, in spoken order. Each spoken word is used by one phrase at most.
  List<String> _match(List<String> words, List<_Entry> entries, {required int maxSuffix, required bool checkNegation}) {
    final used = List<bool>.filled(words.length, false);
    final found = <(int, String)>[];
    for (final entry in entries) {
      final n = entry.words.length;
      for (var start = 0; start + n <= words.length; start++) {
        var ok = true;
        for (var k = 0; k < n && ok; k++) {
          ok = !used[start + k] && _wordMatches(words[start + k], entry.words[k], maxSuffix);
        }
        if (!ok) continue;
        for (var k = 0; k < n; k++) {
          used[start + k] = true;
        }
        if (checkNegation && _negated(words, start, start + n - 1, entry)) continue;
        found.add((start, entry.id));
      }
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final f in found) f.$2];
  }

  /// "बुखार नहीं है" / "no fever": the sign was said, but as absent.
  /// Phrases that contain a negation themselves ("चारा नहीं खा", "not eating") are signs.
  static bool _negated(List<String> words, int first, int last, _Entry entry) {
    if (entry.words.any((w) => _negationAfter.contains(w) || _negationBefore.contains(w))) return false;
    for (var i = last + 1; i <= last + 2 && i < words.length; i++) {
      if (_negationAfter.contains(words[i])) return true;
    }
    for (var i = first - 1; i >= first - 2 && i >= 0; i--) {
      if (_negationBefore.contains(words[i])) return true;
    }
    return false;
  }

  int? _number(String word) => int.tryParse(word) ?? _numbers[word];

  bool _isAnimalWord(String word) =>
      _species.any((e) => e.words.length == 1 && _wordMatches(word, e.words.first, _maxAnimalSuffix));

  /// Numbers said next to animal, "sick" or "died" words: "दो गाय बीमार हैं, एक मर गई".
  ({int? sick, int? dead, int? total}) _counts(List<String> words) {
    int? sick, dead, total;
    for (var i = 0; i < words.length; i++) {
      final value = _number(words[i]);
      if (value == null) continue;
      final after = words.sublist(i + 1, (i + 4).clamp(0, words.length));
      if (after.isNotEmpty && _timeWords.contains(after.first)) continue;
      final before = i >= 2 ? '${words[i - 2]} ${words[i - 1]}' : (i == 1 ? words[0] : '');
      final totalBefore = (i >= 1 && _totalBefore.contains(words[i - 1])) || before == 'out of';
      // "दस गायों में से", Marathi "वीस गायींपैकी" (पैकी is joined to the word).
      final totalAfter = _followedBy(after, ['में', 'से']) || _followedBy(after, ['मे', 'से']) || after.any((w) => w.endsWith('पैकी'));
      if (totalBefore || totalAfter) {
        total ??= value;
      } else if (after.any((w) => _deadStems.any((s) => w.startsWith(s)))) {
        dead ??= value;
      } else if (after.any((w) => _sickWords.contains(w) || _isAnimalWord(w))) {
        sick ??= value;
      }
    }
    return (sick: sick, dead: dead, total: total);
  }

  static bool _followedBy(List<String> words, List<String> pair) {
    for (var i = 0; i + 1 < words.length; i++) {
      if (words[i] == pair[0] && words[i + 1] == pair[1]) return true;
    }
    return false;
  }
}
