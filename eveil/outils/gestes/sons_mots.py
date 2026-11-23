"""Quels gestes Lou fait pour un mot : une suite de sons par syllabe (wagon).

Décision de l'utilisateur (06/10/2026) : les gestes validés sont montrés par Lou dans le petit train
et dans les livres des sons, wagon par wagon. Chaque son d'une syllabe donne l'étiquette de son geste
(`gestes.py`, champ `son`) :

- une voyelle ou une consonne : son geste (/ɔ/ → « o », /ø/ → « eu », /œ/ → « eu ouvert », /ə/ → « e ») ;
- /w/ suivi de /a/ → « oi », suivi de /ɛ̃/ → « oin » : un seul geste pour les deux sons, comme dans le
  livre (oi, oin sont des « tout ») ; /w/ ailleurs n'a pas de geste à lui : on le saute ;
- /j/ → « ill » ;
- /ɥ/ → « ui » : pas de geste (« à trouver »), Lou ne montre que sa bouche.

Français seulement : la méthode est celle du français (pas de geste en anglais).
Miroir Swift : `TrainPracticeUI/LouSounds.swift` (mêmes cas dans les tests). Stdlib uniquement.
"""
from __future__ import annotations

from livres.sons import phonemes

from .gestes import TOUS

PAR_API = {g.api: g.son for g in TOUS if len(g.api) == 1 or g.api in ("ɑ̃", "ɔ̃", "ɛ̃")}
PAR_API.update({"ɔ": "o"})
GLISSANTE_W = {"a": "oi", "ɛ̃": "oin"}


def gestes_de_syllabe(syllabe: str) -> list[str]:
    """« vwa » → ["v", "oi"] ; « ʒi » → ["j", "i"] ; « nɥ » → ["n", "ui"]."""
    phs = [p for p, _ in phonemes(syllabe, "fr-FR")]
    out, i = [], 0
    while i < len(phs):
        p = phs[i]
        if p == "w":
            suivant = phs[i + 1] if i + 1 < len(phs) else None
            if suivant in GLISSANTE_W:
                out.append(GLISSANTE_W[suivant])
                i += 2
                continue
            i += 1
            continue
        if p in PAR_API:
            out.append(PAR_API[p])
        i += 1
    return out


def gestes_du_mot(api: str) -> list[list[str]]:
    """Une liste de gestes par syllabe (« ʒi.ʁaf » → [["j", "i"], ["r", "a", "f"]])."""
    return [gestes_de_syllabe(s) for s in api.replace("ˈ", "").replace("ˌ", "").split(".") if s]
