"""La voix modèle dit-elle bien la fin des mots ? Notre détecteur juge les rendus de `supertonic_essai.py`.

La voix du petit train doit faire entendre la consonne finale (« dou-chhh ») : c'est elle que l'enfant
apprend à dire. On passe chaque mot entier rendu dans le VRAI détecteur (`reference/wordend`,
réglages par défaut) avec sa cible (noyaux, consonne finale) : un mot à fourgon doit sortir COMPLET.
Stdlib uniquement.

    python3 eveil/outils/voix/verifier_fins.py eveil/outils/voix/rendu
"""
from __future__ import annotations

import json
import sys
import wave
from array import array
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "reference"))
from wordend.detector import Shape, detect  # noqa: E402

CIBLES = {  # mot : (noyaux, consonne finale du fourgon ou None)
    "douche": (1, "S"), "mouche": (1, "S"), "tasse": (1, "s"), "os": (1, "s"), "minouche": (2, "S"),
    "saucisse": (2, "s"), "glace": (1, "s"), "princesse": (2, "s"), "jus": (1, None), "peau": (1, None),
    "mur": (1, None), "vert": (1, None), "chat": (1, None), "lune": (1, None),
}


def lire(chemin: Path) -> tuple[list[float], int]:
    with wave.open(str(chemin)) as w:
        assert w.getsampwidth() == 2 and w.getnchannels() == 1
        brut = array("h", w.readframes(w.getnframes()))
        return [v / 32768.0 for v in brut], w.getframerate()


def main(argv: list[str]) -> int:
    dossier = Path(argv[0])
    manifeste = json.loads((dossier / "manifeste.json").read_text(encoding="utf-8"))
    resultats = {}
    for f in manifeste["fichiers"]:
        if f["famille"] != "mot":
            continue
        noyaux, coda = CIBLES[f["texte"]]
        samples, rate = lire(dossier / f["fichier"])
        v = detect(samples, Shape(nuclei=noyaux, coda=coda), rate=rate)
        resultats.setdefault(f["style"], []).append((f["texte"], v.kind.value, v.reasons))
    bilan = {}
    for style, lignes in resultats.items():
        ok = sum(k == "complete" for _, k, _ in lignes)
        bilan[style] = {"complets": ok, "total": len(lignes),
                        "autres": [(t, k, list(r)[:2]) for t, k, r in lignes if k != "complete"]}
        print(f"{style} : {ok}/{len(lignes)} complets ; " +
              "; ".join(f"{t} → {k}" for t, k, _ in lignes if k != "complete"))
    (dossier / "fins.json").write_text(json.dumps(bilan, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
