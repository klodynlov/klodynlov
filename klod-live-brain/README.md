# KLOD Live Brain · module KLOD GrooveDNA

> Un **coprocesseur musical temps réel et agentique** : le Teensy assure les
> réflexes (horloge, MIDI, scheduler), le Mac assure l'intelligence (IA,
> mémoire, génération). Premier module : **GrooveDNA** — capturer, représenter,
> transférer et interpoler le *feel* rythmique réel d'un musicien.

**Règle du projet (§0) : réalité technique avant prose.** Rien n'est annoncé
« fonctionnel » sans documentation *et* mesure. D'où les statuts partout :
✅ PROUVÉ · 🟢 FAISABLE · 🟡 EXPÉRIMENTAL · ⛔ NON VIABLE.

---

## Où en est le projet

| Brique | Statut | Preuve |
|---|---|---|
| **Moteur GrooveDNA** (capture · apply · morph · format versionné) | ✅ **PROUVÉ** | [`host/groovedna/`](host/groovedna/) — **35 tests verts**, démo §38 chiffrée |
| Audit de faisabilité V0 (Teensy, MIDI, timing) | ✅ **PRODUIT** | [`docs/TECHNICAL_REALITY.md`](docs/TECHNICAL_REALITY.md) |
| Couche réflexe Teensy (timing, scheduler, MIDI) | 🟢 FAISABLE | [`firmware/`](firmware/) — squelette de référence ; **file bornée testée en natif**, reste **non mesuré** sur carte |
| IA / MCP / MPC / DAW | ⏳ à venir | pas de backend ⇒ pas d'annonce |

Autrement dit : le **pari central** du projet — *peut-on représenter et
transférer un feel de façon mesurable et reproductible ?* — est **gagné sur le
fond**, en logiciel pur, indépendamment du matériel. Le reste attend la mesure.

---

## Le critère de réussite, exécutable

Le cahier des charges (§38) définit la viabilité par une chaîne précise. Elle
tourne, chiffrée et reproductible :

```bash
cd klod-live-brain/host
python3 -m groovedna.demo
```

```
performance humaine  →  capture_groove()  →  GrooveDNA
  kick  : décalage moyen  -6.0 ticks ( -3.75 ms)   ← feel mesuré
  snare : décalage moyen +14.0 ticks ( +8.75 ms)
  swing : 0.573
pattern quantifié  →  apply_groove(dna, amount)  →  feel transféré
  amount 0.00 → +0.00 ms | 0.50 → +4.38 ms | 1.00 → +8.75 ms   ← linéaire
  12 notes en entrée · 12 en sortie → aucune note perdue
```

---

## Idée directrice

```
Le Mac réfléchit.  Le Teensy exécute en temps réel.
```

Le LLM n'est **jamais** dans la boucle temporelle critique : il prépare les
décisions, le Teensy les joue. Le système doit tenir **sans IA** (robustesse
§27) — l'intelligence est une augmentation, pas une dépendance. Voir
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Structure

```
klod-live-brain/
├── docs/
│   ├── TECHNICAL_REALITY.md   audit Phase 0 — statuts, preuves, risques, sources
│   ├── GROOVEDNA_SPEC.md       format KLOD_GROOVE_V1 + base mathématique
│   └── ARCHITECTURE.md         4 niveaux, frontière temps réel, flux V0
├── host/
│   └── groovedna/              moteur musical, stdlib pur — ✅ 35 tests
└── firmware/                   couche réflexe Teensy — squelette ; file bornée ✅ testée en natif
```

On n'ajoute `mcp/`, `integrations/`, `ml/` **que lorsque leurs backends
existent** (§32, « commencer minimal »). Le `firmware/` est un squelette de
référence : voir son [README](firmware/) pour ce qui est testé (la file) et ce
qui attend le matériel (timing, MIDI, benchmarks).

---

## Prochain jalon

Porter la couche **réflexe** sur Teensy 4.1 et la **mesurer** (jitter, latence,
overruns) — le vrai verrou du temps réel musical, tranché par le benchmark et
non par la prose. La capture haute précision passera par le **MIDI DIN** (faible
jitter), pas par l'USB (qui regroupe les messages) : voir l'analyse dans
[`docs/TECHNICAL_REALITY.md`](docs/TECHNICAL_REALITY.md). Tant que la chaîne
matérielle n'est pas bouclée et chiffrée, **on ne passe pas à l'IA** (§38).
