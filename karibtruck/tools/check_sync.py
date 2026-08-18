#!/usr/bin/env python3
"""Garde-fou : les vecteurs figés dans les tests Swift == sortie de l'oracle.

Sans ça, quelqu'un pourrait modifier la sérialisation Swift ET les hashes des
tests en même temps, et la CI resterait verte à tort. Ce script recalcule la
chaîne avec l'oracle (source de vérité indépendante) et exige que chaque hash
apparaisse littéralement dans les fichiers de tests Swift.

Exécuté en CI (job Python). Sortie non nulle = dérive détectée.
"""
from __future__ import annotations

import pathlib
import sys

import oracle  # même dossier

TESTS_DIR = pathlib.Path(__file__).resolve().parent.parent / "Tests" / "KaribTruckCoreTests"


def main() -> int:
    chain = oracle.build_chain(oracle.FIXTURE)
    if not oracle.verify_chain(chain):
        print("ERREUR: la chaîne de l'oracle ne se vérifie pas.", file=sys.stderr)
        return 1

    swift_text = "\n".join(
        p.read_text(encoding="utf-8") for p in TESTS_DIR.glob("*.swift")
    )

    missing = [e["hash"] for e in chain if e["hash"] not in swift_text]
    if missing:
        print("DÉRIVE: hashes de l'oracle absents des tests Swift :", file=sys.stderr)
        for h in missing:
            print(f"  - {h}", file=sys.stderr)
        print("Régénère les vecteurs (python3 tools/oracle.py) et mets à jour "
              "JournalTests.swift / FacadeTests.swift.", file=sys.stderr)
        return 1

    print(f"check_sync: OK — {len(chain)} vecteurs synchronisés avec les tests Swift.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
