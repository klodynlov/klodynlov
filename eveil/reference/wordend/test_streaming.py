"""Tests du suivi en flux : parité avec l'analyse par lots, monotonie de l'aperçu."""
from __future__ import annotations

import unittest

from wordend.detector import Shape, VerdictKind, detect
from wordend.dsp import SplitMix64
from wordend.streaming import (CodaHeard, Ended, NucleusHeard, Phase, SpeechStarted,
                               StreamingConfig, StreamingTracker)
from wordend.synth import LIBRARY, synthesize, utterance

K = VerdictKind


def stream(x, target, chunk_sizes, **cfg):
    tr = StreamingTracker(target, stream=StreamingConfig(**cfg)) if cfg else StreamingTracker(target)
    events, i, k = [], 0, 0
    while i < len(x) and tr.phase is not Phase.ENDED:
        n = chunk_sizes[k % len(chunk_sizes)]
        events.extend(tr.push(x[i:i + n]))
        i += n
        k += 1
    return tr, events


class TestStreaming(unittest.TestCase):
    CASES = [("douche", Shape(1, "S")), ("dou", Shape(1, "S")), ("minouche", Shape(2, "S")),
             ("minou", Shape(2, "S")), ("mi", Shape(2, "S"))]

    def test_final_verdict_matches_batch(self):
        for name, target in self.CASES:
            x = synthesize(utterance(LIBRARY[name], seed=31))
            batch = detect(x, target)
            for chunks in ([240], [1024], [4800], [100, 3000, 777]):
                with self.subTest(name=name, chunks=chunks):
                    tr, events = stream(x, target, chunks)
                    ends = [e for e in events if isinstance(e, Ended)]
                    self.assertEqual(len(ends), 1)
                    self.assertIs(ends[0].verdict.kind, batch.kind)
                    self.assertEqual(ends[0].cause, "silence")

    def test_preview_is_monotonic_and_ordered(self):
        x = synthesize(utterance(LIBRARY["minouche"], seed=32))
        _, events = stream(x, Shape(2, "S"), [480])
        kinds = [type(e) for e in events]
        self.assertEqual(kinds[0], SpeechStarted)
        self.assertEqual(kinds[-1], Ended)
        counts = [e.count for e in events if isinstance(e, NucleusHeard)]
        self.assertEqual(counts, sorted(counts))
        self.assertEqual(counts[-1], 2)
        coda = [e for e in events if isinstance(e, CodaHeard)]
        self.assertEqual(len(coda), 1)
        last_nucleus = [e for e in events if isinstance(e, NucleusHeard)][-1]
        self.assertGreater(coda[0].frame, last_nucleus.frame)

    def test_no_coda_event_when_final_consonant_missing(self):
        x = synthesize(utterance(LIBRARY["minou"], seed=33))
        _, events = stream(x, Shape(2, "S"), [480])
        self.assertFalse(any(isinstance(e, CodaHeard) for e in events))

    def test_timeout_on_silence(self):
        r = SplitMix64(5)
        x = [0.001 * r.next_signed() for _ in range(24_000 * 3)]
        tr, events = stream(x, Shape(1, "S"), [2400], max_wait_ms=1500.0)
        end = events[-1]
        self.assertIsInstance(end, Ended)
        self.assertEqual(end.cause, "timeout")
        self.assertIs(end.verdict.kind, K.NO_SPEECH)

    def test_stop_and_no_events_after_end(self):
        x = synthesize(utterance(LIBRARY["douche"], seed=34))
        tr = StreamingTracker(Shape(1, "S"))
        tr.push(x[: len(x) // 2])
        ev = tr.stop()
        self.assertEqual(ev[0].cause, "stopped")
        self.assertEqual(tr.push(x[len(x) // 2:]), [])
        self.assertEqual(tr.stop(), [])

    def test_max_duration_guard(self):
        spec = "d50 u3000 S200"
        x = synthesize(utterance(spec, seed=35))
        _, events = stream(x, Shape(1, "S"), [2400], max_utterance_ms=1500.0)
        self.assertEqual(events[-1].cause, "max_duration")


if __name__ == "__main__":
    unittest.main()
