#!/usr/bin/env python3
"""Oracle de référence du journal inviolable de KaribTruck.

Ce fichier définit — en Python, indépendamment de l'implémentation Swift — la
**sérialisation canonique** et le **chaînage SHA-256** du journal append-only.
Il sert à deux choses :

1. Vérifier la spec contre `hashlib` (vecteurs standards SHA-256).
2. Générer des **vecteurs de réponse connue** (known-answer tests) que l'on fige
   dans la suite XCTest Swift. Si l'implémentation Swift diverge d'un seul octet,
   la CI vire au rouge.

Le journal est volontairement générique : chaque entrée est
(index, timestamp, kind, payload{str:str}, previousHash). La sérialisation est
**préfixée en longueur** (byte-length UTF-8) pour être sans ambiguïté : aucun
séparateur ne peut être injecté depuis une valeur pour forger une autre entrée.

Aucune dépendance externe. `python3 tools/oracle.py` lance les tests et imprime
les vecteurs. Sortie 0 = tout est vert.
"""
from __future__ import annotations

import hashlib
import json
import sys

GENESIS_PREV_HASH = "0" * 64


def _field(s: str) -> bytes:
    """Encode un champ en préfixe-longueur : '<nb_octets_utf8>:' + octets_utf8."""
    raw = s.encode("utf-8")
    return f"{len(raw)}:".encode("ascii") + raw


def canonical_bytes(index: int, timestamp: str, kind: str,
                    previous_hash: str, payload: dict[str, str]) -> bytes:
    """Forme canonique déterministe d'une entrée (clés de payload triées)."""
    out = bytearray()
    out += _field(str(index))
    out += _field(timestamp)
    out += _field(kind)
    out += _field(previous_hash)
    out += _field(str(len(payload)))
    for key in sorted(payload.keys()):
        out += _field(key)
        out += _field(payload[key])
    return bytes(out)


def entry_hash(index: int, timestamp: str, kind: str,
               previous_hash: str, payload: dict[str, str]) -> str:
    return hashlib.sha256(
        canonical_bytes(index, timestamp, kind, previous_hash, payload)
    ).hexdigest()


def build_chain(records: list[dict]) -> list[dict]:
    """Chaîne une liste de (timestamp, kind, payload) en entrées scellées."""
    entries = []
    prev = GENESIS_PREV_HASH
    for i, rec in enumerate(records):
        h = entry_hash(i, rec["timestamp"], rec["kind"], prev, rec["payload"])
        entries.append({
            "index": i,
            "timestamp": rec["timestamp"],
            "kind": rec["kind"],
            "payload": rec["payload"],
            "previousHash": prev,
            "hash": h,
        })
        prev = h
    return entries


def verify_chain(entries: list[dict]) -> bool:
    """Revérifie hachages + chaînage. Toute altération casse la vérification."""
    prev = GENESIS_PREV_HASH
    for e in entries:
        if e["previousHash"] != prev:
            return False
        expected = entry_hash(e["index"], e["timestamp"], e["kind"],
                              prev, e["payload"])
        if e["hash"] != expected:
            return False
        prev = e["hash"]
    return True


# --- Fixture partagée avec les tests Swift (mêmes valeurs des deux côtés) ------
FIXTURE = [
    {"timestamp": "2026-08-18T07:00:00Z", "kind": "enclosure.reading",
     "payload": {"enclosure": "frigo", "celsius": "3.5",
                 "rule": "max", "limit": "4.0", "status": "ok"}},
    {"timestamp": "2026-08-18T07:01:00Z", "kind": "enclosure.reading",
     "payload": {"enclosure": "vitrine-chaude", "celsius": "61.0",
                 "rule": "min", "limit": "63.0", "status": "alert"}},
    {"timestamp": "2026-08-18T07:05:00Z", "kind": "checklist.run",
     "payload": {"checklist": "ouverture", "done": "5", "total": "5",
                 "operator": "klody"}},
    {"timestamp": "2026-08-18T07:10:00Z", "kind": "reception",
     "payload": {"supplier": "Antilles Frais", "lot": "LOT-2208",
                 "dlc": "2026-08-25", "product": "poulet"}},
    {"timestamp": "2026-08-18T18:00:00Z", "kind": "frying-oil.check",
     "payload": {"fryer": "friteuse-1", "action": "controle",
                 "quality": "bonne", "changed": "false"}},
    {"timestamp": "2026-08-18T18:30:00Z", "kind": "nonconformity",
     "payload": {"severity": "majeure", "what": "coupure elec 40min",
                 "action": "jeter produits frais vitrine"}},
    {"timestamp": "2026-08-19T06:00:00Z", "kind": "market.schedule",
     "payload": {"date": "2026-08-20", "place": "Marche de Fort-de-France",
                 "slot": "08:00-14:00"}},
]


def _selftest() -> None:
    # 1. SHA-256 conforme à hashlib sur vecteurs standards (sanity du digest).
    assert hashlib.sha256(b"").hexdigest() == (
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    assert hashlib.sha256(b"abc").hexdigest() == (
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")

    # 2. _field est sans ambiguïté : deux découpages différents -> octets différents.
    assert _field("a=b") != _field("a") + _field("b")

    # 3. Chaîne construite puis vérifiée.
    chain = build_chain(FIXTURE)
    assert verify_chain(chain), "la chaîne de référence doit se vérifier"

    # 4. Inviolabilité : altérer une valeur casse la vérification.
    tampered = json.loads(json.dumps(chain))
    tampered[0]["payload"]["celsius"] = "9.9"  # on falsifie un relevé de froid
    assert not verify_chain(tampered), "une altération doit être détectée"

    # 5. Inviolabilité : réordonner des entrées casse le chaînage.
    reordered = json.loads(json.dumps(chain))
    reordered[2], reordered[3] = reordered[3], reordered[2]
    assert not verify_chain(reordered), "un réordonnancement doit être détecté"

    print("oracle self-test: OK (5/5)")


def main() -> int:
    _selftest()
    chain = build_chain(FIXTURE)
    # Vecteurs à copier dans KaribTruckCoreTests (known-answer tests).
    print("\n// === Vecteurs de réponse connue (générés par tools/oracle.py) ===")
    for e in chain:
        print(f'// index {e["index"]} [{e["kind"]}] hash = {e["hash"]}')
    print("\nHEAD_HASH =", chain[-1]["hash"])
    # Émission JSON pour outillage éventuel.
    with open("tools/fixture_vectors.json", "w", encoding="utf-8") as fh:
        json.dump(chain, fh, ensure_ascii=False, indent=2)
    print("écrit: tools/fixture_vectors.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
