"""Tests des lexiques, du banc de validation et des vecteurs de référence."""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from wordend import golden
from wordend.bench import (Gate, build_demo_corpus, cohen_kappa, evaluate_corpus, read_annotations,
                           read_wav, wilson, write_wav)
from wordend.lexicon import (caboose_segment, custom_word, ipa_syllables, load_locale, problems, voice_segments,
                             wagon_segments)
from wordend.synth import LIBRARY, synthesize, utterance


class TestLexicons(unittest.TestCase):
    def test_both_lexicons_are_sound(self):
        for locale in ("fr-FR", "en-US"):
            with self.subTest(locale=locale):
                lex = load_locale(locale)
                self.assertEqual(problems(lex), [])
                self.assertGreaterEqual(len(lex.words), 10)
                self.assertIn("PROPOS", lex.status.upper())       # proposition à valider

    def test_lists_are_designed_not_translated(self):
        # Les listes à fourgon, écrites à la main. Les mots des livres (avec leur dessin) sont les
        # mêmes objets dans les deux langues : « orange », « table » s'écrivent pareil, c'est voulu.
        fr = {w.text for w in load_locale("fr-FR").words if not w.drawing}
        en = {w.text for w in load_locale("en-US").words if not w.drawing}
        self.assertEqual(fr & en, set())

    def test_levels_progress(self):
        for locale in ("fr-FR", "en-US"):
            lex = load_locale(locale)
            self.assertTrue(all(w.nuclei == 1 for w in lex.words if w.level == 1))
            self.assertTrue(any(w.nuclei == 2 for w in lex.words if w.level == 2))

    def test_voice_follows_the_wagons(self):
        """La voix modèle dit un segment par wagon ; le dernier garde la consonne finale."""
        fr = load_locale("fr-FR")
        segs = voice_segments(fr.by_id("fr.minouche"))
        self.assertEqual([(s.text, s.ipa) for s in segs], [("mi", "mi"), ("nouch", "nuʃ")])
        segs = voice_segments(load_locale("en-US").by_id("en.radish"))
        self.assertEqual([(s.text, s.ipa) for s in segs], [("ra", "ɹæ"), ("dish", "dɪʃ")])
        for locale in ("fr-FR", "en-US"):
            for w in load_locale(locale).words:
                segs = voice_segments(w)
                self.assertEqual(len(segs), len(w.wagons), w.id)
                self.assertTrue(all(s.ipa for s in segs), w.id)
                self.assertEqual("".join(s.ipa for s in segs), "".join(ipa_syllables(w.ipa)), w.id)

    def test_touching_a_wagon_says_its_syllable(self):
        """Toucher un wagon fait entendre SA syllabe ; le fourgon, sa consonne."""
        minouche = load_locale("fr-FR").by_id("fr.minouche")
        self.assertEqual([(s.text, s.ipa) for s in wagon_segments(minouche)], [("mi", "mi"), ("nou", "nu")])
        self.assertEqual((caboose_segment(minouche).text, caboose_segment(minouche).ipa), ("ch", "ʃ"))
        tasse = load_locale("fr-FR").by_id("fr.tasse")
        self.assertEqual([(s.text, s.ipa) for s in wagon_segments(tasse)], [("ta", "ta")])
        self.assertEqual(caboose_segment(tasse).ipa, "s")
        for locale in ("fr-FR", "en-US"):
            for w in load_locale(locale).words:
                wagons = wagon_segments(w)
                self.assertEqual(len(wagons), len(w.wagons), w.id)
                self.assertTrue(all(s.ipa for s in wagons), w.id)
                # Les wagons + le fourgon redonnent exactement le mot.
                fourgon = caboose_segment(w)
                self.assertEqual("".join(s.ipa for s in wagons) + (fourgon.ipa if fourgon else ""),
                                 "".join(ipa_syllables(w.ipa)), w.id)

    def test_voice_without_ipa_reads_the_wagons(self):
        w = custom_word("Minouche", ["Mi", "nou"], "S", "fr-FR")
        self.assertEqual([(s.text, s.ipa) for s in voice_segments(w)], [("Mi", None), ("nou", None)])

    def test_ipa_syllables(self):
        self.assertEqual(ipa_syllables("ˈɹæ.dɪʃ"), ["ɹæ", "dɪʃ"])
        self.assertEqual(ipa_syllables("pʁɛ̃.sɛs"), ["pʁɛ̃", "sɛs"])
        self.assertEqual(ipa_syllables("duʃ"), ["duʃ"])

    def test_custom_family_word(self):
        w = custom_word("Minouche", ["Mi", "nou"], "S", "fr-FR")
        self.assertEqual((w.nuclei, w.coda, w.caboose, w.custom), (2, "S", "ch", True))
        self.assertTrue(w.id.startswith("fr.perso."))
        self.assertEqual(custom_word("Moose", ["moo"], "s", "en-US").caboose, "s")
        with self.assertRaises(ValueError):
            custom_word("", ["a"], None, "fr-FR")
        with self.assertRaises(ValueError):
            custom_word("robot", ["ro", "bot"], "t", "fr-FR")
        with self.assertRaises(ValueError):
            custom_word("x", ["a", "b", "c", "d", "e"], None, "fr-FR")


class TestStatistics(unittest.TestCase):
    def test_kappa_textbook_example(self):
        # 50 items : 20 oui/oui, 15 non/non, 5 oui/non, 10 non/oui ⇒ κ = 0,4
        a = ["oui"] * 20 + ["non"] * 15 + ["oui"] * 5 + ["non"] * 10
        b = ["oui"] * 20 + ["non"] * 15 + ["non"] * 5 + ["oui"] * 10
        self.assertAlmostEqual(cohen_kappa(a, b), 0.4, places=9)
        self.assertEqual(cohen_kappa(["x", "y"], ["x", "y"]), 1.0)

    def test_wilson_interval(self):
        lo, hi = wilson(0, 30)
        self.assertEqual(lo, 0.0)
        self.assertAlmostEqual(hi, 0.1135, places=3)   # « 0/30 » n'est pas « 0 % »
        lo, hi = wilson(5, 10)
        self.assertAlmostEqual(lo, 0.2366, places=3)
        self.assertAlmostEqual(hi, 0.7634, places=3)


class TestBench(unittest.TestCase):
    def test_wav_roundtrip(self):
        x = synthesize(utterance(LIBRARY["douche"], seed=41))
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "t.wav"
            write_wav(p, x, 24_000)
            y, rate = read_wav(p)
        self.assertEqual(rate, 24_000)
        self.assertEqual(len(y), len(x))
        self.assertLess(max(abs(a - b) for a, b in zip(x, y)), 1e-4)

    def test_annotations_parsing(self):
        lex = load_locale("fr-FR")
        text = "fichier,mot,juge_a,juge_b\na.wav,fr.douche,complet,complet\nb.wav,douche,autre,complet\n"
        items, excluded = read_annotations(text, lex)
        self.assertEqual((len(items), excluded), (1, 1))
        text = "fichier;mot;juge_a;juge_b;noyaux;coda\nc.wav;Titouche;fin_absente;fin_absente;2;S\n"
        items, _ = read_annotations(text, None)
        self.assertEqual((items[0].nuclei, items[0].coda), (2, "S"))
        with self.assertRaises(ValueError):
            read_annotations("fichier;mot;juge_a;juge_b\na.wav;fr.douche;peut-etre;complet\n", lex)

    def test_demo_corpus_end_to_end(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            text = build_demo_corpus(root, seeds=(1, 2))
            items, excluded = read_annotations(text, load_locale("fr-FR"))
            rep = evaluate_corpus(items, root, gate=Gate(max_false_alarm_upper=0.5))
        self.assertEqual(rep.false_alarm[0], 0)             # aucune fausse alerte
        self.assertEqual(rep.detection, (4, 4))             # absences toutes détectées
        self.assertEqual(rep.n_consensus, rep.n_items - 1)  # le désaccord est écarté
        self.assertTrue(rep.go)
        md = rep.markdown()
        self.assertIn("Fausse alerte", md)
        self.assertIn("GO", md)

    def test_gate_refuses_small_evidence(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            text = build_demo_corpus(root, seeds=(1,))
            items, _ = read_annotations(text, load_locale("fr-FR"))
            rep = evaluate_corpus(items, root)              # porte par défaut : borne haute ≤ 10 %
        # 0 fausse alerte sur 2 mots complets : l'IC95 reste bien trop large pour conclure.
        self.assertEqual(rep.false_alarm, (0, 2))
        self.assertFalse(rep.go)


class TestGolden(unittest.TestCase):
    def test_golden_file_is_current(self):
        self.assertTrue(golden.GOLDEN_PATH.exists(), "lancer `python3 -m wordend.golden`")
        self.assertEqual(golden.GOLDEN_PATH.read_text(encoding="utf-8"), golden.render(golden.build()),
                         "vecteurs périmés : relancer `python3 -m wordend.golden`")


if __name__ == "__main__":
    unittest.main()
