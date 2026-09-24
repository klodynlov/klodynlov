"""Tests de la politique pédagogique : ce qu'un enfant de 3 ans voit et entend."""
from __future__ import annotations

import unittest

from wordend.detector import LexicalEvidence, Verdict, VerdictKind, apply_lexical
from wordend.lexicon import lexical_evidence, load_locale
from wordend.policy import MAX_ATTEMPTS, MESSAGES, NEUTRAL_KEYS, SessionPolicy, feedback_for

K = VerdictKind


def verdict(kind: VerdictKind) -> Verdict:
    return Verdict(kind, heard_nuclei=1, expected_nuclei=2, coda_expected=True, coda_heard=False)


class TestFeedback(unittest.TestCase):
    def test_pointing_only_on_confident_missing(self):
        for kind in K:
            for attempt in range(1, MAX_ATTEMPTS + 1):
                fb = feedback_for(verdict(kind), wagons=2, has_caboose=True, attempt=attempt)
                pointing = fb.caboose == "pointed" or fb.mascot == "point_caboose"
                if pointing:
                    self.assertIs(kind, K.MISSING_FINAL_CONSONANT)

    def test_unsure_and_silence_are_neutral(self):
        for kind in (K.UNSURE, K.NO_SPEECH, K.FEWER_SYLLABLES):
            for attempt in range(1, MAX_ATTEMPTS + 1):
                fb = feedback_for(verdict(kind), wagons=2, has_caboose=True, attempt=attempt)
                self.assertIn(fb.message_key, NEUTRAL_KEYS, (kind, attempt))
                self.assertEqual(fb.caboose, "waiting")

    def test_fewer_syllables_never_designates_a_wagon(self):
        fb = feedback_for(verdict(K.FEWER_SYLLABLES), wagons=3, has_caboose=True, attempt=1)
        self.assertEqual(fb.lit_wagons, (False, False, False))
        self.assertEqual(fb.mascot, "model_word")

    def test_complete_lights_everything(self):
        fb = feedback_for(verdict(K.COMPLETE), wagons=2, has_caboose=True, attempt=1)
        self.assertEqual(fb.lit_wagons, (True, True))
        self.assertEqual(fb.caboose, "hooked")
        self.assertTrue(fb.advance)
        fb = feedback_for(verdict(K.COMPLETE), wagons=1, has_caboose=False, attempt=1)
        self.assertEqual(fb.caboose, "none")

    def test_missing_points_then_moves_on(self):
        first = feedback_for(verdict(K.MISSING_FINAL_CONSONANT), 2, True, attempt=1)
        self.assertEqual((first.caboose, first.mascot, first.advance), ("pointed", "point_caboose", False))
        self.assertEqual(first.lit_wagons, (True, True))
        last = feedback_for(verdict(K.MISSING_FINAL_CONSONANT), 2, True, attempt=MAX_ATTEMPTS)
        self.assertTrue(last.advance)
        self.assertEqual(last.message_key, "effort_next")

    def test_no_failure_loop(self):
        for kind in K:
            fb = feedback_for(verdict(kind), 2, True, attempt=MAX_ATTEMPTS)
            self.assertTrue(fb.advance, kind)

    def test_messages_exist_in_both_languages(self):
        keys = set()
        for kind in K:
            for attempt in (1, MAX_ATTEMPTS):
                keys.add(feedback_for(verdict(kind), 2, True, attempt).message_key)
        for locale in ("fr-FR", "en-US"):
            self.assertLessEqual(keys, set(MESSAGES[locale]), locale)
        self.assertEqual(set(MESSAGES["fr-FR"]), set(MESSAGES["en-US"]))


class TestLexicalGuard(unittest.TestCase):
    def test_transcripts(self):
        fr = load_locale("fr-FR")
        douche = fr.by_id("fr.douche")
        E = LexicalEvidence
        self.assertIs(lexical_evidence("Douche", douche), E.CONSISTENT)
        self.assertIs(lexical_evidence("doux", douche), E.CONSISTENT)      # forme tronquée = vrai mot
        self.assertIs(lexical_evidence("dou", douche), E.CONSISTENT)
        self.assertIs(lexical_evidence("le bain", douche), E.INCONSISTENT)
        self.assertIs(lexical_evidence("", douche), E.NOT_CHECKED)
        self.assertIs(lexical_evidence("  ?! ", douche), E.NOT_CHECKED)
        self.assertIs(lexical_evidence("mi nouche", fr.by_id("fr.minouche")), E.CONSISTENT)
        self.assertIs(lexical_evidence("BÛCHE", fr.by_id("fr.douche")), E.INCONSISTENT)

    def test_asr_can_only_make_verdicts_more_cautious(self):
        for kind in K:
            v = verdict(kind)
            for ev in LexicalEvidence:
                out = apply_lexical(v, ev)
                if out.kind is not kind:
                    self.assertIs(out.kind, K.UNSURE)
                    self.assertIs(ev, LexicalEvidence.INCONSISTENT)
                    self.assertIn("other_word_suspected", out.reasons)
            self.assertIs(apply_lexical(v, LexicalEvidence.CONSISTENT).kind, kind)   # jamais promu


class TestSessionPolicy(unittest.TestCase):
    def test_steps(self):
        p = SessionPolicy()
        self.assertEqual(p.next_step(0, 0, 0), "continue")
        self.assertEqual(p.next_step(p.words_per_session, 60, 60), "end_session")
        self.assertEqual(p.next_step(1, p.max_session_s, 60), "end_session")
        self.assertEqual(p.next_step(0, 0, p.daily_budget_s), "rest_today")

    def test_defaults_stay_short(self):
        p = SessionPolicy()
        self.assertLessEqual(p.max_session_s, 10 * 60)
        self.assertLessEqual(p.daily_budget_s, 20 * 60)


if __name__ == "__main__":
    unittest.main()
