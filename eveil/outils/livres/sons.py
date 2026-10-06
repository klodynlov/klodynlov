"""Les sons des livres : découper l'API en phonèmes, trouver où est le son dans le mot.

Un LIVRE par son (comme OrthoPicto, mais construit ici à partir des mots dessinés) : tous
les mots qui contiennent ce son, rangés « au début », « au milieu », « à la fin ». Le wagon
où il se trouve (la syllabe) s'allume dans le train ; les lettres qui l'écrivent sont
colorées pour l'adulte (et l'enfant qui commence à lire). Stdlib uniquement.
"""
from __future__ import annotations

import unicodedata
from dataclasses import dataclass

# Phonèmes à plusieurs caractères (les plus longs d'abord).
MULTI_EN = ("tʃ", "dʒ", "aɪ", "aʊ", "oʊ", "eɪ", "ɔɪ")
MARQUES = "ˈˌ"


def phonemes(api: str, locale: str) -> list[tuple[str, int]]:
    """[(phonème, n° de syllabe)] : « gi.ʁaf » → [(ʒ,0) (i,0) (ʁ,1) (a,1) (f,1)]."""
    out = []
    multi = MULTI_EN if locale.startswith("en") else ()
    for s, syllabe in enumerate(x for x in api.split(".") if x):
        syllabe = "".join(ch for ch in syllabe if ch not in MARQUES)
        i = 0
        while i < len(syllabe):
            m = next((m for m in multi if syllabe.startswith(m, i)), None)
            if m:
                out.append((m, s))
                i += len(m)
                continue
            ph = syllabe[i]
            i += 1
            # Voyelle nasale (ɑ̃, ɔ̃…) : le tilde combinant reste attaché ; « ɚ », « ɝ » : un phonème.
            while i < len(syllabe) and unicodedata.combining(syllabe[i]):
                ph += syllabe[i]
                i += 1
            out.append((ph, s))
    return out


def plier(texte: str) -> str:
    """Minuscules sans accents, caractère pour caractère (« Bûche » → « buche »)."""
    nfd = unicodedata.normalize("NFD", texte.lower())
    return "".join(ch for ch in nfd if not unicodedata.combining(ch))


def lettres_dans_syllabe(son: str, graphies: tuple, ecrit: str, api: str, locale: str) -> tuple | None:
    """Où s'écrit le son dans UNE syllabe écrite : (début, longueur), ou None s'il n'y est pas.

    Toutes les graphies du son sont cherchées dans la syllabe ; on garde celle qui tombe au plus
    près de la place du son parmi les sons de la syllabe. Ainsi « dan·ces » (/dæn.sɪz/) : le /s/
    est le premier son de « ces », c'est donc le « c » et pas le « s » final, qui se dit /z/. Puis
    on l'élargit à la graphie plus longue qui la contient : « pou[ss]e », pas « pous[s]e »."""
    sons_ = [ph for ph, _ in phonemes(api, locale)]
    if son not in sons_:
        return None
    centre = (sons_.index(son) + 0.5) / len(sons_)
    plie = plier(ecrit)
    trouves = []                                   # (début, longueur, rang de la graphie)
    for rang, g in enumerate(graphies):
        gp = plier(g)
        k = plie.find(gp)
        while k >= 0:
            trouves.append((k, len(gp), rang))
            k = plie.find(gp, k + 1)
    if not trouves:
        return None
    k, n, _ = min(trouves, key=lambda t: (abs((t[0] + t[1] / 2) / len(plie) - centre), t[2], t[0]))
    for k2, n2, _ in sorted(trouves, key=lambda t: (-t[1], t[2], t[0])):
        if n2 > n and k2 <= k and k2 + n2 >= k + n:
            return (k2, n2)
    return (k, n)


@dataclass(frozen=True)
class SonDansMot:
    syllabe: int          # le wagon où il est
    position: str         # debut | milieu | fin


def ou_est(son: str, api: str, locale: str) -> SonDansMot | None:
    """La première occurrence du son dans le mot, et sa place."""
    phs = phonemes(api, locale)
    for k, (ph, s) in enumerate(phs):
        if ph == son:
            position = "debut" if k == 0 else ("fin" if k == len(phs) - 1 else "milieu")
            return SonDansMot(s, position)
    return None
