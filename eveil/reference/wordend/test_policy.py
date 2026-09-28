"""Tests de la politique pédagogique : ce qu'un enfant de 3 ans voit et entend."""
from __future__ import annotations

import unittest

from wordend.detector import LexicalEvidence, Verdict, VerdictKind, apply_lexical
from wordend.lexicon import lexical_evidence, load_locale
from wordend.policy import (DEFAULT_REPETITIONS, MAX_ATTEMPTS, MAX_STARS, MESSAGES, NEUTRAL_KEYS,
                            REPETITIONS, RepetitionPlan, SessionPolicy, again_text, feedback_for,
                            invite_text, stars_for)

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
                for left in (0, 2):
                    keys.add(feedback_for(verdict(kind), 2, True, attempt, repetitions_left=left).message_key)
        for locale in ("fr-FR", "en-US"):
            self.assertLessEqual(keys, set(MESSAGES[locale]), locale)
        self.assertEqual(set(MESSAGES["fr-FR"]), set(MESSAGES["en-US"]))


class TestRepetitions(unittest.TestCase):
    """Le décompte (« encore 2 fois ») : seul un mot bien dit le fait avancer."""

    def test_success_with_repetitions_left_celebrates_and_waits(self):
        fb = feedback_for(verdict(K.COMPLETE), 2, True, attempt=1, repetitions_left=2)
        self.assertEqual((fb.caboose, fb.mascot, fb.message_key, fb.advance),
                         ("hooked", "celebrate", "again", False))
        self.assertEqual(fb.lit_wagons, (True, True))
        last = feedback_for(verdict(K.COMPLETE), 2, True, attempt=1, repetitions_left=0)
        self.assertEqual((last.message_key, last.advance), ("bravo", True))

    def test_repetitions_never_trap_the_child(self):
        # Règle 4 à chaque répétition : au bout de MAX_ATTEMPTS, on passe quand même.
        for kind in K:
            fb = feedback_for(verdict(kind), 2, True, attempt=MAX_ATTEMPTS, repetitions_left=4)
            self.assertTrue(fb.advance or fb.message_key == "again", kind)
            if kind is not K.COMPLETE:
                self.assertTrue(fb.advance, kind)

    def test_only_complete_is_changed_by_repetitions(self):
        for kind in K:
            if kind is K.COMPLETE:
                continue
            for attempt in range(1, MAX_ATTEMPTS + 1):
                self.assertEqual(feedback_for(verdict(kind), 2, True, attempt, repetitions_left=3),
                                 feedback_for(verdict(kind), 2, True, attempt), (kind, attempt))

    def test_plan_counts_down(self):
        plan = RepetitionPlan(3)
        self.assertEqual((plan.remaining, plan.left_after_success(), plan.is_complete), (3, 2, False))
        plan.record_success()
        plan.record_success()
        self.assertEqual((plan.remaining, plan.left_after_success()), (1, 0))
        plan.record_success()
        plan.record_success()                       # jamais au-delà
        self.assertEqual((plan.done, plan.remaining, plan.is_complete), (3, 0, True))

    def test_plan_is_clamped(self):
        self.assertEqual(RepetitionPlan(0).target, REPETITIONS[0])
        self.assertEqual(RepetitionPlan(99).target, REPETITIONS[-1])
        self.assertEqual(RepetitionPlan().target, DEFAULT_REPETITIONS)
        self.assertIn(DEFAULT_REPETITIONS, REPETITIONS)

    def test_countdown_texts(self):
        self.assertEqual(again_text(2, "fr-FR"), "Bravo ! Encore 2 fois !")
        self.assertEqual(again_text(1, "fr-FR"), "Bravo ! Encore une fois !")
        self.assertEqual(again_text(3, "en-US"), "Great! 3 more times!")
        self.assertEqual(again_text(1, "en-US"), "Great! One more time!")
        self.assertEqual(invite_text(3, "fr-FR"), "À toi ! Dis-le 3 fois au petit train.")
        self.assertEqual(invite_text(1, "fr-FR"), MESSAGES["fr-FR"]["invite"])
        self.assertEqual(invite_text(2, "en-US"), "Your turn! Say it 2 times to the little train.")


class TestStars(unittest.TestCase):
    """Les étoiles : plus c'est bien dit, plus il y en a — jamais un score, jamais une perte."""

    def test_complete_is_the_best(self):
        best = stars_for(verdict(K.COMPLETE))
        self.assertEqual(best, MAX_STARS)
        for kind in K:
            self.assertLessEqual(stars_for(verdict(kind)), best, kind)
            self.assertGreaterEqual(stars_for(verdict(kind)), 0, kind)

    def test_order_follows_the_train(self):
        s = {kind: stars_for(verdict(kind)) for kind in K}
        self.assertGreater(s[K.COMPLETE], s[K.MISSING_FINAL_CONSONANT])
        self.assertGreater(s[K.MISSING_FINAL_CONSONANT], s[K.FEWER_SYLLABLES])
        self.assertGreater(s[K.FEWER_SYLLABLES], s[K.NO_SPEECH])
        self.assertEqual(s[K.NO_SPEECH], 0)

    def test_doubt_costs_no_more_than_a_missing_end(self):
        # Asymétrie : un « pas sûr » (bruit, voix d'adulte…) ne coûte pas plus qu'une fin manquée.
        self.assertGreaterEqual(stars_for(verdict(K.UNSURE)), stars_for(verdict(K.MISSING_FINAL_CONSONANT)))
        self.assertGreater(stars_for(verdict(K.UNSURE)), stars_for(verdict(K.FEWER_SYLLABLES)))

    def test_word_without_caboose(self):
        self.assertEqual(stars_for(verdict(K.MISSING_FINAL_CONSONANT), has_caboose=False),
                         stars_for(verdict(K.UNSURE)))
        self.assertEqual(stars_for(verdict(K.COMPLETE), has_caboose=False), MAX_STARS)


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
