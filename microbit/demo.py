"""Démonstration en ligne de commande du connecteur micro:bit.

    python3 -m microbit.demo scan
    python3 -m microbit.demo infos
    python3 -m microbit.demo texte "Bonjour"
    python3 -m microbit.demo icone coeur
    python3 -m microbit.demo suivre --duree 30
    python3 -m microbit.demo boucle --consigne 24

Chaque commande accepte `--simule` : tout tourne alors contre le micro:bit
simulé de `fake.py`, sans carte ni dongle Bluetooth.
"""

from __future__ import annotations

import argparse
import asyncio
import sys
import time
from typing import Any

from .ble import MicrobitBLE
from .profile import ICONS, ButtonState, MicrobitError, Service

ADRESSE_SIMULEE = "FA:KE:00:00:00:01"


def _horodatage() -> str:
    return time.strftime("%H:%M:%S")


_ETATS = {
    ButtonState.RELEASED: "relâché",
    ButtonState.PRESSED: "pressé",
    ButtonState.LONG_PRESS: "appui long",
}


def _formater_boutons(etats: dict[str, ButtonState]) -> str:
    return "  ".join(f"{nom} : {_ETATS[etat]}" for nom, etat in etats.items())


async def _ouvrir(args: argparse.Namespace) -> MicrobitBLE:
    """Ouvre une session, réelle ou simulée selon les arguments."""
    if args.simule:
        from .fake import fake_factory

        session = MicrobitBLE(
            ADRESSE_SIMULEE, name="micro:bit simulé", client_factory=fake_factory()
        )
        await session.connect()
        return session

    if args.adresse:
        return await MicrobitBLE.connect_to(args.adresse, timeout=args.timeout)
    return await MicrobitBLE.first(timeout=args.timeout)


# --------------------------------------------------------------------------
# Commandes
# --------------------------------------------------------------------------


async def cmd_scan(args: argparse.Namespace) -> int:
    """Liste les micro:bit à portée."""
    if args.simule:
        print(f"micro:bit simulé  [{ADRESSE_SIMULEE}]  -42 dBm")
        return 0

    print(f"Scan pendant {args.timeout:g} s…")
    trouves = await MicrobitBLE.scan(args.timeout, include_all=args.tout)
    if not trouves:
        print("Aucun micro:bit détecté.")
        print(
            "\nÀ vérifier, dans l'ordre :\n"
            "  1. le programme flashé active-t-il l'extension Bluetooth ?\n"
            "  2. la carte est-elle alimentée (USB ou piles) ?\n"
            "  3. est-elle déjà connectée à un autre appareil ?\n"
            "     (une carte connectée n'apparaît plus dans les scans)\n"
            "  4. relancer avec --tout pour voir tous les appareils BLE."
        )
        return 1

    for appareil in trouves:
        print(f"  {appareil}")
    return 0


async def cmd_infos(args: argparse.Namespace) -> int:
    """Connexion, inventaire des services, et un relevé de chaque capteur."""
    async with await _ouvrir(args) as mb:
        print(f"Connecté à {mb.name}  [{mb.address}]")
        print("\nServices exposés :")
        for nom in mb.describe_services():
            print(f"  · {nom}")

        print("\nRelevés :")
        for etiquette, service, lecture, formate in (
            ("température", Service.TEMPERATURE, mb.read_temperature, lambda v: f"{v} °C"),
            ("accéléromètre", Service.ACCELEROMETER, mb.read_accelerometer, str),
            ("cap boussole", Service.MAGNETOMETER, mb.read_bearing, lambda v: f"{v}°"),
            ("boutons", Service.BUTTON, mb.read_buttons, _formater_boutons),
        ):
            if not mb.has(service):
                print(f"  · {etiquette:<14} — service absent")
                continue
            try:
                valeur = await lecture()
            except MicrobitError as exc:
                print(f"  · {etiquette:<14} — {exc}")
            else:
                print(f"  · {etiquette:<14} {formate(valeur)}")
    return 0


async def cmd_texte(args: argparse.Namespace) -> int:
    """Fait défiler un texte sur la matrice LED."""
    async with await _ouvrir(args) as mb:
        if args.delai:
            await mb.set_scrolling_delay(args.delai)
        await mb.show_text(args.message)
        print(f"Affiché sur {mb.name} : « {args.message} »")
        # Laisser le temps au texte de défiler avant de couper la connexion.
        await asyncio.sleep(min(10.0, 0.4 * len(args.message) + 1))
    return 0


async def cmd_icone(args: argparse.Namespace) -> int:
    """Affiche une icône du catalogue."""
    if args.nom not in ICONS:
        print(f"Icône inconnue « {args.nom} ». Disponibles : {', '.join(sorted(ICONS))}")
        return 2
    async with await _ouvrir(args) as mb:
        await mb.show_icon(args.nom)
        print(f"Icône « {args.nom} » affichée :")
        for ligne in ICONS[args.nom]:
            print("   " + " ".join("●" if c == "#" else "·" for c in ligne))
        await asyncio.sleep(1.0)
    return 0


async def cmd_suivre(args: argparse.Namespace) -> int:
    """Affiche en direct les événements de la carte."""
    async with await _ouvrir(args) as mb:
        print(f"Écoute de {mb.name} pendant {args.duree:g} s — Ctrl+C pour arrêter.\n")

        if mb.has(Service.TEMPERATURE):
            await mb.watch_temperature(
                lambda c: print(f"[{_horodatage()}] température  {c} °C"),
                period_ms=args.periode,
            )
        if mb.has(Service.BUTTON):
            await mb.watch_buttons(
                lambda bouton, etat: print(
                    f"[{_horodatage()}] bouton {bouton}     {_ETATS[etat]}"
                )
            )
        if mb.has(Service.UART):
            await mb.watch_uart(lambda ligne: print(f"[{_horodatage()}] uart         « {ligne} »"))

        if args.simule:
            # Un peu de vie côté simulateur, pour que la démo montre quelque chose.
            asyncio.create_task(_animer_simulation(mb))

        try:
            await asyncio.sleep(args.duree)
        except asyncio.CancelledError:
            pass
    return 0


async def _animer_simulation(session: MicrobitBLE) -> None:
    """Déclenche des événements sur la carte simulée pendant `suivre`."""
    fausse_carte: Any = session._client  # accès délibéré au simulateur
    await asyncio.sleep(1.5)
    await fausse_carte.press("A")
    await asyncio.sleep(1.5)
    await fausse_carte.push_uart(b"bonjour depuis la carte\n")
    await asyncio.sleep(1.5)
    await fausse_carte.press("B", long=True)


async def cmd_boucle(args: argparse.Namespace) -> int:
    """Boucle *percevoir → décider → agir* sur du matériel réel.

    Le micro:bit fournit la mesure (température) **et** l'action (afficheur) :
    c'est la même boucle qu'EdgeSense M0, mais avec un capteur physique au
    bout de la radio au lieu d'une pièce simulée.
    """
    async with await _ouvrir(args) as mb:
        if not mb.has(Service.TEMPERATURE) or not mb.has(Service.LED):
            print(
                "Cette démonstration exige les services Température et Affichage LED.\n"
                "Activer « bluetooth.startTemperatureService() » et "
                "« bluetooth.startLEDService() » dans le programme MakeCode."
            )
            return 2

        consigne = args.consigne
        print(
            f"Consigne : {consigne} °C — la carte affiche ↑ s'il fait trop froid, "
            f"↓ s'il fait trop chaud, ✓ dans la plage.\n"
        )
        dernier_etat: str | None = None

        async def sur_mesure(celsius: int) -> None:
            nonlocal dernier_etat
            # Décider.
            if celsius < consigne - 1:
                etat, icone = "trop froid", "fleche_haut"
            elif celsius > consigne + 1:
                etat, icone = "trop chaud", "fleche_bas"
            else:
                etat, icone = "dans la plage", "oui"
            # Agir — uniquement quand la décision change, pour ne pas saturer
            # la liaison BLE d'écritures identiques.
            marqueur = ""
            if etat != dernier_etat:
                await mb.show_icon(icone)
                dernier_etat = etat
                marqueur = "  → afficheur mis à jour"
            print(f"[{_horodatage()}] {celsius} °C  ·  {etat}{marqueur}")

        await mb.watch_temperature(sur_mesure, period_ms=args.periode)
        await asyncio.sleep(args.duree)
        await mb.clear()
    return 0


# --------------------------------------------------------------------------
# Point d'entrée
# --------------------------------------------------------------------------


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python3 -m microbit.demo",
        description="Connecter un BBC micro:bit en Bluetooth et le piloter.",
    )
    parser.add_argument("--simule", action="store_true", help="utiliser le micro:bit simulé")
    parser.add_argument("--adresse", help="adresse ou nom de la carte visée")
    parser.add_argument(
        "--timeout", type=float, default=6.0, help="durée du scan, en secondes (défaut : 6)"
    )
    sous = parser.add_subparsers(dest="commande", required=True)

    p_scan = sous.add_parser("scan", help="lister les micro:bit à portée")
    p_scan.add_argument("--tout", action="store_true", help="montrer tous les appareils BLE")
    p_scan.set_defaults(fonction=cmd_scan)

    sous.add_parser("infos", help="services exposés et relevé des capteurs").set_defaults(
        fonction=cmd_infos
    )

    p_texte = sous.add_parser("texte", help="faire défiler un texte sur l'afficheur")
    p_texte.add_argument("message", help="texte à afficher (20 octets UTF-8 maximum)")
    p_texte.add_argument("--delai", type=int, help="délai de défilement, en ms")
    p_texte.set_defaults(fonction=cmd_texte)

    p_icone = sous.add_parser("icone", help="afficher une icône")
    p_icone.add_argument("nom", help=f"parmi : {', '.join(sorted(ICONS))}")
    p_icone.set_defaults(fonction=cmd_icone)

    p_suivre = sous.add_parser("suivre", help="afficher les événements en direct")
    p_suivre.add_argument("--duree", type=float, default=30.0, help="durée d'écoute (s)")
    p_suivre.add_argument("--periode", type=int, default=2000, help="période température (ms)")
    p_suivre.set_defaults(fonction=cmd_suivre)

    p_boucle = sous.add_parser("boucle", help="boucle percevoir → décider → agir")
    p_boucle.add_argument("--consigne", type=int, default=24, help="température visée (°C)")
    p_boucle.add_argument("--duree", type=float, default=60.0, help="durée de la boucle (s)")
    p_boucle.add_argument("--periode", type=int, default=2000, help="période de mesure (ms)")
    p_boucle.set_defaults(fonction=cmd_boucle)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        return asyncio.run(args.fonction(args))
    except KeyboardInterrupt:
        print("\nInterrompu.")
        return 130
    except MicrobitError as exc:
        print(f"Erreur : {exc}", file=sys.stderr)
        return 1
    except ImportError:
        print(
            "bleak n'est pas installé — « pip install -r microbit/requirements.txt », "
            "ou relancer avec --simule.",
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
