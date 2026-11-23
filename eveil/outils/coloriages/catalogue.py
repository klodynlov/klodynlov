"""Le catalogue : toutes les pages générées, par album, et leur lien avec les mots du petit train.

Les pages dessinées à la main dans l'app (PagesClassics/Animals/Things.swift) et leur
rangement en albums (ColoringAlbums.swift) sont relus dans les sources Swift : les
contrôles croisés (identifiants et titres uniques, 12 pages au plus par album, un
dessin pour chaque mot) portent sur l'atelier entier.
"""
from __future__ import annotations

import re
from pathlib import Path

from . import pages_animaux, pages_fete, pages_jardin, pages_maison, pages_miam, pages_route, pages_train
from .dessin import ALBUMS

PAGES = [*pages_train.PAGES, *pages_animaux.PAGES, *pages_jardin.PAGES, *pages_maison.PAGES,
         *pages_miam.PAGES, *pages_route.PAGES, *pages_fete.PAGES]

TITRES_ALBUMS = {
    "train": ("Le petit train", "The little train"),
    "animaux": ("Les animaux", "Animals"),
    "jardin": ("Le jardin", "The garden"),
    "maison": ("À la maison", "At home"),
    "miam": ("Miam !", "Yummy!"),
    "route": ("En route !", "On the move"),
    "fete": ("La fête", "Party time"),
}
CAPACITE_ALBUM = 12   # toutes les pages d'un album visibles d'un coup, même sur un iPad 11" en paysage

# Chaque mot du petit train (lexiques fr-FR et en-US) → sa page à colorier (le même sujet que son dessin).
MOTS = {
    "fr.douche": "douche", "fr.bouche": "bouche", "fr.niche": "niche", "fr.ruche": "ruche",
    "fr.mouche": "mouche", "fr.vache": "vache", "fr.biche": "biche", "fr.tasse": "tasse",
    "fr.minouche": "minouche", "fr.perruche": "perruche", "fr.saucisse": "saucisse", "fr.trousse": "trousse",
    "fr.mousse": "mousse", "fr.buche": "buche", "fr.tache": "tache", "fr.peche": "peche", "fr.os": "os",
    "fr.police": "police", "fr.caniche": "caniche", "fr.limace": "limace", "fr.carrosse": "carrosse",
    "fr.cactus": "cactus", "fr.cloche": "cloche", "fr.glace": "glace", "fr.fleche": "fleche",
    "fr.brosse": "brosse-a-dents", "fr.autruche": "autruche", "fr.princesse": "princesse",
    "en.fish": "poisson", "en.dish": "assiette", "en.push": "pousser", "en.wash": "laver", "en.goose": "oie",
    "en.moose": "elan", "en.ice": "glacons", "en.piece": "puzzle", "en.bus": "bus", "en.radish": "radis",
    "en.tennis": "tennis", "en.brush": "brosse-a-cheveux", "en.mouse": "souris", "en.juice": "jus",
    "en.house": "maison", "en.circus": "cirque", "en.splash": "plouf",
}

IOS = Path(__file__).resolve().parents[2] / "ios"
COLORING = IOS / "Sources" / "ColoringUI"
FICHIERS_MAIN = ("PagesClassics.swift", "PagesAnimals.swift", "PagesThings.swift")


def pages_dessinees_a_la_main() -> dict[str, tuple[str, str, str]]:
    """Nom Swift → (identifiant, titre FR, titre EN) des pages écrites à la main dans l'app."""
    out = {}
    motif = re.compile(r'static let (\w+) = ColoringPage\("([^"]+)", fr: "([^"]+)", en: "([^"]+)"')
    for nom in FICHIERS_MAIN:
        for m in motif.finditer((COLORING / nom).read_text(encoding="utf-8")):
            out[m.group(1)] = (m.group(2), m.group(3), m.group(4))
    return out


def albums_dans_l_app() -> dict[str, list[str]]:
    """Album → noms Swift des pages écrites à la main qu'il range (ColoringAlbums.swift)."""
    src = (COLORING / "ColoringAlbums.swift").read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r'album\("(\w+)", fr: "[^"]*", en: "[^"]*", \[([^\]]*)\]\)', src):
        out[m.group(1)] = [n.strip() for n in m.group(2).split(",") if n.strip()]
    return out


def verifier_catalogue() -> list[str]:
    """Contrôles croisés sur l'atelier entier (pages à la main + pages générées)."""
    err = []
    main = pages_dessinees_a_la_main()
    ids = [p.id for p in PAGES] + [v[0] for v in main.values()]
    titres = [p.fr for p in PAGES] + [v[1] for v in main.values()]
    for nom, liste in (("identifiant", ids), ("titre", titres)):
        vus = set()
        for x in liste:
            if x in vus:
                err.append(f"{nom} en double : {x}")
            vus.add(x)
    for p in PAGES:
        if p.album not in ALBUMS:
            err.append(f"{p.id} : album inconnu {p.album}")
        if p.fr == p.en:
            err.append(f"{p.id} : même titre en français et en anglais")
    rangement = albums_dans_l_app()
    if set(rangement) != set(ALBUMS):
        err.append(f"albums de l'app {sorted(rangement)} ≠ {sorted(ALBUMS)}")
    ranges = [n for noms in rangement.values() for n in noms]
    for n in main:
        if ranges.count(n) != 1:
            err.append(f"page {n} rangée {ranges.count(n)} fois dans les albums")
    for a in ALBUMS:
        n = len(rangement.get(a, [])) + sum(p.album == a for p in PAGES)
        if n > CAPACITE_ALBUM:
            err.append(f"album {a} : {n} pages (> {CAPACITE_ALBUM})")
    tous = set(ids)
    for mot, pid in MOTS.items():
        if pid not in tous:
            err.append(f"le mot {mot} n'a pas de page ({pid})")
    return err
