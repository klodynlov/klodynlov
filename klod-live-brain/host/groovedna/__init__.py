"""KLOD GrooveDNA — le moteur « musical » de KLOD Live Brain.

Capturer, représenter, transférer et interpoler le *feel* rythmique réel d'un
musicien — en **stdlib pure**, donc testable de bout en bout sans Teensy ni
carte son. C'est la preuve du cœur du projet (cf. `docs/TECHNICAL_REALITY.md`).

    from groovedna import capture_groove, apply_groove, morph_grooves, NoteEvent

    dna = capture_groove(events, ppqn=960, tempo=100)      # performance -> ADN
    joue = apply_groove(pattern_quantifie, dna, amount=1)  # transfert de feel
    mix = morph_grooves(dna_a, dna_b, alpha=0.3)           # interpolation
"""

from .groove import (
    DEFAULT_PPQN,
    FORMAT,
    GM_DRUM_ROLES,
    Grid,
    GrooveDNA,
    GrooveError,
    IncompatibleGrid,
    NoteEvent,
    Quantized,
    Role,
    StepStat,
    UnsupportedFormat,
    VoiceGroove,
    apply_groove,
    capture_groove,
    gm_role,
    groove_distance,
    metric_weight,
    morph_grooves,
)

__all__ = [
    "NoteEvent",
    "Grid",
    "Quantized",
    "GrooveDNA",
    "VoiceGroove",
    "StepStat",
    "Role",
    "GM_DRUM_ROLES",
    "capture_groove",
    "apply_groove",
    "morph_grooves",
    "groove_distance",
    "metric_weight",
    "gm_role",
    "GrooveError",
    "IncompatibleGrid",
    "UnsupportedFormat",
    "FORMAT",
    "DEFAULT_PPQN",
]

__version__ = "0.1.0"
