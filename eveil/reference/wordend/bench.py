"""Banc de validation : le détecteur face au jugement des orthophonistes.

C'est l'outil du protocole de validation par les pairs (docs/EVEIL.md §8) :
des productions d'enfants enregistrées (WAV) sont jugées **indépendamment par
deux orthophonistes** ; le banc mesure leur accord (κ de Cohen), puis compare
le détecteur au **consensus** des deux juges.

Indicateur roi : le **taux de fausse alerte** — la proportion de mots jugés
complets par les orthophonistes pour lesquels le détecteur affirme « il manque
la fin ». Il est rapporté avec un intervalle de confiance de Wilson (les
effectifs seront petits) et conditionne une porte GO / NO GO.

Usage :
    python3 -m wordend.bench --wav-dir enregistrements/ --annotations annotations.csv \\
        --lexique ../lexique/fr-FR.json --rapport rapport.md --sorties verdicts.csv
    python3 -m wordend.bench --demo      # corpus synthétique de démonstration

Format de `annotations.csv` (séparateur `;` ou `,`) :
    fichier;mot;juge_a;juge_b
    e01_douche_1.wav;fr.douche;complet;complet
    e01_douche_2.wav;fr.douche;fin_absente;fin_absente
Étiquettes : complet | fin_absente | syllabe_absente | autre (exclu).
Colonnes optionnelles `noyaux` et `coda` pour un mot hors lexique.
"""
from __future__ import annotations

import argparse
import array
import csv
import io
import math
import sys
import tempfile
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

from .detector import DetectorConfig, Shape, VerdictKind, detect
from .lexicon import Lexicon, load

LABELS = {
    "complet": VerdictKind.COMPLETE,
    "fin_absente": VerdictKind.MISSING_FINAL_CONSONANT,
    "syllabe_absente": VerdictKind.FEWER_SYLLABLES,
}
EXCLUDED = {"autre", "inintelligible", ""}


# ---------------------------------------------------------------------------
# WAV (stdlib)
# ---------------------------------------------------------------------------

def read_wav(path: str | Path) -> tuple[list[float], int]:
    """Lit un WAV PCM entier (8/16/24/32 bits), mélange en mono, → [-1, 1]."""
    with wave.open(str(path), "rb") as w:
        channels = w.getnchannels()
        width = w.getsampwidth()
        rate = w.getframerate()
        raw = w.readframes(w.getnframes())
    if width == 1:
        ints = [b - 128 for b in raw]
        scale = 128.0
    elif width == 2:
        a = array.array("h")
        a.frombytes(raw)
        if sys.byteorder == "big":
            a.byteswap()
        ints = a.tolist()
        scale = 32768.0
    elif width == 3:
        ints = [int.from_bytes(raw[i:i + 3], "little", signed=True) for i in range(0, len(raw), 3)]
        scale = 8388608.0
    elif width == 4:
        a = array.array("i")
        a.frombytes(raw)
        if sys.byteorder == "big":
            a.byteswap()
        ints = a.tolist()
        scale = 2147483648.0
    else:
        raise ValueError(f"{path}: largeur d'échantillon non gérée ({width} octets)")
    if channels > 1:
        ints = [sum(ints[i:i + channels]) / channels for i in range(0, len(ints), channels)]
    return [v / scale for v in ints], rate


def write_wav(path: str | Path, samples: Sequence[float], rate: int) -> None:
    """Écrit un WAV PCM 16 bits mono."""
    a = array.array("h", (int(max(-1.0, min(1.0, v)) * 32767.0) for v in samples))
    if sys.byteorder == "big":
        a.byteswap()
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(a.tobytes())


# ---------------------------------------------------------------------------
# Statistiques
# ---------------------------------------------------------------------------

def cohen_kappa(a: Sequence[str], b: Sequence[str]) -> float:
    """κ de Cohen entre deux juges (mêmes items, étiquettes nominales)."""
    if len(a) != len(b) or not a:
        raise ValueError("séries de même longueur non vides requises")
    n = len(a)
    cats = sorted(set(a) | set(b))
    po = sum(1 for x, y in zip(a, b) if x == y) / n
    pe = sum((a.count(c) / n) * (b.count(c) / n) for c in cats)
    return 1.0 if pe == 1.0 else (po - pe) / (1.0 - pe)


def wilson(successes: int, n: int, z: float = 1.96) -> tuple[float, float]:
    """Intervalle de confiance de Wilson (proportion) — robuste aux petits n."""
    if n == 0:
        return (0.0, 1.0)
    p = successes / n
    den = 1.0 + z * z / n
    centre = (p + z * z / (2 * n)) / den
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return (max(0.0, centre - half), min(1.0, centre + half))


@dataclass(frozen=True)
class Item:
    file: str
    word: str
    judge_a: str
    judge_b: str
    nuclei: int
    coda: str | None


@dataclass(frozen=True)
class Gate:
    max_false_alarm_upper: float = 0.10   # borne haute IC95 de la fausse alerte
    max_unsure_rate: float = 0.30
    min_kappa: float = 0.60               # accord inter-juges minimal pour conclure


@dataclass
class Report:
    n_items: int
    n_excluded: int
    kappa: float | None
    n_consensus: int
    confusion: dict[str, dict[str, int]]
    false_alarm: tuple[int, int]          # (fausses alertes, n complets)
    detection: tuple[int, int]            # (absences détectées, n absences)
    unsure: tuple[int, int]
    decisive_correct: tuple[int, int]
    verdicts: list[tuple[str, str, str]]  # (fichier, consensus, verdict)
    gate: Gate

    @property
    def false_alarm_ci(self) -> tuple[float, float]:
        return wilson(*self.false_alarm)

    @property
    def go(self) -> bool:
        fa_hi = self.false_alarm_ci[1]
        unsure_rate = self.unsure[0] / self.unsure[1] if self.unsure[1] else 1.0
        return (self.kappa is not None and self.kappa >= self.gate.min_kappa
                and self.false_alarm[1] > 0 and fa_hi <= self.gate.max_false_alarm_upper
                and unsure_rate <= self.gate.max_unsure_rate)

    def markdown(self) -> str:
        def pct(k: int, n: int) -> str:
            return f"{k}/{n} ({100.0 * k / n:.1f} %)" if n else "—"
        lo, hi = self.false_alarm_ci
        lines = [
            "# Banc de validation — détecteur de fin de mot", "",
            f"- Items : {self.n_items} (exclus : {self.n_excluded})",
            f"- Accord inter-juges κ = {self.kappa:.3f}" if self.kappa is not None else "- κ : n/a",
            f"- Items en consensus : {self.n_consensus}", "",
            "| Indicateur | Valeur |", "|---|---|",
            f"| **Fausse alerte** (« fin absente » sur un mot complet) | {pct(*self.false_alarm)}"
            f" — IC95 Wilson [{100 * lo:.1f} % ; {100 * hi:.1f} %] |",
            f"| Détection des absences | {pct(*self.detection)} |",
            f"| Taux d'incertitude | {pct(*self.unsure)} |",
            f"| Exactitude quand le détecteur tranche | {pct(*self.decisive_correct)} |", "",
            "## Matrice consensus × détecteur", "",
            "| consensus \\ détecteur | " + " | ".join(k.value for k in VerdictKind) + " |",
            "|---|" + "---|" * len(VerdictKind),
        ]
        for label, row in self.confusion.items():
            lines.append(f"| {label} | " + " | ".join(str(row.get(k.value, 0)) for k in VerdictKind) + " |")
        g = self.gate
        lines += ["", f"## Porte : **{'GO' if self.go else 'NO GO'}**", "",
                  f"Critères : κ ≥ {g.min_kappa} · borne haute IC95 fausse alerte ≤ "
                  f"{100 * g.max_false_alarm_upper:.0f} % · incertitude ≤ {100 * g.max_unsure_rate:.0f} %."]
        return "\n".join(lines) + "\n"


def read_annotations(text: str, lexicon: Lexicon | None) -> tuple[list[Item], int]:
    sample = text[:2048]
    delim = ";" if sample.count(";") >= sample.count(",") else ","
    rows = list(csv.DictReader(io.StringIO(text), delimiter=delim))
    items = []
    excluded = 0
    for r in rows:
        a = (r.get("juge_a") or "").strip().lower()
        b = (r.get("juge_b") or "").strip().lower()
        if a in EXCLUDED or b in EXCLUDED:
            excluded += 1
            continue
        for lab in (a, b):
            if lab not in LABELS:
                raise ValueError(f"étiquette inconnue {lab!r} (attendu : {sorted(LABELS)})")
        word = (r.get("mot") or "").strip()
        if r.get("noyaux"):
            nuclei = int(r["noyaux"])
            coda = (r.get("coda") or "").strip() or None
        elif lexicon is not None:
            w = lexicon.find(word)
            nuclei, coda = w.nuclei, w.coda
        else:
            raise ValueError(f"{word}: ni lexique ni colonnes noyaux/coda")
        items.append(Item(r["fichier"].strip(), word, a, b, nuclei, coda))
    return items, excluded


def evaluate_corpus(items: Iterable[Item], wav_dir: Path, cfg: DetectorConfig = DetectorConfig(),
                    gate: Gate = Gate(), excluded: int = 0) -> Report:
    items = list(items)
    kappa = cohen_kappa([i.judge_a for i in items], [i.judge_b for i in items]) if items else None
    confusion: dict[str, dict[str, int]] = {}
    fa = [0, 0]
    det = [0, 0]
    uns = [0, 0]
    dec = [0, 0]
    verdicts = []
    n_consensus = 0
    for it in items:
        samples, rate = read_wav(wav_dir / it.file)
        v = detect(samples, Shape(it.nuclei, it.coda), rate, cfg)
        if it.judge_a != it.judge_b:
            verdicts.append((it.file, "désaccord", v.kind.value))
            continue
        n_consensus += 1
        truth = LABELS[it.judge_a]
        row = confusion.setdefault(it.judge_a, {})
        row[v.kind.value] = row.get(v.kind.value, 0) + 1
        verdicts.append((it.file, it.judge_a, v.kind.value))
        if truth is VerdictKind.COMPLETE:
            fa[1] += 1
            fa[0] += v.kind is VerdictKind.MISSING_FINAL_CONSONANT
        if truth is VerdictKind.MISSING_FINAL_CONSONANT:
            det[1] += 1
            det[0] += v.kind is VerdictKind.MISSING_FINAL_CONSONANT
        uns[1] += 1
        uns[0] += v.kind is VerdictKind.UNSURE
        if v.kind not in (VerdictKind.UNSURE, VerdictKind.NO_SPEECH):
            dec[1] += 1
            dec[0] += v.kind is truth
    return Report(len(items), excluded, kappa, n_consensus, confusion, (fa[0], fa[1]),
                  (det[0], det[1]), (uns[0], uns[1]), (dec[0], dec[1]), verdicts, gate)


# ---------------------------------------------------------------------------
# Corpus synthétique de démonstration
# ---------------------------------------------------------------------------

def build_demo_corpus(directory: Path, seeds: Sequence[int] = (1, 2, 3)) -> str:
    """Écrit des WAV synthétiques + un CSV d'annotations simulées ; renvoie le CSV."""
    from .synth import LIBRARY, synthesize, utterance
    plan = [("douche", "fr.douche", "complet"), ("dou", "fr.douche", "fin_absente"),
            ("minouche", "fr.minouche", "complet"), ("minou", "fr.minouche", "fin_absente"),
            ("mi", "fr.minouche", "syllabe_absente")]
    lines = ["fichier;mot;juge_a;juge_b"]
    for seed in seeds:
        for name, word, label in plan:
            fname = f"s{seed}_{name}.wav"
            x = synthesize(utterance(LIBRARY[name], seed=seed, snr_db=30.0))
            write_wav(directory / fname, x, 24_000)
            lines.append(f"{fname};{word};{label};{label}")
    # un désaccord entre juges, pour montrer qu'il est écarté du consensus
    lines.append(f"s{seeds[0]}_minouche.wav;fr.minouche;complet;fin_absente")
    text = "\n".join(lines) + "\n"
    (directory / "annotations.csv").write_text(text, encoding="utf-8")
    return text


def main(argv: Sequence[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Banc de validation du détecteur de fin de mot")
    p.add_argument("--wav-dir", type=Path)
    p.add_argument("--annotations", type=Path)
    p.add_argument("--lexique", type=Path)
    p.add_argument("--rapport", type=Path, help="écrit le rapport Markdown ici")
    p.add_argument("--sorties", type=Path, help="écrit les verdicts par fichier (CSV)")
    p.add_argument("--demo", action="store_true", help="corpus synthétique de démonstration")
    args = p.parse_args(argv)

    if args.demo:
        tmp = Path(tempfile.mkdtemp(prefix="eveil-banc-"))
        build_demo_corpus(tmp)
        args.wav_dir, args.annotations = tmp, tmp / "annotations.csv"
        from .lexicon import load_locale
        lexicon = load_locale("fr-FR")
    else:
        if not (args.wav_dir and args.annotations):
            p.error("--wav-dir et --annotations sont requis (ou --demo)")
        lexicon = load(args.lexique) if args.lexique else None
    items, excluded = read_annotations(args.annotations.read_text(encoding="utf-8"), lexicon)
    report = evaluate_corpus(items, args.wav_dir, excluded=excluded)
    md = report.markdown()
    if args.rapport:
        args.rapport.write_text(md, encoding="utf-8")
    if args.sorties:
        with args.sorties.open("w", encoding="utf-8", newline="") as f:
            w = csv.writer(f, delimiter=";")
            w.writerow(["fichier", "consensus", "verdict"])
            w.writerows(report.verdicts)
    print(md)
    return 0 if report.go else 1


if __name__ == "__main__":
    raise SystemExit(main())
