"""Tests du détecteur : verdicts attendus + propriété d'asymétrie.

Rappel : signaux SYNTHÉTIQUES. Ces tests prouvent la logique du détecteur, pas
sa validité sur de vraies voix d'enfants (→ bench.py, protocole §8).
"""
from __future__ import annotations

import unittest

from wordend.detector import DetectorConfig, Shape, VerdictKind, analyze, detect, evaluate
from wordend.dsp import resample
from wordend.synth import LIBRARY, synthesize, utterance

K = VerdictKind
DOUCHE = Shape(1, "S")
MINOUCHE = Shape(2, "S")
GOOSE = Shape(1, "s")


def run(name: str, target: Shape, **kw):
    return detect(synthesize(utterance(LIBRARY[name], **kw)), target)


class TestExpectedVerdicts(unittest.TestCase):
    CASES = [
        ("douche", DOUCHE, K.COMPLETE),
        ("dou", DOUCHE, K.MISSING_FINAL_CONSONANT),
        ("douche_schwa", DOUCHE, K.COMPLETE),
        ("dou_clic", DOUCHE, K.MISSING_FINAL_CONSONANT),
        ("minouche", MINOUCHE, K.COMPLETE),
        ("minou", MINOUCHE, K.MISSING_FINAL_CONSONANT),
        ("mi", MINOUCHE, K.FEWER_SYLLABLES),
        ("minousse", MINOUCHE, K.COMPLETE),
        ("fish", DOUCHE, K.COMPLETE),
        ("fi", DOUCHE, K.MISSING_FINAL_CONSONANT),
        ("goose", GOOSE, K.COMPLETE),
        ("goo", GOOSE, K.MISSING_FINAL_CONSONANT),
        ("chut", DOUCHE, K.UNSURE),
    ]

    def test_library(self):
        for name, target, expected in self.CASES:
            with self.subTest(name=name):
                self.assertIs(run(name, target, seed=5).kind, expected)

    def test_silence_is_no_speech(self):
        v = detect(synthesize(utterance("_500")), DOUCHE)
        self.assertIs(v.kind, K.NO_SPEECH)
        v = detect([0.0] * 24_000, DOUCHE)
        self.assertIs(v.kind, K.NO_SPEECH)

    def test_word_without_expected_coda(self):
        self.assertIs(run("minou", Shape(2, None), seed=5).kind, K.COMPLETE)
        self.assertIs(run("mi", Shape(2, None), seed=5).kind, K.FEWER_SYLLABLES)


class TestAsymmetry(unittest.TestCase):
    """Propriété centrale : jamais « fin manquante » sur un mot complet,
    jamais « complet » sur un mot tronqué — quel que soit le bruit."""

    PAIRS = [("douche", "dou", DOUCHE), ("minouche", "minou", MINOUCHE), ("goose", "goo", GOOSE)]

    def test_over_noise_and_seeds(self):
        for full, cut, target in self.PAIRS:
            for snr in (35.0, 25.0, 15.0, 10.0, 5.0):
                for seed in (1, 2):
                    with self.subTest(word=full, snr=snr, seed=seed):
                        vf = run(full, target, snr_db=snr, seed=seed)
                        vc = run(cut, target, snr_db=snr, seed=seed)
                        self.assertIsNot(vf.kind, K.MISSING_FINAL_CONSONANT)
                        self.assertIsNot(vc.kind, K.COMPLETE)

    def test_low_snr_forbids_affirming_absence(self):
        v = run("dou", DOUCHE, snr_db=12.0, seed=3)
        self.assertIs(v.kind, K.UNSURE)
        self.assertIn("low_snr", v.reasons)

    def test_clean_signal_is_decisive(self):
        for snr in (35.0, 25.0):
            self.assertIs(run("dou", DOUCHE, snr_db=snr, seed=4).kind, K.MISSING_FINAL_CONSONANT)
            self.assertIs(run("douche", DOUCHE, snr_db=snr, seed=4).kind, K.COMPLETE)


class TestRobustness(unittest.TestCase):
    def test_gain_invariance(self):
        for gain in (-25.0, -10.0, 0.0, 10.0):
            with self.subTest(gain=gain):
                self.assertIs(run("douche", DOUCHE, gain_db=gain, seed=6).kind, K.COMPLETE)
                self.assertIs(run("dou", DOUCHE, gain_db=gain, seed=6).kind, K.MISSING_FINAL_CONSONANT)

    def test_child_f0_range(self):
        for f0 in (220.0, 300.0, 420.0):
            with self.subTest(f0=f0):
                v = run("minouche", MINOUCHE, f0_start=f0, f0_end=f0 * 0.85, seed=7)
                self.assertIs(v.kind, K.COMPLETE)

    def test_speaking_rate(self):
        for scale in (0.7, 1.4):
            spec = " ".join(f"{s.phone}{s.ms * scale:g}" for s in utterance(LIBRARY["minouche"]).segments)
            with self.subTest(scale=scale):
                v = detect(synthesize(utterance(spec, seed=8)), MINOUCHE)
                self.assertIs(v.kind, K.COMPLETE)

    def test_white_noise(self):
        self.assertIs(run("minouche", MINOUCHE, noise="white", seed=9).kind, K.COMPLETE)
        self.assertIs(run("minou", MINOUCHE, noise="white", seed=9).kind, K.MISSING_FINAL_CONSONANT)

    def test_48k_input_path(self):
        x = synthesize(utterance(LIBRARY["douche"], rate=48_000, seed=10))
        self.assertIs(detect(x, DOUCHE, rate=48_000).kind, K.COMPLETE)
        y = synthesize(utterance(LIBRARY["dou"], rate=48_000, seed=10))
        self.assertIs(detect(y, DOUCHE, rate=48_000).kind, K.MISSING_FINAL_CONSONANT)


class TestSafetyGuards(unittest.TestCase):
    def test_adult_voice_is_unsure(self):
        v = run("douche", DOUCHE, f0_start=120.0, f0_end=100.0, seed=11)
        self.assertIs(v.kind, K.UNSURE)
        self.assertIn("adult_voice_suspected", v.reasons)

    def test_clipping_is_unsure(self):
        v = run("douche", DOUCHE, gain_db=24.0, seed=12)
        self.assertIs(v.kind, K.UNSURE)
        self.assertIn("clipping", v.reasons)

    def test_breathy_ending_is_never_complete(self):
        self.assertIsNot(run("dou_souffle", DOUCHE, seed=13).kind, K.COMPLETE)

    def test_late_noise_is_not_a_coda(self):
        v = run("dou_clic", DOUCHE, seed=14)
        self.assertFalse(v.coda_heard)

    def test_truncated_recording_is_unsure(self):
        v = run("dou", DOUCHE, post_ms=60.0, seed=15)
        self.assertIs(v.kind, K.UNSURE)

    def test_repeated_word_is_unsure(self):
        # « douche… douche » : selon la pause, un seul énoncé à 2 noyaux ou deux énoncés.
        for gap, reason in ((150, "extra_nuclei"), (900, "multiple_utterances")):
            spec = LIBRARY["douche"] + f" _{gap} " + LIBRARY["douche"]
            with self.subTest(gap=gap):
                v = detect(synthesize(utterance(spec, seed=16)), DOUCHE)
                self.assertIs(v.kind, K.UNSURE)
                self.assertIn(reason, v.reasons)

    def test_syllabified_word_is_one_utterance(self):
        # L'enfant détache les syllabes, comme les wagons : « mi … nouche ».
        v = detect(synthesize(utterance("m70 i160 _350 n70 u190 S180", seed=16)), MINOUCHE)
        self.assertIs(v.kind, K.COMPLETE)
        self.assertEqual(v.heard_nuclei, 2)

    def test_quiet_second_sound_is_ignored(self):
        # Un bruit faible et long après le mot (≥ 10 dB sous la voyelle) ne bloque pas.
        spec = LIBRARY["douche"] + " _900 h:a200/-22"
        v = detect(synthesize(utterance(spec, seed=16)), DOUCHE)
        self.assertIs(v.kind, K.COMPLETE)


class TestDetails(unittest.TestCase):
    def test_epenthetic_schwa_is_accepted(self):
        v = run("douche_schwa", DOUCHE, seed=17)
        self.assertTrue(v.epenthesis)
        self.assertEqual(v.heard_nuclei, 1)

    def test_place_hint_is_informative_not_blocking(self):
        v = run("minousse", MINOUCHE, seed=18)
        self.assertIs(v.kind, K.COMPLETE)
        self.assertEqual(v.coda_place, "alveolar")
        self.assertIn("place_differs", v.reasons)
        self.assertEqual(run("minouche", MINOUCHE, seed=18).coda_place, "postalveolar")

    def test_nuclei_count_and_coda_duration(self):
        an = analyze(synthesize(utterance(LIBRARY["minouche"], seed=19)))
        self.assertEqual(len(an.nuclei), 2)
        v = evaluate(an, MINOUCHE)
        self.assertGreaterEqual(v.coda_ms, 120.0)       # /ʃ/ synthétique de 180 ms

    def test_config_is_honoured(self):
        strict = DetectorConfig(min_snr_db=60.0)
        v = detect(synthesize(utterance(LIBRARY["dou"], seed=20)), DOUCHE, cfg=strict)
        self.assertIs(v.kind, K.UNSURE)

    def test_verdict_serializes(self):
        d = run("douche", DOUCHE, seed=21).to_dict()
        self.assertEqual(d["kind"], "complete")
        self.assertIsInstance(d["reasons"], list)

    def test_resample_roundtrip_keeps_verdict(self):
        x = synthesize(utterance(LIBRARY["minou"], seed=22))
        up = resample(x, 24_000, 48_000)
        self.assertIs(detect(up, MINOUCHE, rate=48_000).kind, K.MISSING_FINAL_CONSONANT)


if __name__ == "__main__":
    unittest.main()
