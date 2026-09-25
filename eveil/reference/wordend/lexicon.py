"""Lexiques cibles (FR/EN) et mots personnels de la famille.

Un mot cible décrit ce que l'enfant *voit* (wagons = syllabes orales, fourgon =
consonne finale) et ce que le détecteur *attend* (nombre de noyaux, classe de
la consonne finale). Les listes livrées sont des **propositions** : elles
n'entrent en usage qu'après validation par un panel d'orthophonistes
(docs/EVEIL.md §8).
"""
from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

CODAS = {"S", "s"}                   # v0 : sibilantes sourdes /ʃ/ et /s/
MAX_WAGONS = 4
LEXICON_DIR = Path(__file__).resolve().parents[2] / "lexique"


@dataclass(frozen=True)
class Contrast:
    text: str
    ipa: str
    picturable: bool


@dataclass(frozen=True)
class TargetWord:
    id: str
    text: str
    locale: str
    wagons: tuple[str, ...]
    caboose: str | None
    nuclei: int
    coda: str | None
    ipa: str = ""
    level: int = 1
    contrast: Contrast | None = None
    custom: bool = False
    notes: str = ""


@dataclass(frozen=True)
class Lexicon:
    locale: str
    status: str
    words: tuple[TargetWord, ...]
    caboose_sounds: dict = field(default_factory=dict)

    def by_id(self, word_id: str) -> TargetWord:
        for w in self.words:
            if w.id == word_id:
                return w
        raise KeyError(word_id)

    def find(self, key: str) -> TargetWord:
        """Par identifiant (`fr.douche`) ou par texte (`douche`)."""
        for w in self.words:
            if w.id == key or w.text == key:
                return w
        raise KeyError(key)


def _word(d: dict, locale: str) -> TargetWord:
    c = d.get("contrast")
    return TargetWord(
        id=d["id"], text=d["text"], locale=locale, wagons=tuple(d["wagons"]),
        caboose=d.get("caboose"), nuclei=int(d["nuclei"]), coda=d.get("coda"),
        ipa=d.get("ipa", ""), level=int(d.get("level", 1)),
        contrast=Contrast(c["text"], c["ipa"], bool(c["picturable"])) if c else None,
        notes=d.get("notes", ""))


def load(path: str | Path) -> Lexicon:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    locale = data["locale"]
    words = tuple(_word(d, locale) for d in data["words"])
    return Lexicon(locale, data.get("status", ""), words, data.get("caboose_sounds", {}))


def load_locale(locale: str) -> Lexicon:
    return load(LEXICON_DIR / f"{locale}.json")


def problems(lex: Lexicon) -> list[str]:
    """Contrôles de cohérence (vides = lexique sain)."""
    out = []
    seen = set()
    prefix = lex.locale.split("-")[0] + "."
    for w in lex.words:
        if w.id in seen:
            out.append(f"{w.id}: identifiant dupliqué")
        seen.add(w.id)
        if not w.id.startswith(prefix):
            out.append(f"{w.id}: préfixe attendu {prefix!r}")
        if not 1 <= len(w.wagons) <= MAX_WAGONS:
            out.append(f"{w.id}: {len(w.wagons)} wagons (1..{MAX_WAGONS})")
        if len(w.wagons) != w.nuclei:
            out.append(f"{w.id}: wagons ({len(w.wagons)}) ≠ noyaux ({w.nuclei})")
        if w.coda is not None and w.coda not in CODAS:
            out.append(f"{w.id}: consonne finale {w.coda!r} hors v0 {sorted(CODAS)}")
        if (w.coda is None) != (w.caboose is None):
            out.append(f"{w.id}: fourgon et consonne finale doivent aller ensemble")
        if w.coda is not None and w.coda not in lex.caboose_sounds:
            out.append(f"{w.id}: pas de symbole sonore pour {w.coda!r}")
        if w.contrast is not None and w.contrast.text == w.text:
            out.append(f"{w.id}: le contraste doit différer du mot")
    return out


def custom_word(text: str, wagons: list[str], coda: str | None, locale: str,
                caboose: str | None = None) -> TargetWord:
    """Mot personnel saisi par le parent (prénom du chat, du doudou…).

    Le parent découpe le mot en wagons et choisit le son du fourgon ; le mot
    reste sur l'appareil. Lève ValueError si la forme est hors du périmètre v0.
    """
    text = text.strip()
    wagons = [w.strip() for w in wagons if w.strip()]
    if not text:
        raise ValueError("mot vide")
    if not 1 <= len(wagons) <= MAX_WAGONS:
        raise ValueError(f"entre 1 et {MAX_WAGONS} wagons")
    if coda is not None and coda not in CODAS:
        raise ValueError(f"son final {coda!r} non pris en charge en v0")
    labels = {"S": "ch" if locale.startswith("fr") else "sh", "s": "s"}
    label = caboose if caboose else (labels.get(coda) if coda else None)
    slug = "".join(ch for ch in text.lower() if ch.isalnum()) or "mot"
    return TargetWord(id=f"{locale.split('-')[0]}.perso.{slug}", text=text, locale=locale,
                      wagons=tuple(wagons), caboose=label, nuclei=len(wagons), coda=coda,
                      custom=True)


def fold(text: str) -> str:
    """Minuscules sans diacritiques (« Bûche » → « buche »)."""
    nfd = unicodedata.normalize("NFD", text.lower())
    return "".join(ch for ch in nfd if not unicodedata.combining(ch))


def accepted_forms(word: TargetWord) -> set[str]:
    """Formes qui prouvent que l'enfant a bien TENTÉ ce mot (complet ou tronqué)."""
    forms = {fold(word.text), fold("".join(word.wagons))}
    if word.contrast is not None:
        forms.add(fold(word.contrast.text))
    return {f for f in forms if f}


def lexical_evidence(transcript: str, word: TargetWord):
    """Compare une transcription on-device aux formes acceptées du mot."""
    from .detector import LexicalEvidence
    tokens = [t for t in re.split(r"[^a-z0-9]+", fold(transcript)) if t]
    if not tokens:
        return LexicalEvidence.NOT_CHECKED
    joined = "".join(tokens)
    forms = accepted_forms(word)
    if any(t in forms for t in tokens) or any(f == joined for f in forms):
        return LexicalEvidence.CONSISTENT
    return LexicalEvidence.INCONSISTENT
