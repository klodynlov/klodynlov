"""Mesures de la comparaison LibraryBrain ↔ passe cloud (COMPARAISON.md, § Mesures).

Lit les réponses CODÉES (`resultats/reponses.jsonl`, dernière ligne par question × passe) et les
verdicts cloud de `docs/EVEIL-SOURCES.md` ; imprime des tableaux Markdown pour le rapport.
À ne lancer qu'en phase 3 : il affiche les verdicts cloud.

    python3 eveil/librarybrain/mesurer.py

Réutilise `cohen_kappa` et `wilson` du banc de validation (`eveil/reference/wordend/bench.py`).
Stdlib uniquement.
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "reference"))
sys.path.insert(0, str(HERE))
from wordend.bench import cohen_kappa, wilson  # noqa: E402

REPONSES = HERE / "resultats" / "reponses.jsonl"
PASSES = ("P0", "P0b", "P1")
COUVERT = ("SOURCÉ", "PARTIEL")
# Position de LibraryBrain (sur la proposition) ↔ verdict de la passe cloud.
VERS_CLOUD = {"SOUTIENT": "CONFIRMÉ", "NUANCE": "NUANCÉ", "CONTREDIT": "RÉFUTÉ"}
SOUPLE = {"CONFIRMÉ": "tient", "NUANCÉ": "tient", "RÉFUTÉ": "réfuté"}


def charger(path: Path = REPONSES) -> dict[tuple[str, int], dict]:
    der: dict[tuple[str, int], dict] = {}
    for ligne in path.read_text(encoding="utf-8").splitlines():
        r = json.loads(ligne)
        der[(r["passe"], r["q"])] = r
    return der


def couverture(codes: list[dict]) -> tuple[int, int, tuple[float, float]]:
    k = sum(1 for r in codes if r.get("couverture") in COUVERT)
    return k, len(codes), wilson(k, len(codes))


def accord(temoins: list[dict], verdicts: dict[str, str], souple: bool = False) -> dict:
    """Accord sur les témoins où LibraryBrain prend position (position ≠ NON TROUVÉ)."""
    paires = []
    for r in temoins:
        lb = VERS_CLOUD.get(r.get("position") or "")
        if lb is None:
            continue
        cloud = verdicts[r["ids"][0]]
        paires.append((SOUPLE[lb], SOUPLE[cloud]) if souple else (lb, cloud))
    if not paires:
        return {"n": 0, "accord": None, "kappa": None, "matrice": {}}
    a, b = [p[0] for p in paires], [p[1] for p in paires]
    # Une seule classe des deux côtés : κ n'est pas défini (bench.cohen_kappa renverrait 1,0).
    kappa = None if len(set(a) | set(b)) < 2 else cohen_kappa(a, b)
    return {"n": len(paires), "accord": sum(x == y for x, y in paires) / len(paires),
            "kappa": kappa, "matrice": dict(Counter(paires))}


def fermes(codes: list[dict], verdicts: dict[str, str]) -> list[int]:
    """Q1–Q18 sourcées ET vérifiées dont au moins une cible est NON VÉRIFIÉ côté cloud."""
    return [r["q"] for r in codes if r["q"] <= 18 and r.get("couverture") == "SOURCÉ"
            and r.get("verifie") == "oui" and any(verdicts.get(i) == "NON VÉRIFIÉ" for i in r["ids"])]


def changements(der: dict, avant: str, apres: str) -> list[int]:
    """Questions dont le codage (couverture ou position) change entre deux passes."""
    out = []
    for (passe, q), r in sorted(der.items()):
        if passe != apres or (avant, q) not in der:
            continue
        a = der[(avant, q)]
        if (a.get("couverture"), a.get("position")) != (r.get("couverture"), r.get("position")):
            out.append(q)
    return out


def _pct(x: float | None) -> str:
    return "—" if x is None else f"{100 * x:.0f} %"


def fermes_par_librarybrain(texte: str) -> set[str]:
    """Identifiants fermés après coup (« LibraryBrain, vérifié dans le texte ») : NON VÉRIFIÉ à l'origine."""
    out = set()
    for ligne in texte.splitlines():
        cells = [c.strip() for c in ligne.strip().strip("|").split("|")]
        if len(cells) >= 3 and ligne.startswith("| ") and "LibraryBrain, vérifié dans le texte" in cells[2]:
            out.add(cells[0])
    return out


def main() -> int:
    from test_questions import SOURCES, cloud_verdicts
    der, verdicts = charger(), cloud_verdicts()
    # Mesurer contre les verdicts de la passe cloud, avant les fermetures issues de cette comparaison.
    verdicts |= {i: "NON VÉRIFIÉ" for i in fermes_par_librarybrain(SOURCES.read_text(encoding="utf-8"))}
    passes = [p for p in PASSES if any(k[0] == p for k in der)]
    print("| Passe | Couverture (sourcé + partiel) | IC 95 % (Wilson) | NON VÉRIFIÉ fermés (cible NON VÉRIFIÉ, sourcé, vérifié) |")
    print("|---|---|---|---|")
    for p in passes:
        codes = [r for (pp, _), r in sorted(der.items()) if pp == p]
        k, n, (lo, hi) = couverture(codes)
        f = fermes(codes, verdicts)
        print(f"| {p} | {k}/{n} ({_pct(k / n)}) | {_pct(lo)} – {_pct(hi)} | {len(f)} {f or ''} |")
    print()
    print("| Passe | Lecture | Témoins avec position | Accord | κ de Cohen | Matrice (LibraryBrain, cloud) |")
    print("|---|---|---|---|---|---|")
    for p in passes:
        temoins = [r for (pp, q), r in sorted(der.items()) if pp == p and q >= 19]
        for souple in (False, True):
            m = accord(temoins, verdicts, souple)
            kap = ("—" if not m["n"] else "n.d.") if m["kappa"] is None else f"{m['kappa']:.2f}"
            mat = ", ".join(f"({a}, {b}) × {c}" for (a, b), c in sorted(m["matrice"].items())) or "—"
            print(f"| {p} | {'souple' if souple else 'stricte'} | {m['n']}/15 | {_pct(m['accord'])} | {kap} | {mat} |")
    print()
    for avant, apres in (("P0", "P0b"), ("P0b", "P1"), ("P0", "P1")):
        if avant in passes and apres in passes:
            print(f"- Codage changé {avant} → {apres} : {changements(der, avant, apres) or 'aucun'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
