"""L'inventaire de la voix préparée suit l'app (mêmes énoncés, même clé) ; le manifeste est à jour."""
from __future__ import annotations

import json
import unittest

from voix import generer


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
        self.assertIn("en-US|sentence|Choo-choo! All aboard!|", cles)

    def test_dire_sans_changer_la_cle(self):
        self.assertEqual(generer.a_dire("fr-FR", "On l'accroche avec « chhh » ?"), "On l'accroche avec chhhhhh ?")

    def test_manifeste_a_jour(self):
        self.assertEqual(generer.verifier(), 0)
        m = json.loads((generer.SORTIE / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(m["voix"], "Supertonic 3, style F5")
        self.assertEqual(m["licence"], "OpenRAIL-M")


if __name__ == "__main__":
    unittest.main()
