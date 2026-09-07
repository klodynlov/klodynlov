# GROOVEDNA_SPEC.md — format `KLOD_GROOVE_V1`

Représentation, **indépendante du BPM**, du *feel* rythmique réel d'une
performance : décalages de microtiming, dynamique, swing, densité, syncope,
variation. Chaque grandeur a une **base mathématique documentée** (exigence
§16 du cahier des charges) et une implémentation **prouvée par 35 tests**
(`host/groovedna/`).

Version : **1** (`KLOD_GROOVE_V1`). Format versionné, conçu pour évoluer sans
casser les données anciennes (voir §7).

---

## 1. Principes de conception

1. **Indépendant du tempo.** Le microtiming est stocké en **fraction de noire**
   (unité : *beat*), pas en millisecondes. On enregistre `tempo_reference`
   uniquement pour reconstituer des ms à l'affichage :
   `ms = offset_beats × 60000 / tempo`. Un même feel se réapplique donc à
   n'importe quel tempo.
2. **Un gabarit, pas un sac de réglages.** La représentation centrale est un
   *groove template* : pour chaque **(voix, pas de la grille)**, on mesure le
   décalage moyen, la dynamique moyenne et la probabilité de frappe. C'est ce
   que font les *groove templates* des DAW — et non des paramètres inventés.
3. **Rien d'aléatoire.** Toutes les valeurs sont des **statistiques de frappes
   réelles**. `apply_groove` applique des moyennes ⇒ résultat **reproductible**
   (le cahier l'exige, §29/§38 ; on n'« humanise » jamais au `random()`, §34).
4. **Versionné.** Le champ `format` porte la version ; le chargeur accepte la
   famille `KLOD_GROOVE_V*` et réserve un point de migration.

---

## 2. Grille métrique

| Paramètre | Rôle | Défaut |
|---|---|---|
| `ppqn` | ticks par noire (résolution) | 960 |
| `beats_per_bar` | temps par mesure | 4 |
| `subdivision` | pas par temps (4 ⇒ doubles-croches, 3 ⇒ triolets) | 4 |

Dérivés : `ticks_per_step = ppqn / subdivision` (doit être entier),
`steps_per_bar = beats_per_bar × subdivision`.

**Quantification.** La position théorique d'une note est la subdivision la plus
proche, calculée globalement :

```
step_global = round(tick / ticks_per_step)
grid_tick   = step_global × ticks_per_step
offset_ticks = tick − grid_tick          (signé : − en avance, + en retard)
offset_beats = offset_ticks / ppqn
```

Arrondir *globalement* gère proprement une note jouée en avance sur le premier
temps de la mesure suivante : elle appartient à ce temps-là, avec un décalage
négatif — pas à la fin de la mesure précédente.

---

## 3. Modèle de données

```
GrooveDNA
├─ format, tempo_reference, ppqn, beats_per_bar, subdivision, bars
├─ voices : { role → VoiceGroove }
├─ swing, density, syncopation, variation      (features dérivées, scalaires)
├─ bar_variation : [float]                       (par mesure)
└─ accent_map    : [float]                       (vélocité moy. par pas, kit)

VoiceGroove(role)
├─ steps : { step → StepStat }                   (le gabarit)
└─ offset_mean, offset_std, velocity_mean, count (agrégats de la voix)

StepStat
├─ count, hit_prob
├─ offset_mean, offset_std       (en beats)
└─ velocity_mean, velocity_std   (normalisés 0..1)
```

**Voix (rôles).** Par défaut, carte de percussion General MIDI :
`kick` (35,36), `snare` (37–40), `hat` (42,44,46), `tom`, `cymbal`, `perc`,
`other`. Le résolveur de rôle est **injectable** (p. ex. par canal, pour du
mélodique).

---

## 4. Métriques dérivées — définitions mathématiques

Soit, pour une voix, l'ensemble de ses décalages `{oᵢ}` (en beats) et vélocités
normalisées `{vᵢ}`.

**Décalage moyen / écart-type** (par voix et par pas) :
`offset_mean = moyenne(oᵢ)`, `offset_std = écart-type de population`. L'écart-type
est la *souplesse* du jeu (0 = mécanique).

**Probabilité de frappe** d'un pas : `hit_prob = count_pas / bars` (borné à 1).

**Swing** ∈ [0,1] : position normalisée moyenne des croches « et » dans le
temps. Une « et » binaire tombe à 0,5 du temps ; swinguée, elle est poussée plus
tard. On lit le décalage moyen sur les pas « et » (indice `step mod subdivision =
subdivision/2`) : `swing = 0.5 + moyenne(offset_beats sur ces pas)`. Pas de
« et » jouée ⇒ `0.5` (binaire). `0.667 ≈` triolet.

**Poids métrique** `w(step) ∈ [0,1]` — hiérarchie métrique du 4/4 (grille
métrique de *Longuet-Higgins & Lee 1984*, ici simplifiée) :

| Position | Poids |
|---|---|
| 1er temps (downbeat) | 1,00 |
| temps médian (temps 3 en 4/4) | 0,90 |
| autres temps | 0,75 |
| croche « et » | 0,50 |
| double-croche | 0,25 |

**Syncope** ∈ [0,1] : fraction de l'énergie (vélocité) tombant sur des positions
métriques **faibles** :
`syncopation = Σ vᵢ·(1 − w(stepᵢ)) / Σ vᵢ`. C'est un **proxy** documenté de la
grille métrique, pas le modèle LHL complet — et c'est dit.

**Densité** ∈ [0,1] : occupation moyenne des créneaux. Par voix,
`occ = min(count, S) / S` avec `S = steps_per_bar × bars` ; `density = moyenne
des occ sur les voix actives`.

**Variation inter-mesures** ∈ [0,1] : distance de **Jaccard** moyenne des
ensembles d'onsets `{(voix, pas)}` de chaque mesure jouée aux *autres* mesures
jouées : `d(A,B) = |A △ B| / |A ∪ B|`. Symétrique, sans mesure « de référence »
privilégiée, et **robuste aux mesures vides** (décompte silencieux ignoré).

**Carte d'accents** : pour chaque pas de la mesure, vélocité normalisée moyenne
sur l'ensemble du kit (longueur `steps_per_bar`).

---

## 5. Transfert — `apply_groove(pattern, groove, amount)`

Pour chaque note du pattern, on trouve sa (voix, pas), on lit le gabarit et on
**interpole linéairement** entre la note d'origine et la cible du groove :

```
cible_tick = grid_tick + offset_mean[voix,pas] × ppqn
cible_vel  = velocity_mean[voix,pas] × 127
tick′ = tick + amount × (cible_tick − tick)
vel′  = vel  + amount × (cible_vel  − vel)
```

- `amount = 0` ⇒ **identité** (pattern inchangé — prouvé).
- `amount = 1` ⇒ feel complet du groove.
- **Repli** : si le pas n'a jamais été joué dans ce groove, on applique le
  décalage **agrégé de la voix** et on **laisse la vélocité intacte** (on
  n'invente pas de dynamique).

Garanties (testées) : **aucune note perdue** (autant en sortie qu'en entrée),
`tick ≥ 0`, `1 ≤ vel ≤ 127`.

*Exemple mesuré* (snare quantifiée, feel dont la snare traîne de +14 ticks) :

| amount | décalage | vélocité |
|---|---|---|
| 0,00 | +0 tick (+0,00 ms) | 80 |
| 0,25 | +4 ticks (+2,50 ms) | 84 |
| 0,50 | +7 ticks (+4,38 ms) | 88 |
| 0,75 | +10 ticks (+6,25 ms) | 92 |
| 1,00 | +14 ticks (+8,75 ms) | 96 |

---

## 6. Morphing — `morph_grooves(a, b, alpha)`

`alpha = 0 → A`, `alpha = 1 → B`. Ce qui est **continu** (décalages, vélocités,
probabilités, features) est interpolé linéairement. Ce qui est **structurel**
(une voix ou un pas présent d'un seul côté) *apparaît/disparaît* via son poids
plutôt que d'être moyenné n'importe comment : un pas dont le `count` morphé tombe
à ~0 est retiré, ce qui garantit des **bornes exactes** (A à 0, B à 1) sans
artefact d'union. Grilles incompatibles (ppqn/mesure/subdivision différents) ⇒
refus explicite. C'est la réponse à l'avertissement §6 du cahier :
« ne pas interpoler naïvement ce qui détruirait la structure rythmique ».

---

## 7. Format JSON & versionnement

Exemple réel (1 mesure ; kick légèrement en retard, snare qui traîne, charley
swinguée ; valeurs abrégées) :

```json
{
  "format": "KLOD_GROOVE_V1",
  "tempo_reference": 100, "ppqn": 960,
  "beats_per_bar": 4, "subdivision": 4, "bars": 1,
  "swing": 0.573, "density": 0.083, "syncopation": 0.256, "variation": 0.0,
  "accent_map": [0.866, 0.0, 0.472, 0.0, 0.724, 0.0, 0.457, 0.0, ...],
  "voices": {
    "kick":  { "role": "kick",  "offset_mean": 0.006, "velocity_mean": 0.866, "count": 1,
               "steps": { "0": { "count": 1, "offset_mean": 0.006, "velocity_mean": 0.866,
                                 "offset_std": 0.0, "velocity_std": 0.0, "hit_prob": 1.0 } } },
    "hat":   { "role": "hat", "offset_mean": 0.073, "...": "..." },
    "snare": { "role": "snare", "offset_mean": 0.013, "...": "..." }
  }
}
```

**Politique de version.** Le chargeur accepte tout `format` commençant par
`KLOD_GROOVE_V` (un futur `KLOD_GROOVE_V2` reste chargeable) et **rejette** tout
autre format (`UnsupportedFormat`). La fonction `from_dict` réserve
explicitement l'emplacement d'une migration V1 → V2. Aller-retour JSON
**sans perte** (testé).

---

## 8. Ce qui est prouvé

- Capture d'offsets connus, à la fraction de tick près.
- Transfert dosé **linéaire** (0/25/50/75/100 %), vélocité comprise.
- **Aucune note perdue**, ticks et vélocités bornés.
- Morphing aux **bornes exactes** + milieu = moyenne.
- Sérialisation versionnée **sans perte** ; rejet d'un format inconnu.
- Métriques (swing, syncope, densité, variation, accents) cohérentes sur cas
  connus (binaire vs swingué, quatre-au-sol vs contretemps, mesures identiques
  vs différentes).

35 tests : `cd klod-live-brain/host && python3 -m unittest groovedna.test_groove -v`.

Ce qui **reste** (non prouvé ici) : l'apprentissage des **styles réels**
(zouk/shatta/kompa…) depuis de **vrais fichiers MIDI**, le modèle de **groove
personnel** du musicien, et le portage temps réel sur Teensy — voir
`TECHNICAL_REALITY.md`.
