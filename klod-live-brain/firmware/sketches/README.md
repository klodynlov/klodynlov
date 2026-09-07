# `firmware/sketches/` — croquis de bring-up (Arduino IDE)

Deux croquis autonomes pour **valider le matériel** avant d'attaquer le MIDI.
⚠️ Croquis de référence, **non flashés ni mesurés dans ce dépôt** : à valider
sur la carte. La logique est standard.

| Croquis | Rôle |
|---|---|
| `i2c_scan/` | Liste les adresses I²C présentes sur le bus 18/19. **À lancer en premier.** |
| `klod_lcd_hello/` | Affiche « KLOD Live Brain » + uptime + battement sur le LCD 2004. |

## Prérequis Arduino IDE

- **Teensyduino** installé (support carte Teensy).
- Carte **« Teensy 4.1 »**, *USB Type* **« Serial »** (suffisant pour ces tests).
- Pour le LCD : bibliothèque **`hd44780`** (Bill Perry) — *Croquis → Inclure une
  bibliothèque → Gérer les bibliothèques → « hd44780 » → Installer*. Elle
  **auto-détecte** l'adresse (0x27/0x3F) et le câblage du backpack.

## Marche à suivre

1. **Câble l'écran** en 3,3 V (voir `../README.md` et le schéma) : `VCC→3V`,
   `GND→G`, `SDA→18`, `SCL→19`. Jamais 5 V.
2. **Flashe `i2c_scan`**, ouvre le Moniteur série (115200). Tu dois voir
   `0x27` **ou** `0x3F` (le LCD) et `0x0A` (le codec audio). Rien ? Vérifie le
   câblage avant d'aller plus loin.
3. **Flashe `klod_lcd_hello`.** L'écran affiche l'identité KLOD ; tourne le
   **potentiomètre bleu** si le contraste est trop faible. L'astérisque en haut
   à droite clignote = tout tourne.

Ensuite seulement : câblage du **MIDI DIN** (broches 0/1) et affichage des
vrais compteurs `in / out / dropped / queue_hwm` (cf. `../src/metrics/metrics.h`).
