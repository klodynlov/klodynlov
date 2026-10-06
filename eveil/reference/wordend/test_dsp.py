"""Tests des primitives DSP (PRNG, FFT, descripteurs, F0, rééchantillonnage)."""
from __future__ import annotations

import math
import unittest

from wordend.dsp import (ANALYSIS_RATE, BIN_HZ, FRAME_SIZE, HANN, HOP_SIZE, SplitMix64, band_bins,
                         compute_frame, dft_naive, estimate_f0, fft, frame_count, moving_average,
                         percentile, resample)


def tone(freq: float, seconds: float, rate: int = ANALYSIS_RATE, amp: float = 0.3) -> list[float]:
    return [amp * math.sin(2.0 * math.pi * freq * i / rate) for i in range(int(seconds * rate))]


class TestSplitMix64(unittest.TestCase):
    def test_reference_value(self):
        # Valeur de référence publiée de SplitMix64 (graine 0, premier tirage).
        self.assertEqual(SplitMix64(0).next_u64(), 0xE220A8397B1DCDAF)

    def test_deterministic_and_seed_sensitive(self):
        a = [SplitMix64(42).next_u64() for _ in range(1)]
        b = [SplitMix64(42).next_u64() for _ in range(1)]
        self.assertEqual(a, b)
        self.assertNotEqual(SplitMix64(42).next_u64(), SplitMix64(43).next_u64())

    def test_unit_range(self):
        r = SplitMix64(1)
        vals = [r.next_unit() for _ in range(2000)]
        self.assertTrue(all(0.0 <= v < 1.0 for v in vals))
        self.assertAlmostEqual(sum(vals) / len(vals), 0.5, delta=0.03)
        s = [r.next_signed() for _ in range(2000)]
        self.assertTrue(all(-1.0 <= v < 1.0 for v in s))


class TestFFT(unittest.TestCase):
    def test_matches_naive_dft(self):
        r = SplitMix64(3)
        for n in (2, 8, 64, 256):
            x = [r.next_signed() for _ in range(n)]
            a = fft(x)
            b = dft_naive(x)
            self.assertLess(max(abs(p - q) for p, q in zip(a, b)), 1e-9, n)

    def test_rejects_non_power_of_two(self):
        with self.assertRaises(ValueError):
            fft([0.0] * 6)

    def test_band_bins_are_exact(self):
        self.assertEqual(BIN_HZ, 46.875)
        self.assertEqual(band_bins(3000.0, 11000.0), (64, 235))
        self.assertEqual(band_bins(300.0, 2500.0), (7, 54))

    def test_hann_is_periodic(self):
        self.assertEqual(HANN[0], 0.0)
        self.assertAlmostEqual(HANN[FRAME_SIZE // 2], 1.0)


class TestFrameFeatures(unittest.TestCase):
    def test_low_tone_is_vowel_like(self):
        f = compute_frame(tone(700.0, 0.1), 2)
        self.assertLess(f.high_ratio, 0.01)
        self.assertAlmostEqual(f.zcr_hz, 1400.0, delta=100.0)   # 2 passages par période

    def test_high_tone_is_frication_like(self):
        f = compute_frame(tone(5000.0, 0.1), 2)
        self.assertGreater(f.high_ratio, 0.99)
        self.assertAlmostEqual(f.centroid_hz, 5000.0, delta=150.0)
        self.assertAlmostEqual(f.zcr_hz, 10000.0, delta=300.0)

    def test_level_shift_is_additive_in_db(self):
        a = compute_frame(tone(1000.0, 0.1, amp=0.1), 2)
        b = compute_frame(tone(1000.0, 0.1, amp=0.01), 2)
        self.assertAlmostEqual(a.rms_db - b.rms_db, 20.0, delta=0.01)
        self.assertAlmostEqual(a.low_db - b.low_db, 20.0, delta=0.01)
        self.assertAlmostEqual(a.high_ratio, b.high_ratio, places=6)

    def test_frame_count(self):
        self.assertEqual(frame_count(FRAME_SIZE - 1), 0)
        self.assertEqual(frame_count(FRAME_SIZE), 1)
        self.assertEqual(frame_count(FRAME_SIZE + HOP_SIZE), 2)


class TestHelpers(unittest.TestCase):
    def test_percentile(self):
        self.assertEqual(percentile([5, 1, 4, 2, 3], 0.0), 1)
        self.assertEqual(percentile([5, 1, 4, 2, 3], 1.0), 5)
        self.assertEqual(percentile(list(range(11)), 0.1), 1)
        with self.assertRaises(ValueError):
            percentile([], 0.5)

    def test_moving_average_edges(self):
        self.assertEqual(moving_average([0, 0, 9, 0, 0], 3), [0, 3, 3, 3, 0])

    def test_f0_on_pulse_train(self):
        rate = ANALYSIS_RATE
        x = [0.0] * (rate // 5)
        period = rate / 300.0
        k = 0.0
        while k < len(x):
            x[int(k)] = 1.0
            k += period
        # un peu de coloration pour ressembler à une voyelle
        y, prev = [], 0.0
        for v in x:
            prev = 0.9 * prev + v
            y.append(prev)
        self.assertAlmostEqual(estimate_f0(y, 5), 300.0, delta=10.0)

    def test_f0_none_on_noise(self):
        r = SplitMix64(9)
        self.assertIsNone(estimate_f0([r.next_signed() for _ in range(4000)], 3))

    def test_resample_preserves_tone_and_rejects_alias(self):
        x = tone(1000.0, 0.2, rate=48_000)
        y = resample(x, 48_000, ANALYSIS_RATE)
        self.assertAlmostEqual(len(y), len(x) // 2, delta=1)
        self.assertAlmostEqual(compute_frame(y, 3).zcr_hz, 2000.0, delta=150.0)
        hi = tone(15_000.0, 0.2, rate=48_000)          # replierait vers 9 kHz
        z = resample(hi, 48_000, ANALYSIS_RATE)
        rms_in = math.sqrt(sum(v * v for v in hi) / len(hi))
        rms_out = math.sqrt(sum(v * v for v in z[200:-200]) / len(z[200:-200]))
        self.assertLess(rms_out / rms_in, 0.05)


if __name__ == "__main__":
    unittest.main()
