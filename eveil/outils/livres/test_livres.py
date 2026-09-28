"""Tests des livres des sons : phonèmes, place du son, lettres colorées, livres construits.

    cd eveil/outils && python3 -m unittest livres.test_livres
"""
from __future__ import annotations

import unittest

from phrases.grammaire import morceau, phrase
from phrases.lexique import PAR_ID, PREP_EN, PREP_FR, VERBE_PAR_ID, VERBES

from .livres import MIN_MOTS, PLACES, SONS_EN, SONS_FR, _plier, lettres_du_son, livres
from .mots import NOUVEAUX, TOUS
from .phrases import CHOIX, PAR_NIVEAU, SYLLABES, a_le_son, phrases_du_livre
from .sons import lettres_dans_syllabe, ou_est, phonemes
from .verifier import lettres_suspectes, problemes


class TestPhonemes(unittest.TestCase):
    def test_une_syllabe_par_point(self):
        self.assertEqual(phonemes("ʒi.ʁaf", "fr-FR"), [("ʒ", 0), ("i", 0), ("ʁ", 1), ("a", 1), ("f", 1)])

    def test_la_voyelle_nasale_reste_entiere(self):
        self.assertEqual([p for p, _ in phonemes("ʃɑ̃.pi.ɲɔ̃", "fr-FR")], ["ʃ", "ɑ̃", "p", "i", "ɲ", "ɔ̃"])

    def test_diphtongues_et_affriquees_anglaises(self):
        self.assertEqual([p for p, _ in phonemes("keɪdʒ", "en-US")], ["k", "eɪ", "dʒ"])
        self.assertEqual([p for p, _ in phonemes("ˈsut.keɪs", "en-US")], ["s", "u", "t", "k", "eɪ", "s"])

    def test_en_francais_pas_d_affriquee(self):
        # « tʃ » n'existe pas dans les livres français : t puis ʃ.
        self.assertEqual([p for p, _ in phonemes("tʃa", "fr-FR")], ["t", "ʃ", "a"])


class TestPlaceDuSon(unittest.TestCase):
    def test_debut_milieu_fin(self):
        self.assertEqual((ou_est("ʃ", "ʃə.val", "fr-FR").syllabe, ou_est("ʃ", "ʃə.val", "fr-FR").position), (0, "debut"))
        self.assertEqual((ou_est("ʃ", "fuʁ.ʃɛt", "fr-FR").syllabe, ou_est("ʃ", "fuʁ.ʃɛt", "fr-FR").position), (1, "milieu"))
        self.assertEqual((ou_est("ʃ", "vaʃ", "fr-FR").syllabe, ou_est("ʃ", "vaʃ", "fr-FR").position), (0, "fin"))

    def test_absent(self):
        self.assertIsNone(ou_est("ʃ", "ʒi.ʁaf", "fr-FR"))

    def test_premiere_occurrence(self):
        # « sauce » /sos/ : le premier « s », au début.
        self.assertEqual(ou_est("s", "sos", "fr-FR").position, "debut")


class TestLettres(unittest.TestCase):
    def test_la_graphie_la_plus_longue_d_abord(self):
        son_s = next(s for s in SONS_FR if s.etiquette == "s")
        self.assertEqual(lettres_du_son(son_s, "trousse"), "ss")
        son_ch = next(s for s in SONS_FR if s.etiquette == "ch")
        self.assertEqual(lettres_du_son(son_ch, "chette"), "ch")

    def test_accents_ignores_mais_texte_garde(self):
        son_ch = next(s for s in SONS_FR if s.etiquette == "ch")
        self.assertEqual(lettres_du_son(son_ch, "bûche"), "ch")
        son_f = next(s for s in SONS_FR if s.etiquette == "f")
        self.assertEqual(lettres_du_son(son_f, "Fée"), "F")      # telles qu'écrites

    def test_introuvable(self):
        son_ch = next(s for s in SONS_FR if s.etiquette == "ch")
        self.assertEqual(lettres_du_son(son_ch, "gi"), "")

    def test_chaque_son_range_ses_graphies_des_plus_longues(self):
        # Une graphie contenue dans une autre doit venir APRÈS elle (« ss » avant « s »).
        for sons in (SONS_FR, SONS_EN):
            for son in sons:
                for i, a in enumerate(son.lettres):
                    for b in son.lettres[:i]:
                        self.assertFalse(a != b and b in a, f"{son.etiquette} : « {a} » après « {b} »")


class TestLivres(unittest.TestCase):
    def test_controles_sans_les_dessins(self):
        self.assertEqual(problemes(verifier_dessins=False), [])

    def test_chaque_livre_est_bien_forme(self):
        for loc in ("fr-FR", "en-US"):
            fr = loc.startswith("fr")
            books = livres(loc)
            self.assertGreaterEqual(len(books), 12, loc)
            for b in books:
                self.assertGreaterEqual(len(b.pages), MIN_MOTS, b.son.etiquette)
                ids = [pg.mot.id for pg in b.pages]
                self.assertEqual(len(ids), len(set(ids)), f"{loc} {b.son.etiquette} : mot en double")
                places = [PLACES.index(pg.position) for pg in b.pages]
                self.assertEqual(places, sorted(places), f"{loc} {b.son.etiquette} : début, milieu, fin")
                for pg in b.pages:
                    wagons = pg.mot.fr_wagons if fr else pg.mot.en_wagons
                    self.assertIn(pg.wagon, range(len(wagons)), pg.mot.id)
                    self.assertTrue(pg.lettres, f"{loc} {b.son.etiquette} {pg.mot.id}")
                    self.assertIn(_plier(pg.lettres), _plier(wagons[pg.wagon]), pg.mot.id)

    def test_un_son_sans_assez_de_mots_n_a_pas_de_livre(self):
        for loc, sons in (("fr-FR", SONS_FR), ("en-US", SONS_EN)):
            avec_livre = {b.son.etiquette for b in livres(loc)}
            for son in sons:
                if son.etiquette in avec_livre:
                    continue
                fr = loc.startswith("fr")
                n = sum(1 for m in TOUS if ou_est(son.api, m.fr_api if fr else m.en_api, loc) is not None)
                self.assertLess(n, MIN_MOTS, f"{loc} {son.etiquette} : {n} mots mais pas de livre")

    def test_les_nouveaux_mots_ont_leur_dessin_a_eux(self):
        for m in NOUVEAUX:
            self.assertEqual(m.dessin, f"mot.{m.id}")
            self.assertTrue(m.nouveau)
        for m in TOUS:
            if m not in NOUVEAUX:
                self.assertFalse(m.dessin.startswith("mot."), m.id)

    def test_rien_d_aleatoire(self):
        self.assertEqual(livres("fr-FR"), livres("fr-FR"))



class TestEnCours(unittest.TestCase):
    """`generer --en-cours` : seulement les mots déjà dessinés, jamais une image manquante."""

    def test_seulement_des_mots_dessines(self):
        from .verifier import dessins_connus, mots_dessines
        connus = dessins_connus()
        mots = mots_dessines()
        self.assertTrue(mots)
        self.assertTrue(all(m.dessin in connus for m in mots))
        for loc in ("fr-FR", "en-US"):
            for b in livres(loc, mots):
                self.assertGreaterEqual(len(b.pages), MIN_MOTS, b.son.etiquette)
                self.assertTrue(all(pg.mot in mots for pg in b.pages), b.son.etiquette)

    def test_l_entete_dit_si_c_est_en_cours(self):
        from .generer import swift_source
        self.assertNotIn("EN COURS", swift_source(TOUS))
        self.assertIn("EN COURS", swift_source(TOUS[:-1]))


class TestPlaceDesLettres(unittest.TestCase):
    """Le son se colore là où il se dit, dans sa syllabe (la place du son parmi ses sons)."""

    def s(self, etiquette, sons=SONS_EN):
        return next(x for x in sons if x.etiquette == etiquette)

    def test_le_c_de_dances_et_pas_le_s_final(self):
        s = self.s("s")
        self.assertEqual(lettres_dans_syllabe(s.api, s.lettres, "ces", "sɪz", "en-US"), (0, 1))

    def test_debut_ou_fin_de_syllabe(self):
        s, k = self.s("s"), self.s("k")
        self.assertEqual(lettres_dans_syllabe(k.api, k.lettres, "case", "keɪs", "en-US"), (0, 1))
        self.assertEqual(lettres_dans_syllabe(s.api, s.lettres, "case", "keɪs", "en-US"), (2, 1))

    def test_la_graphie_entiere(self):
        s = self.s("s", SONS_FR)
        self.assertEqual(lettres_dans_syllabe(s.api, s.lettres, "pousse", "pus", "fr-FR"), (3, 2))
        j = self.s("j", SONS_FR)
        self.assertEqual(lettres_dans_syllabe(j.api, j.lettres, "range", "ʁɑ̃ʒ", "fr-FR"), (3, 2))

    def test_le_s_de_sac_pas_le_c(self):
        s = self.s("s", SONS_FR)
        self.assertEqual(lettres_dans_syllabe(s.api, s.lettres, "sac", "sak", "fr-FR"), (0, 1))

    def test_absent(self):
        s = self.s("s", SONS_FR)
        self.assertIsNone(lettres_dans_syllabe(s.api, s.lettres, "chat", "ʃa", "fr-FR"))


class TestPhrasesDesLivres(unittest.TestCase):
    """Les phrases des livres : bien formées, riches en son, lettres justes, pictos proposés."""

    @classmethod
    def setUpClass(cls):
        cls.tous = [(loc, b, phrases_du_livre(b.son, loc)) for loc in ("fr-FR", "en-US") for b in livres(loc)]

    def test_chaque_livre_a_ses_phrases(self):
        for loc, b, ps in self.tous:
            for niveau in (2, 3):
                n = sum(1 for p in ps if p.niveau == niveau)
                self.assertGreaterEqual(n, 3, f"{loc} {b.son.etiquette} niveau {niveau}")
                self.assertLessEqual(n, PAR_NIVEAU)
            textes = [p.texte for p in ps]
            self.assertEqual(len(textes), len(set(textes)), f"{loc} {b.son.etiquette} : phrase en double")

    def test_phrases_bien_formees(self):
        for loc, b, ps in self.tous:
            for p in ps:
                roles = tuple(c.role for c in p.cartes)
                q, v, x = p.cartes
                verbe = VERBE_PAR_ID[v.id]
                self.assertIn("qui", PAR_ID[q.id].roles)
                if p.niveau == 2:
                    self.assertEqual(roles, ("qui", "verbe", "quoi"))
                    self.assertTrue(verbe.transitif)
                    self.assertIn(x.id, verbe.objets)
                    self.assertNotEqual(x.id, q.id)
                else:
                    self.assertEqual(roles, ("qui", "verbe", "ou"))
                    self.assertFalse(verbe.transitif)
                    self.assertIn(x.preposition, verbe.prepositions)
                    self.assertIn(x.preposition, PAR_ID[x.id].prepositions)
                    if verbe.lieux:
                        self.assertIn(x.id, verbe.lieux)
                self.assertEqual(p.texte, phrase(list(p.cartes), loc))

    def test_le_son_est_dans_un_nom(self):
        for loc, b, ps in self.tous:
            for p in ps:
                noms_ = [c for c in p.cartes if c.role != "verbe"]
                apis = [PAR_ID[c.id].fr_api if loc.startswith("fr") else PAR_ID[c.id].en_api for c in noms_]
                self.assertTrue(any(a_le_son(b.son, a, loc) for a in apis), f"{loc} {b.son.etiquette} : {p.texte}")

    def test_les_lettres_du_son(self):
        for loc, b, ps in self.tous:
            graphies = {_plier(g) for g in b.son.lettres}
            for p in ps:
                for c, m in zip(p.cartes, p.marques):
                    texte = morceau(c, loc)
                    if m is None:
                        continue
                    lettres = texte[m.debut:m.debut + m.longueur]
                    self.assertIn(_plier(lettres), graphies, f"{loc} {b.son.etiquette} : « {lettres} » dans « {texte} »")
                    self.assertIsNone(lettres_suspectes(b.son.lettres, texte, m.debut, m.longueur), texte)
                    if c.role in ("qui", "quoi"):
                        n = PAR_ID[c.id]
                        mot = n.fr if loc.startswith("fr") else n.en
                        self.assertGreaterEqual(m.debut, len(texte) - len(mot), f"jamais l'article : {texte}")
                # Un nom qui porte le son a toujours ses lettres colorées.
                for c, m in zip(p.cartes, p.marques):
                    if c.role in ("qui", "quoi"):
                        n = PAR_ID[c.id]
                        if a_le_son(b.son, n.fr_api if loc.startswith("fr") else n.en_api, loc):
                            self.assertIsNotNone(m, f"{loc} {b.son.etiquette} : {morceau(c, loc)}")

    def test_les_pictos_proposes(self):
        for loc, b, ps in self.tous:
            for niveau in (2, 3):
                du_niveau = [p for p in ps if p.niveau == niveau]
                for k, p in enumerate(du_niveau):
                    for w, (bonne, choix) in enumerate(zip(p.cartes, p.choix)):
                        self.assertEqual(len(choix), CHOIX)
                        self.assertEqual(len(set(choix)), CHOIX, "trois pictos différents")
                        self.assertEqual(choix[(k + w) % CHOIX], bonne, "la bonne carte change de place")
                        self.assertTrue(all(c.role == bonne.role for c in choix))
                        if bonne.role == "ou" and len(PAR_ID[bonne.id].prepositions) > 1:
                            memes = [c for c in choix if c.id == bonne.id and c != bonne]
                            self.assertTrue(memes, f"{p.texte} : le même lieu, une autre préposition")

    def test_verbes_et_prepositions_en_syllabes(self):
        for loc in ("fr-FR", "en-US"):
            fr = loc.startswith("fr")
            textes = [v.fr if fr else v.en for v in VERBES] + list((PREP_FR if fr else PREP_EN).values())
            for t in textes:
                self.assertIn(t, SYLLABES[loc], t)
            for v in VERBES:
                ecrit, api = SYLLABES[loc][v.fr if fr else v.en]
                self.assertEqual(ecrit.replace("-", "").replace(" ", ""), (v.fr if fr else v.en).replace(" ", ""))
                a = [ph for ph, _ in phonemes(api, loc) if ph.strip()]
                attendu = [ph for ph, _ in phonemes(v.fr_api if fr else v.en_api, loc) if ph.strip()]
                self.assertEqual(a, attendu, f"{loc} {v.id}")

    def test_rien_d_aleatoire(self):
        phrases_du_livre.cache_clear()
        loc, b, ps = self.tous[0]
        self.assertEqual(phrases_du_livre(b.son, loc), ps)


if __name__ == "__main__":
    unittest.main()
