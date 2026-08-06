"""Connecteur Bluetooth Low Energy pour le BBC micro:bit.

Percevoir (température, accéléromètre, boussole, boutons) et agir (afficheur
LED, UART) sur une carte micro:bit depuis Python, en local et sans cloud.

    import asyncio
    from microbit import MicrobitBLE

    async def main():
        async with await MicrobitBLE.first() as mb:
            print(await mb.read_temperature(), "°C")
            await mb.show_icon("coeur")

    asyncio.run(main())

Organisation :

* `profile` — UUIDs, codecs et allowlist d'écriture (**stdlib pure**) ;
* `ble`     — session BLE au-dessus de bleak ;
* `fake`    — micro:bit simulé, pour tester et développer sans matériel ;
* `server`  — exposition MCP, pour qu'un agent pilote la carte ;
* `demo`    — démonstration en ligne de commande.
"""

from .ble import Discovered, MicrobitBLE
from .profile import (
    Acceleration,
    ButtonState,
    Char,
    MagneticField,
    MicrobitError,
    NotConnected,
    Service,
    ServiceUnavailable,
    WriteRefused,
    ICONS,
)

__all__ = [
    "MicrobitBLE",
    "Discovered",
    "Acceleration",
    "MagneticField",
    "ButtonState",
    "Service",
    "Char",
    "ICONS",
    "MicrobitError",
    "NotConnected",
    "ServiceUnavailable",
    "WriteRefused",
]

__version__ = "0.1.0"
