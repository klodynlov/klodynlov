#!/usr/bin/env python3
"""
EdgeSense — cœur de simulation (M0).

Modèle « objets » minimal mais cohérent : une pièce avec un capteur de
température et un actionneur de chauffage. Le chauffage influe réellement sur la
température lue → la boucle *percevoir → décider → agir → percevoir* est fermée
et observable.

Aucune dépendance externe (bibliothèque standard uniquement). Le serveur MCP
(`server.py`) n'est qu'une fine couche par-dessus ce cœur ; toute la logique —
et donc les tests — vit ici.

Garde-fous (ADN local-first) déjà présents dès M0 :
  - allowlist stricte des actionneurs et de leurs états ;
  - journal d'actions append-only à chaînage de hachage (tamper-evident).
La signature cryptographique complète du journal est prévue pour M3.
"""

from __future__ import annotations

import hashlib
import json
import time
from dataclasses import dataclass
from random import Random


# --------------------------------------------------------------------------- #
#  Modèle de monde simulé
# --------------------------------------------------------------------------- #
class SimulatedRoom:
    """Une pièce : température dérivant vers l'ambiant, chauffée par un relais.

    À chaque `tick`, la température monte si le chauffage est actif, sinon elle
    tend vers la température ambiante. Un léger bruit rend les lectures réalistes.
    """

    def __init__(
        self,
        *,
        ambient: float = 18.0,
        start: float = 19.0,
        heat_rate: float = 0.6,
        cooling: float = 0.12,
        noise: float = 0.05,
        seed: int | None = None,
    ) -> None:
        self.ambient = ambient
        self.temp = start
        self.heater_on = False
        self._heat_rate = heat_rate
        self._cooling = cooling
        self._noise = noise
        self._rng = Random(seed)

    def tick(self, dt: float = 1.0) -> float:
        """Avance la simulation d'un pas de temps et renvoie la température."""
        if self.heater_on:
            self.temp += self._heat_rate * dt
        else:
            self.temp += (self.ambient - self.temp) * self._cooling * dt
        self.temp += self._rng.uniform(-self._noise, self._noise)
        return self.temp


# --------------------------------------------------------------------------- #
#  Erreurs
# --------------------------------------------------------------------------- #
class DeviceError(ValueError):
    """Appareil inconnu ou commande refusée par un garde-fou."""


# --------------------------------------------------------------------------- #
#  Passerelle EdgeSense
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class SensorSpec:
    type: str
    unit: str


class EdgeSense:
    """Passerelle : catalogue d'appareils, lectures, commandes, journal.

    C'est l'objet qu'expose le serveur MCP. Il ne connaît rien à MCP.
    """

    #: capteurs disponibles (id → spec)
    SENSORS: dict[str, SensorSpec] = {
        "temp-1": SensorSpec(type="temperature", unit="°C"),
    }
    #: actionneurs disponibles (id → états autorisés) — allowlist stricte
    ACTUATORS: dict[str, frozenset[str]] = {
        "heater-1": frozenset({"on", "off"}),
    }

    def __init__(self, *, seed: int | None = None) -> None:
        self.room = SimulatedRoom(seed=seed)
        self._actuator_state: dict[str, str] = {"heater-1": "off"}
        self.journal: list[dict] = []

    # -- Lecture ------------------------------------------------------------ #
    def list_devices(self) -> list[dict]:
        """Catalogue des appareils exposés."""
        sensors = [
            {"id": did, "kind": "sensor", "type": s.type, "unit": s.unit}
            for did, s in self.SENSORS.items()
        ]
        actuators = [
            {"id": did, "kind": "actuator", "states": sorted(states),
             "state": self._actuator_state[did]}
            for did, states in self.ACTUATORS.items()
        ]
        return sensors + actuators

    def read_sensor(self, device_id: str) -> dict:
        """Lit un capteur. Chaque lecture avance la simulation d'un pas."""
        spec = self.SENSORS.get(device_id)
        if spec is None:
            raise DeviceError(f"capteur inconnu : {device_id!r}")
        value = round(self.room.tick(), 2)
        return {
            "device_id": device_id,
            "type": spec.type,
            "value": value,
            "unit": spec.unit,
            "ts": time.time(),
        }

    def is_on(self, device_id: str) -> bool:
        return self._actuator_state.get(device_id) == "on"

    # -- Commande ----------------------------------------------------------- #
    def set_actuator(self, device_id: str, state: str) -> dict:
        """Change l'état d'un actionneur, après validation par l'allowlist."""
        allowed = self.ACTUATORS.get(device_id)
        if allowed is None:
            raise DeviceError(f"actionneur inconnu : {device_id!r}")
        if state not in allowed:
            raise DeviceError(
                f"état refusé {state!r} pour {device_id!r} "
                f"(autorisés : {sorted(allowed)})"
            )
        previous = self._actuator_state[device_id]
        self._actuator_state[device_id] = state
        if device_id == "heater-1":
            self.room.heater_on = state == "on"
        entry = self._journal_action(device_id, previous, state)
        return {
            "device_id": device_id,
            "state": state,
            "previous": previous,
            "journal_hash": entry["hash"],
        }

    # -- État & journal ----------------------------------------------------- #
    def snapshot(self) -> dict:
        """Instantané complet — utile comme `resource` MCP."""
        return {
            "devices": self.list_devices(),
            "room": {
                "temp": round(self.room.temp, 2),
                "ambient": self.room.ambient,
                "heater_on": self.room.heater_on,
            },
            "journal_len": len(self.journal),
            "ts": time.time(),
        }

    def _journal_action(self, device_id: str, previous: str, state: str) -> dict:
        """Ajoute une action au journal append-only à chaînage de hachage."""
        body = {
            "device_id": device_id,
            "previous": previous,
            "state": state,
            "ts": time.time(),
        }
        prev_hash = self.journal[-1]["hash"] if self.journal else "genesis"
        payload = json.dumps(body, sort_keys=True)
        digest = hashlib.sha256((prev_hash + payload).encode()).hexdigest()
        entry = {**body, "prev": prev_hash, "hash": digest}
        self.journal.append(entry)
        return entry

    def verify_journal(self) -> bool:
        """Revérifie l'intégrité de la chaîne de hachage du journal."""
        prev_hash = "genesis"
        for entry in self.journal:
            body = {k: entry[k] for k in ("device_id", "previous", "state", "ts")}
            payload = json.dumps(body, sort_keys=True)
            expected = hashlib.sha256((prev_hash + payload).encode()).hexdigest()
            if entry["prev"] != prev_hash or entry["hash"] != expected:
                return False
            prev_hash = entry["hash"]
        return True
