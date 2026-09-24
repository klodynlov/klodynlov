"""Vecteurs de référence partagés Python ↔ Swift.

Le portage Swift (`WordEndCore`) ne peut pas être compilé dans l'environnement
où ce module est prouvé ; la parité est donc garantie **par construction** :
ce script fige, pour des énoncés synthétiques déterministes, les sommes de
contrôle du signal, des descripteurs de trames, l'analyse et le verdict. Les
tests Swift régénèrent les mêmes signaux (même PRNG, même synthèse) et doivent
retrouver ces valeurs à une tolérance près.

    python3 -m wordend.golden            # réécrit le fichier
    python3 -m wordend.golden --check    # échoue si le fichier est périmé
"""
from __future__ import annotations

import argparse
import json
from dataclasses import asdict
from pathlib import Path

from .detector import DetectorConfig, Shape, analyze, evaluate
from .dsp import ANALYSIS_RATE, FRAME_SIZE, HANN, HOP_SIZE, Bands, SplitMix64, band_bins, fft
from .synth import LIBRARY, synthesize, utterance

GOLDEN_PATH = (Path(__file__).resolve().parents[2]
               / "ios" / "Tests" / "WordEndCoreTests" / "Resources" / "golden_vectors.json")

# (nom du cas, spec, paramètres d'énoncé, cible)
CASES: list[tuple[str, str, dict, Shape]] = [
    ("douche", LIBRARY["douche"], {"seed": 11}, Shape(1, "S")),
    ("dou", LIBRARY["dou"], {"seed": 12}, Shape(1, "S")),
    ("douche_schwa", LIBRARY["douche_schwa"], {"seed": 13}, Shape(1, "S")),
    ("dou_clic", LIBRARY["dou_clic"], {"seed": 14}, Shape(1, "S")),
    ("minouche", LIBRARY["minouche"], {"seed": 15}, Shape(2, "S")),
    ("minou", LIBRARY["minou"], {"seed": 16}, Shape(2, "S")),
    ("mi", LIBRARY["mi"], {"seed": 17}, Shape(2, "S")),
    ("minousse", LIBRARY["minousse"], {"seed": 18}, Shape(2, "S")),
    ("fish", LIBRARY["fish"], {"seed": 19}, Shape(1, "S")),
    ("goose", LIBRARY["goose"], {"seed": 20}, Shape(1, "s")),
    ("goo", LIBRARY["goo"], {"seed": 21}, Shape(1, "s")),
    ("chut", LIBRARY["chut"], {"seed": 22}, Shape(1, "S")),
    ("silence", "_400", {"seed": 23}, Shape(1, "S")),
    ("adulte", LIBRARY["douche"], {"seed": 24, "f0_start": 120.0, "f0_end": 100.0}, Shape(1, "S")),
    ("ecretage", LIBRARY["douche"], {"seed": 25, "gain_db": 24.0}, Shape(1, "S")),
    ("bruit_fort", LIBRARY["dou"], {"seed": 26, "snr_db": 12.0}, Shape(1, "S")),
    ("bruit_blanc", LIBRARY["minouche"], {"seed": 27, "noise": "white"}, Shape(2, "S")),
]


def _r(x: float, nd: int = 6) -> float:
    return round(float(x), nd)


def _case(name: str, spec: str, params: dict, target: Shape, cfg: DetectorConfig) -> dict:
    u = utterance(spec, **params)
    x = synthesize(u)
    an = analyze(x, cfg=cfg)
    v = evaluate(an, target, cfg)
    frames = an.frames
    probes = sorted({n.frame for n in an.nuclei} | {f.start + f.frames // 2 for f in an.frications}
                    | {len(frames) // 2})
    return {
        "name": name,
        "spec": spec,
        "params": {k: (float(v2) if isinstance(v2, (int, float)) and k != "seed" else v2)
                   for k, v2 in params.items()},
        "target": {"nuclei": target.nuclei, "coda": target.coda},
        "signal": {
            "count": len(x),
            "sum": _r(sum(x), 9),
            "sum_squares": _r(sum(v2 * v2 for v2 in x), 9),
            "probe": {str(i): _r(x[i], 9) for i in (0, 1000, 7200, len(x) // 2, len(x) - 1)},
        },
        "analysis": {
            "frames": len(frames),
            "floor_rms_db": _r(an.floor_rms_db),
            "floor_low_db": _r(an.floor_low_db),
            "floor_high_db": _r(an.floor_high_db),
            "speech": list(an.speech) if an.speech else None,
            "nuclei": [[n.frame, _r(n.level_db), n.onset, n.offset,
                        _r(n.f0_hz) if n.f0_hz is not None else None] for n in an.nuclei],
            "frications": [[f.start, f.end, _r(f.centroid_hz)] for f in an.frications],
            "clipped_fraction": _r(an.clipped_fraction),
            "snr_db": _r(an.snr_db),
        },
        "frame_probes": [{
            "index": t, "rms_db": _r(frames[t].rms_db), "low_db": _r(frames[t].low_db),
            "high_db": _r(frames[t].high_db), "high_ratio": _r(frames[t].high_ratio),
            "centroid_hz": _r(frames[t].centroid_hz), "zcr_hz": _r(frames[t].zcr_hz),
            "peak": _r(frames[t].peak, 9)} for t in probes],
        "verdict": v.to_dict(),
    }


def build() -> dict:
    cfg = DetectorConfig()
    rng = SplitMix64(42)
    u64 = [str(rng.next_u64()) for _ in range(5)]
    rng2 = SplitMix64(7)
    units = [_r(rng2.next_unit(), 15) for _ in range(5)]
    fft_in = [0.5, -1.0, 0.25, 2.0, -0.75, 0.0, 1.5, -0.5]
    spec = fft(fft_in)
    bands = Bands()
    return {
        "schema": "eveil.golden.v1",
        "generator": "eveil/reference/wordend/golden.py",
        "constants": {"analysis_rate": ANALYSIS_RATE, "frame_size": FRAME_SIZE, "hop_size": HOP_SIZE},
        "config": {k: (list(v) if isinstance(v, tuple) else v)
                   for k, v in asdict(cfg).items() if k != "bands"},
        "splitmix64": {"seed": 42, "u64": u64, "unit_seed": 7, "unit": units},
        "fft": {"input": fft_in, "re": [_r(c.real, 12) for c in spec],
                "im": [_r(c.imag, 12) for c in spec]},
        "hann_head": [_r(h, 15) for h in HANN[:4]],
        "band_bins": {"low": list(band_bins(*bands.low)), "high": list(band_bins(*bands.high)),
                      "centroid": list(band_bins(*bands.centroid))},
        "cases": [_case(*c, cfg) for c in CASES],
    }


def render(data: dict) -> str:
    return json.dumps(data, ensure_ascii=False, indent=1, sort_keys=False) + "\n"


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Vecteurs de référence Python ↔ Swift")
    p.add_argument("--check", action="store_true")
    args = p.parse_args(argv)
    text = render(build())
    if args.check:
        current = GOLDEN_PATH.read_text(encoding="utf-8") if GOLDEN_PATH.exists() else ""
        if current != text:
            print(f"périmé : {GOLDEN_PATH} — relancer `python3 -m wordend.golden`")
            return 1
        print("à jour")
        return 0
    GOLDEN_PATH.parent.mkdir(parents=True, exist_ok=True)
    GOLDEN_PATH.write_text(text, encoding="utf-8")
    print(f"écrit : {GOLDEN_PATH} ({len(text)} octets)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
