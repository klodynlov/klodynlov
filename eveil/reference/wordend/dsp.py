"""Primitives DSP en Python stdlib pur — la référence de `WordEndCore` (Swift).

Règle de portabilité : chaque fonction a son équivalent Swift **ligne à ligne**
(`eveil/ios/Sources/WordEndCore/`). Pas de numpy, aucun aléa non seedé, des
constantes explicites. Les deux implémentations sont tenues en parité par des
vecteurs de référence (`golden.py` → `golden_vectors.json`).

Le signal est analysé à une fréquence **canonique de 24 kHz** : assez pour les
sibilantes d'enfant (énergie jusque vers 10 kHz), deux fois moins coûteux que
les 48 kHz natifs de l'iPad (qui sont décimés par 2 avant analyse).
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Sequence

ANALYSIS_RATE = 24_000          # Hz — fréquence d'analyse canonique
FRAME_SIZE = 512                # échantillons = taille FFT (21,3 ms à 24 kHz)
HOP_SIZE = 240                  # échantillons (10 ms à 24 kHz)
BIN_HZ = ANALYSIS_RATE / FRAME_SIZE   # 46,875 Hz — exactement représentable
EPS = 1e-12                     # plancher numérique avant log10
MASK64 = 0xFFFF_FFFF_FFFF_FFFF


def frame_ms() -> float:
    """Pas d'analyse en millisecondes (10 ms)."""
    return 1000.0 * HOP_SIZE / ANALYSIS_RATE


def ms_to_frames(ms: float) -> int:
    """Convertit une durée en nombre de trames (arrondi au plus proche)."""
    return int(round(ms / frame_ms()))


# ---------------------------------------------------------------------------
# Générateur pseudo-aléatoire déterministe (identique bit à bit en Swift)
# ---------------------------------------------------------------------------

class SplitMix64:
    """SplitMix64 (Steele, Lea & Flood 2014) — trivial à porter à l'identique.

    En Swift, les additions/multiplications utilisent `&+` / `&*` (modulo 2⁶⁴) ;
    ici, on masque explicitement sur 64 bits.
    """

    def __init__(self, seed: int) -> None:
        self.state = seed & MASK64

    def next_u64(self) -> int:
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK64
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK64
        return z ^ (z >> 31)

    def next_unit(self) -> float:
        """Uniforme dans [0, 1) sur 53 bits de mantisse."""
        return (self.next_u64() >> 11) * (1.0 / 9007199254740992.0)

    def next_signed(self) -> float:
        """Uniforme dans [-1, 1) — bruit blanc sans fonction transcendante."""
        return 2.0 * self.next_unit() - 1.0


# ---------------------------------------------------------------------------
# FFT radix-2 itérative (portable ; le backend Accelerate est optionnel en Swift)
# ---------------------------------------------------------------------------

_TWIDDLES: dict[int, list[complex]] = {}


def _twiddles(n: int) -> list[complex]:
    table = _TWIDDLES.get(n)
    if table is None:
        table = [complex(math.cos(-2.0 * math.pi * k / n), math.sin(-2.0 * math.pi * k / n))
                 for k in range(n // 2)]
        _TWIDDLES[n] = table
    return table


def fft(values: Sequence[float]) -> list[complex]:
    """DFT d'un signal réel par Cooley-Tukey radix-2 (taille puissance de 2)."""
    n = len(values)
    if n == 0 or n & (n - 1):
        raise ValueError(f"taille FFT non puissance de 2 : {n}")
    a = [complex(v, 0.0) for v in values]
    j = 0
    for i in range(1, n):                     # permutation bit-reverse
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            a[i], a[j] = a[j], a[i]
    table = _twiddles(n)
    size = 2
    while size <= n:
        half = size // 2
        step = n // size
        for start in range(0, n, size):
            for k in range(half):
                w = table[k * step]
                u = a[start + k]
                v = a[start + k + half] * w
                a[start + k] = u + v
                a[start + k + half] = u - v
        size *= 2
    return a


def dft_naive(values: Sequence[float]) -> list[complex]:
    """DFT directe O(n²) — sert uniquement à vérifier `fft` dans les tests."""
    n = len(values)
    out = []
    for k in range(n):
        acc = 0j
        for t, v in enumerate(values):
            ang = -2.0 * math.pi * k * t / n
            acc += v * complex(math.cos(ang), math.sin(ang))
        out.append(acc)
    return out


HANN = [0.5 - 0.5 * math.cos(2.0 * math.pi * i / FRAME_SIZE) for i in range(FRAME_SIZE)]


def band_bins(lo_hz: float, hi_hz: float) -> tuple[int, int]:
    """Indices de bins [k0, k1) couvrant la bande [lo_hz, hi_hz)."""
    k0 = max(1, math.ceil(lo_hz / BIN_HZ))
    k1 = min(FRAME_SIZE // 2 + 1, math.ceil(hi_hz / BIN_HZ))
    return k0, max(k0, k1)


def to_db(power: float) -> float:
    return 10.0 * math.log10(power + EPS)


# ---------------------------------------------------------------------------
# Descripteurs par trame
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class Bands:
    """Bandes d'analyse (Hz). Valeurs par défaut justifiées dans docs/EVEIL.md §5."""

    low: tuple[float, float] = (300.0, 2500.0)       # voyelles (F1/F2)
    high: tuple[float, float] = (3000.0, 11000.0)    # bruit de friction sibilant
    centroid: tuple[float, float] = (1000.0, 11000.0)


@dataclass(frozen=True)
class FrameFeatures:
    index: int
    rms_db: float        # énergie totale (dB, référence arbitraire)
    low_db: float        # énergie bande « voyelle »
    high_db: float       # énergie bande « friction »
    high_ratio: float    # E_high / (E_low + E_high) ∈ [0, 1]
    centroid_hz: float   # centroïde spectral sur la bande `centroid`
    zcr_hz: float        # passages par zéro par seconde
    peak: float          # max |x| (détection d'écrêtage)


def frame_count(n_samples: int) -> int:
    """Nombre de trames entièrement contenues dans le signal."""
    if n_samples < FRAME_SIZE:
        return 0
    return 1 + (n_samples - FRAME_SIZE) // HOP_SIZE


def compute_frame(samples: Sequence[float], index: int, bands: Bands = Bands()) -> FrameFeatures:
    """Descripteurs de la trame `index` (fenêtre de Hann, DC retiré)."""
    start = index * HOP_SIZE
    seg = list(samples[start:start + FRAME_SIZE])
    if len(seg) < FRAME_SIZE:
        seg.extend([0.0] * (FRAME_SIZE - len(seg)))
    mean = sum(seg) / FRAME_SIZE
    x = [s - mean for s in seg]
    energy = sum(v * v for v in x) / FRAME_SIZE

    crossings = 0
    prev_neg = x[0] < 0.0
    for v in x[1:]:
        neg = v < 0.0
        if neg != prev_neg:
            crossings += 1
        prev_neg = neg
    zcr_hz = crossings * ANALYSIS_RATE / FRAME_SIZE
    peak = max(abs(s) for s in seg)

    spectrum = fft([x[i] * HANN[i] for i in range(FRAME_SIZE)])
    power = [c.real * c.real + c.imag * c.imag for c in spectrum[:FRAME_SIZE // 2 + 1]]

    l0, l1 = band_bins(*bands.low)
    h0, h1 = band_bins(*bands.high)
    c0, c1 = band_bins(*bands.centroid)
    e_low = sum(power[l0:l1])
    e_high = sum(power[h0:h1])
    e_c = 0.0
    e_cf = 0.0
    for k in range(c0, c1):
        e_c += power[k]
        e_cf += power[k] * k * BIN_HZ
    centroid = e_cf / e_c if e_c > EPS else 0.0
    ratio = e_high / (e_low + e_high) if (e_low + e_high) > EPS else 0.0
    return FrameFeatures(index, to_db(energy), to_db(e_low), to_db(e_high), ratio,
                         centroid, zcr_hz, peak)


def compute_frames(samples: Sequence[float], bands: Bands = Bands()) -> list[FrameFeatures]:
    return [compute_frame(samples, t, bands) for t in range(frame_count(len(samples)))]


# ---------------------------------------------------------------------------
# Outils statistiques et signaux
# ---------------------------------------------------------------------------

def percentile(values: Sequence[float], p: float) -> float:
    """Percentile « rang inférieur » déterministe (p ∈ [0, 1])."""
    if not values:
        raise ValueError("percentile d'une liste vide")
    ordered = sorted(values)
    idx = int(p * (len(ordered) - 1))
    return ordered[max(0, min(len(ordered) - 1, idx))]


def moving_average(values: Sequence[float], width: int) -> list[float]:
    """Moyenne glissante centrée ; aux bords, moyenne des valeurs disponibles."""
    half = width // 2
    n = len(values)
    out = []
    for t in range(n):
        lo = max(0, t - half)
        hi = min(n, t + half + 1)
        out.append(sum(values[lo:hi]) / (hi - lo))
    return out


def estimate_f0(samples: Sequence[float], frame_index: int,
                f0_min: float = 90.0, f0_max: float = 800.0,
                min_corr: float = 0.5) -> float | None:
    """F0 par autocorrélation normalisée sur une trame ; None si non voisé.

    Retient le plus petit retard dont la corrélation atteint 90 % du maximum
    (limite les erreurs d'octave vers le bas).
    """
    start = frame_index * HOP_SIZE
    seg = list(samples[start:start + FRAME_SIZE])
    if len(seg) < FRAME_SIZE:
        return None
    mean = sum(seg) / FRAME_SIZE
    x = [s - mean for s in seg]
    lag_min = int(ANALYSIS_RATE / f0_max)
    lag_max = min(FRAME_SIZE - 2, int(ANALYSIS_RATE / f0_min))
    corr: list[tuple[int, float]] = []
    for lag in range(lag_min, lag_max + 1):
        num = 0.0
        e0 = 0.0
        e1 = 0.0
        for i in range(FRAME_SIZE - lag):
            a = x[i]
            b = x[i + lag]
            num += a * b
            e0 += a * a
            e1 += b * b
        den = math.sqrt(e0 * e1)
        corr.append((lag, num / den if den > EPS else 0.0))
    best = max(c for _, c in corr)
    if best < min_corr:
        return None
    for lag, c in corr:
        if c >= 0.9 * best:
            return ANALYSIS_RATE / lag
    return None


def lowpass_fir(cutoff_hz: float, rate: float, taps: int = 63) -> list[float]:
    """Filtre RIF passe-bas (sinus cardinal fenêtré Blackman), gain unitaire."""
    fc = cutoff_hz / rate
    mid = (taps - 1) / 2.0
    h = []
    for i in range(taps):
        m = i - mid
        sinc = 2.0 * fc if m == 0 else math.sin(2.0 * math.pi * fc * m) / (math.pi * m)
        w = 0.42 - 0.5 * math.cos(2.0 * math.pi * i / (taps - 1)) + 0.08 * math.cos(4.0 * math.pi * i / (taps - 1))
        h.append(sinc * w)
    total = sum(h)
    return [v / total for v in h]


def resample(samples: Sequence[float], rate_in: int, rate_out: int = ANALYSIS_RATE) -> list[float]:
    """Rééchantillonnage : passe-bas anti-repliement (si décimation) + interpolation linéaire.

    Suffisant pour des énergies de bande ; sur iOS, `AVAudioConverter` fait mieux
    et livre directement du 24 kHz mono au détecteur.
    """
    if rate_in == rate_out:
        return list(samples)
    src = list(samples)
    if rate_out < rate_in:
        h = lowpass_fir(0.45 * rate_out, rate_in)
        half = len(h) // 2
        filtered = []
        n = len(src)
        for i in range(n):
            acc = 0.0
            for k, hk in enumerate(h):
                j = i + half - k
                if 0 <= j < n:
                    acc += hk * src[j]
            filtered.append(acc)
        src = filtered
    ratio = rate_in / rate_out
    n_out = int(len(src) / ratio)
    out = []
    for i in range(n_out):
        pos = i * ratio
        j = int(pos)
        frac = pos - j
        a = src[j]
        b = src[j + 1] if j + 1 < len(src) else a
        out.append(a + (b - a) * frac)
    return out
