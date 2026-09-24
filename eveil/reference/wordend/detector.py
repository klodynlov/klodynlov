"""Détecteur de fin de mot — la logique, sans iOS, sans modèle opaque.

Chaîne : trames → planchers de bruit → région de parole → **noyaux syllabiques**
(pics d'énergie en bande « voyelle », voisés, séparés par un creux — critère à
la de Jong & Wempe 2009) → **segments de friction** (énergie haute fréquence
nettement au-dessus du plancher) → **verdict** comparé au mot cible (nombre de
noyaux attendus + consonne finale attendue).

Principe directeur : **asymétrie des erreurs**. Dire « il manque la fin » à un
enfant qui l'a prononcée est l'erreur la plus coûteuse (démotivation, fausse
consigne). Le détecteur n'affirme donc une absence que sur une *preuve
d'absence* (silence haute fréquence juste après la voyelle, bon rapport
signal/bruit, voix d'enfant, pas d'écrêtage). Dans le doute : INCERTAIN, et
l'interface reste neutre (`policy.py`).

Tous les seuils sont dans `DetectorConfig` : ce sont des **valeurs de départ**,
à recalibrer sur le corpus annoté du protocole de validation (`bench.py`).
"""
from __future__ import annotations

from dataclasses import asdict, dataclass, field, replace
from enum import Enum
from typing import Protocol, Sequence

from .dsp import (ANALYSIS_RATE, FRAME_SIZE, HOP_SIZE, Bands, FrameFeatures, compute_frames,
                  estimate_f0, frame_ms, moving_average, ms_to_frames, percentile, resample)


class TargetShape(Protocol):
    """Ce que le détecteur doit savoir du mot cible (cf. `lexicon.TargetWord`)."""

    nuclei: int              # nombre de syllabes orales (noyaux vocaliques)
    coda: str | None         # consonne finale attendue ("S", "s"…) ou None


@dataclass(frozen=True)
class DetectorConfig:
    bands: Bands = Bands()
    floor_percentile: float = 0.10       # plancher = 10e percentile des trames
    vad_on_db: float = 10.0              # parole : RMS ≥ plancher + 10 dB
    vad_min_ms: float = 50.0             # région de parole ≥ 50 ms (rejette les clics)
    vad_merge_gap_ms: float = 450.0      # fusion : un enfant peut segmenter (« mi… nouche »)
    other_region_max_below_db: float = 10.0   # 2e énoncé « comparable » ⇒ incertain
    envelope_smooth_frames: int = 5      # lissage de l'enveloppe (50 ms)
    nucleus_min_above_floor_db: float = 15.0
    nucleus_max_below_peak_db: float = 20.0
    nucleus_max_zcr_hz: float = 3000.0   # voisement grossier (voyelles : ZCR bas)
    nucleus_max_high_ratio: float = 0.5
    nucleus_min_dip_db: float = 3.0      # creux entre deux noyaux (de Jong & Wempe : 2 dB)
    vowel_offset_drop_db: float = 10.0   # fin de voyelle : enveloppe < pic − 10 dB
    fric_min_above_floor_db: float = 10.0
    fric_min_high_ratio: float = 0.7
    fric_min_zcr_hz: float = 3000.0
    fric_min_ms: float = 50.0
    fric_merge_gap_ms: float = 20.0
    coda_max_gap_ms: float = 150.0       # la friction doit suivre la voyelle de près
    absence_guard_ms: float = 30.0       # ignorer la queue de la voyelle
    absence_window_ms: float = 250.0     # fenêtre où l'on exige le silence HF
    absence_max_above_floor_db: float = 6.0
    absence_max_fraction: float = 0.2    # tolérance : 20 % de trames au-dessus
    min_snr_db: float = 20.0
    epenthesis_min_drop_db: float = 6.0  # schwa final plus faible que la voyelle
    clip_level: float = 0.99
    clip_max_fraction: float = 0.005
    adult_f0_max_hz: float = 165.0       # F0 médiane < 165 Hz ⇒ voix adulte probable
    postalveolar_max_centroid_hz: float = 6000.0   # /ʃ/ vs /s/ — à calibrer (enfants)


class VerdictKind(str, Enum):
    NO_SPEECH = "no_speech"
    COMPLETE = "complete"
    MISSING_FINAL_CONSONANT = "missing_final_consonant"
    FEWER_SYLLABLES = "fewer_syllables"
    UNSURE = "unsure"


@dataclass(frozen=True)
class Nucleus:
    frame: int            # trame du pic
    level_db: float       # enveloppe basse fréquence lissée au pic
    onset: int
    offset: int
    f0_hz: float | None = None


@dataclass(frozen=True)
class Frication:
    start: int            # trame de début (incluse)
    end: int              # trame de fin (incluse)
    centroid_hz: float    # centroïde moyen
    peak_high_db: float

    @property
    def frames(self) -> int:
        return self.end - self.start + 1


@dataclass(frozen=True)
class Analysis:
    frames: tuple[FrameFeatures, ...]
    floor_rms_db: float
    floor_low_db: float
    floor_high_db: float
    envelope: tuple[float, ...]
    speech: tuple[int, int] | None
    nuclei: tuple[Nucleus, ...]
    frications: tuple[Frication, ...]
    clipped_fraction: float
    snr_db: float
    other_regions: int = 0


@dataclass(frozen=True)
class Verdict:
    kind: VerdictKind
    heard_nuclei: int
    expected_nuclei: int
    coda_expected: bool
    coda_heard: bool
    coda_place: str | None = None        # "postalveolar" (/ʃ/-like) | "alveolar" (/s/-like)
    coda_ms: float = 0.0
    epenthesis: bool = False
    snr_db: float = 0.0
    reasons: tuple[str, ...] = field(default_factory=tuple)

    def to_dict(self) -> dict:
        d = asdict(self)
        d["kind"] = self.kind.value
        d["reasons"] = list(self.reasons)
        return d


# ---------------------------------------------------------------------------
# Analyse
# ---------------------------------------------------------------------------

def _runs(flags: Sequence[bool]) -> list[tuple[int, int]]:
    runs = []
    start = None
    for i, f in enumerate(flags):
        if f and start is None:
            start = i
        elif not f and start is not None:
            runs.append((start, i - 1))
            start = None
    if start is not None:
        runs.append((start, len(flags) - 1))
    return runs


def _merge(runs: list[tuple[int, int]], max_gap: int) -> list[tuple[int, int]]:
    merged: list[tuple[int, int]] = []
    for r in runs:
        if merged and r[0] - merged[-1][1] - 1 <= max_gap:
            merged[-1] = (merged[-1][0], r[1])
        else:
            merged.append(r)
    return merged


def _speech_regions(frames: Sequence[FrameFeatures], floor_rms: float,
                    cfg: DetectorConfig) -> tuple[tuple[int, int] | None, int]:
    """Région de parole principale + nombre d'autres régions comparables.

    Principale = celle qui contient la trame la plus forte en bande « voyelle ».
    Une autre région est « comparable » si son pic basse fréquence est à moins
    de `other_region_max_below_db` du pic principal (un 2e mot, la voix d'un
    parent…) : on ne sait alors plus quelle production juger.
    """
    active = [f.rms_db >= floor_rms + cfg.vad_on_db for f in frames]
    runs = _merge(_runs(active), ms_to_frames(cfg.vad_merge_gap_ms))
    runs = [r for r in runs if r[1] - r[0] + 1 >= ms_to_frames(cfg.vad_min_ms)]
    if not runs:
        return None, 0
    peaks = [max(f.low_db for f in frames[a:b + 1]) for a, b in runs]
    main = max(range(len(runs)), key=lambda i: peaks[i])
    others = sum(1 for i, p in enumerate(peaks)
                 if i != main and p >= peaks[main] - cfg.other_region_max_below_db)
    return runs[main], others


def _find_nuclei(env: Sequence[float], frames: Sequence[FrameFeatures], region: tuple[int, int],
                 floor_low: float, cfg: DetectorConfig) -> list[Nucleus]:
    a, b = region
    cands = []
    for t in range(a, b + 1):
        left = env[t - 1] if t - 1 >= a else float("-inf")
        right = env[t + 1] if t + 1 <= b else float("-inf")
        if env[t] > left and env[t] >= right:
            f = frames[t]
            if (env[t] >= floor_low + cfg.nucleus_min_above_floor_db
                    and f.zcr_hz <= cfg.nucleus_max_zcr_hz
                    and f.high_ratio <= cfg.nucleus_max_high_ratio):
                cands.append(t)
    kept: list[int] = []
    for t in cands:
        if not kept:
            kept.append(t)
            continue
        q = kept[-1]
        dip = min(env[q:t + 1])
        if env[q] - dip >= cfg.nucleus_min_dip_db and env[t] - dip >= cfg.nucleus_min_dip_db:
            kept.append(t)
        elif env[t] > env[q]:
            kept[-1] = t
    if kept:
        top = max(env[t] for t in kept)
        kept = [t for t in kept if env[t] >= top - cfg.nucleus_max_below_peak_db]
    nuclei = []
    for i, t in enumerate(kept):
        lo_lim = a if i == 0 else min(range(kept[i - 1], t + 1), key=lambda k: env[k])
        hi_lim = b if i == len(kept) - 1 else min(range(t, kept[i + 1] + 1), key=lambda k: env[k])
        level = env[t] - cfg.vowel_offset_drop_db
        s = t
        while s - 1 >= lo_lim and env[s - 1] >= level:
            s -= 1
        e = t
        while e + 1 <= hi_lim and env[e + 1] >= level:
            e += 1
        nuclei.append(Nucleus(t, env[t], s, e))
    return nuclei


def _find_frications(frames: Sequence[FrameFeatures], floor_high: float,
                     cfg: DetectorConfig) -> list[Frication]:
    flags = [f.high_ratio >= cfg.fric_min_high_ratio
             and f.high_db >= floor_high + cfg.fric_min_above_floor_db
             and f.zcr_hz >= cfg.fric_min_zcr_hz for f in frames]
    runs = _merge(_runs(flags), ms_to_frames(cfg.fric_merge_gap_ms))
    out = []
    for s, e in runs:
        if e - s + 1 < ms_to_frames(cfg.fric_min_ms):
            continue
        seg = frames[s:e + 1]
        centroid = sum(f.centroid_hz for f in seg) / len(seg)
        out.append(Frication(s, e, centroid, max(f.high_db for f in seg)))
    return out


def analyze_frames(frames: Sequence[FrameFeatures], samples: Sequence[float],
                   cfg: DetectorConfig = DetectorConfig(), with_f0: bool = True) -> Analysis:
    """Analyse à partir de trames déjà calculées (chemin commun batch / flux)."""
    frames = tuple(frames)
    if not frames:
        return Analysis(frames, 0.0, 0.0, 0.0, (), None, (), (), 0.0, 0.0, 0)
    floor_rms = percentile([f.rms_db for f in frames], cfg.floor_percentile)
    floor_low = percentile([f.low_db for f in frames], cfg.floor_percentile)
    floor_high = percentile([f.high_db for f in frames], cfg.floor_percentile)
    env = moving_average([f.low_db for f in frames], cfg.envelope_smooth_frames)
    region, others = _speech_regions(frames, floor_rms, cfg)
    nuclei: list[Nucleus] = []
    clipped = 0.0
    snr = 0.0
    if region is not None:
        nuclei = _find_nuclei(env, frames, region, floor_low, cfg)
        if with_f0:
            nuclei = [Nucleus(n.frame, n.level_db, n.onset, n.offset,
                              estimate_f0(samples, n.frame)) for n in nuclei]
        a, b = region
        s0 = a * HOP_SIZE
        s1 = min(len(samples), b * HOP_SIZE + FRAME_SIZE)
        if s1 > s0:
            clipped = sum(1 for v in samples[s0:s1] if abs(v) >= cfg.clip_level) / (s1 - s0)
        top = max((n.level_db for n in nuclei), default=max(env[a:b + 1]))
        snr = top - floor_low
    fr = _find_frications(frames, floor_high, cfg)
    return Analysis(frames, floor_rms, floor_low, floor_high, tuple(env), region,
                    tuple(nuclei), tuple(fr), clipped, snr, others)


def analyze(samples: Sequence[float], rate: int = ANALYSIS_RATE,
            cfg: DetectorConfig = DetectorConfig()) -> Analysis:
    """Analyse complète d'un énoncé (mono, flottants dans [-1, 1])."""
    x = resample(samples, rate, ANALYSIS_RATE) if rate != ANALYSIS_RATE else list(samples)
    return analyze_frames(compute_frames(x, cfg.bands), x, cfg)


# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------

def _coda_after(n: Nucleus, frications: Sequence[Frication], cfg: DetectorConfig) -> Frication | None:
    gap = ms_to_frames(cfg.coda_max_gap_ms)
    for fr in frications:
        if n.frame <= fr.start <= n.offset + gap:
            return fr
    return None


def _median(values: Sequence[float]) -> float:
    s = sorted(values)
    m = len(s) // 2
    return s[m] if len(s) % 2 else 0.5 * (s[m - 1] + s[m])


def evaluate(an: Analysis, target: TargetShape, cfg: DetectorConfig = DetectorConfig()) -> Verdict:
    """Compare l'analyse au mot cible. Voir le principe d'asymétrie en tête de module."""
    expected = target.nuclei
    coda_expected = target.coda is not None
    base = dict(expected_nuclei=expected, coda_expected=coda_expected, snr_db=round(an.snr_db, 2))
    if an.speech is None:
        return Verdict(VerdictKind.NO_SPEECH, 0, coda_heard=False, reasons=("no_speech",), **base)
    if not an.nuclei:
        return Verdict(VerdictKind.UNSURE, 0, coda_heard=False, reasons=("no_vowel_nucleus",), **base)

    reasons: list[str] = []
    blocking = False                    # interdit tout verdict autre qu'INCERTAIN
    if an.clipped_fraction > cfg.clip_max_fraction:
        reasons.append("clipping")
        blocking = True
    f0s = [n.f0_hz for n in an.nuclei if n.f0_hz is not None]
    if f0s and _median(f0s) < cfg.adult_f0_max_hz:
        reasons.append("adult_voice_suspected")
        blocking = True
    if an.other_regions > 0:
        reasons.append("multiple_utterances")
        blocking = True
    low_snr = an.snr_db < cfg.min_snr_db
    if low_snr:
        reasons.append("low_snr")

    nuclei = list(an.nuclei)
    heard = len(nuclei)
    coda = _coda_after(nuclei[-1], an.frications, cfg)
    epenthesis = False
    if coda is None and heard >= 2:
        prev, last = nuclei[-2], nuclei[-1]
        c = _coda_after(prev, an.frications, cfg)
        if (c is not None and c.end < last.frame
                and last.level_db <= prev.level_db - cfg.epenthesis_min_drop_db):
            coda, heard, epenthesis = c, heard - 1, True
            reasons.append("epenthetic_schwa")

    place = None
    coda_ms = 0.0
    if coda is not None:
        place = "postalveolar" if coda.centroid_hz <= cfg.postalveolar_max_centroid_hz else "alveolar"
        coda_ms = coda.frames * frame_ms()
        if target.coda == "S" and place != "postalveolar":
            reasons.append("place_differs")
        elif target.coda == "s" and place != "alveolar":
            reasons.append("place_differs")

    common = dict(coda_heard=coda is not None, coda_place=place, coda_ms=round(coda_ms, 1),
                  epenthesis=epenthesis, **base)

    def unsure(*why: str) -> Verdict:
        return Verdict(VerdictKind.UNSURE, heard, reasons=tuple(reasons) + why, **common)

    if blocking:
        return unsure()
    if heard > expected:
        return unsure("extra_nuclei")
    if heard < expected:
        if low_snr:
            return unsure()
        return Verdict(VerdictKind.FEWER_SYLLABLES, heard, reasons=tuple(reasons), **common)
    if not coda_expected or coda is not None:
        return Verdict(VerdictKind.COMPLETE, heard, reasons=tuple(reasons), **common)

    # Consonne finale attendue et non entendue : exiger une PREUVE d'absence.
    if low_snr:
        return unsure()
    last = nuclei[-1]
    w0 = last.offset + 1 + ms_to_frames(cfg.absence_guard_ms)
    w1 = w0 + ms_to_frames(cfg.absence_window_ms)
    if w1 > len(an.frames):
        return unsure("truncated")
    above = sum(1 for t in range(w0, w1)
                if an.frames[t].high_db > an.floor_high_db + cfg.absence_max_above_floor_db)
    if above / (w1 - w0) > cfg.absence_max_fraction:
        return unsure("coda_ambiguous")
    return Verdict(VerdictKind.MISSING_FINAL_CONSONANT, heard, reasons=tuple(reasons), **common)


def detect(samples: Sequence[float], target: TargetShape, rate: int = ANALYSIS_RATE,
           cfg: DetectorConfig = DetectorConfig()) -> Verdict:
    """Raccourci : analyse + verdict."""
    return evaluate(analyze(samples, rate, cfg), target, cfg)


@dataclass(frozen=True)
class Shape:
    """Cible minimale (tests, banc) : nombre de noyaux + consonne finale."""

    nuclei: int
    coda: str | None = None


# ---------------------------------------------------------------------------
# Garde-fou lexical (reconnaissance vocale on-device, OPTIONNELLE)
# ---------------------------------------------------------------------------

class LexicalEvidence(str, Enum):
    NOT_CHECKED = "not_checked"      # pas d'ASR, ou transcription vide
    CONSISTENT = "consistent"        # le mot (ou sa forme tronquée) a été reconnu
    INCONSISTENT = "inconsistent"    # un autre mot semble avoir été dit


def apply_lexical(v: Verdict, evidence: LexicalEvidence) -> Verdict:
    """L'ASR ne peut que rendre le verdict PLUS prudent, jamais l'inverse.

    La reconnaissance vocale « corrige » vers des mots réels et se trompe
    beaucoup sur les voix de 3-5 ans : elle ne décide jamais de la fin du mot.
    Elle sert seulement à éviter de juger la fin d'un AUTRE mot (« bain » dit à
    la place de « douche »).
    """
    decisive = (VerdictKind.COMPLETE, VerdictKind.MISSING_FINAL_CONSONANT,
                VerdictKind.FEWER_SYLLABLES)
    if evidence is LexicalEvidence.INCONSISTENT and v.kind in decisive:
        return replace(v, kind=VerdictKind.UNSURE, reasons=v.reasons + ("other_word_suspected",))
    return v
