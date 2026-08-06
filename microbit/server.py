"""Serveur MCP — expose un micro:bit à un agent.

    pip install -r microbit/requirements.txt
    python3 -m microbit.server            # carte réelle
    python3 -m microbit.server --simule   # micro:bit simulé, sans matériel

L'agent obtient des outils pour *percevoir* (température, accéléromètre,
boussole, boutons) et *agir* (afficheur LED, UART) — la carte devient un
périphérique parmi d'autres dans la boîte à outils.

**Note de conception — le temps réel.** MCP est un protocole requête/réponse :
un serveur ne peut pas réveiller l'agent quand un bouton est pressé. Plutôt
que de prétendre le contraire, on s'abonne aux notifications BLE dès la
connexion et on les accumule dans un tampon borné que l'agent vient relever
avec `evenements_recents`. C'est suffisant pour « que s'est-il passé ? », pas
pour une réaction en millisecondes — ce qui reste le point à valider avec un
vrai bus pub/sub (EdgeSense M2).
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import sys
import time
from collections import deque
from typing import Any

from .ble import MicrobitBLE
from .profile import ICONS, ButtonState, MicrobitError, Service

try:
    # SDK MCP 2.x
    from mcp.server.mcpserver import MCPServer as _Serveur
except ImportError:  # pragma: no cover - dépend de l'environnement
    try:
        # SDK MCP 1.x — même surface de décorateurs (.tool / .resource / .run)
        from mcp.server.fastmcp import FastMCP as _Serveur  # type: ignore[assignment]
    except ImportError:
        print(
            "Le paquet « mcp » est requis pour lancer le serveur :\n"
            "    pip install -r microbit/requirements.txt",
            file=sys.stderr,
        )
        raise

mcp = _Serveur("microbit")

#: Session unique — un serveur MCP pilote une carte à la fois.
_session: MicrobitBLE | None = None
_verrou = asyncio.Lock()
#: Tampon borné des notifications reçues depuis la connexion.
_evenements: deque[dict[str, Any]] = deque(maxlen=200)
#: Fabrique de client injectée par `--simule`.
_fabrique: Any = None


def _requiert_session() -> MicrobitBLE:
    if _session is None or not _session.is_connected:
        raise MicrobitError("aucun micro:bit connecté — appeler d'abord « connecter »")
    return _session


#: Libellés français des états de bouton, pour une API homogène côté agent.
_ETAT_FR = {
    ButtonState.RELEASED: "relâché",
    ButtonState.PRESSED: "pressé",
    ButtonState.LONG_PRESS: "appui long",
}


def _noter(type_evenement: str, **details: Any) -> None:
    maintenant = time.time()
    _evenements.append(
        {
            "horodatage": maintenant,
            "heure": time.strftime("%H:%M:%S", time.localtime(maintenant)),
            "type": type_evenement,
            **details,
        }
    )


# --------------------------------------------------------------------------
# Connexion
# --------------------------------------------------------------------------


@mcp.tool()
async def scanner(duree_s: float = 6.0) -> list[dict[str, Any]]:
    """Liste les micro:bit à portée Bluetooth.

    Args:
        duree_s: durée du scan en secondes.
    """
    if _fabrique is not None:
        return [{"nom": "micro:bit simulé", "adresse": "FA:KE:00:00:00:01", "rssi": -42}]
    trouves = await MicrobitBLE.scan(duree_s)
    return [{"nom": d.name, "adresse": d.address, "rssi": d.rssi} for d in trouves]


@mcp.tool()
async def connecter(adresse: str | None = None, duree_scan_s: float = 6.0) -> dict[str, Any]:
    """Se connecte à un micro:bit et s'abonne à ses événements.

    Args:
        adresse: adresse ou nom de la carte. Si omis, prend la plus proche.
        duree_scan_s: durée du scan préalable, en secondes.
    """
    global _session
    async with _verrou:
        if _session is not None and _session.is_connected:
            return {
                "statut": "déjà connecté",
                "nom": _session.name,
                "adresse": _session.address,
                "services": _session.describe_services(),
            }

        if _fabrique is not None:
            _session = MicrobitBLE(
                "FA:KE:00:00:00:01", name="micro:bit simulé", client_factory=_fabrique
            )
            await _session.connect()
        elif adresse:
            _session = await MicrobitBLE.connect_to(adresse, timeout=duree_scan_s)
        else:
            _session = await MicrobitBLE.first(timeout=duree_scan_s)

        _evenements.clear()
        await _abonner(_session)
        _noter("connexion", adresse=_session.address, nom=_session.name)
        return {
            "statut": "connecté",
            "nom": _session.name,
            "adresse": _session.address,
            "services": _session.describe_services(),
        }


async def _abonner(session: MicrobitBLE) -> None:
    """Abonne le tampon d'événements à ce que la carte sait pousser."""
    if session.has(Service.BUTTON):
        await session.watch_buttons(
            lambda bouton, etat: _noter("bouton", bouton=bouton, etat=_ETAT_FR[etat])
        )
    if session.has(Service.UART):
        await session.watch_uart(lambda ligne: _noter("uart", message=ligne))


@mcp.tool()
async def deconnecter() -> dict[str, str]:
    """Ferme la connexion Bluetooth."""
    global _session
    async with _verrou:
        if _session is None:
            return {"statut": "aucune connexion"}
        await _session.disconnect()
        _session = None
        _noter("déconnexion")
        return {"statut": "déconnecté"}


@mcp.tool()
async def etat() -> dict[str, Any]:
    """État courant de la connexion et services disponibles."""
    if _session is None or not _session.is_connected:
        return {"connecte": False}
    return {
        "connecte": True,
        "nom": _session.name,
        "adresse": _session.address,
        "services": _session.describe_services(),
        "evenements_en_attente": len(_evenements),
    }


# --------------------------------------------------------------------------
# Percevoir
# --------------------------------------------------------------------------


@mcp.tool()
async def lire_temperature() -> dict[str, Any]:
    """Température mesurée par le processeur du micro:bit, en °C.

    C'est la température du composant, quelques degrés au-dessus de
    l'ambiante : utile pour une tendance, pas pour une mesure d'ambiance
    précise.
    """
    return {"celsius": await _requiert_session().read_temperature()}


@mcp.tool()
async def lire_accelerometre() -> dict[str, Any]:
    """Accélération sur les trois axes, en *g* (≈ 1 g au repos)."""
    accel = await _requiert_session().read_accelerometer()
    return {"x_g": accel.x, "y_g": accel.y, "z_g": accel.z, "norme_g": round(accel.magnitude, 3)}


@mcp.tool()
async def lire_boussole() -> dict[str, Any]:
    """Cap boussole en degrés depuis le Nord (carte calibrée requise)."""
    return {"degres": await _requiert_session().read_bearing()}


@mcp.tool()
async def lire_boutons() -> dict[str, str]:
    """État courant des boutons A et B."""
    etats = await _requiert_session().read_buttons()
    return {nom: _ETAT_FR[etat] for nom, etat in etats.items()}


@mcp.tool()
async def evenements_recents(limite: int = 20, vider: bool = False) -> list[dict[str, Any]]:
    """Relève les événements accumulés depuis la connexion (boutons, UART).

    MCP ne permet pas au serveur de réveiller l'agent : ces événements sont
    mis en tampon et doivent être relevés. Le tampon garde les 200 derniers.

    Args:
        limite: nombre maximum d'événements renvoyés, du plus récent au plus ancien.
        vider: vider le tampon après lecture.
    """
    _requiert_session()
    recents = list(_evenements)[-limite:][::-1]
    if vider:
        _evenements.clear()
    return recents


# --------------------------------------------------------------------------
# Agir
# --------------------------------------------------------------------------


@mcp.tool()
async def afficher_texte(texte: str) -> dict[str, str]:
    """Fait défiler un texte sur la matrice LED (20 octets UTF-8 maximum).

    Args:
        texte: message à afficher.
    """
    await _requiert_session().show_text(texte)
    _noter("affichage", texte=texte)
    return {"statut": "affiché", "texte": texte}


@mcp.tool()
async def afficher_icone(nom: str) -> dict[str, Any]:
    """Affiche une icône prédéfinie sur la matrice LED.

    Args:
        nom: icône parmi coeur, sourire, triste, oui, non, carre, plein, vide,
            fleche_haut, fleche_bas.
    """
    await _requiert_session().show_icon(nom)
    _noter("affichage", icone=nom)
    return {"statut": "affiché", "icone": nom, "motif": list(ICONS[nom])}


@mcp.tool()
async def afficher_motif(lignes: list[str]) -> dict[str, Any]:
    """Affiche un motif 5×5 sur la matrice LED.

    Args:
        lignes: 5 chaînes de 5 caractères, « # » pour allumé et « . » pour éteint.
    """
    await _requiert_session().show(lignes)
    _noter("affichage", motif=lignes)
    return {"statut": "affiché", "motif": lignes}


@mcp.tool()
async def effacer_affichage() -> dict[str, str]:
    """Éteint toutes les LED."""
    await _requiert_session().clear()
    _noter("affichage", motif="vide")
    return {"statut": "effacé"}


@mcp.tool()
async def envoyer_uart(message: str) -> dict[str, str]:
    """Envoie un message au programme embarqué via le service UART.

    Args:
        message: texte à transmettre (20 octets maximum par envoi).
    """
    await _requiert_session().send_uart(message)
    _noter("uart_envoi", message=message)
    return {"statut": "envoyé", "message": message}


# --------------------------------------------------------------------------
# Ressource
# --------------------------------------------------------------------------


@mcp.resource("microbit://state")
async def etat_ressource() -> str:
    """Instantané lisible de la carte connectée."""
    if _session is None or not _session.is_connected:
        return "Aucun micro:bit connecté."

    lignes = [
        f"micro:bit : {_session.name}  [{_session.address}]",
        "Services  : " + ", ".join(_session.describe_services()),
    ]
    if _session.has(Service.TEMPERATURE):
        lignes.append(f"Température : {await _session.read_temperature()} °C")
    if _session.has(Service.BUTTON):
        etats = await _session.read_buttons()
        lignes.append("Boutons   : " + "  ".join(f"{n} : {_ETAT_FR[e]}" for n, e in etats.items()))
    if _session.has(Service.LED):
        lignes.append("Afficheur :")
        lignes += ["    " + ligne for ligne in await _session.read_led_matrix()]
    lignes.append(f"Événements en tampon : {len(_evenements)}")
    return "\n".join(lignes)


def main(argv: list[str] | None = None) -> int:
    global _fabrique
    parser = argparse.ArgumentParser(
        prog="python3 -m microbit.server", description="Serveur MCP pour BBC micro:bit."
    )
    parser.add_argument(
        "--simule", action="store_true", help="piloter un micro:bit simulé, sans matériel"
    )
    args = parser.parse_args(argv)

    # En transport stdio, stdout porte le protocole MCP : tout message de
    # journal doit partir sur stderr, sous peine de corrompre la session.
    logging.basicConfig(stream=sys.stderr, level=logging.INFO, format="%(name)s: %(message)s")

    if args.simule:
        from .fake import fake_factory

        _fabrique = fake_factory()
        print("Serveur MCP micro:bit — mode simulé.", file=sys.stderr)

    mcp.run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
