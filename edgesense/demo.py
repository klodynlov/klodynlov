#!/usr/bin/env python3
"""
EdgeSense — démonstration de la boucle fermée (M0), SANS MCP ni matériel.

Un « agent » thermostat minimal pilote le cœur `EdgeSense` : il lit la
température, décide, actionne le chauffage, et observe l'effet au tour suivant.
C'est la preuve que la boucle *percevoir → décider → agir → percevoir* tient.

    python3 demo.py

Le vrai agent (LLM local via MCP) remplacera la politique codée en dur ci-dessous
par du raisonnement ; l'interface (`read_sensor` / `set_actuator`) est identique.
"""

from __future__ import annotations

import argparse

from devices import EdgeSense


def run(steps: int = 16, low: float = 20.0, high: float = 22.0,
        seed: int = 42) -> EdgeSense:
    core = EdgeSense(seed=seed)
    print(f"Cible : maintenir {low}–{high} °C\n")
    print("  t   temp    chauffage  action")
    print("  --  ------  ---------  ---------------")
    for step in range(steps):
        reading = core.read_sensor("temp-1")
        temp = reading["value"]

        # --- politique d'agent (sera remplacée par le LLM) ----------------- #
        if temp < low and not core.is_on("heater-1"):
            core.set_actuator("heater-1", "on")
            action = "→ chauffage ON"
        elif temp > high and core.is_on("heater-1"):
            core.set_actuator("heater-1", "off")
            action = "→ chauffage OFF"
        else:
            action = ""

        heat = "ON " if core.is_on("heater-1") else "off"
        print(f"  {step:02d}  {temp:5.2f}   {heat:>7}    {action}")

    print(f"\nActions journalisées : {len(core.journal)}")
    print(f"Intégrité du journal : {'OK' if core.verify_journal() else 'CORROMPU'}")
    return core


def main() -> None:
    parser = argparse.ArgumentParser(description="Démo boucle fermée EdgeSense.")
    parser.add_argument("--steps", type=int, default=16)
    parser.add_argument("--low", type=float, default=20.0)
    parser.add_argument("--high", type=float, default=22.0)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    run(steps=args.steps, low=args.low, high=args.high, seed=args.seed)


if __name__ == "__main__":
    main()
