#!/usr/bin/env python3
"""
Tests du cœur EdgeSense — bibliothèque standard uniquement (`unittest`).

    python3 -m unittest test_devices -v
    # ou, si pytest est installé :
    pytest test_devices.py
"""

from __future__ import annotations

import unittest

from devices import DeviceError, EdgeSense


class TestReadSensor(unittest.TestCase):
    def test_reading_structure(self) -> None:
        core = EdgeSense(seed=1)
        r = core.read_sensor("temp-1")
        self.assertEqual(r["device_id"], "temp-1")
        self.assertEqual(r["type"], "temperature")
        self.assertEqual(r["unit"], "°C")
        self.assertIsInstance(r["value"], float)
        self.assertIn("ts", r)

    def test_unknown_sensor_rejected(self) -> None:
        core = EdgeSense(seed=1)
        with self.assertRaises(DeviceError):
            core.read_sensor("does-not-exist")


class TestActuatorGuards(unittest.TestCase):
    def test_unknown_actuator_rejected(self) -> None:
        core = EdgeSense(seed=1)
        with self.assertRaises(DeviceError):
            core.set_actuator("relay-99", "on")

    def test_state_outside_allowlist_rejected(self) -> None:
        core = EdgeSense(seed=1)
        with self.assertRaises(DeviceError):
            core.set_actuator("heater-1", "explode")

    def test_valid_command_applies(self) -> None:
        core = EdgeSense(seed=1)
        res = core.set_actuator("heater-1", "on")
        self.assertEqual(res["state"], "on")
        self.assertEqual(res["previous"], "off")
        self.assertTrue(core.is_on("heater-1"))


class TestClosedLoop(unittest.TestCase):
    def test_heater_raises_temperature(self) -> None:
        """Avec le chauffage ON, la température monte sur la durée."""
        core = EdgeSense(seed=7)
        start = core.read_sensor("temp-1")["value"]
        core.set_actuator("heater-1", "on")
        for _ in range(20):
            last = core.read_sensor("temp-1")["value"]
        self.assertGreater(last, start)

    def test_ambient_cooling(self) -> None:
        """Sans chauffage, la température tend vers l'ambiant (18 °C)."""
        core = EdgeSense(seed=7)
        core.room.temp = 30.0
        for _ in range(50):
            last = core.read_sensor("temp-1")["value"]
        self.assertLess(last, 22.0)


class TestJournal(unittest.TestCase):
    def test_journal_grows_and_verifies(self) -> None:
        core = EdgeSense(seed=1)
        core.set_actuator("heater-1", "on")
        core.set_actuator("heater-1", "off")
        self.assertEqual(len(core.journal), 2)
        self.assertTrue(core.verify_journal())

    def test_tampering_is_detected(self) -> None:
        core = EdgeSense(seed=1)
        core.set_actuator("heater-1", "on")
        core.journal[0]["state"] = "off"  # falsification
        self.assertFalse(core.verify_journal())


if __name__ == "__main__":
    unittest.main()
