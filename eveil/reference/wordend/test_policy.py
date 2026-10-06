"""Tests de la politique pédagogique : ce qu'un enfant de 3 ans voit et entend."""
from __future__ import annotations

import unittest

from wordend.detector import LexicalEvidence, Verdict, VerdictKind, apply_lexical
from wordend.lexicon import lexical_evidence, load_locale
from wordend.policy import (DEFAULT_REPETITIONS, LEVELS, MAX_ATTEMPTS, MAX_STARS, MESSAGES, MIXED_LEVEL,
                            NEUTRAL_KEYS, REPETITIONS, UNLOCK_WORDS, LevelProgress, RepetitionPlan,
                            SessionPolicy, again_text, deck, feedback_for, invite_text, level_words,
                            mixed, next_level, stars_for, unlock_target)

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



class TestLevels(unittest.TestCase):
    """Progression « quand il réussit » : une syllabe d'abord (conseil d'une orthophoniste)."""

    def setUp(self):
        self.fr = load_locale("fr-FR").words
        self.en = load_locale("en-US").words

    def test_level_one_is_one_syllable_words_only(self):
        for words in (self.fr, self.en):
            d = deck(words, 1)
            self.assertTrue(d)
            self.assertTrue(all(w.level == 1 and len(w.wagons) == 1 for w in d))
            self.assertEqual([w.id for w in d], [w.id for w in words if w.level == 1])   # ordre du lexique

    def test_each_level_plays_only_its_words(self):
        for lv in (1, 2, 3):
            self.assertTrue(all(w.level == lv for w in deck(self.fr, lv)))
        self.assertTrue(all(len(w.wagons) == 2 for w in deck(self.fr, 2)))

    def test_level_four_mixes_every_word_once(self):
        d = deck(self.fr, MIXED_LEVEL)
        self.assertEqual(sorted(w.id for w in d), sorted(w.id for w in self.fr))
        self.assertEqual([w.level for w in d[:6]], [1, 1, 2, 1, 3, 2])
        self.assertEqual(d, mixed(self.fr))
        self.assertEqual(d, deck(self.fr, MIXED_LEVEL))                                  # pas de hasard

    def test_unlock_target(self):
        self.assertEqual(unlock_target(self.fr, 1), UNLOCK_WORDS)
        trois = level_words(self.fr, 1)[:3]                                              # moins de 6 : tous
        self.assertEqual(unlock_target(trois, 1), 3)

    def test_starts_at_one_syllable(self):
        self.assertEqual(LevelProgress().level, 1)
        self.assertEqual(LEVELS, (1, 2, 3, 4))

    def test_six_different_words_open_the_next_level_next_session(self):
        p = LevelProgress()
        ones = level_words(self.fr, 1)
        for w in ones[:UNLOCK_WORDS - 1]:
            p.record(w, K.COMPLETE)
            p.record(w, K.COMPLETE)                       # le même mot deux fois ne compte qu'une fois
        self.assertFalse(p.ready(self.fr))
        self.assertEqual(p.start_session(self.fr), 1)
        p.record(ones[UNLOCK_WORDS - 1], K.COMPLETE)
        self.assertTrue(p.ready(self.fr))
        self.assertEqual(p.level, 1)                      # rien ne change pendant la séance
        self.assertEqual(p.start_session(self.fr), 2)     # la séance suivante
        self.assertEqual(p.said, set())                   # le compte repart de zéro

    def test_only_a_complete_verdict_counts(self):
        p = LevelProgress()
        for kind in K:
            if kind is not K.COMPLETE:
                for w in level_words(self.fr, 1):
                    p.record(w, kind)
        self.assertEqual(p.said, set())

    def test_demo_and_adult_trial_count_nothing(self):
        p = LevelProgress()
        for w in level_words(self.fr, 1):
            p.record(w, K.COMPLETE, counted=False)
        self.assertEqual(p.start_session(self.fr), 1)

    def test_words_of_another_level_do_not_count(self):
        p = LevelProgress()
        for w in self.fr:
            if w.level != 1:
                p.record(w, K.COMPLETE)
        self.assertFalse(p.ready(self.fr))

    def test_whole_path_then_stays(self):
        p = LevelProgress()
        seen = [p.level]
        for _ in range(10):
            for w in level_words(self.en, p.level) if p.level < MIXED_LEVEL else self.en:
                p.record(w, K.COMPLETE)
            p.start_session(self.en)
            seen.append(p.level)
        self.assertEqual(seen[:4], [1, 2, 3, 4])
        self.assertTrue(all(lv == MIXED_LEVEL for lv in seen[3:]))

    def test_never_goes_down_by_itself(self):
        p = LevelProgress(level=3)
        for _ in range(5):                                # des séances ratées : on reste au niveau 3
            for kind in K:
                if kind is not K.COMPLETE:
                    for w in self.fr:
                        p.record(w, kind)
            self.assertEqual(p.start_session(self.fr), 3)

    def test_adult_sets_the_level_and_the_count_restarts(self):
        p = LevelProgress()
        for w in level_words(self.fr, 1):
            p.record(w, K.COMPLETE)
        p.set_by_adult(1)                                 # l'adulte veut qu'il reste au niveau 1
        self.assertEqual(p.start_session(self.fr), 1)
        p.set_by_adult(9)
        self.assertEqual(p.level, MIXED_LEVEL)
        p.set_by_adult(0)
        self.assertEqual(p.level, 1)

    def test_empty_levels_are_skipped(self):
        only_ones = level_words(self.fr, 1)
        self.assertEqual(next_level(only_ones, 1), MIXED_LEVEL)
        self.assertEqual(next_level(self.fr, 1), 2)
        self.assertEqual(deck(only_ones, 2), mixed(only_ones))   # niveau vide : tous les mots

    def test_one_syllable_first_every_sound(self):
        """Demande de l'utilisateur (06/10/2026) : « commencer avec des mots d'une syllabe, comme mur,
        vert, ne plus se focaliser sur les ch ou ss », puis « pas que mur et vert : des mots comme jus,
        peau ». Le niveau 1 commence par « jus », « peau », puis les autres mots finis par une voyelle
        (syllabe directe d'abord, Borel-Maisonny), sons d'attaque variés ; puis les syllabes fermées,
        où se mêlent les mots à fourgon (jugés sur leur fin « ch »/« s »)."""
        d = deck(self.fr, 1)
        self.assertEqual([w.text for w in d[:2]], ["jus", "peau"])
        self.assertIn("mur", [w.text for w in d])
        premiers = d[:12]
        self.assertTrue(all(w.coda is None and not w.ipa[-1] in "bdfgklmnpstvzʁʃʒ" for w in premiers))
        self.assertGreater(len({w.ipa[0] for w in premiers}), 8)        # pas toujours le même son
        self.assertTrue(any(w.coda is None for w in d) and any(w.coda for w in d))
        self.assertGreater(sum(w.coda is None for w in d), sum(w.coda is not None for w in d))

    def test_a_caboose_only_for_final_ch_or_s(self):
        """Le détecteur ne juge que « ch » et « s » en fin de mot : un mot qui finit autrement
        (« mur », /ʁ/) n'a pas de fourgon, et chaque mot sans fourgon a son dessin."""
        for words in (self.fr, self.en):
            for w in words:
                if w.coda is None:
                    self.assertIsNone(w.caboose, w.id)
                    self.assertTrue(w.drawing, w.id)
                else:
                    self.assertIn(w.coda, ("S", "s"), w.id)

if __name__ == "__main__":
    unittest.main()
