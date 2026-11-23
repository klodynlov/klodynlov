"""Le protocole de comparaison est figé : questions numérotées, identifiants réels, témoins mêlés."""
from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
QUESTIONS = HERE / "questions.md"
SOURCES = HERE.parents[1] / "docs" / "EVEIL-SOURCES.md"

# Empreinte des 33 lignes de questions, figées le 25/09/2026 (COMPARAISON.md).
# Un changement voulu se déclare comme écart au protocole dans le rapport, puis on met à jour ici.
EMPREINTE = "3dbf95c06504d8070972ecbabcae662f7988d389635c3acb845086f36bbe6530"
VERDICTS = ("CONFIRMÉ", "NUANCÉ", "RÉFUTÉ", "NON VÉRIFIÉ")
ID = re.compile(r"\b([A-F])(\d+)([a-z]?)\b")


def question_rows() -> list[list[str]]:
    rows = []
    for line in QUESTIONS.read_text(encoding="utf-8").splitlines():
        if re.match(r"^\| \d+ \|", line):
            rows.append([c.strip() for c in line.strip().strip("|").split("|")])
    return rows


def cloud_verdicts() -> dict[str, str]:
    """Identifiant → verdict de la passe cloud (lignes des axes ; plages « A18–A23 » dépliées)."""
    out: dict[str, str] = {}
    for line in SOURCES.read_text(encoding="utf-8").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3 or not line.startswith("| "):
            continue
        verdict = next((v for v in VERDICTS if cells[2].replace("*", "").strip().startswith(v)), None)
        if verdict is None:
            continue
        span = re.fullmatch(r"([A-F])(\d+)[–-]\1?(\d+)", cells[0])
        if span:
            for n in range(int(span[2]), int(span[3]) + 1):
                out[f"{span[1]}{n}"] = verdict
        elif ID.fullmatch(cells[0]):
            out[cells[0]] = verdict
    return out


class TestProtocoleFige(unittest.TestCase):
    def test_numerotation_continue(self):
        self.assertEqual([int(r[0]) for r in question_rows()], list(range(1, 34)))

    def test_identifiants_existent(self):
        known = cloud_verdicts()
        for row in question_rows():
            ids = ["".join(m) for m in ID.findall(row[-1])]
            self.assertTrue(ids, f"Q{row[0]} ne renvoie à aucune affirmation")
            for i in ids:
                self.assertIn(i, known, f"Q{row[0]} renvoie à {i}, absent de EVEIL-SOURCES.md")

    def test_temoins_tranches_et_meles(self):
        known = cloud_verdicts()
        temoins = [r for r in question_rows() if int(r[0]) >= 19]
        self.assertEqual(len(temoins), 15)
        for r in temoins:
            self.assertEqual(len(r), 5, f"Q{r[0]} : # | Page | Question | Proposition | Id")
            self.assertIn(r[1], {"`/ask`", "`/consensus`"})
            self.assertNotEqual(known[r[4]], "NON VÉRIFIÉ", f"Q{r[0]} : un témoin doit être tranché")
        # Confirmés, nuancés et réfutés mêlés : sans cela, l'accord ne mesure rien.
        self.assertEqual({known[r[4]] for r in temoins}, {"CONFIRMÉ", "NUANCÉ", "RÉFUTÉ"})

    def test_formulations_figees(self):
        texte = "\n".join(" | ".join(r) for r in question_rows())
        self.assertEqual(hashlib.sha256(texte.encode("utf-8")).hexdigest(), EMPREINTE,
                         "questions.md a changé : écart au protocole à déclarer (COMPARAISON.md)")


if __name__ == "__main__":
    unittest.main()
