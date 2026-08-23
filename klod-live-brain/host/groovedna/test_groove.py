"""Tests du moteur GrooveDNA — aucune dépendance, aucun matériel.

    cd klod-live-brain/host && python3 -m unittest groovedna.test_groove -v

Ces tests *sont* le critère de réussite §38 du cahier des charges, rendu
exécutable : capture d'offsets mesurables, transfert reproductible, aucune note
perdue, interpolation vérifiée quantitativement. Tout est construit à partir de
données explicites (jamais d'aléatoire), donc chaque assertion est exacte.
"""

from __future__ import annotations

import unittest

from groovedna.groove import (
    DEFAULT_PPQN,
    FORMAT,
    Grid,
    GrooveDNA,
    NoteEvent,
    StepStat,
    UnsupportedFormat,
    VoiceGroove,
    apply_groove,
    capture_groove,
    gm_role,
    groove_distance,
    metric_weight,
    morph_grooves,
)

KICK, SNARE, HAT = 36, 38, 42  # notes General MIDI
PPQN = 960
TPB = PPQN * 4          # ticks par mesure (4/4) = 3840
TPS = PPQN // 4         # ticks par pas (doubles-croches) = 240


def note(tick, n=KICK, vel=100, ch=9):
    return NoteEvent(tick=tick, note=n, velocity=vel, channel=ch)


# --------------------------------------------------------------------------


class TestGrid(unittest.TestCase):
    def setUp(self):
        self.g = Grid(PPQN, 4, 4)

    def test_geometrie(self):
        self.assertEqual(self.g.ticks_per_step, 240)
        self.assertEqual(self.g.steps_per_bar, 16)
        self.assertEqual(self.g.ticks_per_bar, 3840)

    def test_quantize_sur_grille(self):
        q = self.g.quantize(960)  # temps 2 de la mesure 1
        self.assertEqual((q.bar, q.step, q.offset_ticks), (0, 4, 0))
        self.assertEqual(q.grid_tick, 960)

    def test_quantize_offset_signe(self):
        self.assertEqual(self.g.quantize(967).offset_ticks, 7)    # en retard
        self.assertEqual(self.g.quantize(953).offset_ticks, -7)   # en avance

    def test_quantize_bascule_de_mesure(self):
        # Une note 10 ticks avant le downbeat de la mesure 2 appartient à
        # ce downbeat, avec un décalage négatif — pas à la fin de la mesure 1.
        q = self.g.quantize(TPB - 10)
        self.assertEqual((q.bar, q.step, q.offset_ticks), (1, 0, -10))

    def test_ppqn_indivisible_refuse(self):
        with self.assertRaises(ValueError):
            Grid(1000, 4, 3)  # 1000 non divisible par 3


class TestNoteEvent(unittest.TestCase):
    def test_bornes(self):
        with self.assertRaises(ValueError):
            NoteEvent(tick=-1, note=36, velocity=100)
        with self.assertRaises(ValueError):
            NoteEvent(tick=0, note=200, velocity=100)
        with self.assertRaises(ValueError):
            NoteEvent(tick=0, note=36, velocity=0)  # 0 = note off, hors domaine


class TestCapturePositions(unittest.TestCase):
    """§29 Test 2 — positions théoriques correctement retrouvées."""

    def test_notes_sur_temps(self):
        events = [note(t) for t in (0, 960, 1920, 2880)]  # 4 noires, 1 mesure
        dna = capture_groove(events, ppqn=PPQN)
        kick = dna.voices["kick"]
        self.assertEqual(set(kick.steps), {0, 4, 8, 12})
        for st in kick.steps.values():
            self.assertAlmostEqual(st.offset_mean, 0.0)

    def test_role_gm(self):
        self.assertEqual(gm_role(note(0, KICK)), "kick")
        self.assertEqual(gm_role(note(0, SNARE)), "snare")
        self.assertEqual(gm_role(note(0, HAT)), "hat")


class TestMicrotiming(unittest.TestCase):
    """§29 Test 3 — décalages connus mesurés fidèlement."""

    def test_offsets_connus(self):
        # Kick à trois temps, avec des décalages en ticks connus.
        events = [note(0 + 19), note(960 - 12), note(1920 + 29)]
        dna = capture_groove(events, ppqn=PPQN)
        steps = dna.voices["kick"].steps
        self.assertAlmostEqual(steps[0].offset_mean, 19 / 960)
        self.assertAlmostEqual(steps[4].offset_mean, -12 / 960)
        self.assertAlmostEqual(steps[8].offset_mean, 29 / 960)

    def test_moyenne_et_ecart_type(self):
        # Même décalage répété sur deux mesures ⇒ moyenne exacte, écart-type nul.
        events = [note(7), note(TPB + 7)]
        dna = capture_groove(events, ppqn=PPQN, bars=2)
        st = dna.voices["kick"].steps[0]
        self.assertAlmostEqual(st.offset_mean, 7 / 960)
        self.assertAlmostEqual(st.offset_std, 0.0)
        self.assertEqual(st.count, 2)

    def test_conversion_millisecondes(self):
        dna = GrooveDNA(tempo_reference=120.0)
        # 1 noire @120 BPM = 500 ms ; +19/960 noire = 19/960*500 ms.
        self.assertAlmostEqual(dna.offset_ms(19 / 960), 19 / 960 * 500)
        # Indépendance du tempo : mêmes beats, ms différentes.
        dna_slow = GrooveDNA(tempo_reference=60.0)
        self.assertAlmostEqual(dna_slow.offset_ms(19 / 960), 19 / 960 * 1000)


class TestGrooveTransfer(unittest.TestCase):
    """§29 Test 4 & 5 — transfert et dosage `amount`."""

    def _groove(self):
        # Groove construit à la main : kick au pas 0, -8 ticks, vélocité 100.
        dna = GrooveDNA(ppqn=PPQN, bars=1)
        dna.voices["kick"] = VoiceGroove(
            role="kick",
            steps={0: StepStat(count=4, offset_mean=-8 / 960, velocity_mean=100 / 127)},
            offset_mean=-8 / 960,
            count=4,
        )
        return dna

    def test_amount_zero_est_identite(self):
        # §29 Test 1 (passthrough) rendu en logiciel : amount 0 ⇒ rien ne bouge.
        pattern = [note(TPB, vel=64), note(TPB + 960, SNARE, 70)]
        out = apply_groove(pattern, self._groove(), amount=0.0)
        self.assertEqual(out, pattern)

    def test_amount_un_applique_tout(self):
        pattern = [note(TPB, vel=64)]  # mesure 2, pas 0, quantifié
        out = apply_groove(pattern, self._groove(), amount=1.0)
        self.assertEqual(out[0].tick, TPB - 8)      # décalage -8 ticks transféré
        self.assertEqual(out[0].velocity, 100)      # vélocité transférée

    def test_amount_interpolation_lineaire(self):
        pattern = [note(TPB, vel=64)]
        groove = self._groove()
        attendus = {0.0: (TPB, 64), 0.25: (TPB - 2, 73),
                    0.5: (TPB - 4, 82), 0.75: (TPB - 6, 91), 1.0: (TPB - 8, 100)}
        for amount, (tick, vel) in attendus.items():
            out = apply_groove(pattern, groove, amount=amount)
            self.assertEqual((out[0].tick, out[0].velocity), (tick, vel),
                             msg=f"amount={amount}")

    def test_aucune_note_perdue(self):
        # §38 : « pas de notes perdues ». 64 notes en entrée, 64 en sortie.
        pattern = [note(i * 120, KICK if i % 2 else SNARE, vel=80) for i in range(64)]
        out = apply_groove(pattern, self._groove(), amount=1.0)
        self.assertEqual(len(out), len(pattern))
        for ev in out:
            self.assertGreaterEqual(ev.tick, 0)
            self.assertTrue(1 <= ev.velocity <= 127)

    def test_repli_pas_non_joue(self):
        # Le groove n'a de données qu'au pas 0 ; une note au pas 4 reçoit le
        # décalage agrégé de la voix, et sa vélocité est laissée intacte.
        out = apply_groove([note(TPB + 960, vel=55)], self._groove(), amount=1.0)
        self.assertEqual(out[0].tick, TPB + 960 - 8)  # offset_mean de la voix
        self.assertEqual(out[0].velocity, 55)          # vélocité inchangée


class TestCaptureThenTransfer(unittest.TestCase):
    """La chaîne complète §38, de bout en bout."""

    def test_feel_humain_transfere_sur_pattern_quantifie(self):
        # 1) Performance « humaine » : kick légèrement en avance, snare en retard.
        #    On démarre après une mesure de décompte (pas de tick négatif : dans
        #    une vraie capture, la 1re note n'est jamais à un temps absolu < 0).
        human = []
        for bar in range(2):
            base = (bar + 1) * TPB
            human.append(note(base + 0 - 6, KICK, 112))      # kick en avance, accentué
            human.append(note(base + 960 + 14, SNARE, 96))   # snare en retard
            human.append(note(base + 1920 - 6, KICK, 90))
            human.append(note(base + 2880 + 14, SNARE, 98))
        dna = capture_groove(human, ppqn=PPQN, tempo=100.0)

        # Capture fidèle : le kick est en avance, la snare en retard.
        self.assertLess(dna.voices["kick"].offset_mean, 0)
        self.assertGreater(dna.voices["snare"].offset_mean, 0)

        # 2) Pattern mécaniquement quantifié (offsets nuls, vélocité plate),
        #    placé en mesure 2 pour rester dans le domaine du groove capturé.
        robotic = [note(TPB + 0, KICK, 80), note(TPB + 960, SNARE, 80),
                   note(TPB + 1920, KICK, 80), note(TPB + 2880, SNARE, 80)]

        # 3) Application du groove : la snare part en retard, le kick en avance.
        grooved = apply_groove(robotic, dna, amount=1.0)
        kick_out = [e for e in grooved if e.note == KICK]
        snare_out = [e for e in grooved if e.note == SNARE]
        self.assertTrue(all(e.tick % 960 != 0 for e in snare_out))  # plus sur la grille
        self.assertGreater(snare_out[0].tick, 960 - 1)              # snare poussée en retard
        # Dynamique transférée : le kick accentué remonte au-dessus de 80.
        self.assertGreater(max(e.velocity for e in kick_out), 80)


class TestMorphing(unittest.TestCase):
    def _a(self):
        dna = GrooveDNA(ppqn=PPQN, bars=1, swing=0.50, syncopation=0.2, density=0.3)
        dna.voices["kick"] = VoiceGroove(
            "kick", {0: StepStat(count=2, offset_mean=-8 / 960, velocity_mean=0.8)},
            offset_mean=-8 / 960, count=2)
        return dna

    def _b(self):
        dna = GrooveDNA(ppqn=PPQN, bars=1, swing=0.62, syncopation=0.8, density=0.7)
        dna.voices["kick"] = VoiceGroove(
            "kick", {0: StepStat(count=2, offset_mean=12 / 960, velocity_mean=0.4)},
            offset_mean=12 / 960, count=2)
        return dna

    def test_bornes_exactes(self):
        a, b = self._a(), self._b()
        self.assertEqual(morph_grooves(a, b, 0.0).to_dict(), a.to_dict())
        self.assertEqual(morph_grooves(a, b, 1.0).to_dict(), b.to_dict())

    def test_milieu_est_moyenne(self):
        m = morph_grooves(self._a(), self._b(), 0.5)
        st = m.voices["kick"].steps[0]
        self.assertAlmostEqual(st.offset_mean, (-8 / 960 + 12 / 960) / 2)
        self.assertAlmostEqual(st.velocity_mean, (0.8 + 0.4) / 2)
        self.assertAlmostEqual(m.swing, (0.50 + 0.62) / 2)

    def test_voix_presente_dun_seul_cote_fond_progressivement(self):
        a, b = self._a(), self._b()
        b.voices["hat"] = VoiceGroove(
            "hat", {2: StepStat(count=4, offset_mean=0.05, velocity_mean=0.5)},
            offset_mean=0.05, count=4)
        # À mi-chemin, la charley existe mais avec un poids réduit.
        m = morph_grooves(a, b, 0.5)
        self.assertIn("hat", m.voices)
        self.assertAlmostEqual(m.voices["hat"].steps[2].count, 2.0)  # 4 * 0.5
        # À la borne A, la charley (absente de A) a disparu.
        self.assertNotIn("hat", morph_grooves(a, b, 0.0).voices)

    def test_grilles_incompatibles_refusees(self):
        from groovedna.groove import IncompatibleGrid
        a = self._a()
        b = GrooveDNA(ppqn=480)  # ppqn différent
        with self.assertRaises(IncompatibleGrid):
            morph_grooves(a, b, 0.5)


class TestSerialisation(unittest.TestCase):
    def test_aller_retour_json(self):
        human = [note(bar * TPB + off, n, v)
                 for bar in range(2)
                 for off, n, v in ((0, KICK, 110), (960 + 10, SNARE, 95),
                                   (480, HAT, 60), (1440, HAT, 55))]
        dna = capture_groove(human, ppqn=PPQN, tempo=98.0, bars=2)
        again = GrooveDNA.from_json(dna.to_json())
        self.assertEqual(again.to_dict(), dna.to_dict())
        self.assertEqual(again.format, FORMAT)

    def test_format_inconnu_rejete(self):
        with self.assertRaises(UnsupportedFormat):
            GrooveDNA.from_dict({"format": "SOMETHING_ELSE", "tempo_reference": 120,
                                 "ppqn": 960, "beats_per_bar": 4, "subdivision": 4,
                                 "bars": 1})

    def test_famille_de_format_acceptee(self):
        # Un futur KLOD_GROOVE_V2 doit rester chargeable (versionnement).
        d = capture_groove([note(0)], ppqn=PPQN).to_dict()
        d["format"] = "KLOD_GROOVE_V2"
        self.assertEqual(GrooveDNA.from_dict(d).format, "KLOD_GROOVE_V2")


class TestMetriques(unittest.TestCase):
    def test_poids_metrique(self):
        g = Grid(PPQN, 4, 4)
        self.assertEqual(metric_weight(0, g), 1.00)   # downbeat
        self.assertEqual(metric_weight(8, g), 0.90)   # temps 3
        self.assertEqual(metric_weight(4, g), 0.75)   # temps 2
        self.assertEqual(metric_weight(2, g), 0.50)   # croche « et »
        self.assertEqual(metric_weight(1, g), 0.25)   # double-croche

    def test_swing_binaire_vs_swingue(self):
        straight = [note(s * TPS, HAT, 70) for s in range(0, 16, 2)]  # croches pile
        self.assertAlmostEqual(capture_groove(straight, ppqn=PPQN).swing, 0.5)
        swung = []
        for s in range(0, 16, 2):
            off = 80 if s % 4 == 2 else 0   # pousse les « et » en retard
            swung.append(note(s * TPS + off, HAT, 70))
        self.assertAlmostEqual(capture_groove(swung, ppqn=PPQN).swing, 0.5 + 80 / 960)

    def test_syncope_faible_vs_forte(self):
        four_floor = capture_groove([note(s * TPS, KICK) for s in (0, 4, 8, 12)],
                                    ppqn=PPQN).syncopation
        offbeat = capture_groove([note(s * TPS, KICK) for s in (1, 3, 5, 7)],
                                 ppqn=PPQN).syncopation
        self.assertLess(four_floor, offbeat)
        self.assertGreater(offbeat, 0.5)

    def test_densite(self):
        dna = capture_groove([note(s * TPS, KICK) for s in (0, 4, 8, 12)],
                             ppqn=PPQN, bars=1)
        self.assertAlmostEqual(dna.density, 4 / 16)  # 1 voix, 4 frappes / 16 créneaux

    def test_variation_inter_mesures(self):
        # Deux mesures identiques ⇒ variation nulle.
        same = [note(bar * TPB + s * TPS, KICK) for bar in range(2) for s in (0, 4, 8, 12)]
        self.assertAlmostEqual(capture_groove(same, ppqn=PPQN, bars=2).variation, 0.0)
        # Mesures différentes ⇒ variation > 0.
        diff = ([note(s * TPS, KICK) for s in (0, 4, 8, 12)] +
                [note(TPB + s * TPS, KICK) for s in (0, 2, 4, 6, 8, 10)])
        self.assertGreater(capture_groove(diff, ppqn=PPQN, bars=2).variation, 0.0)

    def test_variation_robuste_au_decompte(self):
        # Une mesure de décompte silencieuse ne doit ni gonfler la variation ni
        # diluer la densité : les mesures vides sont rognées quand `bars` est auto.
        perf = [note((bar + 1) * TPB + s * TPS, KICK)
                for bar in range(2) for s in (0, 4, 8, 12)]
        dna = capture_groove(perf, ppqn=PPQN)   # bars auto-détecté
        self.assertEqual(dna.bars, 2)           # décompte rogné
        self.assertAlmostEqual(dna.variation, 0.0)
        self.assertAlmostEqual(dna.density, 4 / 16)

    def test_accent_map(self):
        events = [note(0, KICK, 127), note(960, SNARE, 64)]
        amap = capture_groove(events, ppqn=PPQN).accent_map
        self.assertEqual(len(amap), 16)
        self.assertAlmostEqual(amap[0], 1.0)         # 127/127
        self.assertAlmostEqual(amap[4], 64 / 127)

    def test_distance_groove(self):
        g = Grid(PPQN, 4, 4)
        a = GrooveDNA(swing=0.5, syncopation=0.2, density=0.3)
        self.assertAlmostEqual(groove_distance(a, a), 0.0)
        b = GrooveDNA(swing=0.66, syncopation=0.9, density=0.8)
        self.assertGreater(groove_distance(a, b), 0.0)


class TestRobustesse(unittest.TestCase):
    """§29 Test 6 — pas de crash, pas de corruption sur charge/vide."""

    def test_capture_vide(self):
        dna = capture_groove([], ppqn=PPQN)
        self.assertEqual(dna.voices, {})
        self.assertEqual(dna.bars, 1)

    def test_apply_amount_hors_bornes_borne(self):
        dna = GrooveDNA(ppqn=PPQN)
        dna.voices["kick"] = VoiceGroove(
            "kick", {0: StepStat(count=1, offset_mean=0.01, velocity_mean=1.0)},
            offset_mean=0.01, count=1)
        # amount négatif ⇒ borné à 0 (identité) ; > 1 ⇒ borné à 1.
        pat = [note(TPB, vel=64)]
        self.assertEqual(apply_groove(pat, dna, -5.0), pat)
        self.assertEqual(apply_groove(pat, dna, 9.0), apply_groove(pat, dna, 1.0))

    def test_grosse_capture_stable(self):
        events = [note(i * 60, KICK if i % 3 else SNARE, vel=1 + (i % 127))
                  for i in range(2000)]
        dna = capture_groove(events, ppqn=PPQN)
        out = apply_groove(events, dna, amount=1.0)
        self.assertEqual(len(out), 2000)
        self.assertTrue(all(0 <= e.tick and 1 <= e.velocity <= 127 for e in out))


if __name__ == "__main__":
    unittest.main(verbosity=2)
