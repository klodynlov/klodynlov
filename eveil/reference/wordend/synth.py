"""Synthétiseur de « pseudo-parole » déterministe — tester le détecteur sans enfant.

⚠️ Ce n'est PAS de la parole d'enfant. Ce sont des signaux dont la structure
acoustique reproduit ce que le détecteur mesure : noyaux vocaliques voisés
(source glottique + formants), murmure nasal, bruit de friction haute
fréquence, silences d'occlusion, bruit de fond. Réussir sur ces signaux prouve
la **logique** du détecteur, pas sa **validité clinique** : celle-ci ne s'établit
que sur de vraies productions annotées par des orthophonistes
(→ `bench.py` et docs/EVEIL.md §8).

Synthèse « à la Klatt » simplifiée : résonateurs numériques du second ordre en
cascade (Klatt 1980). Formants : ordres de grandeur de voix d'enfant
(moyennes enfants de Peterson & Barney 1952) — plus hauts que chez l'adulte.
Tout l'aléa provient de `SplitMix64` : même graine ⇒ même signal, en Python
comme en Swift.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

from .dsp import ANALYSIS_RATE, SplitMix64

REF_RMS = 0.1   # niveau RMS d'une voyelle à 0 dB (≈ −20 dBFS)

VOWELS: dict[str, tuple[float, float, float]] = {
    "i": (370.0, 3200.0, 3730.0),
    "u": (430.0, 1170.0, 3260.0),
    "a": (1030.0, 1370.0, 3170.0),
    "o": (560.0, 1000.0, 3300.0),
    "e": (530.0, 2500.0, 3500.0),
    "@": (560.0, 1700.0, 3300.0),      # schwa (« e muet » prononcé)
}
NASALS: dict[str, tuple[float, float, float]] = {
    "m": (280.0, 1300.0, 2600.0),
    "n": (280.0, 1700.0, 2700.0),
}
SIBILANTS: dict[str, tuple[float, float]] = {   # centre, largeur de bande (Hz)
    "S": (4200.0, 1500.0),             # /ʃ/ « ch »
    "s": (7500.0, 2000.0),             # /s/
}
PLOSIVES_VOICED = {"d", "b", "g"}
PLOSIVES_VOICELESS = {"t", "p", "k"}

DEFAULT_LEVEL_DB = {
    "vowel": 0.0, "@": -8.0, "nasal": -12.0, "sibilant": -10.0, "f": -22.0,
    "h": -20.0, "click": -3.0,
}


@dataclass(frozen=True)
class Seg:
    """Un segment : code de phone (ASCII, proche X-SAMPA), durée, niveau relatif.

    Codes : voyelles `i u a o e @`, nasales `m n`, sibilantes `S` (/ʃ/) et `s`,
    `f` (fricative faible), `h:<voyelle>` (souffle coloré par la voyelle),
    occlusives `d b g t p k`, `click` (bruit non vocal), `_` (silence).
    """

    phone: str
    ms: float
    level_db: float | None = None


@dataclass(frozen=True)
class Utterance:
    segments: tuple[Seg, ...]
    f0_start: float = 300.0          # Hz — voix d'enfant ≈ 250-400 Hz
    f0_end: float = 250.0
    pre_ms: float = 300.0            # silence (bruit de fond) avant le mot
    post_ms: float = 1200.0          # silence après le mot (> fin d'énoncé du flux : 800 ms)
    snr_db: float = 35.0             # voyelle (0 dB) vs bruit de fond
    noise: str = "pink"              # "pink" | "white" | "none"
    gain_db: float = 0.0             # gain global (tester l'invariance / l'écrêtage)
    seed: int = 1
    rate: int = ANALYSIS_RATE
    tags: tuple[str, ...] = field(default_factory=tuple)

    @property
    def word_ms(self) -> float:
        return sum(s.ms for s in self.segments)


def utterance(spec: str, **kw) -> Utterance:
    """Construit un énoncé depuis une spec compacte : ``"d50 u230 S180"``.

    Un niveau explicite s'écrit ``@110/-9`` (phone @, 110 ms, −9 dB).
    """
    segs = []
    for token in spec.split():
        level = None
        if "/" in token:
            token, lvl = token.split("/", 1)
            level = float(lvl)
        i = len(token)
        while i > 0 and (token[i - 1].isdigit() or token[i - 1] == "."):
            i -= 1
        segs.append(Seg(token[:i], float(token[i:]), level))
    return Utterance(tuple(segs), **kw)


# ---------------------------------------------------------------------------
# Briques de synthèse
# ---------------------------------------------------------------------------

def resonator(x: list[float], f_hz: float, bw_hz: float, rate: int) -> list[float]:
    """Résonateur numérique de Klatt (gain unitaire en continu)."""
    t = 1.0 / rate
    c = -math.exp(-2.0 * math.pi * bw_hz * t)
    b = 2.0 * math.exp(-math.pi * bw_hz * t) * math.cos(2.0 * math.pi * f_hz * t)
    a = 1.0 - b - c
    y1 = 0.0
    y2 = 0.0
    out = []
    for v in x:
        y = a * v + b * y1 + c * y2
        out.append(y)
        y2 = y1
        y1 = y
    return out


def difference(x: list[float]) -> list[float]:
    """Dérivée discrète (+6 dB/octave) : rayonnement aux lèvres / pente de bruit."""
    out = []
    prev = 0.0
    for v in x:
        out.append(v - prev)
        prev = v
    return out


def _rms(x: list[float]) -> float:
    if not x:
        return 0.0
    return math.sqrt(sum(v * v for v in x) / len(x))


def _scale_to(x: list[float], steady: tuple[int, int], target_rms: float) -> list[float]:
    lo, hi = steady
    r = _rms(x[lo:hi]) if hi > lo else _rms(x)
    if r <= 0.0:
        return x
    g = target_rms / r
    return [v * g for v in x]


def _voice_source(n: int, word_start: int, word_end: int, f0_start: float, f0_end: float,
                  rate: int) -> list[float]:
    """Train d'impulsions glottiques continu, F0 linéaire sur la durée du mot."""
    src = [0.0] * n
    phase = 0.0
    span = max(1, word_end - word_start)
    for i in range(max(0, word_start - rate // 50), min(n, word_end + rate // 50)):
        pos = min(1.0, max(0.0, (i - word_start) / span))
        f0 = f0_start + (f0_end - f0_start) * pos
        phase += f0 / rate
        if phase >= 1.0:
            phase -= 1.0
            src[i] = 1.0
    return src


def _noise(rng: SplitMix64, count: int) -> list[float]:
    return [rng.next_signed() for _ in range(count)]


def _envelope(length: int, ramp_in: int, ramp_out: int) -> list[float]:
    """Enveloppe en cosinus surélevé : montée, plateau, descente (fondus croisés)."""
    env = [1.0] * length
    for i in range(min(ramp_in, length)):
        env[i] = 0.5 - 0.5 * math.cos(math.pi * (i + 0.5) / ramp_in)
    for i in range(min(ramp_out, length)):
        j = length - 1 - i
        env[j] = min(env[j], 0.5 - 0.5 * math.cos(math.pi * (i + 0.5) / ramp_out))
    return env


def _level_for(phone: str) -> float:
    if phone == "@":
        return DEFAULT_LEVEL_DB["@"]
    if phone in VOWELS:
        return DEFAULT_LEVEL_DB["vowel"]
    if phone in NASALS:
        return DEFAULT_LEVEL_DB["nasal"]
    if phone in SIBILANTS:
        return DEFAULT_LEVEL_DB["sibilant"]
    if phone == "f":
        return DEFAULT_LEVEL_DB["f"]
    if phone.startswith("h:"):
        return DEFAULT_LEVEL_DB["h"]
    if phone == "click":
        return DEFAULT_LEVEL_DB["click"]
    return -10.0


def _render_segment(seg: Seg, length: int, voice: list[float], rng: SplitMix64,
                    rate: int) -> list[float]:
    """Rend un segment (sans enveloppe), longueur `length`, source voisée alignée."""
    p = seg.phone
    if p in VOWELS or p in NASALS:
        formants = VOWELS.get(p) or NASALS[p]
        bws = (80.0, 120.0, 180.0) if p in VOWELS else (100.0, 200.0, 300.0)
        x = resonator(voice, 0.0, 200.0, rate)          # pente glottique
        for f, bw in zip(formants, bws):
            x = resonator(x, f, bw, rate)
        return difference(x)                             # rayonnement
    if p in SIBILANTS:
        centre, bw = SIBILANTS[p]
        x = difference(difference(_noise(rng, length)))  # graves atténués (+12 dB/oct)
        return resonator(resonator(x, centre, bw, rate), centre, bw, rate)
    if p == "f":
        return difference(_noise(rng, length))
    if p.startswith("h:"):
        formants = VOWELS[p[2:]]
        x = _noise(rng, length)
        for f, bw in zip(formants, (120.0, 180.0, 250.0)):
            x = resonator(x, f, bw, rate)
        return difference(x)
    if p == "click":
        return _noise(rng, length)
    if p in PLOSIVES_VOICED or p in PLOSIVES_VOICELESS:
        return [0.0] * length            # géré à part (occlusion + explosion)
    if p == "_":
        return [0.0] * length
    raise ValueError(f"phone inconnu : {p!r}")


def synthesize(u: Utterance) -> list[float]:
    """Rend l'énoncé en échantillons flottants (mono, `u.rate` Hz), écrêtés à ±1."""
    rate = u.rate
    pre = int(round(u.pre_ms * rate / 1000.0))
    bounds = []
    cursor = pre
    for seg in u.segments:
        length = int(round(seg.ms * rate / 1000.0))
        bounds.append((cursor, cursor + length))
        cursor += length
    word_end = cursor
    n = word_end + int(round(u.post_ms * rate / 1000.0))
    out = [0.0] * n
    voice_full = _voice_source(n, pre, word_end, u.f0_start, u.f0_end, rate)
    rng = SplitMix64(u.seed)
    gain = 10.0 ** (u.gain_db / 20.0)

    for seg, (start, end) in zip(u.segments, bounds):
        p = seg.phone
        level = seg.level_db if seg.level_db is not None else _level_for(p)
        target_rms = REF_RMS * gain * 10.0 ** (level / 20.0)
        if p == "_":
            continue
        if p in PLOSIVES_VOICED or p in PLOSIVES_VOICELESS:
            burst_len = int(round((0.008 if p in PLOSIVES_VOICELESS else 0.006) * rate))
            closure_len = max(0, (end - start) - burst_len)
            if p in PLOSIVES_VOICED and closure_len > 0:     # barre de voisement
                bar = resonator(voice_full[start:start + closure_len], 150.0, 100.0, rate)
                bar = _scale_to(bar, (0, closure_len), REF_RMS * gain * 10.0 ** (-28.0 / 20.0))
                env = _envelope(closure_len, int(0.005 * rate), int(0.005 * rate))
                for i in range(closure_len):
                    out[start + i] += bar[i] * env[i]
            burst = resonator(difference(_noise(rng, burst_len)), 3500.0, 3000.0, rate)
            burst = _scale_to(burst, (0, burst_len), REF_RMS * gain * 10.0 ** (-10.0 / 20.0))
            env = _envelope(burst_len, max(1, int(0.001 * rate)), max(1, int(0.002 * rate)))
            b0 = start + closure_len
            for i in range(burst_len):
                if b0 + i < n:
                    out[b0 + i] += burst[i] * env[i]
            continue
        short = p == "click"
        ramp = max(1, int((0.001 if short else 0.015) * rate))
        lo = max(0, start - ramp)
        hi = min(n, end + ramp)
        length = hi - lo
        voice = voice_full[lo:hi]
        x = _render_segment(seg, length, voice, rng, rate)
        x = _scale_to(x, (start - lo, end - lo), target_rms)
        env = _envelope(length, 2 * ramp, 2 * ramp)
        for i in range(length):
            out[lo + i] += x[i] * env[i]

    if u.noise != "none":
        nrng = SplitMix64(u.seed ^ 0x5DEECE66D)
        white = _noise(nrng, n)
        if u.noise == "pink":
            y = 0.0
            colored = []
            for v in white:
                y = 0.95 * y + v
                colored.append(y)
            bg = colored
        else:
            bg = white
        bg = _scale_to(bg, (0, n), REF_RMS * gain * 10.0 ** (-u.snr_db / 20.0))
        for i in range(n):
            out[i] += bg[i]

    return [max(-1.0, min(1.0, v)) for v in out]


def word_bounds_ms(u: Utterance) -> tuple[float, float]:
    """Début et fin du mot (ms) dans le signal synthétisé."""
    return u.pre_ms, u.pre_ms + u.word_ms


# ---------------------------------------------------------------------------
# Bibliothèque d'énoncés de test (cibles FR/EN de la v0 : sibilante finale)
# ---------------------------------------------------------------------------

LIBRARY: dict[str, str] = {
    # douche /duʃ/ : 1 noyau + /ʃ/ final
    "douche": "d50 u230 S180",
    "dou": "d50 u260",
    "douche_schwa": "d50 u200 S150 @110/-9",     # « dou-che-e » (schwa épenthétique)
    "dou_souffle": "d50 u240 h:u120",           # fin soufflée, pas une sibilante
    "dou_clic": "d50 u260 _600 click15",         # bruit parasite tardif
    # minouche /mi.nuʃ/ : 2 noyaux + /ʃ/ final
    "minouche": "m70 i140 n70 u190 S180",
    "minou": "m70 i150 n70 u240",
    "mi": "m70 i260",
    "minousse": "m70 i140 n70 u190 s180",       # /ʃ/ → /s/ : fin présente, lieu différent
    # anglais — fish /fɪʃ/, goose /ɡus/
    "fish": "f90 i180 S170",
    "fi": "f90 i230",
    "goose": "g50 u220 s170",
    "goo": "g50 u260",
    # isolé : un « chhh » sans voyelle
    "chut": "S300",
}
