"""Connexion Bluetooth Low Energy à un BBC micro:bit.

Couche transport : découverte, connexion, lecture, abonnement aux
notifications, écriture. Tout le décodage vit dans `profile.py`, qui ne
dépend d'aucune radio.

`bleak` n'est importé que si l'on utilise vraiment la radio — un client
injecté (voir `fake.py`) permet de faire tourner l'ensemble sans matériel.

    import asyncio
    from microbit.ble import MicrobitBLE

    async def main():
        async with await MicrobitBLE.first() as mb:
            print(await mb.read_temperature(), "°C")
            await mb.show_text("Salut")

    asyncio.run(main())
"""

from __future__ import annotations

import asyncio
import inspect
import logging
from dataclasses import dataclass
from typing import Any, Awaitable, Callable, Iterable, Protocol, Sequence

from .profile import (
    ADVERTISED_NAME_PREFIX,
    Acceleration,
    ButtonState,
    Char,
    MagneticField,
    MicrobitError,
    NotConnected,
    SERVICE_MAKECODE_BLOCK,
    SERVICE_NAMES,
    Service,
    ServiceUnavailable,
    CHAR_SERVICE,
    check_write,
    decode_accelerometer,
    decode_bearing,
    decode_button,
    decode_led_matrix,
    decode_magnetometer,
    decode_period,
    decode_temperature,
    encode_accelerometer_period,
    encode_led_matrix,
    encode_led_text,
    encode_period,
    encode_uart,
    icon,
)

log = logging.getLogger("microbit.ble")

# Un rappel utilisateur peut être synchrone ou asynchrone.
Callback = Callable[..., Any | Awaitable[Any]]


class ClientLike(Protocol):
    """Sous-ensemble de l'API `bleak.BleakClient` dont ce module a besoin.

    Le déclarer explicitement permet d'injecter un faux client en test sans
    dépendre de bleak.
    """

    address: str

    @property
    def is_connected(self) -> bool: ...

    async def connect(self) -> None: ...

    async def disconnect(self) -> None: ...

    async def read_gatt_char(self, uuid: str) -> bytearray: ...

    async def write_gatt_char(self, uuid: str, data: bytes, response: bool = True) -> None: ...

    async def start_notify(self, uuid: str, callback: Callable[[Any, bytearray], Any]) -> None: ...

    async def stop_notify(self, uuid: str) -> None: ...


@dataclass(frozen=True)
class Discovered:
    """Un micro:bit repéré pendant un scan."""

    name: str
    address: str
    rssi: int | None = None

    def __str__(self) -> str:
        force = f"{self.rssi} dBm" if self.rssi is not None else "signal inconnu"
        return f"{self.name}  [{self.address}]  {force}"


class MicrobitBLE:
    """Session Bluetooth avec un micro:bit.

    S'utilise de préférence comme gestionnaire de contexte asynchrone : la
    déconnexion est alors garantie même si le corps lève une exception.
    """

    def __init__(
        self,
        address: str,
        *,
        name: str = "micro:bit",
        client_factory: Callable[[str], ClientLike] | None = None,
        timeout: float = 20.0,
        pair: bool = False,
    ) -> None:
        self.address = address
        self.name = name
        self._timeout = timeout
        self._pair = pair
        self._client_factory = client_factory or _default_client_factory
        self._client: ClientLike | None = None
        self._services: set[str] = set()
        self._subscriptions: set[str] = set()
        self._uart_buffer = bytearray()

    # -- Découverte --------------------------------------------------------

    @staticmethod
    async def scan(timeout: float = 6.0, *, include_all: bool = False) -> list[Discovered]:
        """Scanne les micro:bit à portée.

        Ne renvoie que les appareils dont le nom annoncé commence par
        « BBC micro:bit », sauf si `include_all` est vrai — pratique pour
        diagnostiquer une carte qui n'annonce pas le nom attendu.
        """
        from bleak import BleakScanner  # import tardif : radio requise

        found = await BleakScanner.discover(timeout=timeout, return_adv=True)
        results: list[Discovered] = []
        for device, adv in found.values():
            name = adv.local_name or device.name or ""
            if include_all or name.startswith(ADVERTISED_NAME_PREFIX):
                results.append(Discovered(name or "(sans nom)", device.address, adv.rssi))
        # Le plus fort signal d'abord : c'est presque toujours la carte visée.
        results.sort(key=lambda d: (d.rssi is None, -(d.rssi or 0)))
        return results

    @classmethod
    async def first(
        cls, timeout: float = 6.0, **kwargs: Any
    ) -> "MicrobitBLE":
        """Renvoie une session **connectée** au micro:bit le plus proche.

        Lève `MicrobitError` si aucune carte n'est visible — avec la liste des
        causes habituelles, qui sont presque toujours côté firmware.
        """
        candidates = await cls.scan(timeout)
        if not candidates:
            raise MicrobitError(
                "aucun micro:bit détecté. Vérifier que : (1) le programme flashé "
                "active l'extension Bluetooth, (2) la carte est alimentée, "
                "(3) elle n'est pas déjà connectée à un autre appareil."
            )
        target = candidates[0]
        session = cls(target.address, name=target.name, **kwargs)
        await session.connect()
        return session

    @classmethod
    async def connect_to(
        cls, address_or_name: str, timeout: float = 10.0, **kwargs: Any
    ) -> "MicrobitBLE":
        """Se connecte par adresse (ou par nom, ex. « BBC micro:bit [vatoz] »)."""
        candidates = await cls.scan(timeout)
        needle = address_or_name.strip().lower()
        for found in candidates:
            if needle in (found.address.lower(), found.name.lower()) or needle in found.name.lower():
                session = cls(found.address, name=found.name, **kwargs)
                await session.connect()
                return session
        # Pas trouvé au scan : on tente quand même l'adresse brute, car sur
        # certaines plateformes une carte déjà appairée ne réapparaît pas.
        session = cls(address_or_name, **kwargs)
        await session.connect()
        return session

    # -- Cycle de vie ------------------------------------------------------

    @property
    def is_connected(self) -> bool:
        return self._client is not None and self._client.is_connected

    async def connect(self) -> None:
        """Établit la connexion et relève les services réellement exposés."""
        if self.is_connected:
            return
        client = self._client_factory(self.address)
        self._client = client
        try:
            await asyncio.wait_for(client.connect(), timeout=self._timeout)
        except asyncio.TimeoutError as exc:
            self._client = None
            raise MicrobitError(
                f"connexion à {self.address} expirée après {self._timeout:g} s"
            ) from exc
        except Exception as exc:  # bleak lève des erreurs très variées
            self._client = None
            raise MicrobitError(f"connexion à {self.address} impossible : {exc}") from exc

        if self._pair:
            await self._try_pair(client)

        self._services = _collect_services(client)
        log.info(
            "connecté à %s (%s) — services : %s",
            self.name,
            self.address,
            ", ".join(sorted(SERVICE_NAMES.get(s, s) for s in self._services)) or "aucun",
        )

    async def disconnect(self) -> None:
        """Coupe proprement les abonnements puis la connexion."""
        client = self._client
        if client is None:
            return
        for uuid in list(self._subscriptions):
            try:
                await client.stop_notify(uuid)
            except Exception:  # la carte peut déjà être partie
                log.debug("désabonnement de %s impossible", uuid, exc_info=True)
        self._subscriptions.clear()
        try:
            await client.disconnect()
        finally:
            self._client = None
            self._services.clear()
            self._uart_buffer.clear()

    async def __aenter__(self) -> "MicrobitBLE":
        await self.connect()
        return self

    async def __aexit__(self, *exc_info: object) -> None:
        await self.disconnect()

    async def _try_pair(self, client: ClientLike) -> None:
        pair = getattr(client, "pair", None)
        if pair is None:
            return
        try:
            await pair()
        except NotImplementedError:
            # macOS appaire à la demande, via le dialogue système.
            log.info("appairage programmatique non supporté par cette plateforme")
        except Exception as exc:
            log.warning("appairage refusé : %s", exc)

    # -- Services disponibles ---------------------------------------------

    @property
    def services(self) -> set[str]:
        """UUIDs des services exposés par la carte connectée."""
        return set(self._services)

    def has(self, service_uuid: str) -> bool:
        """Le micro:bit connecté expose-t-il ce service ?"""
        return service_uuid.lower() in self._services

    def describe_services(self) -> list[str]:
        """Noms lisibles des services disponibles — pour l'affichage."""
        return sorted(SERVICE_NAMES.get(s, s) for s in self._services)

    def _require(self, char_uuid: str) -> str:
        """Vérifie connexion + présence du service, sinon lève une erreur claire."""
        if not self.is_connected:
            raise NotConnected("aucune connexion active — appeler connect() d'abord")
        service = CHAR_SERVICE.get(char_uuid)
        # Certains empilements ne remontent pas la table des services : dans le
        # doute on laisse passer, l'erreur GATT remontera au moment de l'appel.
        if service and self._services and service not in self._services:
            nom = SERVICE_NAMES.get(service, service)
            bloc = SERVICE_MAKECODE_BLOCK.get(service)
            aide = f" — activer « {bloc} » dans le programme MakeCode" if bloc else ""
            raise ServiceUnavailable(
                f"le service « {nom} » n'est pas exposé par ce micro:bit{aide}"
            )
        return char_uuid

    # -- Lectures ----------------------------------------------------------

    async def _read(self, char_uuid: str) -> bytes:
        uuid = self._require(char_uuid)  # vérifie la connexion en premier
        assert self._client is not None  # garanti par _require
        return bytes(await self._client.read_gatt_char(uuid))

    async def read_temperature(self) -> int:
        """Température du processeur, en °C."""
        return decode_temperature(await self._read(Char.TEMPERATURE))

    async def read_accelerometer(self) -> Acceleration:
        """Accélération instantanée, en *g*."""
        return decode_accelerometer(await self._read(Char.ACCELEROMETER_DATA))

    async def read_magnetometer(self) -> MagneticField:
        """Champ magnétique brut sur trois axes."""
        return decode_magnetometer(await self._read(Char.MAGNETOMETER_DATA))

    async def read_bearing(self) -> int:
        """Cap boussole en degrés (nécessite une carte calibrée)."""
        return decode_bearing(await self._read(Char.MAGNETOMETER_BEARING))

    async def read_button(self, which: str = "A") -> ButtonState:
        """État courant du bouton « A » ou « B »."""
        uuid = _button_char(which)
        return decode_button(await self._read(uuid))

    async def read_buttons(self) -> dict[str, ButtonState]:
        """État des deux boutons."""
        return {"A": await self.read_button("A"), "B": await self.read_button("B")}

    async def read_led_matrix(self) -> list[str]:
        """Relit la matrice LED affichée (5 lignes de 5 caractères)."""
        return decode_led_matrix(await self._read(Char.LED_MATRIX))

    async def read_temperature_period(self) -> int:
        """Période de notification de la température, en ms."""
        return decode_period(await self._read(Char.TEMPERATURE_PERIOD))

    # -- Écritures ---------------------------------------------------------

    async def _write(self, char_uuid: str, payload: bytes, *, response: bool = True) -> None:
        """Écrit après passage obligatoire par l'allowlist de `profile.py`."""
        uuid = self._require(char_uuid)
        data = check_write(uuid, payload)
        assert self._client is not None
        await self._client.write_gatt_char(uuid, data, response=response)

    async def show_text(self, text: str) -> None:
        """Fait défiler un texte sur la matrice (20 octets UTF-8 maximum)."""
        await self._write(Char.LED_TEXT, encode_led_text(text))

    async def show(self, rows: Sequence[object]) -> None:
        """Affiche une matrice 5×5 (art ASCII, bitmaps ou booléens)."""
        await self._write(Char.LED_MATRIX, encode_led_matrix(rows))

    async def show_icon(self, name: str) -> None:
        """Affiche une icône du catalogue (`profile.ICONS`)."""
        await self._write(Char.LED_MATRIX, icon(name))

    async def clear(self) -> None:
        """Éteint toutes les LED."""
        await self.show_icon("vide")

    async def set_scrolling_delay(self, milliseconds: int) -> None:
        """Règle la vitesse de défilement du texte (ms par caractère)."""
        await self._write(Char.LED_SCROLLING_DELAY, encode_period(milliseconds))

    async def set_temperature_period(self, milliseconds: int) -> None:
        """Règle la cadence des notifications de température."""
        await self._write(Char.TEMPERATURE_PERIOD, encode_period(milliseconds))

    async def set_accelerometer_period(self, milliseconds: int) -> None:
        """Règle la cadence de l'accéléromètre (1, 2, 5, 10, 20, 80, 160 ou 640 ms)."""
        await self._write(Char.ACCELEROMETER_PERIOD, encode_accelerometer_period(milliseconds))

    async def send_uart(self, message: str | bytes) -> None:
        """Envoie un message au micro:bit via le service UART.

        Écrit sur `RX` (…0003) : c'est bien la caractéristique *reçue* par la
        carte, malgré le nom. Voir l'en-tête de `profile.py`.
        """
        await self._write(Char.UART_RX, encode_uart(message), response=False)

    # -- Notifications -----------------------------------------------------

    async def _subscribe(self, char_uuid: str, handler: Callable[[bytes], Any]) -> None:
        uuid = self._require(char_uuid)

        async def _dispatch(_sender: Any, data: bytearray) -> None:
            try:
                result = handler(bytes(data))
                if inspect.isawaitable(result):
                    await result
            except Exception:
                # Une exception qui remonte dans bleak tue la boucle de
                # notification : on journalise et on continue d'écouter.
                log.exception("erreur dans le rappel de %s", uuid)

        assert self._client is not None
        await self._client.start_notify(uuid, _dispatch)
        self._subscriptions.add(uuid)

    async def watch_temperature(self, callback: Callback, *, period_ms: int | None = None) -> None:
        """Appelle `callback(temperature_c)` à chaque mesure."""
        if period_ms is not None:
            await self.set_temperature_period(period_ms)
        await self._subscribe(Char.TEMPERATURE, lambda raw: callback(decode_temperature(raw)))

    async def watch_accelerometer(
        self, callback: Callback, *, period_ms: int | None = None
    ) -> None:
        """Appelle `callback(Acceleration)` à chaque échantillon."""
        if period_ms is not None:
            await self.set_accelerometer_period(period_ms)
        await self._subscribe(
            Char.ACCELEROMETER_DATA, lambda raw: callback(decode_accelerometer(raw))
        )

    async def watch_buttons(self, callback: Callback) -> None:
        """Appelle `callback(bouton, ButtonState)` sur A **et** B."""
        for label in ("A", "B"):
            uuid = _button_char(label)
            await self._subscribe(
                uuid, lambda raw, b=label: callback(b, decode_button(raw))
            )

    async def watch_bearing(self, callback: Callback) -> None:
        """Appelle `callback(degres)` à chaque mise à jour du cap boussole."""
        await self._subscribe(Char.MAGNETOMETER_BEARING, lambda raw: callback(decode_bearing(raw)))

    async def watch_uart(
        self, callback: Callback, *, delimiter: bytes | None = b"\n", encoding: str | None = "utf-8"
    ) -> None:
        """Écoute les messages envoyés par le micro:bit.

        Le service UART découpe en PDU de 20 octets : par défaut on
        réassemble les lignes sur `\\n` (ce qu'émet `bluetooth.uartWriteLine`
        en MakeCode). Passer `delimiter=None` pour recevoir les fragments
        bruts tels qu'ils arrivent.

        On s'abonne à `TX` (…0002), qui fonctionne en **indicate** et non en
        notify — bleak choisit le bon mode automatiquement.
        """

        def _handle(raw: bytes) -> Any:
            if delimiter is None:
                return callback(raw.decode(encoding, "replace") if encoding else raw)
            self._uart_buffer.extend(raw)
            results = []
            while delimiter in self._uart_buffer:
                line, _, rest = bytes(self._uart_buffer).partition(delimiter)
                self._uart_buffer = bytearray(rest)
                payload = line.decode(encoding, "replace") if encoding else line
                results.append(callback(payload))
            # Un rappel asynchrone renvoie une coroutine par ligne : on les
            # agrège pour que `_dispatch` les attende toutes.
            awaitables = [r for r in results if inspect.isawaitable(r)]
            if awaitables:
                return asyncio.gather(*awaitables)
            return None

        await self._subscribe(Char.UART_TX, _handle)

    async def stop_watching(self, char_uuid: str | None = None) -> None:
        """Se désabonne d'une caractéristique, ou de toutes si `None`."""
        if self._client is None:
            return
        targets = [char_uuid] if char_uuid else list(self._subscriptions)
        for uuid in targets:
            if uuid in self._subscriptions:
                await self._client.stop_notify(uuid)
                self._subscriptions.discard(uuid)


# --------------------------------------------------------------------------
# Utilitaires internes
# --------------------------------------------------------------------------


def _button_char(which: str) -> str:
    key = which.strip().upper()
    if key == "A":
        return Char.BUTTON_A
    if key == "B":
        return Char.BUTTON_B
    raise ValueError(f"bouton inconnu « {which} » — attendu « A » ou « B »")


def _default_client_factory(address: str) -> ClientLike:
    """Fabrique un vrai client bleak (import tardif : radio requise)."""
    from bleak import BleakClient

    return BleakClient(address)  # type: ignore[return-value]


def _collect_services(client: ClientLike) -> set[str]:
    """Relève les UUIDs de services exposés par le client connecté.

    Tolère un client qui n'expose pas de table de services : on renvoie alors
    un ensemble vide, et `_require` laisse passer les appels.
    """
    services = getattr(client, "services", None)
    if services is None:
        return set()
    try:
        items: Iterable[Any] = services.services.values() if hasattr(services, "services") else services
        return {str(s.uuid).lower() for s in items}
    except Exception:
        log.debug("table des services illisible", exc_info=True)
        return set()


__all__ = [
    "MicrobitBLE",
    "Discovered",
    "ClientLike",
    "Acceleration",
    "ButtonState",
    "MagneticField",
    "MicrobitError",
    "NotConnected",
    "ServiceUnavailable",
    "Service",
    "Char",
]
