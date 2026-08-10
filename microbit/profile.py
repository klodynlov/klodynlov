"""Profil Bluetooth du BBC micro:bit — UUIDs, codecs et garde-fous.

Ce module est **stdlib pure** : aucune dépendance BLE, aucun accès matériel.
Tout ce qui relève de « comprendre les octets du micro:bit » vit ici, et se
teste donc sans radio ni carte branchée. Le transport (bleak) vit dans
`ble.py`.

Source : *BBC micro:bit Bluetooth Profile*, Lancaster University —
https://lancaster-university.github.io/microbit-docs/resources/bluetooth/bluetooth_profile.html

Trois pièges du profil, encodés ici une fois pour toutes :

1. **UART inversé.** Le micro:bit nomme ses caractéristiques du point de vue
   de la carte : `TX` (…0002) = micro:bit → client, `RX` (…0003) = client →
   micro:bit. C'est l'inverse de l'assignation Nordic UART habituelle, où
   …0002 est la cible d'écriture.
2. **UART TX est en `indicate`, pas en `notify`.** Le CCCD attend 0x0200 et
   non 0x0100. bleak choisit tout seul le bon mode, mais une implémentation
   qui force « notify » échoue silencieusement.
3. **Les services sont optionnels à la compilation.** Un micro:bit flashé sans
   l'extension Bluetooth n'expose que DFU : l'absence d'un service n'est pas
   une panne radio, c'est un mauvais firmware. Voir `README.md`.
"""

from __future__ import annotations

import struct
from dataclasses import dataclass
from enum import IntEnum
from typing import Callable, Iterable, Sequence

# --------------------------------------------------------------------------
# Erreurs
# --------------------------------------------------------------------------


class MicrobitError(Exception):
    """Erreur de base du connecteur micro:bit."""


class WriteRefused(MicrobitError):
    """Écriture refusée par l'allowlist ou par la validation des bornes.

    Levée **avant** que quoi que ce soit n'atteigne la radio.
    """


class ServiceUnavailable(MicrobitError):
    """Service absent du micro:bit connecté (firmware sans l'extension BLE)."""


class NotConnected(MicrobitError):
    """Opération demandée alors qu'aucune connexion n'est établie."""


# --------------------------------------------------------------------------
# UUIDs
# --------------------------------------------------------------------------

# Les UUID propres au micro:bit partagent tous ce suffixe.
_BASE = "-251d-470a-a062-fa1922dfa9a8"


def _mb(prefix: str) -> str:
    """UUID micro:bit à partir de ses 8 premiers chiffres hexadécimaux."""
    return f"{prefix.lower()}{_BASE}"


# Nordic UART : famille d'UUID distincte.
_NORDIC = "-b5a3-f393-e0a9-e50e24dcca9e"

# Nom annoncé en publicité BLE : « BBC micro:bit [vatoz] ».
ADVERTISED_NAME_PREFIX = "BBC micro:bit"


class Service:
    """UUIDs des services GATT du micro:bit."""

    ACCELEROMETER = _mb("e95d0753")
    MAGNETOMETER = _mb("e95df2d8")
    BUTTON = _mb("e95d9882")
    IO_PIN = _mb("e95d127b")
    LED = _mb("e95dd91d")
    TEMPERATURE = _mb("e95d6100")
    EVENT = _mb("e95d93af")
    DFU_CONTROL = _mb("e95d93b0")
    UART = f"6e400001{_NORDIC}"


class Char:
    """UUIDs des caractéristiques GATT du micro:bit."""

    # Température — sint8 °C (lecture + notify), période uint16 ms.
    TEMPERATURE = _mb("e95d9250")
    TEMPERATURE_PERIOD = _mb("e95d1b25")

    # Accéléromètre — 3 × sint16 little-endian en milli-g.
    ACCELEROMETER_DATA = _mb("e95dca4b")
    ACCELEROMETER_PERIOD = _mb("e95dfb24")

    # Magnétomètre — 3 × sint16, cap boussole uint16 en degrés.
    MAGNETOMETER_DATA = _mb("e95dfb11")
    MAGNETOMETER_PERIOD = _mb("e95d386c")
    MAGNETOMETER_BEARING = _mb("e95d9715")
    MAGNETOMETER_CALIBRATION = _mb("e95db358")

    # Boutons — uint8 (0/1/2).
    BUTTON_A = _mb("e95dda90")
    BUTTON_B = _mb("e95dda91")

    # Affichage LED.
    LED_MATRIX = _mb("e95d7b77")
    LED_TEXT = _mb("e95d93ee")
    LED_SCROLLING_DELAY = _mb("e95d0d2d")

    # UART — attention au sens, voir l'en-tête du module.
    UART_TX = f"6e400002{_NORDIC}"  # micro:bit → client (indicate)
    UART_RX = f"6e400003{_NORDIC}"  # client → micro:bit (write)


#: Service auquel appartient chaque caractéristique — sert à produire un
#: message d'erreur utile quand le firmware n'embarque pas le service.
CHAR_SERVICE: dict[str, str] = {
    Char.TEMPERATURE: Service.TEMPERATURE,
    Char.TEMPERATURE_PERIOD: Service.TEMPERATURE,
    Char.ACCELEROMETER_DATA: Service.ACCELEROMETER,
    Char.ACCELEROMETER_PERIOD: Service.ACCELEROMETER,
    Char.MAGNETOMETER_DATA: Service.MAGNETOMETER,
    Char.MAGNETOMETER_PERIOD: Service.MAGNETOMETER,
    Char.MAGNETOMETER_BEARING: Service.MAGNETOMETER,
    Char.MAGNETOMETER_CALIBRATION: Service.MAGNETOMETER,
    Char.BUTTON_A: Service.BUTTON,
    Char.BUTTON_B: Service.BUTTON,
    Char.LED_MATRIX: Service.LED,
    Char.LED_TEXT: Service.LED,
    Char.LED_SCROLLING_DELAY: Service.LED,
    Char.UART_TX: Service.UART,
    Char.UART_RX: Service.UART,
}

#: Nom lisible de chaque service, pour les diagnostics.
SERVICE_NAMES: dict[str, str] = {
    Service.ACCELEROMETER: "Accéléromètre",
    Service.MAGNETOMETER: "Magnétomètre",
    Service.BUTTON: "Boutons",
    Service.IO_PIN: "Broches E/S",
    Service.LED: "Affichage LED",
    Service.TEMPERATURE: "Température",
    Service.EVENT: "Événements",
    Service.DFU_CONTROL: "DFU (reprogrammation)",
    Service.UART: "UART (série)",
}

#: Extension MakeCode à activer pour obtenir chaque service — c'est la
#: réponse à « pourquoi mon micro:bit n'expose pas ce service ? ».
SERVICE_MAKECODE_BLOCK: dict[str, str] = {
    Service.TEMPERATURE: "bluetooth.startTemperatureService()",
    Service.ACCELEROMETER: "bluetooth.startAccelerometerService()",
    Service.MAGNETOMETER: "bluetooth.startMagnetometerService()",
    Service.BUTTON: "bluetooth.startButtonService()",
    Service.LED: "bluetooth.startLEDService()",
    Service.IO_PIN: "bluetooth.startIOPinService()",
    Service.UART: "bluetooth.startUartService()",
}


# --------------------------------------------------------------------------
# Types de données
# --------------------------------------------------------------------------


class ButtonState(IntEnum):
    """État d'un bouton tel que publié par le Button Service."""

    RELEASED = 0
    PRESSED = 1
    LONG_PRESS = 2


@dataclass(frozen=True)
class Acceleration:
    """Accélération en *g* sur les trois axes."""

    x: float
    y: float
    z: float

    @property
    def magnitude(self) -> float:
        """Norme du vecteur, en *g* (≈ 1.0 au repos)."""
        return (self.x**2 + self.y**2 + self.z**2) ** 0.5

    def __str__(self) -> str:
        return f"x={self.x:+.3f}g y={self.y:+.3f}g z={self.z:+.3f}g"


@dataclass(frozen=True)
class MagneticField:
    """Champ magnétique brut sur trois axes.

    Le profil ne documente pas d'unité pour ces valeurs : on expose donc les
    entiers signés tels quels plutôt que d'inventer une conversion.
    """

    x: int
    y: int
    z: int

    def __str__(self) -> str:
        return f"x={self.x} y={self.y} z={self.z}"


# --------------------------------------------------------------------------
# Décodage (micro:bit → Python)
# --------------------------------------------------------------------------


def _expect_len(data: bytes, size: int, what: str) -> None:
    if len(data) != size:
        raise ValueError(f"{what} : {size} octet(s) attendu(s), {len(data)} reçu(s)")


def decode_temperature(data: bytes) -> int:
    """Température en degrés Celsius (sint8).

    C'est la température du **die du processeur**, pas celle de la pièce :
    elle lit typiquement quelques degrés au-dessus de l'ambiante.
    """
    _expect_len(data, 1, "température")
    return struct.unpack("<b", bytes(data))[0]


def decode_accelerometer(data: bytes) -> Acceleration:
    """Accélération en *g* (3 × sint16 little-endian, en milli-g)."""
    _expect_len(data, 6, "accéléromètre")
    x, y, z = struct.unpack("<hhh", bytes(data))
    return Acceleration(x / 1000, y / 1000, z / 1000)


def decode_magnetometer(data: bytes) -> MagneticField:
    """Champ magnétique brut (3 × sint16 little-endian)."""
    _expect_len(data, 6, "magnétomètre")
    x, y, z = struct.unpack("<hhh", bytes(data))
    return MagneticField(x, y, z)


def decode_bearing(data: bytes) -> int:
    """Cap boussole en degrés depuis le Nord (uint16)."""
    _expect_len(data, 2, "cap")
    return struct.unpack("<H", bytes(data))[0]


def decode_button(data: bytes) -> ButtonState:
    """État d'un bouton : 0 relâché, 1 pressé, 2 appui long."""
    _expect_len(data, 1, "bouton")
    raw = bytes(data)[0]
    try:
        return ButtonState(raw)
    except ValueError as exc:  # firmware non conforme
        raise ValueError(f"état de bouton inconnu : {raw}") from exc


def decode_period(data: bytes) -> int:
    """Période d'échantillonnage en millisecondes (uint16)."""
    _expect_len(data, 2, "période")
    return struct.unpack("<H", bytes(data))[0]


def decode_led_matrix(data: bytes) -> list[str]:
    """Matrice LED sous forme de 5 lignes de 5 caractères (`#` allumé)."""
    _expect_len(data, 5, "matrice LED")
    rows = []
    for octet in bytes(data):
        # bit 4 = LED la plus à gauche, bit 0 = la plus à droite.
        rows.append("".join("#" if octet & (1 << (4 - col)) else "." for col in range(5)))
    return rows


# --------------------------------------------------------------------------
# Encodage (Python → micro:bit)
# --------------------------------------------------------------------------

#: Longueur maximale du texte défilant, imposée par le profil (MTU − 3).
MAX_TEXT_BYTES = 20

#: Seules périodes acceptées par l'accéléromètre, selon le profil.
ACCELEROMETER_PERIODS = (1, 2, 5, 10, 20, 80, 160, 640)

_ON_CHARS = frozenset("#xX*1")
_OFF_CHARS = frozenset(".  0_")


def encode_led_text(text: str) -> bytes:
    """Encode un texte à faire défiler (UTF-8, 20 octets maximum).

    La limite porte sur les **octets**, pas les caractères : « éé » compte
    pour 4. On tronque jamais en silence — un texte trop long est une erreur.
    """
    payload = text.encode("utf-8")
    if len(payload) > MAX_TEXT_BYTES:
        raise ValueError(
            f"texte trop long : {len(payload)} octets UTF-8 pour un maximum de "
            f"{MAX_TEXT_BYTES} (« {text} »)"
        )
    return payload


def _encode_row(row: object, index: int) -> int:
    """Convertit une ligne (str, int ou itérable de booléens) en bitmap 5 bits."""
    if isinstance(row, int):
        if not 0 <= row <= 0b11111:
            raise ValueError(f"ligne {index} : bitmap hors bornes 0–31 ({row})")
        return row

    if isinstance(row, str):
        cells: Sequence[object] = row
    elif isinstance(row, Iterable):
        cells = list(row)
    else:
        raise TypeError(f"ligne {index} : type non supporté ({type(row).__name__})")

    if len(cells) != 5:
        raise ValueError(f"ligne {index} : 5 colonnes attendues, {len(cells)} reçues")

    bitmap = 0
    for col, cell in enumerate(cells):
        if isinstance(cell, str):
            if cell in _ON_CHARS:
                on = True
            elif cell in _OFF_CHARS:
                on = False
            else:
                raise ValueError(f"ligne {index}, colonne {col} : caractère « {cell} » inconnu")
        else:
            on = bool(cell)
        if on:
            bitmap |= 1 << (4 - col)  # bit 4 = colonne la plus à gauche
    return bitmap


def encode_led_matrix(rows: Sequence[object]) -> bytes:
    """Encode une matrice 5×5 en 5 octets.

    Accepte des lignes en art ASCII (`"#.#.#"`), des bitmaps entiers, ou des
    itérables de booléens. Octet 0 = ligne du haut, bit 4 = colonne de gauche.
    """
    if len(rows) != 5:
        raise ValueError(f"5 lignes attendues, {len(rows)} reçues")
    return bytes(_encode_row(row, i) for i, row in enumerate(rows))


def encode_period(milliseconds: int) -> bytes:
    """Encode une période d'échantillonnage (uint16 little-endian)."""
    if not isinstance(milliseconds, int) or isinstance(milliseconds, bool):
        raise TypeError("la période doit être un entier de millisecondes")
    if not 0 <= milliseconds <= 0xFFFF:
        raise ValueError(f"période hors bornes 0–65535 ms ({milliseconds})")
    return struct.pack("<H", milliseconds)


def encode_accelerometer_period(milliseconds: int) -> bytes:
    """Comme `encode_period`, mais restreint aux valeurs admises par le profil."""
    if milliseconds not in ACCELEROMETER_PERIODS:
        raise ValueError(
            f"période accéléromètre invalide ({milliseconds} ms) — valeurs admises : "
            + ", ".join(str(p) for p in ACCELEROMETER_PERIODS)
        )
    return encode_period(milliseconds)


def encode_uart(payload: str | bytes) -> bytes:
    """Encode un message UART (20 octets maximum par PDU)."""
    data = payload.encode("utf-8") if isinstance(payload, str) else bytes(payload)
    if not data:
        raise ValueError("message UART vide")
    if len(data) > MAX_TEXT_BYTES:
        raise ValueError(
            f"message UART trop long : {len(data)} octets pour un maximum de {MAX_TEXT_BYTES}"
        )
    return data


# --------------------------------------------------------------------------
# Allowlist d'écriture
# --------------------------------------------------------------------------
#
# Même principe que les actionneurs d'EdgeSense : ce qui peut être *écrit* sur
# la carte est énuméré explicitement, avec ses bornes. Une caractéristique
# absente de cette table est refusée avant d'atteindre la radio — y compris
# DFU, dont l'écriture déclencherait une reprogrammation à distance.


@dataclass(frozen=True)
class WriteRule:
    """Règle d'écriture : nom lisible, taille attendue, validateur optionnel."""

    name: str
    size: int | None  # None = taille variable
    max_size: int | None = None
    validate: Callable[[bytes], None] | None = None


def _check_accelerometer_period(data: bytes) -> None:
    period = decode_period(data)
    if period not in ACCELEROMETER_PERIODS:
        raise ValueError(f"période accéléromètre invalide ({period} ms)")


WRITE_ALLOWLIST: dict[str, WriteRule] = {
    Char.LED_TEXT: WriteRule("texte LED", size=None, max_size=MAX_TEXT_BYTES),
    Char.LED_MATRIX: WriteRule("matrice LED", size=5),
    Char.LED_SCROLLING_DELAY: WriteRule("délai de défilement", size=2),
    Char.TEMPERATURE_PERIOD: WriteRule("période température", size=2),
    Char.ACCELEROMETER_PERIOD: WriteRule(
        "période accéléromètre", size=2, validate=_check_accelerometer_period
    ),
    Char.MAGNETOMETER_PERIOD: WriteRule("période magnétomètre", size=2),
    Char.UART_RX: WriteRule("message UART", size=None, max_size=MAX_TEXT_BYTES),
}


def check_write(uuid: str, payload: bytes) -> bytes:
    """Valide une écriture et renvoie la charge utile, ou lève `WriteRefused`.

    Unique porte d'entrée des écritures dans `ble.py` : allowlist d'abord,
    bornes ensuite. Aucun octet ne part vers la carte sans passer par ici.
    """
    rule = WRITE_ALLOWLIST.get(uuid.lower())
    if rule is None:
        raise WriteRefused(
            f"écriture refusée : la caractéristique {uuid} n'est pas dans l'allowlist"
        )

    data = bytes(payload)
    if rule.size is not None and len(data) != rule.size:
        raise WriteRefused(
            f"écriture refusée ({rule.name}) : {rule.size} octet(s) attendu(s), "
            f"{len(data)} fourni(s)"
        )
    if rule.max_size is not None and len(data) > rule.max_size:
        raise WriteRefused(
            f"écriture refusée ({rule.name}) : {len(data)} octets pour un maximum "
            f"de {rule.max_size}"
        )
    if not data:
        raise WriteRefused(f"écriture refusée ({rule.name}) : charge utile vide")
    if rule.validate is not None:
        try:
            rule.validate(data)
        except ValueError as exc:
            raise WriteRefused(f"écriture refusée ({rule.name}) : {exc}") from exc
    return data


# --------------------------------------------------------------------------
# Icônes prêtes à l'emploi
# --------------------------------------------------------------------------

ICONS: dict[str, tuple[str, str, str, str, str]] = {
    "coeur": (".#.#.", "#####", "#####", ".###.", "..#.."),
    "sourire": (".....", ".#.#.", ".....", "#...#", ".###."),
    "triste": (".....", ".#.#.", ".....", ".###.", "#...#"),
    "oui": (".....", "....#", "...#.", "#.#..", ".#..."),
    "non": ("#...#", ".#.#.", "..#..", ".#.#.", "#...#"),
    "carre": ("#####", "#...#", "#...#", "#...#", "#####"),
    "plein": ("#####", "#####", "#####", "#####", "#####"),
    "vide": (".....", ".....", ".....", ".....", "....."),
    "fleche_haut": ("..#..", ".###.", "#.#.#", "..#..", "..#.."),
    "fleche_bas": ("..#..", "..#..", "#.#.#", ".###.", "..#.."),
}


def icon(name: str) -> bytes:
    """Encode une icône du catalogue `ICONS`."""
    try:
        rows = ICONS[name]
    except KeyError:
        raise ValueError(
            f"icône inconnue « {name} » — disponibles : " + ", ".join(sorted(ICONS))
        ) from None
    return encode_led_matrix(rows)
