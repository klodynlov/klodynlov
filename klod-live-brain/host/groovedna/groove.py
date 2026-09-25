"""KLOD GrooveDNA — capturer, représenter, transférer et interpoler un *groove*.

**stdlib pure.** Aucune dépendance : ni MIDI, ni matériel, ni réseau. Tout ce
qui relève de « comprendre le feel rythmique » vit ici et se teste donc sans
Teensy ni carte son. C'est le *spike* qui prouve le cœur de KLOD Live Brain
(cf. `docs/TECHNICAL_REALITY.md`, `docs/GROOVEDNA_SPEC.md`) : la couche
« musical » de l'architecture, volontairement indépendante du transport et du
matériel, pour être vérifiable de bout en bout avant tout portage firmware.

Chaîne prouvée (critère de réussite §38 du cahier des charges) ::

    performance humaine  →  capture_groove()  →  GrooveDNA
    pattern quantifié    →  apply_groove(pattern, dna, amount)  →  pattern « joué »
    dna_a, dna_b         →  morph_grooves(a, b, alpha)          →  dna interpolé

Choix structurants (détaillés dans `docs/GROOVEDNA_SPEC.md`) :

* le microtiming est stocké en **fraction de noire** (beats), donc
  **indépendant du tempo** ; on convertit en millisecondes seulement à
  l'affichage, avec le tempo de référence enregistré ;
* la représentation centrale est un **gabarit de groove** — pour chaque
  (voix, pas de la grille) : décalage moyen, dynamique moyenne, probabilité de
  frappe — exactement ce que fait un *groove template* de DAW, et non un sac de
  paramètres inventés ;
* rien n'est aléatoire : `apply_groove` applique des moyennes mesurées, donc le
  résultat est **reproductible** (une exigence, pas un détail).

Format versionné : ``KLOD_GROOVE_V1``.
"""

from __future__ import annotations

import json
from collections import defaultdict
from dataclasses import dataclass, field
from statistics import fmean, pstdev
from typing import Callable, Dict, Iterable, List, Optional, Sequence

FORMAT = "KLOD_GROOVE_V1"
FORMAT_FAMILY = "KLOD_GROOVE_V"
DEFAULT_PPQN = 960  # résolution de référence (comme les séquenceurs à haute déf.)


# --------------------------------------------------------------------------
# Erreurs
# --------------------------------------------------------------------------


class GrooveError(Exception):
    """Erreur de base du moteur GrooveDNA."""


class IncompatibleGrid(GrooveError):
    """Deux grooves aux grilles incompatibles (ppqn/mesure/subdivision)."""


class UnsupportedFormat(GrooveError):
    """Version de format inconnue au chargement (versionnement du format)."""


# --------------------------------------------------------------------------
# Événement de note — l'unité capturée
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class NoteEvent:
    """Une frappe MIDI, positionnée en ticks absolus.

    Volontairement minimal et *indépendant du transport* : que la note vienne
    d'un port DIN, d'USB MIDI ou d'un fichier .mid, elle arrive ici sous la
    même forme. Le champ décisif est ``tick`` : la position **réelle**, telle
    que jouée, pas la position théorique sur la grille.
    """

    tick: int          # position absolue, en ticks (à la résolution ppqn du contexte)
    note: int          # hauteur MIDI 0..127
    velocity: int      # 1..127 (0 = note off en MIDI, hors de notre domaine)
    channel: int = 9   # 0-indexé ; 9 = canal 10 = batterie General MIDI
    duration: int = 0  # durée en ticks (0 = inconnue)

    def __post_init__(self) -> None:
        if self.tick < 0:
            raise ValueError(f"tick négatif : {self.tick}")
        if not 0 <= self.note <= 127:
            raise ValueError(f"note hors 0..127 : {self.note}")
        if not 1 <= self.velocity <= 127:
            raise ValueError(f"velocity hors 1..127 : {self.velocity}")
        if not 0 <= self.channel <= 15:
            raise ValueError(f"channel hors 0..15 : {self.channel}")


# --------------------------------------------------------------------------
# Grille métrique — la référence théorique contre laquelle on mesure le feel
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class Grid:
    """Grille métrique : ppqn, mesure, subdivision.

    ``subdivision`` = nombre de pas par temps. 4 ⇒ doubles-croches (16 pas par
    mesure en 4/4) ; 3 ⇒ triolets. ``ppqn`` doit être divisible par
    ``subdivision`` pour que les pas tombent sur des ticks entiers.
    """

    ppqn: int = DEFAULT_PPQN
    beats_per_bar: int = 4
    subdivision: int = 4

    def __post_init__(self) -> None:
        if self.ppqn <= 0 or self.beats_per_bar <= 0 or self.subdivision <= 0:
            raise ValueError("ppqn, beats_per_bar et subdivision doivent être > 0")
        if self.ppqn % self.subdivision != 0:
            raise ValueError(
                f"ppqn ({self.ppqn}) doit être divisible par subdivision "
                f"({self.subdivision}) pour une grille en ticks entiers"
            )

    @property
    def ticks_per_step(self) -> int:
        return self.ppqn // self.subdivision

    @property
    def steps_per_bar(self) -> int:
        return self.beats_per_bar * self.subdivision

    @property
    def ticks_per_bar(self) -> int:
        return self.ppqn * self.beats_per_bar

    def quantize(self, tick: int) -> "Quantized":
        """Position réelle → (mesure, pas, décalage).

        Le décalage est ``tick - grille_la_plus_proche``, en ticks (signé). On
        arrondit à la subdivision la plus proche *globalement*, ce qui gère
        proprement une note en avance sur le premier temps de la mesure
        suivante (elle appartient à ce temps-là, avec un décalage négatif).
        """
        step_global = round(tick / self.ticks_per_step)
        grid_tick = step_global * self.ticks_per_step
        return Quantized(
            bar=step_global // self.steps_per_bar,
            step=step_global % self.steps_per_bar,
            offset_ticks=tick - grid_tick,
            grid_tick=grid_tick,
        )


@dataclass(frozen=True)
class Quantized:
    bar: int
    step: int          # 0 .. steps_per_bar-1
    offset_ticks: int  # signé : négatif = en avance, positif = en retard
    grid_tick: int     # position théorique absolue


# --------------------------------------------------------------------------
# Rôles / carte de batterie General MIDI
# --------------------------------------------------------------------------


class Role:
    KICK = "kick"
    SNARE = "snare"
    HAT = "hat"
    TOM = "tom"
    CYMBAL = "cymbal"
    PERC = "perc"
    OTHER = "other"


# Sous-ensemble de la carte de percussion General MIDI (canal 10).
GM_DRUM_ROLES: Dict[int, str] = {
    35: Role.KICK, 36: Role.KICK,
    37: Role.SNARE, 38: Role.SNARE, 39: Role.SNARE, 40: Role.SNARE,
    42: Role.HAT, 44: Role.HAT, 46: Role.HAT,
    41: Role.TOM, 43: Role.TOM, 45: Role.TOM, 47: Role.TOM, 48: Role.TOM, 50: Role.TOM,
    49: Role.CYMBAL, 51: Role.CYMBAL, 52: Role.CYMBAL, 53: Role.CYMBAL,
    55: Role.CYMBAL, 57: Role.CYMBAL, 59: Role.CYMBAL,
}


def gm_role(event: NoteEvent) -> str:
    """Rôle d'une note selon la carte General MIDI (percussion).

    C'est le résolveur par défaut. On peut en passer un autre à
    ``capture_groove`` / ``apply_groove`` (p.ex. par canal, pour du mélodique).
    """
    return GM_DRUM_ROLES.get(event.note, Role.PERC if event.channel == 9 else Role.OTHER)


RoleOf = Callable[[NoteEvent], str]


# --------------------------------------------------------------------------
# Représentation d'un groove
# --------------------------------------------------------------------------


@dataclass
class StepStat:
    """Statistiques d'une voix à un pas donné de la grille (le cœur du gabarit).

    Décalage et vélocité sont des **moyennes mesurées**, pas des réglages : ce
    sont elles qui portent le feel. ``offset_*`` est en fraction de noire
    (indépendant du tempo) ; ``velocity_*`` est normalisé 0..1.
    """

    count: int = 0
    offset_mean: float = 0.0   # beats (fraction de noire), signé
    offset_std: float = 0.0    # beats
    velocity_mean: float = 0.0  # 0..1
    velocity_std: float = 0.0   # 0..1
    hit_prob: float = 0.0       # probabilité de frappe sur ce pas (count / bars)


@dataclass
class VoiceGroove:
    """Le groove d'une voix (kick, snare, hat…) : un gabarit par pas + agrégats."""

    role: str
    steps: Dict[int, StepStat] = field(default_factory=dict)
    offset_mean: float = 0.0   # agrégat sur toutes les frappes (beats)
    offset_std: float = 0.0
    velocity_mean: float = 0.0
    count: int = 0


@dataclass
class GrooveDNA:
    """Signature statistique d'une performance rythmique — le « GrooveDNA ».

    Indépendant du BPM : ``tempo_reference`` n'est là que pour reconstituer les
    millisecondes à l'affichage. Le contenu porteur de feel est ``voices`` (les
    gabarits par voix) ; ``swing``/``density``/``syncopation``/``variation``
    sont des **features dérivées** documentées, utiles à la comparaison, au
    morphing et à l'affichage.
    """

    format: str = FORMAT
    tempo_reference: float = 120.0
    ppqn: int = DEFAULT_PPQN
    beats_per_bar: int = 4
    subdivision: int = 4
    bars: int = 1
    voices: Dict[str, VoiceGroove] = field(default_factory=dict)
    swing: float = 0.5           # 0.5 = binaire ; 0.667 ≈ triolet ; base : voir spec
    density: float = 0.0         # occupation moyenne des pas, 0..1
    syncopation: float = 0.0     # énergie sur temps faibles, 0..1
    variation: float = 0.0       # variation inter-mesures moyenne, 0..1
    bar_variation: List[float] = field(default_factory=list)  # par mesure vs mesure 1
    accent_map: List[float] = field(default_factory=list)     # vélocité moyenne/pas, kit

    # -- accès pratique ----------------------------------------------------

    @property
    def grid(self) -> Grid:
        return Grid(self.ppqn, self.beats_per_bar, self.subdivision)

    def step_stat(self, role: str, step: int) -> Optional[StepStat]:
        voice = self.voices.get(role)
        if voice is None:
            return None
        return voice.steps.get(step)

    def offset_ms(self, offset_beats: float) -> float:
        """Convertit un décalage (beats) en millisecondes au tempo de référence."""
        return offset_beats * 60_000.0 / self.tempo_reference

    # -- sérialisation versionnée -----------------------------------------

    def to_dict(self) -> dict:
        return {
            "format": self.format,
            "tempo_reference": self.tempo_reference,
            "ppqn": self.ppqn,
            "beats_per_bar": self.beats_per_bar,
            "subdivision": self.subdivision,
            "bars": self.bars,
            "swing": self.swing,
            "density": self.density,
            "syncopation": self.syncopation,
            "variation": self.variation,
            "bar_variation": list(self.bar_variation),
            "accent_map": list(self.accent_map),
            "voices": {
                role: {
                    "role": v.role,
                    "offset_mean": v.offset_mean,
                    "offset_std": v.offset_std,
                    "velocity_mean": v.velocity_mean,
                    "count": v.count,
                    "steps": {
                        str(step): {
                            "count": s.count,
                            "offset_mean": s.offset_mean,
                            "offset_std": s.offset_std,
                            "velocity_mean": s.velocity_mean,
                            "velocity_std": s.velocity_std,
                            "hit_prob": s.hit_prob,
                        }
                        for step, s in sorted(v.steps.items())
                    },
                }
                for role, v in self.voices.items()
            },
        }

    def to_json(self, *, indent: int = 2) -> str:
        return json.dumps(self.to_dict(), indent=indent, ensure_ascii=False)

    @classmethod
    def from_dict(cls, data: dict) -> "GrooveDNA":
        fmt = data.get("format", "")
        if not fmt.startswith(FORMAT_FAMILY):
            raise UnsupportedFormat(
                f"format inconnu : {fmt!r} (attendu : {FORMAT_FAMILY}*)"
            )
        # Point d'extension : ici viendrait la migration V1 -> V2 le jour venu.
        voices = {
            role: VoiceGroove(
                role=v["role"],
                offset_mean=v["offset_mean"],
                offset_std=v["offset_std"],
                velocity_mean=v["velocity_mean"],
                count=v["count"],
                steps={
                    int(step): StepStat(**s) for step, s in v["steps"].items()
                },
            )
            for role, v in data.get("voices", {}).items()
        }
        return cls(
            format=fmt,
            tempo_reference=data["tempo_reference"],
            ppqn=data["ppqn"],
            beats_per_bar=data["beats_per_bar"],
            subdivision=data["subdivision"],
            bars=data["bars"],
            voices=voices,
            swing=data.get("swing", 0.5),
            density=data.get("density", 0.0),
            syncopation=data.get("syncopation", 0.0),
            variation=data.get("variation", 0.0),
            bar_variation=list(data.get("bar_variation", [])),
            accent_map=list(data.get("accent_map", [])),
        )

    @classmethod
    def from_json(cls, text: str) -> "GrooveDNA":
        return cls.from_dict(json.loads(text))


# --------------------------------------------------------------------------
# Petits utilitaires
# --------------------------------------------------------------------------


def _clamp(x: float, lo: float, hi: float) -> float:
    return lo if x < lo else hi if x > hi else x


def _agg(values: Sequence[float]) -> "tuple[float, float]":
    """Moyenne et écart-type de population, robustes au vide/singleton."""
    if not values:
        return 0.0, 0.0
    if len(values) == 1:
        return values[0], 0.0
    return fmean(values), pstdev(values)


# --------------------------------------------------------------------------
# Métriques dérivées (base mathématique documentée dans GROOVEDNA_SPEC.md)
# --------------------------------------------------------------------------


def metric_weight(step: int, grid: Grid) -> float:
    """Poids métrique d'un pas dans la mesure, dans [0, 1].

    Hiérarchie métrique classique du 4/4 (cf. grille métrique de
    Longuet-Higgins & Lee 1984, ici simplifiée) : plus un pas coïncide avec une
    grande subdivision, plus il est « fort ».
    """
    spb = grid.subdivision
    beat = step // spb            # index du temps dans la mesure
    within = step % spb           # position dans le temps
    if within == 0:               # sur un temps
        if beat == 0:
            return 1.00           # premier temps (downbeat)
        if grid.beats_per_bar % 2 == 0 and beat == grid.beats_per_bar // 2:
            return 0.90           # temps médian (temps 3 en 4/4)
        return 0.75               # autres temps
    if spb % 2 == 0 and within == spb // 2:
        return 0.50               # la croche « et »
    return 0.25                   # doubles-croches et plus fin


def _swing_from(offsets_by_step: Dict[int, List[float]], grid: Grid) -> float:
    """Swing = position normalisée moyenne des croches « et » dans le temps.

    Une croche « et » binaire tombe à 0.5 du temps ; jouée en swing elle est
    poussée plus tard. On lit donc le décalage moyen sur ces pas et on ajoute
    0.5. Pas de « et » joué ⇒ 0.5 (binaire).
    """
    spb = grid.subdivision
    if spb % 2 != 0:
        return 0.5
    half = spb // 2
    pushed: List[float] = []
    for step, offs in offsets_by_step.items():
        if step % spb == half:
            pushed.extend(offs)
    if not pushed:
        return 0.5
    return 0.5 + fmean(pushed)


# --------------------------------------------------------------------------
# Capture : performance MIDI -> GrooveDNA
# --------------------------------------------------------------------------


def capture_groove(
    events: Iterable[NoteEvent],
    *,
    ppqn: int = DEFAULT_PPQN,
    tempo: float = 120.0,
    beats_per_bar: int = 4,
    subdivision: int = 4,
    bars: Optional[int] = None,
    role_of: RoleOf = gm_role,
) -> GrooveDNA:
    """Extrait le GrooveDNA d'une performance (liste de ``NoteEvent``).

    Mesure, pour chaque (voix, pas) : décalage moyen (beats), écart-type,
    vélocité moyenne, probabilité de frappe. Puis les features dérivées. Rien
    d'aléatoire, rien d'inventé : que des statistiques des frappes réelles.
    """
    grid = Grid(ppqn, beats_per_bar, subdivision)
    events = sorted(events, key=lambda e: (e.tick, e.note))

    # Rognage des mesures vides de tête/queue quand le nombre de mesures est
    # auto-détecté : un décompte silencieux ne doit pas diluer densité et
    # probabilités de frappe. Si l'appelant fixe `bars`, on respecte sa valeur.
    onset_bars = [grid.quantize(e.tick).bar for e in events]
    if bars is None:
        if onset_bars:
            first_bar = min(onset_bars)
            bars = max(onset_bars) - first_bar + 1
        else:
            first_bar, bars = 0, 1
    else:
        first_bar = 0

    # Accumulateurs
    step_offsets: Dict[str, Dict[int, List[float]]] = defaultdict(lambda: defaultdict(list))
    step_vels: Dict[str, Dict[int, List[float]]] = defaultdict(lambda: defaultdict(list))
    voice_offsets: Dict[str, List[float]] = defaultdict(list)
    voice_vels: Dict[str, List[float]] = defaultdict(list)
    kit_step_vels: Dict[int, List[float]] = defaultdict(list)
    bar_onsets: Dict[int, set] = defaultdict(set)   # mesure -> {(role, step)}
    kit_onsets: List["tuple[int, float]"] = []      # (step, vel_norm) pour syncope

    for e in events:
        role = role_of(e)
        q = grid.quantize(e.tick)
        bar = min(max(q.bar - first_bar, 0), bars - 1)
        off_beats = q.offset_ticks / grid.ppqn
        vel_norm = e.velocity / 127.0

        step_offsets[role][q.step].append(off_beats)
        step_vels[role][q.step].append(vel_norm)
        voice_offsets[role].append(off_beats)
        voice_vels[role].append(vel_norm)
        kit_step_vels[q.step].append(vel_norm)
        bar_onsets[bar].add((role, q.step))
        kit_onsets.append((q.step, vel_norm))

    # Construire les voix
    voices: Dict[str, VoiceGroove] = {}
    for role, offs_by_step in step_offsets.items():
        steps: Dict[int, StepStat] = {}
        for step, offs in offs_by_step.items():
            o_mean, o_std = _agg(offs)
            v_mean, v_std = _agg(step_vels[role][step])
            steps[step] = StepStat(
                count=len(offs),
                offset_mean=o_mean,
                offset_std=o_std,
                velocity_mean=v_mean,
                velocity_std=v_std,
                hit_prob=_clamp(len(offs) / bars, 0.0, 1.0),
            )
        vo_mean, vo_std = _agg(voice_offsets[role])
        vv_mean, _ = _agg(voice_vels[role])
        voices[role] = VoiceGroove(
            role=role,
            steps=steps,
            offset_mean=vo_mean,
            offset_std=vo_std,
            velocity_mean=vv_mean,
            count=len(voice_offsets[role]),
        )

    dna = GrooveDNA(
        tempo_reference=tempo,
        ppqn=ppqn,
        beats_per_bar=beats_per_bar,
        subdivision=subdivision,
        bars=bars,
        voices=voices,
    )
    dna.swing = _compute_swing(step_offsets, grid)
    dna.density = _compute_density(voices, grid, bars)
    dna.syncopation = _compute_syncopation(kit_onsets, grid)
    dna.accent_map = _compute_accent_map(kit_step_vels, grid)
    dna.bar_variation = _compute_bar_variation(bar_onsets, bars)
    played = [b for b in range(bars) if bar_onsets.get(b)]
    dna.variation = (
        fmean([dna.bar_variation[b] for b in played]) if len(played) > 1 else 0.0
    )
    return dna


def _compute_swing(step_offsets: Dict[str, Dict[int, List[float]]], grid: Grid) -> float:
    # Swing des charleys si présents, sinon de l'ensemble du kit.
    if Role.HAT in step_offsets:
        return _swing_from(step_offsets[Role.HAT], grid)
    merged: Dict[int, List[float]] = defaultdict(list)
    for by_step in step_offsets.values():
        for step, offs in by_step.items():
            merged[step].extend(offs)
    return _swing_from(merged, grid)


def _compute_density(voices: Dict[str, VoiceGroove], grid: Grid, bars: int) -> float:
    slots = grid.steps_per_bar * bars
    if slots == 0 or not voices:
        return 0.0
    # Occupation d'une voix = frappes distinctes / créneaux ; densité = moyenne.
    occ = [min(v.count, slots) / slots for v in voices.values()]
    return _clamp(fmean(occ), 0.0, 1.0)


def _compute_syncopation(kit_onsets: List["tuple[int, float]"], grid: Grid) -> float:
    # Fraction de l'énergie (vélocité) tombant sur des positions métriques faibles.
    total = sum(vel for _, vel in kit_onsets)
    if total == 0:
        return 0.0
    weak = sum(vel * (1.0 - metric_weight(step, grid)) for step, vel in kit_onsets)
    return _clamp(weak / total, 0.0, 1.0)


def _compute_accent_map(kit_step_vels: Dict[int, List[float]], grid: Grid) -> List[float]:
    return [
        fmean(kit_step_vels[step]) if kit_step_vels.get(step) else 0.0
        for step in range(grid.steps_per_bar)
    ]


def _compute_bar_variation(bar_onsets: Dict[int, set], bars: int) -> List[float]:
    # Distance de Jaccard moyenne de chaque mesure jouée aux *autres* mesures
    # jouées. Symétrique (aucune mesure « de référence » privilégiée) et robuste
    # aux mesures vides, simplement ignorées.
    played = [b for b in range(bars) if bar_onsets.get(b)]
    out = [0.0] * bars
    if len(played) < 2:
        return out
    for i in played:
        cur = bar_onsets[i]
        dists = []
        for j in played:
            if j == i:
                continue
            other = bar_onsets[j]
            union = cur | other
            dists.append(len(cur ^ other) / len(union) if union else 0.0)
        out[i] = fmean(dists)
    return out


# --------------------------------------------------------------------------
# Transfert de groove : appliquer un GrooveDNA à un pattern
# --------------------------------------------------------------------------


def apply_groove(
    pattern: Iterable[NoteEvent],
    groove: GrooveDNA,
    amount: float = 1.0,
    *,
    ppqn: Optional[int] = None,
    beats_per_bar: Optional[int] = None,
    subdivision: Optional[int] = None,
    role_of: RoleOf = gm_role,
) -> List[NoteEvent]:
    """Transfère le feel de ``groove`` sur ``pattern``, dosé par ``amount``.

    ``amount = 0`` → pattern inchangé (identité, prouvé par les tests).
    ``amount = 1`` → chaque note prend le décalage et la dynamique appris pour
    sa (voix, pas). Interpolation **linéaire** entre les deux.

    Aucune note n'est perdue : la sortie a exactement autant d'événements que
    l'entrée. Les ticks restent ≥ 0, les vélocités bornées à 1..127.
    """
    amount = _clamp(amount, 0.0, 1.0)
    grid = Grid(
        ppqn or groove.ppqn,
        beats_per_bar or groove.beats_per_bar,
        subdivision or groove.subdivision,
    )
    out: List[NoteEvent] = []
    for e in pattern:
        role = role_of(e)
        q = grid.quantize(e.tick)
        stat = groove.step_stat(role, q.step)

        if stat is not None and stat.count > 0:
            target_tick = q.grid_tick + stat.offset_mean * grid.ppqn
            target_vel = stat.velocity_mean * 127.0
        else:
            # Repli : le pas n'a jamais été joué dans ce groove. On applique le
            # décalage agrégé de la voix (le « push/drag » global) et on laisse
            # la vélocité telle quelle plutôt que d'inventer une dynamique.
            voice = groove.voices.get(role)
            base = voice.offset_mean if voice else 0.0
            target_tick = q.grid_tick + base * grid.ppqn
            target_vel = float(e.velocity)

        new_tick = e.tick + amount * (target_tick - e.tick)
        new_vel = e.velocity + amount * (target_vel - e.velocity)
        out.append(
            NoteEvent(
                tick=max(0, round(new_tick)),
                note=e.note,
                velocity=int(_clamp(round(new_vel), 1, 127)),
                channel=e.channel,
                duration=e.duration,
            )
        )
    out.sort(key=lambda ev: (ev.tick, ev.note))
    return out


# --------------------------------------------------------------------------
# Morphing : interpoler deux grooves
# --------------------------------------------------------------------------


def _lerp(a: float, b: float, t: float) -> float:
    return a + t * (b - a)


def _lerp_step(a: Optional[StepStat], b: Optional[StepStat], t: float) -> StepStat:
    a = a or StepStat()
    b = b or StepStat()
    return StepStat(
        count=_lerp(a.count, b.count, t),  # fractionnaire pendant le morph
        offset_mean=_lerp(a.offset_mean, b.offset_mean, t),
        offset_std=_lerp(a.offset_std, b.offset_std, t),
        velocity_mean=_lerp(a.velocity_mean, b.velocity_mean, t),
        velocity_std=_lerp(a.velocity_std, b.velocity_std, t),
        hit_prob=_lerp(a.hit_prob, b.hit_prob, t),
    )


def _lerp_list(a: List[float], b: List[float], t: float) -> List[float]:
    n = max(len(a), len(b))
    pa = list(a) + [0.0] * (n - len(a))
    pb = list(b) + [0.0] * (n - len(b))
    return [_lerp(x, y, t) for x, y in zip(pa, pb)]


def morph_grooves(a: GrooveDNA, b: GrooveDNA, alpha: float = 0.5) -> GrooveDNA:
    """Interpole deux GrooveDNA. ``alpha=0`` → A, ``alpha=1`` → B.

    Ce qui est **continu** (décalages, vélocités, probabilités, features) est
    interpolé linéairement. Ce qui est **structurel** (une voix ou un pas
    présent d'un seul côté) *apparaît/disparaît* progressivement via son poids
    plutôt que d'être moyenné n'importe comment : une voix dont le poids morphé
    tombe à zéro est retirée. Aux bornes exactes, on renvoie une copie fidèle
    de A ou B — pas d'artefact d'union.
    """
    if a.ppqn != b.ppqn or a.beats_per_bar != b.beats_per_bar or a.subdivision != b.subdivision:
        raise IncompatibleGrid(
            "morph impossible : grilles différentes "
            f"(A: {a.ppqn}/{a.beats_per_bar}/{a.subdivision}, "
            f"B: {b.ppqn}/{b.beats_per_bar}/{b.subdivision})"
        )
    alpha = _clamp(alpha, 0.0, 1.0)
    if alpha == 0.0:
        return GrooveDNA.from_dict(a.to_dict())
    if alpha == 1.0:
        return GrooveDNA.from_dict(b.to_dict())

    voices: Dict[str, VoiceGroove] = {}
    for role in set(a.voices) | set(b.voices):
        va, vb = a.voices.get(role), b.voices.get(role)
        steps_keys = set(va.steps if va else {}) | set(vb.steps if vb else {})
        steps: Dict[int, StepStat] = {}
        for step in steps_keys:
            s = _lerp_step(
                va.steps.get(step) if va else None,
                vb.steps.get(step) if vb else None,
                alpha,
            )
            if s.count > 1e-9:  # un pas dont le poids s'annule disparaît
                steps[step] = s
        if not steps:
            continue
        voices[role] = VoiceGroove(
            role=role,
            steps=steps,
            offset_mean=_lerp(va.offset_mean if va else 0.0, vb.offset_mean if vb else 0.0, alpha),
            offset_std=_lerp(va.offset_std if va else 0.0, vb.offset_std if vb else 0.0, alpha),
            velocity_mean=_lerp(va.velocity_mean if va else 0.0, vb.velocity_mean if vb else 0.0, alpha),
            count=_lerp(va.count if va else 0.0, vb.count if vb else 0.0, alpha),
        )

    return GrooveDNA(
        tempo_reference=_lerp(a.tempo_reference, b.tempo_reference, alpha),
        ppqn=a.ppqn,
        beats_per_bar=a.beats_per_bar,
        subdivision=a.subdivision,
        bars=max(a.bars, b.bars),
        voices=voices,
        swing=_lerp(a.swing, b.swing, alpha),
        density=_lerp(a.density, b.density, alpha),
        syncopation=_lerp(a.syncopation, b.syncopation, alpha),
        variation=_lerp(a.variation, b.variation, alpha),
        bar_variation=_lerp_list(a.bar_variation, b.bar_variation, alpha),
        accent_map=_lerp_list(a.accent_map, b.accent_map, alpha),
    )


# --------------------------------------------------------------------------
# Comparaison : « à quel point ce jeu ressemble-t-il à cette référence ? »
# --------------------------------------------------------------------------


def groove_distance(a: GrooveDNA, b: GrooveDNA) -> float:
    """Distance simple entre deux grooves, dans [0, 1] (0 = identiques).

    Moyenne de trois écarts normalisés : swing, syncope, densité. Base honnête
    et documentée pour un futur « GROOVE MATCH » (§16), pas une note magique.
    """
    d_swing = abs(a.swing - b.swing)              # swing ∈ ~[0.5, 0.75] → écart petit
    d_sync = abs(a.syncopation - b.syncopation)   # déjà dans [0, 1]
    d_dens = abs(a.density - b.density)            # déjà dans [0, 1]
    return _clamp(fmean([min(d_swing * 2, 1.0), d_sync, d_dens]), 0.0, 1.0)
