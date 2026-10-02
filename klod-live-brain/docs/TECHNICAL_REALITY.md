# TECHNICAL_REALITY.md — audit de faisabilité de la V0

> **Phase 0 du cahier des charges.** Avant d'écrire du firmware, on établit ce
> qui est *réellement* vrai, sourcé et — quand c'est possible — mesuré. La règle
> §0 : **réalité technique avant prose.** Une fonctionnalité n'est pas
> « implémentable » parce qu'elle est plausible.

**Date de l'audit :** 2026-08-23 · **Portée :** chaîne V0
`MIDI IN → capture → GrooveDNA → apply_groove → MIDI OUT`.

## Légende des statuts

| Statut | Sens |
|---|---|
| ✅ **PROUVÉ** | Vérifié par la documentation *et* par du code/test exécuté. |
| 🟢 **FAISABLE** | Briques disponibles et documentées, intégration crédible — **pas encore construite/mesurée ici**. |
| 🟡 **EXPÉRIMENTAL** | Nécessite un prototype ou un benchmark sur matériel avant tout engagement. |
| ⛔ **NON VIABLE** | À abandonner dans l'état actuel. |

**Ce qui a été prouvé *dans cette session* :** uniquement le **moteur GrooveDNA**
(couche « musical »), en Python stdlib pur, par **35 tests verts** + une démo
exécutable (`host/groovedna/`). Aucun Teensy n'a été flashé ni mesuré ici :
tout ce qui touche au matériel est donc au mieux **FAISABLE** (documenté), et sa
performance temps réel reste **EXPÉRIMENTALE** jusqu'à mesure. Cette honnêteté
est le cœur de l'exercice.

---

## 1. Tableau d'audit — capacités de la V0

| Fonction | Statut | Preuve | Risque principal |
|---|---|---|---|
| **Moteur GrooveDNA** (capture, apply, morph, format versionné) | ✅ PROUVÉ | `host/groovedna/` — 35 tests unittest verts, démo §38 exécutée ; offsets mesurés, reproductibles, aucune note perdue | Aucun sur le fond ; reste à alimenter avec de **vrais** MIDI (styles) |
| **Horodatage haute résolution** (Teensy) | 🟢 FAISABLE | `ARM_DWT_CYCCNT` : compteur 32 bits @ 600 MHz ⇒ **1,667 ns/tick**, débordement ~7,16 s (à cumuler sur 64 bits). Doit être déverrouillé sur Cortex-M7 | Débordement mal géré ; jitter réel ≠ résolution (à mesurer) |
| **MIDI IN — DIN 5 broches** (UART) | 🟢 FAISABLE | Arduino MIDI Library (FortySevenEffects, **MIT**), UART matériel @ 31250 bauds ; réception **octet par octet**, déterministe | Latence série constante ~1 ms (≠ jitter, voir §3) |
| **MIDI IN — USB Device** | 🟡 EXPÉRIMENTAL | `usbMIDI` intégré à Teensyduino, mais l'USB **groupe** les messages par intervalle de polling : +1 intervalle de délai (~2,2 ms observé), fiabilité longue durée signalée variable | **Risque n°1** : le batching USB écrase le microtiming de notes quasi simultanées. À **mesurer** |
| **MIDI IN/OUT — USB Host** (contrôleur/MPC branché *sur* le Teensy) | 🟢 FAISABLE | `USBHost_t36` (PaulStoffregen), classe `MIDIDevice`, inclus dans Teensyduino ; exemples fournis | Doc « lacunaire », bugs connus (hub, envoi) ; à valider par contrôleur |
| **Scheduler temps réel** (file d'événements horodatés) | 🟢 FAISABLE | `IntervalTimer`/PIT + boucle lisant le DWT ; allocation statique ; RAM abondante | Jitter/overrun **non mesurés** — cœur du travail à venir |
| **Mémoire** (files, stockage grooves) | ✅ PROUVÉ (fiche technique) | i.MX RT1062 : **1024 KB RAM** (512 KB *tightly-coupled*, 0 wait-state), **8 MB Flash**, 32 canaux DMA | Aucun pour la V0 |
| **Pont Mac ↔ Teensy** (plan de contrôle, non temps réel) | 🟢 FAISABLE | USB Serial / RawHID / USB MIDI côté carte ; `mido`+`python-rtmidi` (RtMidi, CoreMIDI/IAC) côté Mac | Framing/CRC/ACK à définir (cahier §26) |
| **Sortie MIDI** (DIN + USB) | 🟢 FAISABLE | Mêmes bibliothèques ; `send`/`usbMIDI.send*` | Ordonnancement précis = le vrai défi (scheduler) |

---

## 2. L'horodatage : ce qui est vrai

Le Teensy 4.1 (NXP i.MX RT1062, ARM Cortex-M7 @ 600 MHz) expose le compteur de
cycles du DWT :

- `ARM_DWT_CYCCNT` s'incrémente **à chaque cycle CPU**. À 600 MHz, un cycle vaut
  **1,667 ns**. La résolution d'horodatage n'est donc pas le facteur limitant.
- Compteur **32 bits** ⇒ débordement en `2³² / 600·10⁶ ≈ 7,16 s`. Pour des
  mesures longues, il faut l'accumuler dans une variable 64 bits (lue assez
  souvent). *Piège encodé pour plus tard : ne jamais soustraire deux
  timestamps 32 bits bruts sans gérer le wrap.*
- Sur Cortex-M7, l'accès au DWT doit être **déverrouillé**
  (`DWT->LAR = 0xC5ACCE55`, `TRCENA` dans `DEMCR`) — sinon le compteur reste à
  zéro. C'est la cause n°1 des « mon chrono ne compte pas » sur M7.

**Conclusion :** horodater une note à la microseconde près est une capacité
**documentée et standard**. Ce qui reste à prouver, c'est le **jitter de bout en
bout** (transport + interruption + scheduler), pas la résolution du compteur.

---

## 3. Le vrai risque n°1 : jitter de capture (DIN vs USB)

C'est la décision d'architecture la plus importante de la V0, et elle est
contre-intuitive.

**DIN MIDI (UART, 31250 bauds).** Chaque octet = 10 bits = **320 µs** ; un
Note On de 3 octets ≈ **960 µs** sur le fil. Cette latence est **constante**.
Or GrooveDNA ne mesure que des **décalages relatifs** (note vs grille, un
instrument vs un autre) : *une latence constante s'annule dans la soustraction*.
Seule la **variance** (jitter) corrompt le microtiming. Le jitter d'une réception
UART sur Teensy est celui de l'interruption RX — bien inférieur à la
milliseconde. **La DIN est donc le chemin de capture à faible jitter.**

**USB MIDI.** L'USB **regroupe** les messages par intervalle de polling. Deux
notes jouées à 2 ms d'écart peuvent être livrées dans **le même paquet** et
lues avec un timestamp quasi identique : le microtiming est perdu *avant* qu'on
ait pu l'horodater. La documentation forum PJRC relève un délai additionnel
d'~1 intervalle de polling (**~2,2 ms**) et des soucis de fiabilité en session
longue selon l'hôte.

**Décision V0 :** la **capture haute précision passe par la DIN** ; l'USB MIDI
reste supporté pour le confort mais son jitter doit être **mesuré** avant tout
usage de capture (statut EXPÉRIMENTAL). C'est exactement le genre d'affirmation
que le cahier des charges interdit de « masquer par de la prose » (§30, §34).

---

## 4. Ce qui est ⛔ NON VIABLE (dans l'état actuel)

Repris de la liste d'erreurs à ne jamais commettre (§34), avec la raison
technique :

| Idée | Pourquoi NON VIABLE | Alternative viable |
|---|---|---|
| **LLM sur le Teensy** | Un LLM utile pèse des Go ; le Teensy a 1 MB de RAM. Ordres de grandeur. | LLM côté Mac ; le Teensy exécute (architecture §1). |
| **Séparation de sources (Demucs) sur Teensy** | Modèle + calcul hors de portée d'un MCU. | Analyse lourde côté Mac. |
| **API « profonde » Akai MPC / API Logic Pro** | Aucune API publique documentée ne l'expose. Le supposer, c'est inventer (§20, §22). | MIDI / MIDI Clock / PC / CC / fichiers — voir doc d'intégration. |
| **« MCP pilote le DAW »** sans adaptateur réel | MCP est un protocole ; sans backend qui parle à REAPER/Logic, c'est de la prose. | MCP → adaptateur hôte → **ReaScript/OSC** (REAPER, FAISABLE) ; Logic plus limité. |
| **Beat tracker audio « parfait »** | Robustesse non démontrée sur de la vraie musique. | Classé **EXPÉRIMENTAL** ; à isoler et prouver (cahier §12). |

Le beat tracking audio n'est pas *non viable*, il est **expérimental** : on ne
l'annoncera pas fonctionnel tant qu'il n'aura pas été testé sur de vrais titres.

---

## 5. Registre des risques

| # | Risque | Gravité | Mitigation | Statut |
|---|---|---|---|---|
| 1 | **Jitter de capture USB** écrase le microtiming | Élevée | Capture via **DIN** ; mesurer le jitter USB avant de s'y fier | Ouvert (à mesurer) |
| 2 | **Débordement** du compteur de cycles 32 bits (~7,16 s) | Moyenne | Accumuler sur 64 bits, lu régulièrement | Connu, encodable |
| 3 | **Push temps réel impossible via MCP** (req/réponse) | Élevée | MCP = plan de contrôle uniquement ; LLM **hors** de la boucle critique (§17) ; vrai temps réel = bus/scheduler sur Teensy | Ouvert — **même verrou que micro:bit / EdgeSense** |
| 4 | **Allocations dynamiques** dans le chemin critique | Moyenne | Files bornées, allocation statique (style §33) | Discipline |
| 5 | **Overruns** de file en surcharge | Moyenne | Files bornées + **compteurs d'événements perdus** dès le départ (observabilité §28) | À instrumenter |
| 6 | **Dérive d'horloge** MIDI Clock (24 PPQN) entre appareils | Moyenne | Choisir un maître d'horloge ; mesurer la dérive | Ouvert |
| 7 | **Grooves stylistiques inventés** (clichés) | Élevée (crédibilité) | N'apprendre les styles que depuis de **vrais fichiers MIDI** (§7) | Discipline — rien d'inventé pour l'instant |

Le risque n°3 est la **continuité directe** des projets `microbit/` et EdgeSense
de ce dépôt : MCP ne peut pas réveiller un agent en millisecondes. La réponse est
la même — le réflexe temps réel vit au plus près du matériel (ici le Teensy), le
LLM prépare, il ne joue pas dans la boucle.

---

## 6. Verdict de la Phase 0

- La **couche musicale** (GrooveDNA) est **PROUVÉE**, indépendamment du
  matériel. Le pari du projet — « peut-on représenter et transférer un feel de
  façon mesurable et reproductible ? » — est **gagné sur le fond** (voir
  `GROOVEDNA_SPEC.md` et les 35 tests).
- La **couche réflexe** (Teensy : timing, MIDI, scheduler) est **FAISABLE** sur
  la base d'une documentation solide. Un **squelette de référence** existe
  désormais (`../firmware/`), *grounded* sur les vraies API ; sa seule pièce
  indépendante du matériel — la **file bornée** — est **testée en natif** (g++).
  Mais sa qualité temps réel (**jitter, overruns, latence**) reste **à mesurer**
  — c'est le prochain jalon, et il exige du matériel + des benchmarks
  (`BENCHMARKS.md`, à produire).
- Rien n'autorise encore à parler d'IA, de MPC, de DAW « pilotés » : ces couches
  attendent leurs backends réels (§37, §38 : *ne pas passer à l'IA* tant que la
  chaîne n'est pas bouclée sur matériel).

---

## Sources

- [Teensy 4.1 — fiche produit, PJRC](https://www.pjrc.com/store/teensy41.html)
- [Using USB MIDI with Teensy — PJRC](https://www.pjrc.com/teensy/td_midi.html)
- [MIDI Library (DIN) sur Teensy — PJRC](https://www.pjrc.com/teensy/td_libs_MIDI.html)
- [Arduino MIDI Library — FortySevenEffects (licence MIT)](https://github.com/FortySevenEffects/arduino_midi_library)
- [USBHost_t36 — PaulStoffregen](https://github.com/PaulStoffregen/USBHost_t36)
- [Teensy Forum — compteur nanoseconde / ARM_DWT_CYCCNT](https://forum.pjrc.com/index.php?threads/t-4-1-nanosecond-counter.70539/)
- [Cycle counting on ARM Cortex-M with DWT — MCU on Eclipse](https://mcuoneclipse.com/2017/01/30/cycle-counting-on-arm-cortex-m-with-dwt/)
- [Teensy Forum — latence/fiabilité USB MIDI](https://forum.pjrc.com/index.php?threads/issue-with-usb-midi-failing-over-time-when-using-usbmidi-sendrealtime.53371/)
- [python-rtmidi — SpotlightKid](https://spotlightkid.github.io/python-rtmidi/rtmidi.html)
- [mido — backend RtMidi](https://mido.readthedocs.io/en/latest/backends/rtmidi.html)
