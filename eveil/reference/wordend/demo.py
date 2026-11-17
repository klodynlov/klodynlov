"""Démonstration : le petit train, sur des signaux synthétiques.

    cd eveil/reference && python3 -m wordend.demo

Aucune dépendance, aucun micro : la démo synthétise des « pseudo-mots »
(douche / dou, minouche / minou / mi…) et montre ce que l'enfant verrait.
"""
from __future__ import annotations

from .detector import VerdictKind, detect
from .dsp import ANALYSIS_RATE, frame_ms
from .lexicon import load_locale
from .policy import feedback_for
from .streaming import CodaHeard, Ended, NucleusHeard, SpeechStarted, StreamingTracker
from .synth import LIBRARY, synthesize, utterance

LABELS = {
    VerdictKind.COMPLETE: "COMPLET",
    VerdictKind.MISSING_FINAL_CONSONANT: "FIN MANQUANTE",
    VerdictKind.FEWER_SYLLABLES: "SYLLABE(S) EN MOINS",
    VerdictKind.UNSURE: "INCERTAIN",
    VerdictKind.NO_SPEECH: "RIEN ENTENDU",
}


def train(word, fb) -> str:
    cars = [f"[{label.upper()}]" if lit else f"[{'·' * len(label)}]"
            for label, lit in zip(word.wagons, fb.lit_wagons)]
    body = "🚂" + "═".join(cars)
    if fb.caboose == "hooked":
        return body + f"═[{word.caboose.upper()}]"
    if fb.caboose == "pointed":
        return body + f"   [{word.caboose}] resté en gare  ← la mascotte le montre"
    if fb.caboose == "waiting":
        return body + f"   ({word.caboose}) en attente"
    return body


def main() -> None:
    fr = load_locale("fr-FR")
    en = load_locale("en-US")
    cases = [
        (fr.by_id("fr.douche"), "douche", {}),
        (fr.by_id("fr.douche"), "dou", {}),
        (fr.by_id("fr.douche"), "douche_schwa", {}),
        (fr.by_id("fr.minouche"), "minouche", {}),
        (fr.by_id("fr.minouche"), "minou", {}),
        (fr.by_id("fr.minouche"), "minousse", {}),
        (fr.by_id("fr.minouche"), "mi", {}),
        (fr.by_id("fr.douche"), "dou", {"snr_db": 12.0}),
        (fr.by_id("fr.douche"), "douche", {"f0_start": 120.0, "f0_end": 100.0}),
        (en.by_id("en.fish"), "fish", {}),
        (en.by_id("en.goose"), "goo", {}),
    ]
    print("Suite Éveil — détecteur de fin de mot (signaux SYNTHÉTIQUES, pas de vraie voix)\n")
    print(f"{'cible':10s} {'prononcé':22s} {'verdict':20s} ce que voit l'enfant")
    print("-" * 100)
    for word, name, extra in cases:
        v = detect(synthesize(utterance(LIBRARY[name], **extra)), word)
        fb = feedback_for(v, len(word.wagons), word.coda is not None, attempt=1)
        said = name + ("".join(f" {k}={val:g}" for k, val in extra.items() if k != "f0_end"))
        why = f"  ({', '.join(v.reasons)})" if v.reasons else ""
        print(f"{word.text:10s} {said:22s} {LABELS[v.kind]:20s} {train(word, fb)}{why}")

    print("\nFlux temps réel — « minouche », blocs de 10 ms :")
    word = fr.by_id("fr.minouche")
    x = synthesize(utterance(LIBRARY["minouche"]))
    tracker = StreamingTracker(word)
    step = ANALYSIS_RATE // 100
    for i in range(0, len(x), step):
        for ev in tracker.push(x[i:i + step]):
            t = None
            if isinstance(ev, SpeechStarted):
                t, msg = ev.frame, "parole détectée"
            elif isinstance(ev, NucleusHeard):
                t, msg = ev.frame, f"wagon {ev.count} allumé ({word.wagons[min(ev.count, len(word.wagons)) - 1]})"
            elif isinstance(ev, CodaHeard):
                t, msg = ev.frame, f"fourgon accroché ({word.caboose})"
            elif isinstance(ev, Ended):
                t, msg = ev.frame, f"fin d'énoncé ({ev.cause}) → {LABELS[ev.verdict.kind]}"
            print(f"  t = {t * frame_ms() / 1000:5.2f} s   {msg}")


if __name__ == "__main__":
    main()
