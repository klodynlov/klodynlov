"""Rendu local HTML → PNG / PDF, avec le Google Chrome installé sur le Mac (mode sans écran).

`pictos/apercu.py` vise un Chromium Linux absent du Mac. Ici on cherche, dans l'ordre :
la variable `EVEIL_CHROME`, Google Chrome (/Applications), Chromium, puis un Chromium Linux.
Pas de réseau, rien à installer. Sur macOS, Chrome sans écran peut rester ouvert après avoir
écrit son fichier : on attend que le fichier soit écrit et stable, puis on le ferme.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

CANDIDATS = (
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell",
)


def navigateur() -> str | None:
    env = os.environ.get("EVEIL_CHROME")
    if env and Path(env).exists():
        return env
    for c in CANDIDATS:
        if Path(c).exists():
            return c
    for nom in ("google-chrome", "chromium", "chromium-browser"):
        p = shutil.which(nom)
        if p:
            return p
    return None


def _lancer(args: list[str], sortie: Path, delai: float = 120.0) -> None:
    if sortie.exists():
        sortie.unlink()
    with tempfile.TemporaryDirectory(prefix="eveil-chrome-") as profil:
        cmd = [args[0], "--headless=new", "--disable-gpu", "--no-first-run", "--no-default-browser-check",
               "--disable-extensions", f"--user-data-dir={profil}", *args[1:]]
        proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        debut, taille, stable = time.monotonic(), -1, 0
        try:
            while time.monotonic() - debut < delai:
                if proc.poll() is not None and sortie.exists():
                    break
                if sortie.exists():
                    t = sortie.stat().st_size
                    stable = stable + 1 if (t == taille and t > 0) else 0
                    taille = t
                    if stable >= 4:
                        break
                time.sleep(0.25)
            else:
                raise TimeoutError(f"le navigateur n'a pas écrit {sortie}")
        finally:
            if proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    proc.kill()


def png(page: Path, sortie: Path, largeur: int, hauteur: int) -> Path:
    nav = navigateur()
    if nav is None:
        raise FileNotFoundError("aucun Chrome/Chromium local : ouvrir le HTML à la main")
    _lancer([nav, "--hide-scrollbars", "--force-device-scale-factor=1", f"--window-size={largeur},{hauteur}",
             f"--screenshot={sortie}", page.resolve().as_uri()], sortie)
    return sortie


def pdf(page: Path, sortie: Path) -> Path:
    nav = navigateur()
    if nav is None:
        raise FileNotFoundError("aucun Chrome/Chromium local : ouvrir le HTML à la main")
    _lancer([nav, "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={sortie}",
             page.resolve().as_uri()], sortie)
    return sortie
