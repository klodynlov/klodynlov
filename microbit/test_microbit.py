"""Tests du connecteur micro:bit — aucun matériel requis.

    python3 -m unittest microbit.test_microbit -v   # depuis la racine du dépôt

Deux catégories :

* **codecs** (`profile.py`) — pure arithmétique d'octets, vérifiée contre les
  exemples du profil Bluetooth officiel ;
* **session** (`ble.py`) — pilotée par le micro:bit simulé de `fake.py`, ce
  qui couvre la connexion, les abonnements et l'allowlist d'écriture sans
  radio.
"""

from __future__ import annotations

import asyncio
import struct
import unittest

from microbit.ble import MicrobitBLE
from microbit.fake import FakeMicrobitClient
from microbit.profile import (
    ACCELEROMETER_PERIODS,
    ButtonState,
    Char,
    NotConnected,
    Service,
    ServiceUnavailable,
    WriteRefused,
    check_write,
    decode_accelerometer,
    decode_bearing,
    decode_button,
    decode_led_matrix,
    decode_temperature,
    encode_accelerometer_period,
    encode_led_matrix,
    encode_led_text,
    encode_period,
    icon,
)


class TestCodecs(unittest.TestCase):
    """Décodage/encodage conformes au profil Bluetooth du micro:bit."""

    def test_temperature_est_signee(self):
        # Exemple du profil : 0x19 = 25 °C.
        self.assertEqual(decode_temperature(b"\x19"), 25)
        # Un octet non signé donnerait 255 : le froid doit rester négatif.
        self.assertEqual(decode_temperature(b"\xff"), -1)
        self.assertEqual(decode_temperature(b"\xec"), -20)

    def test_temperature_refuse_mauvaise_taille(self):
        with self.assertRaises(ValueError):
            decode_temperature(b"\x19\x00")

    def test_accelerometre_signe_little_endian_en_g(self):
        # 3 × sint16 LE en milli-g : au repos, à plat, z ≈ -1 g.
        data = struct.pack("<hhh", 0, 0, -1000)
        accel = decode_accelerometer(data)
        self.assertAlmostEqual(accel.z, -1.0)
        self.assertAlmostEqual(accel.magnitude, 1.0, places=6)

        # Le décodage doit être signé : 0xFC18 = -1000, pas 64536.
        self.assertAlmostEqual(decode_accelerometer(b"\x18\xfc" * 3).x, -1.0)

    def test_boutons(self):
        self.assertIs(decode_button(b"\x00"), ButtonState.RELEASED)
        self.assertIs(decode_button(b"\x01"), ButtonState.PRESSED)
        self.assertIs(decode_button(b"\x02"), ButtonState.LONG_PRESS)
        with self.assertRaises(ValueError):
            decode_button(b"\x07")

    def test_cap_boussole_non_signe(self):
        self.assertEqual(decode_bearing(struct.pack("<H", 359)), 359)

    def test_texte_led_limite_en_octets_pas_en_caracteres(self):
        self.assertEqual(encode_led_text("Bonjour"), b"Bonjour")
        self.assertEqual(len(encode_led_text("é" * 10)), 20)  # 10 caractères = 20 octets
        with self.assertRaises(ValueError):
            encode_led_text("é" * 11)
        with self.assertRaises(ValueError):
            encode_led_text("x" * 21)

    def test_matrice_bit4_est_la_colonne_de_gauche(self):
        # Le profil est explicite : bit 4 = première LED de la ligne.
        self.assertEqual(encode_led_matrix(["#....", ".....", ".....", ".....", "....."]),
                         bytes([0b10000, 0, 0, 0, 0]))
        self.assertEqual(encode_led_matrix([".....", ".....", ".....", ".....", "....#"]),
                         bytes([0, 0, 0, 0, 0b00001]))
        # Octet 0 = ligne du haut.
        self.assertEqual(encode_led_matrix(["#####", ".....", ".....", ".....", "....."])[0], 0b11111)

    def test_matrice_accepte_bitmaps_et_booleens(self):
        par_bitmap = encode_led_matrix([0b10101, 0, 0, 0, 0])
        par_bool = encode_led_matrix([[1, 0, 1, 0, 1], [0] * 5, [0] * 5, [0] * 5, [0] * 5])
        self.assertEqual(par_bitmap, par_bool)

    def test_matrice_aller_retour(self):
        motif = ["#.#.#", ".###.", "#...#", ".....", "##..#"]
        self.assertEqual(decode_led_matrix(encode_led_matrix(motif)), motif)

    def test_matrice_refuse_dimensions_invalides(self):
        with self.assertRaises(ValueError):
            encode_led_matrix(["#####"] * 4)
        with self.assertRaises(ValueError):
            encode_led_matrix(["####"] * 5)
        with self.assertRaises(ValueError):
            encode_led_matrix(["#?#.#"] + ["....."] * 4)

    def test_icones(self):
        self.assertEqual(len(icon("coeur")), 5)
        self.assertEqual(icon("vide"), bytes(5))
        self.assertEqual(icon("plein"), bytes([0b11111] * 5))
        with self.assertRaises(ValueError):
            icon("licorne")

    def test_periode_uint16_little_endian(self):
        self.assertEqual(encode_period(640), b"\x80\x02")
        with self.assertRaises(ValueError):
            encode_period(70000)

    def test_periode_accelerometre_restreinte(self):
        for valide in ACCELEROMETER_PERIODS:
            self.assertEqual(len(encode_accelerometer_period(valide)), 2)
        with self.assertRaises(ValueError):
            encode_accelerometer_period(100)  # absent de la liste du profil


class TestAllowlist(unittest.TestCase):
    """Rien ne part vers la carte sans passer par l'allowlist."""

    def test_accepte_une_ecriture_legitime(self):
        self.assertEqual(check_write(Char.LED_TEXT, b"Salut"), b"Salut")

    def test_refuse_une_caracteristique_hors_liste(self):
        # La température est en lecture seule côté profil.
        with self.assertRaises(WriteRefused):
            check_write(Char.TEMPERATURE, b"\x30")

    def test_refuse_le_service_dfu(self):
        # Écrire sur DFU déclencherait une reprogrammation à distance.
        with self.assertRaises(WriteRefused) as ctx:
            check_write(Service.DFU_CONTROL, b"\x01")
        self.assertIn("allowlist", str(ctx.exception))

    def test_refuse_une_taille_invalide(self):
        with self.assertRaises(WriteRefused):
            check_write(Char.LED_MATRIX, b"\x00" * 4)
        with self.assertRaises(WriteRefused):
            check_write(Char.LED_TEXT, b"x" * 21)

    def test_refuse_une_charge_vide(self):
        with self.assertRaises(WriteRefused):
            check_write(Char.LED_TEXT, b"")

    def test_refuse_une_periode_accelerometre_hors_profil(self):
        with self.assertRaises(WriteRefused):
            check_write(Char.ACCELEROMETER_PERIOD, struct.pack("<H", 100))
        self.assertEqual(check_write(Char.ACCELEROMETER_PERIOD, struct.pack("<H", 160)),
                         struct.pack("<H", 160))


class TestSession(unittest.IsolatedAsyncioTestCase):
    """Session complète contre le micro:bit simulé."""

    def setUp(self):
        self.fake: FakeMicrobitClient | None = None

    def _session(self, **kwargs) -> MicrobitBLE:
        def factory(address: str) -> FakeMicrobitClient:
            self.fake = FakeMicrobitClient(address, **kwargs)
            return self.fake

        return MicrobitBLE("FA:KE:00:00:00:01", client_factory=factory)

    async def test_connexion_et_services(self):
        async with self._session() as mb:
            self.assertTrue(mb.is_connected)
            self.assertTrue(mb.has(Service.TEMPERATURE))
            self.assertIn("Température", mb.describe_services())
        self.assertFalse(mb.is_connected)

    async def test_lectures(self):
        async with self._session(temperature=27) as mb:
            self.assertEqual(await mb.read_temperature(), 27)
            self.assertAlmostEqual((await mb.read_accelerometer()).z, -1.0)
            self.assertEqual(await mb.read_bearing(), 187)
            self.assertIs((await mb.read_buttons())["A"], ButtonState.RELEASED)

    async def test_affichage(self):
        async with self._session() as mb:
            await mb.show_text("Bonjour")
            await mb.show_icon("coeur")
            self.assertEqual(self.fake.text_shown, ["Bonjour"])
            self.assertEqual(self.fake.display()[0], ".#.#.")
            await mb.clear()
            self.assertEqual(self.fake.matrix, bytes(5))

    async def test_ecriture_refusee_avant_la_radio(self):
        """Une écriture invalide ne doit jamais atteindre le client BLE."""
        async with self._session() as mb:
            with self.assertRaises(ValueError):
                await mb.show_text("beaucoup trop long pour l'afficheur")
            with self.assertRaises(ValueError):
                await mb.set_accelerometer_period(100)
            self.assertEqual(self.fake.writes, [])  # rien n'est parti

    async def test_service_absent_donne_un_message_actionnable(self):
        """Firmware sans le service température : erreur claire, pas un timeout."""
        async with self._session(services=(Service.LED, Service.DFU_CONTROL)) as mb:
            with self.assertRaises(ServiceUnavailable) as ctx:
                await mb.read_temperature()
            message = str(ctx.exception)
            self.assertIn("Température", message)
            self.assertIn("bluetooth.startTemperatureService()", message)
            # Le service présent, lui, fonctionne.
            await mb.show_icon("oui")

    async def test_operation_sans_connexion(self):
        mb = self._session()
        with self.assertRaises(NotConnected):
            await mb.read_temperature()

    async def test_notification_boutons(self):
        recu: list[tuple[str, ButtonState]] = []
        async with self._session() as mb:
            await mb.watch_buttons(lambda bouton, etat: recu.append((bouton, etat)))
            await self.fake.press("A")
            await self.fake.press("B", long=True)
        self.assertEqual(recu[0], ("A", ButtonState.PRESSED))
        self.assertEqual(recu[1], ("A", ButtonState.RELEASED))
        self.assertEqual(recu[2], ("B", ButtonState.LONG_PRESS))

    async def test_rappel_asynchrone_supporte(self):
        recu: list[int] = []

        async def sur_mesure(valeur: int) -> None:
            await asyncio.sleep(0)
            recu.append(valeur)

        async with self._session(temperature=21) as mb:
            await mb.watch_temperature(sur_mesure, period_ms=10)
            await asyncio.sleep(0.05)
        self.assertTrue(recu, "aucune notification de température reçue")

    async def test_une_exception_de_rappel_ne_tue_pas_l_abonnement(self):
        appels: list[str] = []

        def rappel(bouton: str, etat: ButtonState) -> None:
            appels.append(bouton)
            if len(appels) == 1:
                raise RuntimeError("boum")

        async with self._session() as mb:
            await mb.watch_buttons(rappel)
            with self.assertLogs("microbit.ble", level="ERROR"):
                await self.fake.press("A")
            await self.fake.press("B")
        self.assertGreaterEqual(len(appels), 3)  # on écoute toujours après l'erreur

    async def test_uart_ecrit_sur_rx_et_ecoute_sur_tx(self):
        """Le micro:bit inverse les rôles Nordic : ce test verrouille le sens."""
        recu: list[str] = []
        async with self._session(echo_uart=False) as mb:
            await mb.watch_uart(recu.append)
            await mb.send_uart("ping")
            await self.fake.push_uart(b"pong\n")

        # Écriture : sur RX (…0003), la caractéristique que la carte *reçoit*.
        uuids_ecrits = [uuid for uuid, _ in self.fake.writes]
        self.assertEqual(uuids_ecrits, [Char.UART_RX])
        self.assertEqual(self.fake.uart_received, [b"ping"])
        # Lecture : sur TX (…0002), en indicate.
        self.assertEqual(recu, ["pong"])

    async def test_uart_reassemble_les_lignes_coupees_en_pdu(self):
        """Un message de plus de 20 octets arrive fragmenté : on recolle."""
        recu: list[str] = []
        long_message = "a" * 25 + "|fin"
        async with self._session(echo_uart=False) as mb:
            await mb.watch_uart(recu.append)
            await self.fake.push_uart(long_message.encode() + b"\n")
            self.assertEqual(recu, [long_message])

            # Une ligne incomplète reste en tampon jusqu'au délimiteur.
            await self.fake.push_uart(b"partiel")
            self.assertEqual(len(recu), 1)
            await self.fake.push_uart(b"...suite\n")
            self.assertEqual(recu[1], "partiel...suite")

    async def test_uart_brut_sans_delimiteur(self):
        morceaux: list[str] = []
        async with self._session(echo_uart=False) as mb:
            await mb.watch_uart(morceaux.append, delimiter=None)
            await self.fake.push_uart(b"x" * 25)
        self.assertEqual([len(m) for m in morceaux], [20, 5])

    async def test_deconnexion_annule_les_abonnements(self):
        async with self._session() as mb:
            await mb.watch_buttons(lambda *_: None)
            self.assertTrue(self.fake._notify)
        self.assertFalse(self.fake._notify)

    async def test_reglage_des_periodes(self):
        async with self._session() as mb:
            await mb.set_accelerometer_period(160)
            await mb.set_temperature_period(2000)
            await mb.set_scrolling_delay(90)
            self.assertEqual(self.fake.periods[Char.ACCELEROMETER_PERIOD], 160)
            self.assertEqual(self.fake.periods[Char.TEMPERATURE_PERIOD], 2000)
            self.assertEqual(await mb.read_temperature_period(), 2000)


if __name__ == "__main__":
    unittest.main(verbosity=2)
