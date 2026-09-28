"""Génère les livres des sons pour l'app : `eveil/ios/Sources/PhraseCore/SoundBooksData.swift`.

    python3 -m livres.generer            # écrit le fichier (refuse s'il y a un problème)
    python3 -m livres.generer --check    # échoue s'il n'est pas à jour
    python3 -m livres.generer --en-cours [--check]
        # seulement les mots dont le dessin existe déjà : des livres plus courts (et moins de
        # livres), jamais une image manquante — en attendant que tous les mots soient dessinés.
"""
from __future__ import annotations

import sys
from pathlib import Path

from .livres import livres
from .mots import TOUS
from .phrases import phrases_du_livre
from .verifier import mots_dessines, problemes

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "ios" / "Sources" / "PhraseCore" / "SoundBooksData.swift"
LOCALES = ("fr-FR", "en-US")


def _s(v: str) -> str:
    return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _carte(c) -> str:
    prep = f", preposition: {_s(c.preposition)}" if c.preposition else ""
    return f"PhraseCard(.{c.role}, {_s(c.id)}{prep})"


# Au plus ce nombre d'éléments dans un même littéral Swift. En Debug (le ▶︎ d'Xcode), un littéral
# se construit d'un bloc dans le cadre de pile de la fonction qui le porte : 349 Ko de livres en un
# seul `static let` ont fait déborder la pile du fil principal (l'app se fermait en ouvrant les
# livres, 28/09/2026). Un constructeur par livre, un pour ses mots, un pour ses phrases : de
# petits cadres, libérés au retour (comme PictoDessins.swift : une fonction par picto).
MAX_PAR_LITTERAL = 40


def _nom_swift(loc: str, k: int) -> str:
    return ("fr" if loc.startswith("fr") else "en") + f"{k:02d}"


def swift_source(mots: tuple = TOUS) -> str:
    out = [
        "// SoundBooksData.swift — FICHIER GÉNÉRÉ par eveil/outils/livres/generer.py : ne pas modifier à la main.",
        "//",
        "// Les livres des sons : un livre par son, calculé à partir des mots dessinés (au début, au",
        "// milieu, à la fin), avec le wagon du son et ses lettres ; ses phrases (niveau 2 : qui + fait",
        "// quoi + quoi ; niveau 3 : qui + fait quoi + où), avec les lettres du son dans chaque wagon et",
        "// les pictos proposés ; une image sonore et une idée de jeu pour l'adulte (propositions à",
        "// valider par des orthophonistes, docs/EVEIL.md § 8).",
        "//",
        "// Un constructeur par livre (et un pour ses mots, un pour ses phrases), jamais un littéral géant :",
        "// en Debug, un littéral se construit d'un bloc sur la pile, et 349 Ko en un seul faisaient",
        "// déborder celle du fil principal (l'app se fermait en ouvrant les livres).",
    ]
    if len(mots) < len(TOUS):
        out.append(f"// EN COURS : {len(mots)} mots sur {len(TOUS)} ont déjà leur dessin ; les livres grandiront.")
    noms = [(loc, k, livre) for loc in LOCALES for k, livre in enumerate(livres(loc, mots))]
    out += ["", "extension SoundBooks {", "    public static let all: [SoundBook] = ["]
    out += [f"        book{_nom_swift(loc, k).capitalize()}()," for loc, k, _ in noms]
    out.append("    ]")
    for loc, k, livre in noms:
        fr = loc.startswith("fr")
        son = livre.son
        n = _nom_swift(loc, k).capitalize()
        phrases = phrases_du_livre(son, loc)
        if len(livre.pages) > MAX_PAR_LITTERAL or len(phrases) > MAX_PAR_LITTERAL:
            raise ValueError(f"{loc} {son.etiquette} : trop d'éléments pour un seul littéral")
        out += [
            "",
            f"    /// {SoundBooksTitle(loc, son.etiquette)}",
            f"    private static func book{n}() -> SoundBook {{",
            f"        SoundBook(locale: {_s(loc)}, sound: {_s(son.api)}, label: {_s(son.etiquette)},",
            f"                  image: {_s(son.image)},",
            f"                  game: {_s(son.jeu)},",
            f"                  words: words{n}(), sentences: sentences{n}())",
            "    }",
            "",
            f"    private static func words{n}() -> [SoundBookWord] {{",
            "        [",
        ]
        for pg in livre.pages:
            m = pg.mot
            texte, api, wagons = (m.fr, m.fr_api, m.fr_wagons) if fr else (m.en, m.en_api, m.en_wagons)
            wag = ", ".join(_s(w) for w in wagons)
            out.append(f"            SoundBookWord(id: {_s(m.id)}, drawing: {_s(m.dessin)}, "
                       f"text: {_s(texte)}, ipa: {_s(api)}, wagons: [{wag}], targetWagon: {pg.wagon}, "
                       f"letters: {_s(pg.lettres)}, position: .{ {'debut': 'start', 'milieu': 'middle', 'fin': 'end'}[pg.position] }),")
        out += ["        ]", "    }", "", f"    private static func sentences{n}() -> [SoundBookSentence] {{", "        ["]
        for ph in phrases:
            marques = ", ".join("nil" if m is None else f"SoundMark(start: {m.debut}, length: {m.longueur})"
                                for m in ph.marques)
            choix = ", ".join("[" + ", ".join(_carte(c) for c in ch) + "]" for ch in ph.choix)
            out.append(f"            SoundBookSentence(level: {ph.niveau}, "
                       f"cards: [{', '.join(_carte(c) for c in ph.cartes)}],")
            out.append(f"                              marks: [{marques}],")
            out.append(f"                              choices: [{choix}],")
            out.append(f"                              text: {_s(ph.texte)}),")
        out += ["        ]", "    }"]
    out += ["}", ""]
    return "\n".join(out)


def SoundBooksTitle(loc: str, etiquette: str) -> str:
    return f"Le livre du « {etiquette} »" if loc.startswith("fr") else f"The “{etiquette}” book"


def main(argv: list[str]) -> int:
    en_cours = "--en-cours" in argv
    pbs = problemes(verifier_dessins=not en_cours)
    if pbs:
        print("\n".join(pbs))
        print(f"✗ {len(pbs)} problème(s) : rien n'est écrit.")
        return 1
    mots = mots_dessines() if en_cours else TOUS
    source = swift_source(mots)
    if "--check" in argv:
        if not SORTIE.exists() or SORTIE.read_text(encoding="utf-8") != source:
            print(f"✗ {SORTIE.name} n'est pas à jour : python3 -m livres.generer")
            return 1
        print(f"✓ {SORTIE.name} à jour ({len(mots)} mots sur {len(TOUS)}).")
        return 0
    SORTIE.write_text(source, encoding="utf-8")
    print(f"✓ {SORTIE.relative_to(RACINE.parent)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
