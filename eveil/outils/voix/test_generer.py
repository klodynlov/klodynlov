"""L'inventaire de la voix préparée suit l'app (mêmes énoncés, même clé) ; le manifeste est à jour."""
from __future__ import annotations

import json
import math
import re
import unittest

from voix import composer, generer


class TestVoix(unittest.TestCase):
    def test_cle_comme_dans_l_app(self):
        e = generer.Enonce("fr-FR", "word", "douche", "duʃ")
        self.assertEqual(e.cle, "fr-FR|word|douche|duʃ")
        self.assertEqual(generer.Enonce("fr-FR", "word", "Encore !", "").cle, "fr-FR|word|Encore !|")
        self.assertTrue(e.fichier.endswith(".m4a") and len(e.fichier) == 20)

    def test_inventaire(self):
        inv = generer.inventaire()
        cles = {e.cle for e in inv}
        self.assertEqual(len(cles), len(inv))                          # pas de doublon
        self.assertIn("fr-FR|word|douche|duʃ", cles)
        self.assertIn("fr-FR|syllable|mi|mi", cles)                  # minouche : wagon et modèle
        self.assertIn("fr-FR|syllable|nouch|nuʃ", cles)              # la dernière syllabe garde sa fin
        self.assertIn("fr-FR|syllable|nou|nu", cles)                 # le wagon touché, sans la fin
        self.assertIn("fr-FR|word|jus|ʒy", cles)                     # un mot des livres entré dans le train
        self.assertFalse(any(e.text in ("ch", "s", "sse") for e in inv))   # pas de son seul
        # La bulle dite à voix haute (17/11/2026) : messages, invitation et décompte de 1 à 5.
        self.assertIn("fr-FR|sentence|À toi ! Dis-le 3 fois au petit train.|", cles)
        self.assertIn("fr-FR|sentence|Bravo ! Encore 2 fois !|", cles)
        self.assertIn("fr-FR|sentence|Écoute bien le train…|", cles)
        self.assertIn("en-US|sentence|Well done!|", cles)

    def test_dire_sans_changer_la_cle(self):
        self.assertEqual(generer.a_dire("fr-FR", "On l'accroche avec « chhh » ?"), "On l'accroche avec chhhhhh ?")

    def test_manifeste_a_jour(self):
        self.assertEqual(generer.verifier(), 0)
        m = json.loads((generer.SORTIE / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(m["voix"], "Supertonic 3, style F5")
        self.assertEqual(m["licence"], "OpenRAIL-M")


class TestActivites(unittest.TestCase):
    """Les autres activités (17/11/2026) : l'inventaire vient de l'app (JSON écrit par un test Swift)."""

    def test_inventaire_lu_et_ajoute(self):
        fr = generer.activites("fr-FR")
        self.assertIn(("Colorie le soleil en jaune !", "coloriage"), fr)
        self.assertIn(("Qui fait ce bruit ?", "ecoute"), fr)
        self.assertIn(("Le chat mange quoi ?", "phrases_questions"), fr)
        self.assertIn(("le chat", "phrases_morceaux"), fr)
        self.assertIn(("À toi !", "livres"), fr)
        self.assertIn(("What does the cat do?", "phrases_questions"), generer.activites("en-US"))
        cles = {e.cle for e in generer.inventaire()}
        for locale in generer.LOCALES:
            for texte, _ in generer.activites(locale):
                self.assertIn(f"{locale}|sentence|{texte}|", cles)   # débit « phrase », sans API

    def test_inventaire_absent(self):
        ancien = generer.INVENTAIRE_ACTIVITES
        try:
            generer.INVENTAIRE_ACTIVITES = ancien.parent / "n-existe-pas.json"
            self.assertEqual(generer.activites("fr-FR"), [])
        finally:
            generer.INVENTAIRE_ACTIVITES = ancien

    def test_inventaire_ecrit_par_l_app(self):
        d = json.loads(generer.INVENTAIRE_ACTIVITES.read_text(encoding="utf-8"))
        self.assertIn("VoiceInventoryTests", d["_note"])
        self.assertEqual(set(d["fr-FR"]), {"coloriage", "ecoute", "phrases_questions", "phrases_morceaux", "livres"})
        self.assertTrue(all(len(x["morceaux"]) >= 2 for x in d["_composition"]["fr-FR"]))

    def test_lectures_phrase(self):
        self.assertEqual(generer.lectures_phrase("fr-FR", "Le chat dort où ?"),
                         ["Le chat dort… où ?", "Le chat dort, où ?"])
        self.assertEqual(generer.lectures_phrase("fr-FR", "Le chat mange quoi ?"),
                         ["Le chat mange quoi ?", "Le chat mange… quoi ?"])
        self.assertEqual(generer.lectures_phrase("fr-FR", "Où est l'os ?"), ["Où est l'osse ?"])
        self.assertEqual(generer.lectures_phrase("fr-FR", "Ça, c'est l'oiseau."), ["Ça, c'est l'oiseau."])
        self.assertEqual(generer.lectures_phrase("en-US", "The cat sleeps where?"), ["The cat sleeps where?"])
        self.assertEqual(generer.lectures_phrase("fr-FR", "rit"), ["ri"])                 # sinon « ré », « rite »
        self.assertEqual(generer.lectures_phrase("fr-FR", "La biche rit où ?"), ["La biche ri… où ?", "La biche ri, où ?"])
        self.assertEqual(generer.lectures_phrase("fr-FR", "Lou"), ["Lou", "Lou !"])
        self.assertEqual(generer.lectures_phrase("fr-FR", "Lou dort où ?")[0], "Lou dort… où ?")

    def test_wer_normalise(self):
        self.assertEqual(generer.wer("Ça, c'est la vache.", "Ça c'est la vache"), 0)
        self.assertEqual(generer.wer("Le chat dort où ?", "Le chat dort ou..."), 0)       # accents
        self.assertEqual(generer.wer("Ça, c'est Lou.", "Ça c'est loup.", "fr-FR"), 0)     # homophones
        self.assertEqual(generer.wer("Le chat dort où ?", "Le chat d'orot."), 0.5)    # « d orot » : 2 mots faux sur 4
        self.assertEqual(generer.wer("Well done!", "Well, done."), 0)
        self.assertEqual(generer.wer("Le chat sent quoi ?", "Le chat sang quoi ?", "fr-FR"), 0)
        self.assertEqual(generer.wer("Le chat rit.", "Le chat riz.", "fr-FR"), 0)
        self.assertEqual(generer.wer("dort", "d'or.", "fr-FR"), 0)
        self.assertEqual(generer.wer("That's sleeps.", "that sleeps.", "en-US"), 0)

    def test_exceptions_justifiees(self):
        exc = json.loads(generer.EXCEPTIONS.read_text(encoding="utf-8"))
        m = json.loads((generer.SORTIE / "manifest.json").read_text(encoding="utf-8"))["clips"]
        textes = {f"{loc}|{t}" for loc in generer.LOCALES for t, _ in generer.activites(loc)}
        for cle, raison in exc.items():
            self.assertIn(cle, textes)
            self.assertIn("Whisper", raison)
            loc, texte = cle.split("|", 1)
            self.assertNotIn(generer.Enonce(loc, "sentence", texte, "").cle, m)   # vraiment sans fichier


class TestTaille(unittest.TestCase):
    def test_sans_bourrage_ne_change_pas_le_son(self):
        import shutil
        import subprocess
        import tempfile
        from pathlib import Path
        if not shutil.which("afconvert"):
            self.skipTest("afconvert (macOS)")
        m = json.loads((generer.SORTIE / "manifest.json").read_text(encoding="utf-8"))["clips"]
        mot = next(f for k, f in sorted(m.items()) if "|word|" in k)          # les mots gardent leur bourrage
        with tempfile.TemporaryDirectory() as tmp:
            a, b = Path(tmp) / "a.m4a", Path(tmp) / "b.m4a"
            shutil.copy(generer.SORTIE / mot, a)
            shutil.copy(a, b)
            self.assertGreater(generer.sans_bourrage(b), 1000)
            self.assertEqual(generer.sans_bourrage(b), 0)                       # déjà fait : rien
            for x in (a, b):
                subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16", str(x), str(x.with_suffix(".wav"))], check=True)
            self.assertEqual(a.with_suffix(".wav").read_bytes(), b.with_suffix(".wav").read_bytes())

    def test_phrases_sans_bourrage(self):
        m = json.loads((generer.SORTIE / "manifest.json").read_text(encoding="utf-8"))["clips"]
        phrases = [f for k, f in m.items() if "|sentence|" in k]
        self.assertGreater(len(phrases), 2500)
        import struct
        for f in phrases[::97]:
            d, i, noms = (generer.SORTIE / f).read_bytes(), 0, []
            while i < len(d):
                n, t = struct.unpack(">I4s", d[i:i + 8])
                noms.append(t)
                i += n
            self.assertEqual(i, len(d), f)
            self.assertEqual(noms, [b"ftyp", b"moov", b"mdat"], f)


class TestComposer(unittest.TestCase):
    def test_memes_constantes_que_l_app(self):
        swift = (generer.EVEIL / "ios" / "Sources" / "WordEndAudio" / "ClipJoiner.swift").read_text(encoding="utf-8")
        for nom, valeur in [("frame", composer.TRAME), ("threshold", composer.SEUIL), ("lead", composer.AVANT),
                            ("tail", composer.APRES), ("gap", composer.PAUSE), ("fade", composer.FONDU)]:
            m = re.search(rf"static let {nom} = ([0-9.]+)", swift)
            self.assertIsNotNone(m, nom)
            self.assertAlmostEqual(float(m.group(1)), valeur, msg=nom)

    def test_coupe_le_silence_et_pose_une_pause(self):
        rate = 8000
        voix = [0.5 * math.sin(i * 2 * math.pi * 220 / rate) for i in range(int(rate * 0.5))]
        m = [0.0] * int(rate * 0.3) + voix + [0.0] * int(rate * 0.4)
        a, b = composer.zone_parlee(m, rate)
        self.assertAlmostEqual(a / rate, 0.3 - composer.AVANT, delta=0.011)
        self.assertAlmostEqual(b / rate, 0.8 + composer.APRES, delta=0.011)
        x = composer.composer([m, m], rate)
        attendu = 2 * (0.5 + composer.AVANT + composer.APRES) + composer.PAUSE
        self.assertAlmostEqual(len(x) / rate, attendu, delta=0.03)
        self.assertEqual(x[0], 0.0)


if __name__ == "__main__":
    unittest.main()
