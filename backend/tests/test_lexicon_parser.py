"""Server copy of the voice/SMS parser: the same sentences the Dart test uses (spec 10.5)."""

import json

import pytest

from app.core.config import SHARED_DIR
from app.core.shared_loader import get_shared_data
from app.services.triage.lexicon_parser import LexiconParser, normalise

LEXICON = get_shared_data().lexicon
SENTENCES = json.loads((SHARED_DIR / "voice_test_sentences.json").read_text(encoding="utf-8"))
CASES = [(lang, case) for lang in ("hi", "mr", "en") for case in SENTENCES[lang]]


@pytest.mark.parametrize(("language", "case"), CASES, ids=[c["text"][:40] for _, c in CASES])
def test_same_result_as_the_phone(language, case):
    heard = LexiconParser(LEXICON, language).parse(case["text"])
    expected = case["expect"]
    assert set(heard.symptoms) == set(expected["symptoms"])
    assert (heard.species, heard.sick, heard.dead, heard.total) == (
        expected["species"], expected["sick"], expected["dead"], expected["total"])


def test_normalising_matches_the_dart_rules():
    assert normalise("गाँठ") == normalise("गांठ")
    assert normalise("बुख़ार!") == "बुखार"
    assert normalise("२ गाय।") == "2 गाय"
    assert normalise("snake_case") == "snake case"
