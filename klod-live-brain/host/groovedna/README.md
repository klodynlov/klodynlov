# `groovedna/` — capturer et transférer un *feel* rythmique

Le moteur **musical** de KLOD Live Brain : capturer la façon dont un musicien
joue (microtiming, dynamique, swing…), la représenter dans un format versionné,
puis la **transférer** sur d'autres patterns ou **interpoler** deux grooves.

**stdlib pure** — aucune dépendance, aucun matériel. C'est volontaire : le cœur
du projet se prouve **sans Teensy ni carte son** (cf.
[`../../docs/TECHNICAL_REALITY.md`](../../docs/TECHNICAL_REALITY.md)).

---

## Essayer tout de suite

```bash
cd klod-live-brain/host
python3 -m groovedna.demo                          # preuve du critère §38, chiffrée
python3 -m unittest groovedna.test_groove -v       # 35 tests, aucune dépendance
```

`demo` déroule la chaîne complète : une performance « jouée à la main » →
capture → GrooveDNA → application sur un pattern quantifié → morphing →
aller-retour JSON. Tous les chiffres sont **reproductibles** (aucun aléatoire).

---

## Bibliothèque

```python
from groovedna import capture_groove, apply_groove, morph_grooves, NoteEvent

# 1. Capturer le feel d'une performance (liste d'événements MIDI horodatés).
dna = capture_groove(events, ppqn=960, tempo=100)

# 2. Le transférer sur un pattern quantifié — dosé de 0 (rien) à 1 (tout).
joue = apply_groove(pattern_mecanique, dna, amount=0.6)

# 3. Interpoler deux grooves.
mix = morph_grooves(dna_a, dna_b, alpha=0.3)

# 4. Sauvegarder / recharger (format versionné, sans perte).
texte = dna.to_json()
dna2  = type(dna).from_json(texte)
```

| Fonction | Rôle |
|---|---|
| `capture_groove(events, ppqn, tempo, …)` | performance → `GrooveDNA` |
| `apply_groove(pattern, groove, amount)` | transfert de feel, `amount ∈ [0,1]` |
| `morph_grooves(a, b, alpha)` | interpolation, `alpha ∈ [0,1]` |
| `groove_distance(a, b)` | écart simple entre deux grooves (futur GROOVE MATCH) |
| `GrooveDNA.to_json / from_json` | sérialisation versionnée `KLOD_GROOVE_V1` |
| `NoteEvent(tick, note, velocity, …)` | l'unité capturée, indépendante du transport |

Le format et la base mathématique des métriques (swing, syncope, densité,
variation…) sont détaillés dans
[`GROOVEDNA_SPEC.md`](../../docs/GROOVEDNA_SPEC.md).

---

## Comment c'est construit

```
groove.py        NoteEvent, Grid, GrooveDNA, capture/apply/morph, format   ← tout le cœur
demo.py          preuve exécutable du critère §38
test_groove.py   35 tests unittest
```

Un seul choix structurant : **le cœur ne connaît ni MIDI ni matériel.** Un
`NoteEvent` est une position en ticks, une note, une vélocité — que la note
vienne d'un port DIN, d'USB ou d'un fichier `.mid`. Le transport (rtmidi,
Teensy…) viendra *autour*, jamais dedans. C'est ce qui rend les 35 tests
exécutables en CI, sans radio ni carte son — la même discipline que `microbit/`
et EdgeSense de ce dépôt.

---

## Ce qui est prouvé ici — et ce qui ne l'est pas

**Prouvé** (35 tests + démo) : capture d'offsets mesurables, transfert
reproductible et linéaire, **aucune note perdue**, morphing aux bornes exactes,
sérialisation versionnée sans perte, métriques cohérentes sur cas connus.

**Pas encore** : l'apprentissage des **styles réels** (zouk, shatta, kompa…)
depuis de **vrais fichiers MIDI** — jamais des clichés inventés (§7) ; le
**groove personnel** du musicien, calculé sur des performances accumulées ; et
le **portage temps réel sur Teensy**, dont le jitter reste à mesurer
([`TECHNICAL_REALITY.md`](../../docs/TECHNICAL_REALITY.md)).
