# `firmware/` — couche réflexe Teensy 4.1 (squelette de référence)

> **Statut : 🟢 FAISABLE, non mesuré.** Ce dossier est un **squelette de
> référence**. À une exception près (la file bornée), rien ici n'a été
> **compilé, flashé ni mesuré** dans ce dépôt : je n'ai pas de Teensy sous la
> main. Le code est *grounded* sur les vraies API (compteur de cycles DWT,
> `usbMIDI`, bibliothèque MIDI FortySevenEffects) — voir
> [`../docs/TECHNICAL_REALITY.md`](../docs/TECHNICAL_REALITY.md) — mais il attend
> son épreuve du feu : le **matériel** et les **benchmarks**.

Cette honnêteté est le cœur du projet (§0 : *réalité technique avant prose*).
On n'annonce « faible latence » ou « temps réel » qu'avec des **chiffres** (§30).

---

## Ce qui est vérifié ici — et ce qui ne l'est pas

| Élément | Vérifié dans ce dépôt ? | Comment |
|---|---|---|
| **File d'événements bornée** (`queue/event_queue.h`) | ✅ **oui** | logique pure, **test natif** (g++), 15045 vérifications vertes |
| `MidiEvent` (`midi/midi_event.h`) | ✅ compile en natif | utilisé par le test |
| Horloge DWT (`timing/cycle_clock.*`) | ❌ non | compile sous Teensyduino seulement ; **jitter à mesurer** |
| E/S MIDI (`midi/midi_io.*`) | ❌ non | idem ; correspondances d'API marquées « à vérifier » |
| Passthrough (`main.cpp`) | ❌ non | premier jalon matériel : §29 Test 1 |

### Tester la file (sans Teensy)

```bash
cd klod-live-brain/firmware
c++ -std=c++17 -Isrc -Wall -Wextra test/test_event_queue.cpp -o /tmp/tq && /tmp/tq
```

Vérifie : FIFO, capacité `N-1`, **débordement qui ne perd rien** (compté, §28),
enroulement sur 10 000 cycles, ligne de flottaison, `reset`.

---

## Ce que fait ce firmware (jalon V0)

Une boucle **percevoir → (file) → agir** minimale :

```
MIDI IN (DIN + USB) ──▶ horodatage DWT ──▶ file bornée ──▶ passthrough ──▶ MIDI OUT
                                                    │
                                                    └▶ métriques série (in/out/dropped/hwm)
```

Le premier objectif, falsifiable, est le **passthrough** (§29 Test 1) : ce qui
entre ressort à l'identique. Le **scheduler** déterministe, la **capture
GrooveDNA** embarquée et le **pont Mac** viennent ensuite — pas avant que ce
socle soit chiffré (§31).

---

## Structure

```
firmware/
├── platformio.ini            build Teensy (PlatformIO) — non lancé ici
├── src/
│   ├── config.h              réglages (tailles de files, cadences)   ← portable
│   ├── midi/
│   │   ├── midi_event.h      l'événement horodaté                    ← portable
│   │   ├── midi_io.h/.cpp    DIN + USB device + USB host             ← Teensy
│   ├── timing/
│   │   └── cycle_clock.h/.cpp compteur DWT (1,667 ns, wrap ~7,16 s)  ← Teensy
│   ├── queue/
│   │   └── event_queue.h     file bornée, allocation statique        ← portable ✅ testé
│   ├── metrics/
│   │   └── metrics.h         compteurs d'observabilité               ← portable
│   └── main.cpp              boucle passthrough + diagnostic         ← Teensy
└── test/
    └── test_event_queue.cpp  test natif de la file                  ← ✅ g++
```

---

## Compiler pour le Teensy (avec le matériel)

```bash
cd klod-live-brain/firmware
pio run                 # PlatformIO + plateforme "teensy"
```

ou **Arduino IDE + Teensyduino** : carte « Teensy 4.1 », *USB Type* « Serial +
MIDI ». Épingler la version de la bibliothèque *MIDI Library* au premier build.

---

## Ce qu'il faut MESURER ensuite → `BENCHMARKS.md`

Rien de tout cela n'est un acquis tant que ce n'est pas chiffré (§11, §30) :

| Mesure | Pourquoi | Méthode envisagée |
|---|---|---|
| **Jitter d'horodatage** DIN vs USB | valider le choix « capture par DIN » (risque n°1) | générateur MIDI cadencé → écart-type des offsets |
| **Latence** entrée→sortie (round-trip) | quantifier le passthrough | boucle physique + mesure DWT aux deux bouts |
| **Événements/s** avant perte | dimensionner la file | rafale MIDI croissante → premier `dropped` |
| **Comportement en surcharge** | pas de corruption, pertes comptées | saturation prolongée + relecture `high_water`/`dropped` |
| **Stabilité longue durée** | fiabilité (soucis USB signalés en session longue) | plusieurs heures, sans crash ni note perdue |

Le rappel décisif (voir `TECHNICAL_REALITY.md` §3) : la **DIN** est le chemin de
capture à faible jitter ; l'**USB** regroupe les messages par intervalle de
polling. C'est une hypothèse **à confirmer par la mesure**, pas une conclusion
acquise.
