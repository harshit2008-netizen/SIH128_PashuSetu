"""Text -> symptom ids, species and counts, from shared/symptom_lexicon.json.

Python twin of mobile/lib/features/report/voice/lexicon_parser.dart, used for
reports that arrive as SMS (P2). Both pass the same sentences in
shared/voice_test_sentences.json, so the phone and the server read a sentence
the same way. Keep the two step-for-step identical.
"""

import re
from dataclasses import dataclass, field

_NUKTA_LETTERS = {0x0958: 0x0915, 0x0959: 0x0916, 0x095A: 0x0917, 0x095B: 0x091C,
                  0x095C: 0x0921, 0x095D: 0x0922, 0x095E: 0x092B, 0x095F: 0x092F}
_NOT_WORD = re.compile("[^\\wऀ-ॿ]+")  # the Devanagari block, so vowel signs count as letters
_PUNCTUATION_IN_WORD_CHARS = str.maketrans({"_": " ", "।": " ", "॥": " ", "॰": " "})

NEGATION_AFTER = {"नहीं", "नही", "नाही", "ना", "न", "नको"}
NEGATION_BEFORE = {"no", "not", "without", "never", "doesn", "isn", "didn", "don", "hasn"}
DEAD_STEMS = ("मर", "मौत", "मृत", "मेल", "die", "dead", "death")
SICK_WORDS = {"बीमार", "bimar", "beemar", "आजारी", "sick", "ill", "unwell", "affected"}
TOTAL_BEFORE = {"कुल", "एकूण", "total"}
TIME_WORDS = {"दिन", "दिनों", "हफ्ते", "हफ्ता", "महीने", "दिवस", "दिवसांपासून", "आठवडे", "day", "days", "week", "weeks"}
MAX_SIGN_SUFFIX = 4
MAX_ANIMAL_SUFFIX = 6


def normalise(text: str) -> str:
    out = []
    for ch in text.lower():
        code = ord(ch)
        if 0x0966 <= code <= 0x096F:
            out.append(chr(0x30 + code - 0x0966))  # Devanagari digit
        elif code == 0x0901:
            out.append(chr(0x0902))  # chandrabindu -> anusvara
        elif code == 0x093C:
            continue  # nukta dropped
        else:
            out.append(chr(_NUKTA_LETTERS.get(code, code)))
    # Same result as Dart's [^\p{L}\p{M}\p{N}]: underscore and the danda (। ॥ ॰) are punctuation.
    cleaned = _NOT_WORD.sub(" ", "".join(out).translate(_PUNCTUATION_IN_WORD_CHARS))
    return " ".join(cleaned.split())


@dataclass
class Parsed:
    transcript: str
    symptoms: list[str] = field(default_factory=list)
    species: str | None = None
    sick: int | None = None
    dead: int | None = None
    total: int | None = None


@dataclass(frozen=True)
class _Entry:
    words: tuple[str, ...]
    id: str

    @property
    def length(self) -> int:
        return len(" ".join(self.words))


def _entries(by_id: dict, language: str) -> list[_Entry]:
    entries = [_Entry(tuple(normalise(phrase).split(" ")), item_id)
               for item_id, item in by_id.items()
               for lang in dict.fromkeys([language, "en"])
               for phrase in item.get(lang, []) if normalise(phrase)]
    return sorted(entries, key=lambda e: (-e.length, e.id))  # longest phrase first


def _word_matches(spoken: str, phrase_word: str, max_suffix: int) -> bool:
    return spoken.startswith(phrase_word) and len(spoken) - len(phrase_word) <= max_suffix


class LexiconParser:
    def __init__(self, lexicon: dict, language: str):
        self.language = language
        self._symptoms = _entries(lexicon["symptoms"], language)
        self._species = _entries(lexicon["species"], language)
        self._numbers = {normalise(word): value for lang in dict.fromkeys([language, "en"])
                         for word, value in lexicon["numbers"].get(lang, {}).items()}

    def parse(self, text: str) -> Parsed:
        words = [w for w in normalise(text).split(" ") if w]
        symptoms = self._match(words, self._symptoms, MAX_SIGN_SUFFIX, check_negation=True)
        species = self._match(words, self._species, MAX_ANIMAL_SUFFIX, check_negation=False)
        sick, dead, total = self._counts(words)
        return Parsed(transcript=text, symptoms=list(dict.fromkeys(symptoms)),
                      species=species[0] if species else None, sick=sick, dead=dead, total=total)

    def _match(self, words: list[str], entries: list[_Entry], max_suffix: int, check_negation: bool) -> list[str]:
        used = [False] * len(words)
        found = []
        for entry in entries:
            n = len(entry.words)
            for start in range(len(words) - n + 1):
                if not all(not used[start + k] and _word_matches(words[start + k], entry.words[k], max_suffix)
                           for k in range(n)):
                    continue
                for k in range(n):
                    used[start + k] = True
                if check_negation and _negated(words, start, start + n - 1, entry):
                    continue
                found.append((start, entry.id))
        return [item_id for _, item_id in sorted(found, key=lambda f: f[0])]

    def _number(self, word: str) -> int | None:
        return int(word) if word.isdigit() else self._numbers.get(word)

    def _is_animal_word(self, word: str) -> bool:
        return any(len(e.words) == 1 and _word_matches(word, e.words[0], MAX_ANIMAL_SUFFIX) for e in self._species)

    def _counts(self, words: list[str]) -> tuple[int | None, int | None, int | None]:
        sick = dead = total = None
        for i, word in enumerate(words):
            value = self._number(word)
            if value is None:
                continue
            after = words[i + 1:i + 4]
            if after and after[0] in TIME_WORDS:
                continue
            before = " ".join(words[max(i - 2, 0):i])
            total_before = (i >= 1 and words[i - 1] in TOTAL_BEFORE) or before == "out of"
            total_after = (_followed_by(after, ("में", "से")) or _followed_by(after, ("मे", "से"))
                           or any(w.endswith("पैकी") for w in after))
            if total_before or total_after:
                total = total if total is not None else value
            elif any(w.startswith(DEAD_STEMS) for w in after):
                dead = dead if dead is not None else value
            elif any(w in SICK_WORDS or self._is_animal_word(w) for w in after):
                sick = sick if sick is not None else value
        return sick, dead, total


def _negated(words: list[str], first: int, last: int, entry: _Entry) -> bool:
    if any(w in NEGATION_AFTER or w in NEGATION_BEFORE for w in entry.words):
        return False
    if any(words[i] in NEGATION_AFTER for i in range(last + 1, min(last + 3, len(words)))):
        return True
    return any(words[i] in NEGATION_BEFORE for i in range(max(first - 2, 0), first))


def _followed_by(words: list[str], pair: tuple[str, str]) -> bool:
    return any(words[i] == pair[0] and words[i + 1] == pair[1] for i in range(len(words) - 1))
