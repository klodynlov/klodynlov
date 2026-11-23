"""Contrôles des livres des sons (vides = sain)."""
from __future__ import annotations

import json
from pathlib import Path

from .livres import MIN_MOTS, PLACES, SONS_EN, SONS_FR, livres
from .mots import NOUVEAUX, TOUS
from .sons import phonemes, plier

# La première consonne d'une syllabe API s'écrit au début de la syllabe écrite : sinon, les deux
# découpages ne se correspondent pas (« os·trich » ≠ « ɑ.stɹɪtʃ ») et le son se colore ailleurs.
DEBUTS = {
    "fr": {"p": "p", "b": "b", "t": "t", "d": "d", "k": "cqk", "ɡ": "g", "f": "fp", "v": "vw", "s": "scçx",
           "z": "zs", "ʃ": "cs", "ʒ": "jg", "m": "m", "n": "n", "ɲ": "g", "l": "l", "ʁ": "r"},
    "en": {"p": "p", "b": "b", "t": "t", "d": "d", "k": "ckq", "ɡ": "g", "f": "fp", "v": "v", "s": "scx",
           "z": "zsx", "ʃ": "sc", "tʃ": "c", "dʒ": "jg", "m": "m", "n": "nk", "l": "l", "ɹ": "rw", "h": "h"},
}
# Des graphies d'un AUTRE son : les lettres du son ne doivent pas tomber dedans (le « c » de « ch »).
DIGRAPHES = ("tch", "dge", "ch", "sh", "th", "ph", "gn", "qu", "ck", "wh")


def lettres_suspectes(graphies: tuple, texte: str, debut: int, longueur: int) -> str | None:
    """La graphie d'un autre son qui contient les lettres colorées, s'il y en a une."""
    t = plier(texte)
    for d in DIGRAPHES:
        k = t.find(d)
        while k >= 0:
            dedans = k <= debut and debut + longueur <= k + len(d) and (k, len(d)) != (debut, longueur)
            if dedans and d not in [plier(g) for g in graphies]:
                return d
            k = t.find(d, k + 1)
    return None

RACINE = Path(__file__).resolve().parents[2]


def problemes(verifier_dessins: bool = True) -> list[str]:
    out = []
    ids = [m.id for m in TOUS]
    out += [f"{i}: mot en double" for i in sorted({i for i in ids if ids.count(i) > 1})]
    dessins = [m.dessin for m in TOUS]
    out += [f"{d}: dessin de deux mots (l'app reconnaît un mot de livre à son dessin)"
            for d in sorted({d for d in dessins if dessins.count(d) > 1})]
    for m in TOUS:
        if m.genre not in ("m", "f", "pl", "p"):
            out.append(f"{m.id}: genre {m.genre!r}")
        for api, wagons, lang in ((m.fr_api, m.fr_wagons, "fr"), (m.en_api, m.en_wagons, "en")):
            syll = [s for s in api.replace("ˈ", "").replace("ˌ", "").split(".") if s]
            if len(syll) != len(wagons):
                out.append(f"{m.id} ({lang}): {len(syll)} syllabes dans l'API, {len(wagons)} wagons")
            if not all(wagons):
                out.append(f"{m.id} ({lang}): wagon vide")
            if len(syll) == len(wagons):
                table = DEBUTS[lang]
                loc = "fr-FR" if lang == "fr" else "en-US"
                for i, (a, w) in enumerate(zip(syll, wagons)):
                    sons_ = [ph for ph, _ in phonemes(a, loc)]
                    if sons_ and sons_[0] in table and plier(w)[:1] not in table[sons_[0]]:
                        out.append(f"{m.id} ({lang}): la syllabe « {w} » ne commence pas par /{sons_[0]}/ ({a})")
    for sons, loc in ((SONS_FR, "fr-FR"), (SONS_EN, "en-US")):
        etiquettes = [s.etiquette for s in sons]
        out += [f"{loc}: son {e!r} en double" for e in sorted({e for e in etiquettes if etiquettes.count(e) > 1})]
        for livre in livres(loc):
            if len(livre.pages) < MIN_MOTS:
                out.append(f"{loc} {livre.son.etiquette}: trop peu de mots")
            for pg in livre.pages:
                if pg.position not in PLACES:
                    out.append(f"{loc} {livre.son.etiquette} {pg.mot.id}: place {pg.position!r}")
                if not pg.lettres:
                    out.append(f"{loc} {livre.son.etiquette} {pg.mot.id}: lettres du son introuvables")
                else:
                    wagon = (pg.mot.fr_wagons if loc.startswith("fr") else pg.mot.en_wagons)[pg.wagon]
                    k = plier(wagon).find(plier(pg.lettres))
                    d = lettres_suspectes(livre.son.lettres, wagon, k, len(pg.lettres))
                    if d:
                        out.append(f"{loc} {livre.son.etiquette} {pg.mot.id}: « {pg.lettres} » dans « {d} »")
    if verifier_dessins:
        connus = dessins_connus()
        for m in TOUS:
            if m.dessin not in connus:
                out.append(f"{m.id}: dessin {m.dessin!r} pas encore fait" + (" (nouveau mot)" if m in NOUVEAUX else ""))
    return out


def dessins_connus() -> set:
    """Les dessins qui existent : les pictos (outils/pictos) et les dessins vivants des mots du
    petit train (identifiants des lexiques)."""
    from pictos.generer import tous
    connus = {p.id for p in tous()}
    for loc in ("fr-FR", "en-US"):
        data = json.loads((RACINE / "lexique" / f"{loc}.json").read_text(encoding="utf-8"))
        connus |= {w["id"] for w in data["words"]}
    return connus


def mots_dessines() -> tuple:
    """Les mots dont le dessin existe déjà (livres « en cours », en attendant les autres dessins)."""
    connus = dessins_connus()
    return tuple(m for m in TOUS if m.dessin in connus)
