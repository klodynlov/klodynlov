"""Contrôles du lexique du train des phrases (vides = sain)."""
from __future__ import annotations

import json
from pathlib import Path

from .lexique import NOMS, PREPOSITIONS, VERBES, noms

RACINE = Path(__file__).resolve().parents[2]


def dessins_des_mots() -> set[str]:
    """Les identifiants des mots du petit train (leurs dessins vivants existent dans l'app)."""
    ids = set()
    for loc in ("fr-FR", "en-US"):
        data = json.loads((RACINE / "lexique" / f"{loc}.json").read_text(encoding="utf-8"))
        ids |= {w["id"] for w in data["words"]}
    return ids


def pictos() -> dict:
    from pictos.generer import tous
    return {p.id: p for p in tous()}


def problemes(verifier_pictos: bool = True) -> list[str]:
    out = []
    ids = [n.id for n in NOMS]
    out += [f"{i}: nom en double" for i in sorted({i for i in ids if ids.count(i) > 1})]
    vids = [v.id for v in VERBES]
    out += [f"{i}: verbe en double" for i in sorted({i for i in vids if vids.count(i) > 1})]
    mots = dessins_des_mots()
    dessines = pictos() if verifier_pictos else {}
    for n in NOMS:
        if n.genre not in ("m", "f", "p"):
            out.append(f"{n.id}: genre {n.genre!r}")
        if not n.roles or n.roles - {"qui", "quoi", "ou"}:
            out.append(f"{n.id}: rôles {sorted(n.roles)}")
        if n.regarde not in ("gauche", "droite", "face"):
            out.append(f"{n.id}: regarde {n.regarde!r}")
        if not (n.fr and n.en and n.fr_api and n.en_api):
            out.append(f"{n.id}: texte ou API manquant")
        if n.dessin.startswith(("fr.", "en.")):
            if n.dessin not in mots:
                out.append(f"{n.id}: dessin {n.dessin!r} absent des lexiques du petit train")
        elif verifier_pictos and n.dessin not in dessines:
            out.append(f"{n.id}: picto {n.dessin!r} pas encore dessiné (outils/pictos)")
        if "ou" in n.roles:
            if not n.prepositions or set(n.prepositions) - set(PREPOSITIONS):
                out.append(f"{n.id}: prépositions {n.prepositions}")
            if verifier_pictos and n.dessin in dessines:
                ancres = set(dessines[n.dessin].ancres)
                if set(n.prepositions) != ancres:
                    out.append(f"{n.id}: prépositions {sorted(n.prepositions)} ≠ ancres dessinées {sorted(ancres)}")
        elif n.prepositions:
            out.append(f"{n.id}: seul un lieu a des prépositions")
    quoi = {n.id for n in noms("quoi")}
    lieux = {n.id for n in noms("ou")}
    for v in VERBES:
        if verifier_pictos and f"verbe.{v.id}" not in dessines:
            out.append(f"{v.id}: picto verbe.{v.id} pas encore dessiné (outils/pictos)")
        if v.transitif and len(v.objets) < 1:
            out.append(f"{v.id}: verbe transitif sans complément naturel")
        if not v.transitif and v.objets:
            out.append(f"{v.id}: verbe intransitif avec compléments")
        for o in v.objets:
            if o not in quoi:
                out.append(f"{v.id}: complément {o!r} inconnu ou sans le rôle « quoi »")
        if set(v.prepositions) - set(PREPOSITIONS):
            out.append(f"{v.id}: prépositions {v.prepositions}")
        for lieu in v.lieux:
            if lieu not in lieux:
                out.append(f"{v.id}: lieu {lieu!r} inconnu")
    return out
