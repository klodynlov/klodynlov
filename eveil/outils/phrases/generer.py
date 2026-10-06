"""Génère le lexique Swift du train des phrases et ses vecteurs de parité.

    python3 -m phrases.generer            # écrit PhraseLexiconData.swift + phrases-golden.json
    python3 -m phrases.generer --check    # échoue si l'un des deux n'est pas à jour

- `eveil/ios/Sources/PhraseCore/PhraseLexiconData.swift` : les noms et les verbes (source :
  `lexique.py`), relus tels quels par `PhraseCore` ;
- `eveil/ios/Tests/PhraseCoreTests/Resources/phrases-golden.json` : des phrases et des
  plateaux calculés ici ; les tests Swift les recalculent avec `PhraseGrammar` /
  `PhraseLevels` et doivent retrouver exactement les mêmes (parité Python ↔ Swift).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from .grammaire import Carte, morceau, phrase
from .lexique import NOMS, VERBES, noms
from .niveaux import NIVEAUX, plateau, verbes_du_niveau

RACINE = Path(__file__).resolve().parents[2]
SWIFT = RACINE / "ios" / "Sources" / "PhraseCore" / "PhraseLexiconData.swift"
GOLDEN = RACINE / "ios" / "Tests" / "PhraseCoreTests" / "Resources" / "phrases-golden.json"
LOCALES = ("fr-FR", "en-US")


def _s(v: str) -> str:
    return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _liste(vs) -> str:
    return "[" + ", ".join(_s(v) for v in vs) + "]"


def swift_source() -> str:
    out = [
        "// PhraseLexiconData.swift — FICHIER GÉNÉRÉ par eveil/outils/phrases/generer.py : ne pas modifier à la main.",
        "//",
        "// Le lexique du train des phrases (source : eveil/outils/phrases/lexique.py) : les noms",
        "// (qui ? quoi ? où ?) et les verbes, en français et en anglais. Propositions, à valider",
        "// avec le panel (docs/EVEIL.md § 8).",
        "",
        "extension PhraseLexicon {",
        "    public static let nouns: [PhraseNoun] = [",
    ]
    for n in NOMS:
        roles = ", ".join(f".{r}" for r in ("qui", "quoi", "ou") if r in n.roles)
        out.append(f"        PhraseNoun(id: {_s(n.id)}, drawing: {_s(n.dessin)}, gender: .{ {'m': 'masculine', 'f': 'feminine', 'pl': 'plural', 'p': 'proper'}[n.genre] }, "
                   f"fr: {_s(n.fr)}, frIPA: {_s(n.fr_api)}, en: {_s(n.en)}, enIPA: {_s(n.en_api)}, "
                   f"roles: [{roles}], facesLeft: {'true' if n.regarde == 'gauche' else 'false'}, "
                   f"prepositions: {_liste(n.prepositions)}),")
    out += ["    ]", "", "    public static let verbs: [PhraseVerb] = ["]
    for v in VERBES:
        out.append(f"        PhraseVerb(id: {_s(v.id)}, fr: {_s(v.fr)}, frIPA: {_s(v.fr_api)}, en: {_s(v.en)}, "
                   f"enIPA: {_s(v.en_api)}, transitive: {'true' if v.transitif else 'false'}, "
                   f"absolute: {'true' if v.absolu else 'false'}, objects: {_liste(v.objets)}, "
                   f"prepositions: {_liste(v.prepositions)}, places: {_liste(v.lieux)}),")
    out += ["    ]", "}", ""]
    return "\n".join(out)


def _carte(c: Carte) -> dict:
    d = {"role": c.role, "id": c.id}
    if c.preposition:
        d["preposition"] = c.preposition
    return d


def golden() -> dict:
    """Phrases et plateaux de référence (tout est déterministe)."""
    phrases = []
    for niveau, roles in NIVEAUX.items():
        for tour in range(3):
            qui = plateau("qui", niveau, tour)
            verbes = plateau("verbe", niveau, tour)
            for k, (q, v) in enumerate(zip(qui, verbes)):
                cartes = [q, v]
                if "quoi" in roles:
                    quoi = plateau("quoi", niveau, tour, v.id)
                    cartes.append(quoi[k % len(quoi)])
                if "ou" in roles:
                    ou = plateau("ou", niveau, tour, v.id)
                    cartes.append(ou[k % len(ou)])
                phrases.append({"cards": [_carte(c) for c in cartes],
                                **{loc: {"sentence": phrase(cartes, loc),
                                         "chunks": [morceau(c, loc) for c in cartes]} for loc in LOCALES}})
    plateaux = []
    for niveau in NIVEAUX:
        for tour in range(4):
            plateaux.append({"level": niveau, "round": tour, "role": "qui",
                             "cards": [_carte(c) for c in plateau("qui", niveau, tour)]})
            plateaux.append({"level": niveau, "round": tour, "role": "verbe",
                             "cards": [_carte(c) for c in plateau("verbe", niveau, tour)]})
        for v in verbes_du_niveau(niveau):
            for role in NIVEAUX[niveau][2:]:
                for tour in range(2):
                    plateaux.append({"level": niveau, "round": tour, "role": role, "verb": v.id,
                                     "cards": [_carte(c) for c in plateau(role, niveau, tour, v.id)]})
    groupes = [{"id": n.id, **{loc: morceau(Carte("qui" if "qui" in n.roles else "quoi", n.id), loc)
                               for loc in LOCALES}} for n in NOMS if "ou" not in n.roles]
    return {"source": "eveil/outils/phrases (python3 -m phrases.generer)", "sentences": phrases,
            "trays": plateaux, "noun_phrases": groupes,
            "counts": {"qui": len(noms("qui")), "quoi": len(noms("quoi")), "ou": len(noms("ou")),
                       "verbs": len(VERBES)}}


def golden_text() -> str:
    return json.dumps(golden(), ensure_ascii=False, indent=1) + "\n"


def main(argv: list[str]) -> int:
    from .verifier import problemes
    pbs = problemes()
    if pbs:
        print("\n".join(pbs))
        print(f"✗ {len(pbs)} problème(s) : rien n'est écrit.")
        return 1
    fichiers = {SWIFT: swift_source(), GOLDEN: golden_text()}
    if "--check" in argv:
        vieux = [p.name for p, texte in fichiers.items() if not p.exists() or p.read_text(encoding="utf-8") != texte]
        if vieux:
            print(f"✗ pas à jour : {', '.join(vieux)} — python3 -m phrases.generer")
            return 1
        print("✓ lexique Swift et vecteurs de parité à jour.")
        return 0
    for p, texte in fichiers.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(texte, encoding="utf-8")
        print(f"✓ {p.relative_to(RACINE.parent)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
