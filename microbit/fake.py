"""micro:bit simulé — même API que `bleak.BleakClient`, sans radio.

Sert à trois choses :

* **tester** le connecteur sans carte ni dongle Bluetooth (voir
  `test_microbit.py`) ;
* **développer** la logique agent avant d'avoir le matériel sous la main ;
* **démontrer** la boucle complète (`demo.py --simule`) sur une machine nue.

C'est le pendant matériel des appareils simulés d'EdgeSense : la même
discipline « le cœur se teste sans dépendance externe ».
"""

from __future__ import annotations

import asyncio
import random
import struct
from dataclasses import dataclass, field
from typing import Any, Callable

from .profile import Char, Service, decode_led_matrix

#: Services exposés par défaut — ce que donne un programme MakeCode qui
#: démarre les services température, accéléromètre, boutons, LED et UART.
DEFAULT_SERVICES = (
    Service.TEMPERATURE,
    Service.ACCELEROMETER,
    Service.MAGNETOMETER,
    Service.BUTTON,
    Service.LED,
    Service.UART,
    Service.DFU_CONTROL,
)


@dataclass
class _FakeService:
    uuid: str


@dataclass
class _FakeServiceCollection:
    """Reproduit `BleakGATTServiceCollection.services` (dict handle → service)."""

    services: dict[int, _FakeService] = field(default_factory=dict)


class FakeMicrobitClient:
    """Faux `BleakClient` qui se comporte comme un micro:bit sous BLE.

    Toutes les valeurs sont plausibles mais inventées ; la graine rend les
    tirages reproductibles pour les tests.
    """

    def __init__(
        self,
        address: str = "FA:KE:00:00:00:01",
        *,
        services: tuple[str, ...] = DEFAULT_SERVICES,
        temperature: int = 24,
        seed: int = 1234,
        echo_uart: bool = True,
    ) -> None:
        self.address = address
        self._connected = False
        self._rng = random.Random(seed)
        self._echo_uart = echo_uart

        self.services = _FakeServiceCollection(
            {i: _FakeService(uuid.lower()) for i, uuid in enumerate(services)}
        )

        # État interne de la carte simulée.
        self.temperature = temperature
        self.acceleration_mg = (0, 0, -1000)  # au repos, à plat
        self.field_raw = (120, -45, 310)
        self.bearing = 187
        self.buttons = {"A": 0, "B": 0}
        self.matrix = bytes(5)
        self.text_shown: list[str] = []
        self.uart_received: list[bytes] = []
        self.periods = {
            Char.TEMPERATURE_PERIOD: 1000,
            Char.ACCELEROMETER_PERIOD: 640,
            Char.MAGNETOMETER_PERIOD: 640,
            Char.LED_SCROLLING_DELAY: 120,
        }
        self.writes: list[tuple[str, bytes]] = []  # journal des écritures

        self._notify: dict[str, Callable[[Any, bytearray], Any]] = {}
        self._tasks: list[asyncio.Task[None]] = []

    # -- Cycle de vie ------------------------------------------------------

    @property
    def is_connected(self) -> bool:
        return self._connected

    async def connect(self) -> None:
        await asyncio.sleep(0)  # rend le point de suspension réaliste
        self._connected = True

    async def disconnect(self) -> None:
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()
        self._notify.clear()
        self._connected = False

    async def pair(self) -> bool:
        return True

    # -- GATT --------------------------------------------------------------

    def _guard(self, uuid: str) -> str:
        if not self._connected:
            raise RuntimeError("client non connecté")
        return uuid.lower()

    async def read_gatt_char(self, uuid: str) -> bytearray:
        key = self._guard(uuid)
        if key == Char.TEMPERATURE:
            return bytearray(struct.pack("<b", self.temperature))
        if key == Char.ACCELEROMETER_DATA:
            return bytearray(struct.pack("<hhh", *self.acceleration_mg))
        if key == Char.MAGNETOMETER_DATA:
            return bytearray(struct.pack("<hhh", *self.field_raw))
        if key == Char.MAGNETOMETER_BEARING:
            return bytearray(struct.pack("<H", self.bearing))
        if key == Char.BUTTON_A:
            return bytearray([self.buttons["A"]])
        if key == Char.BUTTON_B:
            return bytearray([self.buttons["B"]])
        if key == Char.LED_MATRIX:
            return bytearray(self.matrix)
        if key in self.periods:
            return bytearray(struct.pack("<H", self.periods[key]))
        raise RuntimeError(f"caractéristique non lisible : {uuid}")

    async def write_gatt_char(self, uuid: str, data: bytes, response: bool = True) -> None:
        key = self._guard(uuid)
        payload = bytes(data)
        self.writes.append((key, payload))

        if key == Char.LED_TEXT:
            self.text_shown.append(payload.decode("utf-8", "replace"))
        elif key == Char.LED_MATRIX:
            self.matrix = payload
        elif key in self.periods:
            self.periods[key] = struct.unpack("<H", payload)[0]
        elif key == Char.UART_RX:
            self.uart_received.append(payload)
            if self._echo_uart:
                await self.push_uart(b"echo:" + payload + b"\n")
        else:
            raise RuntimeError(f"caractéristique non inscriptible : {uuid}")

    async def start_notify(self, uuid: str, callback: Callable[[Any, bytearray], Any]) -> None:
        key = self._guard(uuid)
        self._notify[key] = callback
        if key == Char.TEMPERATURE:
            self._tasks.append(asyncio.create_task(self._stream_temperature()))
        elif key == Char.ACCELEROMETER_DATA:
            self._tasks.append(asyncio.create_task(self._stream_accelerometer()))

    async def stop_notify(self, uuid: str) -> None:
        self._notify.pop(self._guard(uuid), None)

    # -- Pilotage de la simulation ----------------------------------------

    async def _emit(self, uuid: str, data: bytes) -> None:
        """Pousse une notification vers l'abonné, s'il y en a un."""
        callback = self._notify.get(uuid.lower())
        if callback is None:
            return
        result = callback(uuid, bytearray(data))
        if asyncio.iscoroutine(result):
            await result

    async def press(self, button: str = "A", *, long: bool = False) -> None:
        """Simule un appui puis un relâchement."""
        label = button.upper()
        state = 2 if long else 1
        self.buttons[label] = state
        await self._emit(Char.BUTTON_A if label == "A" else Char.BUTTON_B, bytes([state]))
        self.buttons[label] = 0
        await self._emit(Char.BUTTON_A if label == "A" else Char.BUTTON_B, bytes([0]))

    async def push_uart(self, payload: bytes) -> None:
        """Simule un message émis par la carte sur le service UART.

        Découpé en PDU de 20 octets, comme la vraie carte — de quoi vérifier
        que le réassemblage des lignes côté client fonctionne.
        """
        for start in range(0, len(payload), 20):
            await self._emit(Char.UART_TX, payload[start : start + 20])

    async def tilt(self, x_mg: int, y_mg: int, z_mg: int = -1000) -> None:
        """Change l'inclinaison simulée et notifie les abonnés."""
        self.acceleration_mg = (x_mg, y_mg, z_mg)
        await self._emit(Char.ACCELEROMETER_DATA, struct.pack("<hhh", x_mg, y_mg, z_mg))

    def display(self) -> list[str]:
        """Rendu texte de la matrice LED — pratique en démo et en test."""
        return decode_led_matrix(self.matrix)

    # -- Flux périodiques --------------------------------------------------

    async def _stream_temperature(self) -> None:
        try:
            while True:
                await asyncio.sleep(self.periods[Char.TEMPERATURE_PERIOD] / 1000)
                # Dérive lente et bornée, comme un capteur qui chauffe.
                self.temperature = max(15, min(40, self.temperature + self._rng.choice((-1, 0, 0, 1))))
                await self._emit(Char.TEMPERATURE, struct.pack("<b", self.temperature))
        except asyncio.CancelledError:
            pass

    def _bruit(self, valeur: int) -> int:
        """Petit tremblement, borné à la plage de l'accéléromètre."""
        return max(-2000, min(2000, valeur + self._rng.randint(-25, 25)))

    async def _stream_accelerometer(self) -> None:
        try:
            while True:
                await asyncio.sleep(self.periods[Char.ACCELEROMETER_PERIOD] / 1000)
                self.acceleration_mg = tuple(self._bruit(v) for v in self.acceleration_mg)  # type: ignore[assignment]
                await self._emit(Char.ACCELEROMETER_DATA, struct.pack("<hhh", *self.acceleration_mg))
        except asyncio.CancelledError:
            pass


def fake_factory(**kwargs: Any) -> Callable[[str], FakeMicrobitClient]:
    """Fabrique injectable dans `MicrobitBLE(client_factory=...)`.

        session = MicrobitBLE("FA:KE", client_factory=fake_factory())
    """

    def factory(address: str) -> FakeMicrobitClient:
        return FakeMicrobitClient(address, **kwargs)

    return factory


__all__ = ["FakeMicrobitClient", "fake_factory", "DEFAULT_SERVICES"]
