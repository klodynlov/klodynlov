"""Les phrases des livres des sons : dans chaque livre, des phrases qui portent le son.

Suite d'« au niveau d'OrthoPicto » (28/09/2026). Dans OrthoPicto, une page de livre est une
phrase illustrée que l'enfant reconstruit avec des pictos, puis l'image s'anime. Ici, chaque
livre reçoit, en plus de ses mots :
  - niveau 2 : des phrases « qui + fait quoi + quoi » (« La vache mange la pêche. ») ;
  - niveau 3 : des phrases « qui + fait quoi + où » (« La vache dort dans la niche. »).
Elles sont bâties avec le lexique du train des phrases (outils/phrases), donc la scène sait les
jouer. Chacune a au moins un NOM qui contient le son. Le choix va au plus de morceaux qui le
contiennent : les noms comptent double, le verbe et la préposition aussi, jamais les articles.
L'ordre est fixe et varié (on évite de reprendre le même sujet, verbe ou complément), et rien
n'est tiré au hasard (docs/EVEIL.md § 4.6).

Pour chaque morceau : où colorer les lettres du son (début, longueur, dans le texte du wagon).
Pour chaque wagon : trois pictos à proposer, le bon et deux autres du même rôle. Pour « où ? »,
les deux autres sont le même lieu avec une autre préposition et un autre lieu : c'est la
préposition qu'on apprend. Stdlib uniquement.
"""
from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from functools import lru_cache

from phrases.grammaire import Carte, morceau, phrase
from phrases.lexique import PAR_ID, PREP_EN, PREP_FR, VERBE_PAR_ID, VERBES, noms
from phrases.niveaux import paires_ou

from .livres import SONS_EN, SONS_FR, Son
from .mots import TOUS
from .sons import lettres_dans_syllabe, phonemes, plier

PAR_NIVEAU = 6          # phrases par niveau et par livre
CHOIX = 3               # pictos proposés par wagon

# Les verbes et les prépositions tels qu'écrits dans les wagons, découpés en syllabes (écrit,
# API) : le son se colore dans la bonne syllabe (« dan·ces » : le « c », pas le « s » final).
SYLLABES = {
    "fr-FR": {
        "dort": ("dort", "dɔʁ"), "saute": ("saute", "sot"), "danse": ("danse", "dɑ̃s"),
        "court": ("court", "kuʁ"), "chante": ("chante", "ʃɑ̃t"), "nage": ("nage", "naʒ"),
        "vole": ("vole", "vɔl"), "tourne": ("tourne", "tuʁn"), "rit": ("rit", "ʁi"),
        "se cache": ("se-cache", "sə.kaʃ"), "mange": ("mange", "mɑ̃ʒ"), "boit": ("boit", "bwa"),
        "pousse": ("pousse", "pus"), "porte": ("porte", "pɔʁt"), "lance": ("lance", "lɑ̃s"),
        "lave": ("lave", "lav"), "attrape": ("a-ttrape", "a.tʁap"), "lèche": ("lèche", "lɛʃ"),
        "sent": ("sent", "sɑ̃"), "tire": ("tire", "tiʁ"),
        "dans": ("dans", "dɑ̃"), "sur": ("sur", "syʁ"), "sous": ("sous", "su"),
        "devant": ("de-vant", "də.vɑ̃"), "derrière": ("de-rrière", "dɛ.ʁjɛʁ"),
    },
    "en-US": {
        "sleeps": ("sleeps", "slips"), "jumps": ("jumps", "dʒʌmps"), "dances": ("dan-ces", "ˈdæn.sɪz"),
        "runs": ("runs", "ɹʌnz"), "sings": ("sings", "sɪŋz"), "swims": ("swims", "swɪmz"),
        "flies": ("flies", "flaɪz"), "spins": ("spins", "spɪnz"), "laughs": ("laughs", "læfs"),
        "hides": ("hides", "haɪdz"), "eats": ("eats", "its"), "drinks": ("drinks", "dɹɪŋks"),
        "pushes": ("push-es", "ˈpʊʃ.ɪz"), "carries": ("ca-rries", "ˈkæ.ɹiz"), "throws": ("throws", "θɹoʊz"),
        "washes": ("wash-es", "ˈwɑʃ.ɪz"), "catches": ("catch-es", "ˈkætʃ.ɪz"), "licks": ("licks", "lɪks"),
        "smells": ("smells", "smɛlz"), "pulls": ("pulls", "pʊlz"),
        "in": ("in", "ɪn"), "on": ("on", "ɑn"), "under": ("un-der", "ˈʌn.dɚ"),
        "in front of": ("in-front-of", "ɪn.ˈfɹʌnt.əv"), "behind": ("be-hind", "bɪ.ˈhaɪnd"),
    },
}

MOTS = {m.id: m for m in TOUS}   # les noms en syllabes (écrit, API) : outils/livres/mots.py


@dataclass(frozen=True)
class Marque:
    """Les lettres du son dans le texte d'un wagon : début et longueur (en caractères)."""
    debut: int
    longueur: int


@dataclass(frozen=True)
class PhraseDuLivre:
    niveau: int
    cartes: tuple           # Carte, une par wagon
    marques: tuple          # Marque | None, une par wagon
    choix: tuple            # par wagon : les pictos proposés (Carte), dans l'ordre d'affichage
    texte: str              # la phrase (référence, pour la parité Swift)


def _fr(locale: str) -> bool:
    return locale.startswith("fr")


@lru_cache(maxsize=None)
def _sons(api: str, locale: str) -> frozenset:
    return frozenset(ph for ph, _ in phonemes(api, locale))


def a_le_son(son: Son, api: str, locale: str) -> bool:
    return son.api in _sons(api, locale)


def _api(carte: Carte, locale: str) -> str:
    if carte.role == "verbe":
        v = VERBE_PAR_ID[carte.id]
        return v.fr_api if _fr(locale) else v.en_api
    n = PAR_ID[carte.id]
    return n.fr_api if _fr(locale) else n.en_api


def _loc(locale: str) -> str:
    return "fr-FR" if _fr(locale) else "en-US"


def _prep(carte: Carte, locale: str) -> str:
    return (PREP_FR if _fr(locale) else PREP_EN)[carte.preposition]


def _api_prep(carte: Carte, locale: str) -> str:
    return SYLLABES[_loc(locale)][_prep(carte, locale)][1]


def _mots_du_wagon(carte: Carte, texte: str, locale: str) -> list:
    """Les mots du wagon qui peuvent porter le son, dans l'ordre : (début dans le texte, syllabes
    écrites, syllabes API). Le verbe ; la préposition puis le nom ; le nom — jamais l'article."""
    if carte.role == "verbe":
        ecrit, api = SYLLABES[_loc(locale)][texte]
        return [(0, ecrit.split("-"), api.split("."))]
    out = []
    if carte.role == "ou":
        ecrit, api = SYLLABES[_loc(locale)][_prep(carte, locale)]
        out.append((0, ecrit.split("-"), api.split(".")))
    m = MOTS[carte.id]
    mot, wagons, api = (m.fr, m.fr_wagons, m.fr_api) if _fr(locale) else (m.en, m.en_wagons, m.en_api)
    out.append((len(texte) - len(mot), list(wagons), [x for x in api.split(".") if x]))
    return out


def _debuts(texte: str, debut: int, syllabes: list) -> list | None:
    """Où commence chaque syllabe écrite dans le texte, à partir de `debut` (espaces sautés)."""
    out, i = [], debut
    for syl in syllabes:
        while i < len(texte) and not texte[i].isalpha():
            i += 1
        if plier(texte[i:i + len(syl)]) != plier(syl):
            return None
        out.append(i)
        i += len(syl)
    return out


def marque(son: Son, carte: Carte, locale: str) -> Marque | None:
    """Où colorer le son dans le wagon : dans la première syllabe (du verbe, de la préposition ou
    du nom, jamais de l'article) qui le contient, à la place qu'il y occupe."""
    texte = morceau(carte, locale)
    for debut, ecrits, apis in _mots_du_wagon(carte, texte, locale):
        debuts = _debuts(texte, debut, ecrits)
        if debuts is None or len(ecrits) != len(apis):
            raise ValueError(f"{carte}: syllabes {ecrits} / {apis} ≠ « {texte} »")
        for k, ecrit, api in zip(debuts, ecrits, apis):
            place = lettres_dans_syllabe(son.api, son.lettres, ecrit, api, locale)
            if place:
                return Marque(k + place[0], place[1])
    return None


# ---------------------------------------------------------------------------
# Choisir les phrases
# ---------------------------------------------------------------------------

def _candidats(son: Son, niveau: int, locale: str) -> list:
    """(score, cartes) de toutes les phrases possibles du niveau qui portent le son dans un nom."""
    out = []
    a = lambda c: a_le_son(son, _api(c, locale), locale)  # noqa: E731
    for q in noms("qui"):
        cq = Carte("qui", q.id)
        for v in VERBES:
            cv = Carte("verbe", v.id)
            if niveau == 2 and v.transitif:
                for o in v.objets:
                    if o == q.id:
                        continue
                    co = Carte("quoi", o)
                    if a(cq) or a(co):
                        out.append((2 * a(cq) + 2 * a(co) + a(cv), (cq, cv, co)))
            elif niveau == 3 and not v.transitif:
                for cl in paires_ou(v.id):
                    if a(cq) or a(cl):
                        prep = a_le_son(son, _api_prep(cl, locale), locale)
                        out.append((2 * a(cq) + 2 * a(cl) + a(cv) + prep, (cq, cv, cl)))
    return out


def _cles(cartes: tuple) -> list:
    return [(c.role, c.id) for c in cartes]


def choisir(son: Son, niveau: int, locale: str, n: int = PAR_NIVEAU) -> list[tuple]:
    """Les phrases d'un livre à un niveau : riches en son d'abord, sans trop se répéter.

    Glouton et déterministe : à chaque pas, la phrase de meilleure valeur = score − reprises
    (sujet et complément ×2, verbe ×1) ; à égalité, la première dans l'ordre du lexique."""
    candidats = _candidats(son, niveau, locale)
    choisies: list[tuple] = []
    usage: Counter = Counter()
    poids = {"qui": 2, "verbe": 1, "quoi": 2, "ou": 2}
    while candidats and len(choisies) < n:
        meilleur, valeur = None, None
        for score, cartes in candidats:
            v = score - sum(poids[r] * usage[(r, i)] for r, i in _cles(cartes))
            if valeur is None or v > valeur:
                meilleur, valeur = (score, cartes), v
        candidats.remove(meilleur)
        cartes = meilleur[1]
        choisies.append(cartes)
        usage.update(_cles(cartes))
        # Le même lieu revient avec une autre préposition, mais pas le même couple sujet-lieu.
        candidats = [c for c in candidats if not (c[1][0] == cartes[0] and c[1][2].id == cartes[2].id)]
    return choisies


# ---------------------------------------------------------------------------
# Les pictos proposés pour chaque wagon
# ---------------------------------------------------------------------------

def _autres(bonne: Carte, voisins: list[Carte], reserve: list[Carte], k: int) -> list[Carte]:
    """k autres cartes du même rôle : celles des autres phrases du livre d'abord, puis la réserve."""
    out: list[Carte] = []
    for c in voisins + reserve:
        if c.id == bonne.id or c in out:
            continue
        out.append(c)
        if len(out) == k:
            break
    return out


def _autres_lieux(bonne: Carte) -> list[Carte]:
    """Pour « où ? » : le même lieu avec une autre préposition, puis un autre lieu (même préposition)."""
    lieu = PAR_ID[bonne.id]
    out = [Carte("ou", lieu.id, p) for p in lieu.prepositions if p != bonne.preposition][:1]
    for autre in noms("ou"):
        if autre.id != bonne.id and bonne.preposition in autre.prepositions:
            out.append(Carte("ou", autre.id, bonne.preposition))
            break
    for autre in noms("ou"):                   # repli : un autre lieu, une préposition qu'il a
        if len(out) >= CHOIX - 1:
            break
        if autre.id != bonne.id and all(c.id != autre.id for c in out):
            out.append(Carte("ou", autre.id, autre.prepositions[0]))
    return out[:CHOIX - 1]


def choix_du_wagon(phrases_du_niveau: list[tuple], k_phrase: int, wagon: int, niveau: int) -> tuple:
    """Les 3 pictos du wagon `wagon` de la phrase `k_phrase` : la bonne carte à la place
    (k_phrase + wagon) % 3 — elle change de place d'une phrase et d'un wagon à l'autre."""
    cartes = phrases_du_niveau[k_phrase]
    bonne = cartes[wagon]
    if bonne.role == "ou":
        autres = _autres_lieux(bonne)
    else:
        voisins = []
        for j in range(1, len(phrases_du_niveau)):
            c = phrases_du_niveau[(k_phrase + j) % len(phrases_du_niveau)][wagon]
            voisins.append(c)
        if bonne.role == "qui":
            reserve = [Carte("qui", q.id) for q in noms("qui")]
        elif bonne.role == "verbe":
            reserve = [Carte("verbe", v.id) for v in VERBES if v.transitif == (niveau == 2)]
        else:
            reserve = [Carte("quoi", o) for o in VERBE_PAR_ID[cartes[1].id].objets]
        # Pas d'autre complément identique au sujet (« la vache lave la vache »).
        interdits = {cartes[0].id} if bonne.role == "quoi" else set()
        autres = [c for c in _autres(bonne, voisins, reserve, CHOIX + 2) if c.id not in interdits][:CHOIX - 1]
    ordre = list(autres)
    ordre.insert((k_phrase + wagon) % CHOIX, bonne)
    return tuple(ordre[:CHOIX])


# ---------------------------------------------------------------------------
# Les phrases d'un livre
# ---------------------------------------------------------------------------

@lru_cache(maxsize=None)
def phrases_du_livre(son: Son, locale: str) -> tuple:
    """Les phrases d'un livre : niveau 2 puis niveau 3 (au plus `PAR_NIVEAU` chacun)."""
    out = []
    for niveau in (2, 3):
        du_niveau = choisir(son, niveau, locale)
        for k, cartes in enumerate(du_niveau):
            out.append(PhraseDuLivre(
                niveau=niveau,
                cartes=cartes,
                marques=tuple(marque(son, c, locale) for c in cartes),
                choix=tuple(choix_du_wagon(du_niveau, k, w, niveau) for w in range(len(cartes))),
                texte=phrase(list(cartes), locale),
            ))
    return tuple(out)


def sons(locale: str) -> tuple:
    return SONS_FR if _fr(locale) else SONS_EN
