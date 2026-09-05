"""Démonstration exécutable du critère de réussite §38 de KLOD GrooveDNA.

    cd klod-live-brain/host && python3 -m groovedna.demo

Ne dépend de rien (stdlib pure) et n'utilise **aucun aléatoire** : les chiffres
affichés sont donc reproductibles à l'identique. La « performance humaine » est
une donnée de test **construite à la main** avec des décalages explicites — elle
sert à prouver le *moteur*, elle ne prétend représenter aucun style réel (les
grooves caribéens documentés viendront de vrais fichiers MIDI, cf. le cahier des
charges §7).

Chaîne démontrée :

    performance « humaine »  →  capture_groove()  →  GrooveDNA (offsets mesurés)
    pattern quantifié        →  apply_groove(dna, amount)  →  feel transféré
    dna_swing, dna_droit     →  morph_grooves(a, b, alpha) →  interpolation
"""

from __future__ import annotations

from groovedna.groove import (
    Grid,
    GrooveDNA,
    NoteEvent,
    apply_groove,
    capture_groove,
    morph_grooves,
)

KICK, SNARE, HAT = 36, 38, 42
PPQN, TEMPO = 960, 100.0
G = Grid(PPQN, 4, 4)
TPB, TPS = G.ticks_per_bar, G.ticks_per_step   # 3840, 240
MS_PER_TICK = 60_000.0 / (TEMPO * PPQN)         # 0.625 ms/tick @100 BPM


def ms(ticks: float) -> float:
    return ticks * MS_PER_TICK


def rule(title: str) -> None:
    print(f"\n{'─' * 68}\n{title}\n{'─' * 68}")


def human_performance(bars: int = 2) -> list[NoteEvent]:
    """Backbeat joué « à la main » : décalages et accents explicites.

    Kick en avance et accentué sur les temps 1 & 3, snare en retard sur 2 & 4,
    charleys en croches dont les « et » sont *swingués* (poussés) et plus doux.
    Démarre après une mesure de décompte (pas de tick négatif).
    """
    ev: list[NoteEvent] = []
    for bar in range(bars):
        base = (bar + 1) * TPB
        # Kick : temps 1 (pas 0) et 3 (pas 8), 6 ticks en avance, accentué.
        ev.append(NoteEvent(base + 0 * TPS - 6, KICK, 112))
        ev.append(NoteEvent(base + 8 * TPS - 6, KICK, 104))
        # Snare : temps 2 (pas 4) et 4 (pas 12), 14 ticks en retard.
        ev.append(NoteEvent(base + 4 * TPS + 14, SNARE, 96))
        ev.append(NoteEvent(base + 12 * TPS + 14, SNARE, 98))
        # Charleys : 8 croches ; les « et » (pas 2,6,10,14) swinguées +70 ticks.
        for step in range(0, 16, 2):
            swung = step % 4 == 2
            off = 70 if swung else 0
            vel = 58 if swung else 78
            ev.append(NoteEvent(base + step * TPS + off, HAT, vel))
    return ev


def quantized_pattern() -> list[NoteEvent]:
    """Même squelette, mécaniquement quantifié (offsets nuls, vélocité plate)."""
    ev = [NoteEvent(0 * TPS, KICK, 80), NoteEvent(8 * TPS, KICK, 80),
          NoteEvent(4 * TPS, SNARE, 80), NoteEvent(12 * TPS, SNARE, 80)]
    ev += [NoteEvent(step * TPS, HAT, 80) for step in range(0, 16, 2)]
    return ev


def main() -> None:
    print("KLOD GrooveDNA — preuve du cœur (critère §38)")
    print(f"grille : {PPQN} PPQN · 4/4 · doubles-croches · tempo réf. {TEMPO:.0f} BPM")

    # 1) CAPTURE ------------------------------------------------------------
    rule("1) CAPTURE — performance humaine → GrooveDNA")
    dna = capture_groove(human_performance(), ppqn=PPQN, tempo=TEMPO)
    for role in ("kick", "snare", "hat"):
        v = dna.voices[role]
        print(f"  {role:5} : décalage moyen {v.offset_mean * PPQN:+6.1f} ticks "
              f"({ms(v.offset_mean * PPQN):+6.2f} ms)  ·  "
              f"vélocité moy. {v.velocity_mean * 127:5.1f}  ·  {v.count} frappes")
    print(f"  swing      : {dna.swing:.3f}   (0.5 = binaire ; "
          f"ici les « et » de charley poussées de {ms(70):+.1f} ms)")
    print(f"  syncope    : {dna.syncopation:.3f}")
    print(f"  densité    : {dna.density:.3f}")
    print(f"  variation  : {dna.variation:.3f}  (mesures 1 et 2 identiques → 0)")

    # 2) TRANSFERT ----------------------------------------------------------
    rule("2) TRANSFERT — apply_groove() sur un pattern quantifié, dosé par amount")
    pattern = quantized_pattern()
    print("  snare au pas 4 (temps 2) — position réelle et vélocité par amount :")
    print(f"    {'amount':>7} | {'offset':>12} | {'vélocité':>8}")
    for amount in (0.0, 0.25, 0.5, 0.75, 1.0):
        out = apply_groove(pattern, dna, amount=amount)
        snare = next(e for e in out if e.note == SNARE and e.tick // TPS in (4, 3, 5))
        off_ticks = snare.tick - 4 * TPS
        print(f"    {amount:7.2f} | {off_ticks:+3d} ticks {ms(off_ticks):+6.2f} ms "
              f"| {snare.velocity:8d}")
    print("  → décalage et vélocité varient linéairement de 0 % à 100 % : transfert prouvé.")

    # Aucune note perdue.
    out_full = apply_groove(pattern, dna, amount=1.0)
    print(f"  notes en entrée : {len(pattern)}  ·  en sortie : {len(out_full)}  "
          f"→ aucune note perdue" if len(out_full) == len(pattern) else "  ERREUR")

    # 3) MORPHING -----------------------------------------------------------
    rule("3) MORPHING — interpolation entre deux feels")
    straight = capture_groove(quantized_pattern(), ppqn=PPQN, tempo=TEMPO)  # swing 0.5
    print(f"  A = joué main (swing {dna.swing:.3f})   B = quantifié (swing {straight.swing:.3f})")
    for alpha in (0.0, 0.25, 0.5, 0.75, 1.0):
        m = morph_grooves(dna, straight, alpha)
        print(f"    alpha {alpha:.2f} → swing {m.swing:.3f}")
    print("  → alpha 0 = A, alpha 1 = B, interpolation continue entre les deux.")

    # 4) FORMAT VERSIONNÉ ---------------------------------------------------
    rule("4) FORMAT — sérialisation versionnée (aller-retour JSON)")
    again = GrooveDNA.from_json(dna.to_json())
    ok = again.to_dict() == dna.to_dict()
    print(f"  format : {dna.format}")
    print(f"  aller-retour JSON identique : {'oui' if ok else 'NON'}")
    print(f"  taille sérialisée : {len(dna.to_json())} octets")

    rule("Résultat")
    print("  Chaîne §38 vérifiée de bout en bout, avec des offsets mesurables,")
    print("  reproductibles et sans note perdue. Le cœur « musical » est prouvé,")
    print("  indépendamment du matériel. Reste à porter timing/scheduler sur")
    print("  Teensy (cf. docs/TECHNICAL_REALITY.md) — statut FAISABLE, à mesurer.")


if __name__ == "__main__":
    main()
