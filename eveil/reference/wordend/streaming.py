"""Suivi en flux : allumer les wagons pendant que l'enfant parle.

Le micro livre des blocs de 24 kHz mono ; le traqueur calcule les trames au fil
de l'eau, détecte le début de parole, **prévisualise** les noyaux confirmés
(un wagon s'allume) et la friction finale (le fourgon s'accroche), puis décide
la fin d'énoncé (silence prolongé). Le **verdict final** est calculé par le même
chemin que l'analyse par lots (`detector.analyze_frames`) : flux et lots ne
peuvent pas diverger sur la décision.

L'aperçu est volontairement *optimiste et monotone* (un wagon allumé ne
s'éteint pas pendant l'écoute) ; seul le verdict final fait foi, et
l'interface se recale dessus.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Sequence, Union

from .detector import (DetectorConfig, TargetShape, Verdict, analyze_frames, evaluate,
                       _coda_after)
from .dsp import FRAME_SIZE, HOP_SIZE, compute_frame, ms_to_frames, percentile


class Phase(str, Enum):
    WAITING = "waiting"
    SPEAKING = "speaking"
    ENDED = "ended"


@dataclass(frozen=True)
class SpeechStarted:
    frame: int


@dataclass(frozen=True)
class NucleusHeard:
    count: int
    frame: int


@dataclass(frozen=True)
class CodaHeard:
    frame: int


@dataclass(frozen=True)
class Ended:
    verdict: Verdict
    frame: int
    cause: str          # "silence" | "max_duration" | "timeout" | "stopped"


Event = Union[SpeechStarted, NucleusHeard, CodaHeard, Ended]


@dataclass(frozen=True)
class StreamingConfig:
    min_preroll_ms: float = 100.0      # trames nécessaires avant toute décision VAD
    onset_frames: int = 3              # 30 ms au-dessus du seuil ⇒ début de parole
    vad_off_db: float = 6.0            # « silence » : RMS < plancher + 6 dB
    end_silence_ms: float = 800.0      # > fusion de régions (450 ms) : laisser l'enfant finir
    max_wait_ms: float = 6000.0        # personne ne parle ⇒ fin (aucune parole)
    max_utterance_ms: float = 4000.0   # garde-fou
    preview_every_frames: int = 5      # aperçu toutes les 50 ms


class StreamingTracker:
    """Traqueur incrémental. Entrée : échantillons 24 kHz mono (flottants)."""

    def __init__(self, target: TargetShape, config: DetectorConfig = DetectorConfig(),
                 stream: StreamingConfig = StreamingConfig()) -> None:
        self.target = target
        self.cfg = config
        self.stream = stream
        self.samples: list[float] = []
        self.frames = []
        self.phase = Phase.WAITING
        self._above = 0
        self._silent = 0
        self._speech_start: int | None = None
        self._nuclei_shown = 0
        self._coda_shown = False
        self.verdict: Verdict | None = None

    # -- API -----------------------------------------------------------------

    def push(self, chunk: Sequence[float]) -> list[Event]:
        """Ajoute un bloc d'échantillons ; renvoie les événements produits."""
        if self.phase is Phase.ENDED:
            return []
        self.samples.extend(chunk)
        events: list[Event] = []
        while self.phase is not Phase.ENDED:
            index = len(self.frames)
            if index * HOP_SIZE + FRAME_SIZE > len(self.samples):
                break
            self.frames.append(compute_frame(self.samples, index, self.cfg.bands))
            events.extend(self._on_frame(index))
        return events

    def stop(self) -> list[Event]:
        """Fin forcée (bouton « stop », changement d'écran…)."""
        if self.phase is Phase.ENDED:
            return []
        return [self._end(len(self.frames) - 1, "stopped")]

    # -- interne -------------------------------------------------------------

    def _floor(self) -> float:
        return percentile([f.rms_db for f in self.frames], self.cfg.floor_percentile)

    def _on_frame(self, t: int) -> list[Event]:
        s = self.stream
        if t + 1 < ms_to_frames(s.min_preroll_ms):
            return []
        floor = self._floor()
        rms = self.frames[t].rms_db
        events: list[Event] = []
        if self.phase is Phase.WAITING:
            self._above = self._above + 1 if rms >= floor + self.cfg.vad_on_db else 0
            if self._above >= s.onset_frames:
                self.phase = Phase.SPEAKING
                self._speech_start = t - s.onset_frames + 1
                events.append(SpeechStarted(self._speech_start))
            elif t + 1 >= ms_to_frames(s.max_wait_ms):
                events.append(self._end(t, "timeout"))
            return events

        self._silent = self._silent + 1 if rms < floor + s.vad_off_db else 0
        if (t - self._speech_start) % s.preview_every_frames == 0:
            events.extend(self._preview())
        if self._silent >= ms_to_frames(s.end_silence_ms):
            events.extend(self._preview())
            events.append(self._end(t, "silence"))
        elif t - self._speech_start + 1 >= ms_to_frames(s.max_utterance_ms):
            events.extend(self._preview())
            events.append(self._end(t, "max_duration"))
        return events

    def _preview(self) -> list[Event]:
        an = analyze_frames(self.frames, self.samples, self.cfg, with_f0=False)
        events: list[Event] = []
        dip = self.cfg.nucleus_min_dip_db
        confirmed = [n for n in an.nuclei
                     if any(v <= n.level_db - dip for v in an.envelope[n.frame + 1:])]
        if len(confirmed) > self._nuclei_shown:
            self._nuclei_shown = len(confirmed)
            events.append(NucleusHeard(self._nuclei_shown, confirmed[-1].frame))
        if confirmed and not self._coda_shown and self.target.coda is not None:
            coda = _coda_after(confirmed[-1], an.frications, self.cfg)
            if coda is not None:
                self._coda_shown = True
                events.append(CodaHeard(coda.start))
        return events

    def _end(self, t: int, cause: str) -> Ended:
        self.phase = Phase.ENDED
        an = analyze_frames(self.frames, self.samples, self.cfg, with_f0=True)
        self.verdict = evaluate(an, self.target, self.cfg)
        return Ended(self.verdict, t, cause)
