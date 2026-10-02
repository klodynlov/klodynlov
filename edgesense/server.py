#!/usr/bin/env python3
"""
EdgeSense — serveur MCP (M0).

Expose la passerelle `EdgeSense` (capteur + actionneur simulés) à des agents via
le Model Context Protocol. Un agent local (Klody, ou Claude Desktop branché sur
un modèle Ollama/MLX) peut alors *lire* les capteurs et *actionner* les relais.

Nécessite le SDK MCP officiel :

    pip install -r requirements.txt      # (mcp>=1.2)

Lancement (transport stdio, pour Claude Desktop / un client MCP local) :

    python3 server.py

Le cœur métier vit dans `devices.py` ; ce fichier n'est qu'un adaptateur MCP.
"""

from __future__ import annotations

import json

from mcp.server.fastmcp import FastMCP

from devices import DeviceError, EdgeSense

mcp = FastMCP("EdgeSense")
core = EdgeSense()


@mcp.tool()
def list_devices() -> list[dict]:
    """Liste les appareils exposés (capteurs et actionneurs) et leur état."""
    return core.list_devices()


@mcp.tool()
def read_sensor(device_id: str) -> dict:
    """Lit la valeur courante d'un capteur (ex. `temp-1`)."""
    try:
        return core.read_sensor(device_id)
    except DeviceError as exc:
        return {"error": str(exc)}


@mcp.tool()
def set_actuator(device_id: str, state: str) -> dict:
    """Change l'état d'un actionneur (ex. `heater-1` → `on`/`off`).

    Refuse tout appareil hors catalogue ou tout état hors allowlist, et journalise
    l'action dans un registre append-only à chaînage de hachage.
    """
    try:
        return core.set_actuator(device_id, state)
    except DeviceError as exc:
        return {"error": str(exc)}


@mcp.resource("edgesense://state")
def state() -> str:
    """Instantané complet de la passerelle (appareils + monde simulé)."""
    return json.dumps(core.snapshot(), ensure_ascii=False, indent=2)


if __name__ == "__main__":
    mcp.run()
