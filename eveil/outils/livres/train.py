"""Les mots du petit train qui n'ont pas de fourgon : les mots dessinés des livres, rangés par niveau.

Demande de l'utilisateur (06/10/2026), d'après le conseil d'une orthophoniste : « commencer avec des
mots d'une syllabe, comme mur, vert, ne plus se focaliser sur les ch ou ss ». Le détecteur ne juge
la consonne finale que pour « ch » et « s » (le fourgon) ; les autres mots entrent donc dans le
train SANS fourgon et sont jugés sur leurs syllabes, comme dans les livres des sons
(`TargetWord.bookWord`). On les prend parmi les mots déjà dessinés (`mots.TOUS`), et leur niveau
est calculé :

- 1 : une syllabe, sans groupe de consonnes (mur, vert, chat, lune…) ;
- 2 : deux syllabes, sans groupe (vélo, lapin…) ;
- 3 : un groupe de consonnes dans une syllabe (fleur, zèbre, clé…) ;
- 4 : trois syllabes ou plus : seulement quand tous les mots sont mêlés.

Les glissantes (le « w » de oie, le « j » de chien, le « ɥ » de nuage) ne font pas un groupe.
Ordre dans chaque niveau (Borel-Maisonny : la syllabe « directe », consonne + voyelle, avant la
syllabe « inverse », Langage oral et écrit I, p. 56-57 ; puis l'utilisateur, 06/10/2026 : « pas que
mur et vert, des mots comme jus, peau ») : d'abord les mots qui finissent par une VOYELLE (jus,
peau, puis un son d'attaque différent à chaque mot : feu, nez, lait…), puis ceux qui finissent par une consonne (mur, sac, lune…), où l'on mêle deux mots
nouveaux et un mot à fourgon (douche, vache…). Les mots du lexique écrits à la main restent tels quels.
Le résultat est écrit DANS `eveil/lexique/<langue>.json` (marque `"source": "livres"`), que
lisent Python et l'app.

    python3 -m livres.train            # écrit les deux lexiques
    python3 -m livres.train --check    # échoue s'ils ne sont pas à jour
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from .mots import TOUS, Mot
from .sons import phonemes, plier

LEXIQUE = Path(__file__).resolve().parents[2] / "lexique"
SOURCE = "livres"
MOTIF = ("nouveau", "nouveau", "fourgon")
GLISSANTES = {"j", "w", "ɥ"}
EN_TETE = {"fr": ("jus", "peau"), "en": ()}     # les exemples de l'utilisateur (06/10/2026)
VOYELLES_FR = set("aeiouyɛɔøœəɑ")
VOYELLES_EN = set("aeiouæɑɔəɛɪʊʌɝɚ")


def _consonne(ph: str, locale: str) -> bool:
    voyelles = VOYELLES_FR if locale.startswith("fr") else VOYELLES_EN
    return ph not in GLISSANTES and not any(c in voyelles for c in ph)


def groupe(api: str, locale: str) -> bool:
    """Deux consonnes qui se suivent DANS une même syllabe (« flœʁ », « zɛbʁ »)."""
    phs = phonemes(api, locale)
    return any(s1 == s2 and _consonne(a, locale) and _consonne(b, locale)
               for (a, s1), (b, s2) in zip(phs, phs[1:]))


def ouverte(api: str, locale: str) -> bool:
    """Le mot finit par une voyelle (« po », « ʒy ») : la syllabe la plus simple."""
    phs = phonemes(api, locale)
    return bool(phs) and not _consonne(phs[-1][0], locale) and phs[-1][0] not in GLISSANTES


def varie(mots: list, locale: str) -> list:
    """Un mot par son d'attaque, à tour de rôle (jamais trois « ch » de suite) ; ordre fixe."""
    groupes: dict[str, list] = {}
    for m in sorted(mots, key=lambda n: plier(n["text"])):
        groupes.setdefault(phonemes(m["ipa"], locale)[0][0], []).append(m)
    out = []
    while any(groupes.values()):
        for cle in sorted(groupes):
            if groupes[cle]:
                out.append(groupes[cle].pop(0))
    return out


def niveau(mot: Mot, locale: str) -> int:
    fr = locale.startswith("fr")
    api, wagons = (mot.fr_api, mot.fr_wagons) if fr else (mot.en_api, mot.en_wagons)
    if groupe(api, locale):
        return 3
    return {1: 1, 2: 2}.get(len(wagons), 4)


def mot_du_train(mot: Mot, locale: str) -> dict:
    fr = locale.startswith("fr")
    texte, api, wagons = (mot.fr, mot.fr_api, mot.fr_wagons) if fr else (mot.en, mot.en_api, mot.en_wagons)
    return {"id": f"{locale.split('-')[0]}.livre.{mot.id}", "text": texte, "ipa": api,
            "level": niveau(mot, locale), "wagons": list(wagons), "caboose": None, "nuclei": len(wagons),
            "coda": None, "drawing": mot.dessin, "source": SOURCE}


def _entrelace(nouveaux: list, anciens: list) -> list:
    out, i, j, k = [], 0, 0, 0
    while i < len(nouveaux) or j < len(anciens):
        veut = MOTIF[k % len(MOTIF)]
        k += 1
        if (veut == "nouveau" and i < len(nouveaux)) or j >= len(anciens):
            out.append(nouveaux[i])
            i += 1
        else:
            out.append(anciens[j])
            j += 1
    return out


def lexique(locale: str, data: dict) -> dict:
    """Le lexique `data` avec ses mots sans fourgon recalculés et l'ordre des niveaux refait."""
    fr = locale.startswith("fr")
    anciens = [w for w in data["words"] if w.get("source") != SOURCE]
    connus = {plier(w["text"]) for w in anciens}
    nouveaux, vus = [], set()
    for m in TOUS:
        texte = m.fr if fr else m.en
        if m.genre == "p" or plier(texte) in connus or plier(texte) in vus:
            continue
        vus.add(plier(texte))
        nouveaux.append(mot_du_train(m, locale))
    nouveaux.sort(key=lambda n: plier(n["text"]))
    mots = []
    for lv in (1, 2, 3, 4):
        ici = [n for n in nouveaux if n["level"] == lv]
        a_fourgon = [w for w in anciens if int(w.get("level", 1)) == lv]
        tete = [n for e in EN_TETE[locale[:2]] for n in ici if n["text"] == e]
        mots += tete + varie([n for n in ici if ouverte(n["ipa"], locale) and n not in tete], locale)
        mots += _entrelace(varie([n for n in ici if not ouverte(n["ipa"], locale)], locale), a_fourgon)
    return {**data, "words": mots}


def texte_json(data: dict) -> str:
    """Même mise en forme que les lexiques écrits à la main : un mot par ligne."""
    tete = {k: v for k, v in data.items() if k != "words"}
    corps = json.dumps(tete, ensure_ascii=False, indent=2)[:-2]
    mots = ",\n".join("    " + json.dumps(w, ensure_ascii=False) for w in data["words"])
    return corps + ',\n  "words": [\n' + mots + "\n  ]\n}\n"


def main(argv: list[str]) -> int:
    check = "--check" in argv
    ok = True
    for locale in ("fr-FR", "en-US"):
        chemin = LEXIQUE / f"{locale}.json"
        actuel = chemin.read_text(encoding="utf-8")
        voulu = texte_json(lexique(locale, json.loads(actuel)))
        if check:
            if voulu != actuel:
                print(f"✗ {chemin.name} n'est pas à jour : python3 -m livres.train")
                ok = False
            else:
                print(f"✓ {chemin.name} à jour")
        elif voulu != actuel:
            chemin.write_text(voulu, encoding="utf-8")
            print(f"✓ {chemin.name} écrit")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
