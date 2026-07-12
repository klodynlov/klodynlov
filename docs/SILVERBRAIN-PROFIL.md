# SilverBrain — modèle de données du profil utilisateur

> Spécification du **profil local** qui alimente l'orientation thématique (pilier 2) et le
> contrat de style (pilier 4). Objectif : un profil **lisible, révisable, oubliable**,
> construit en langage naturel et vivant **entièrement en local** (SQLite chiffré au
> repos). Aucune donnée ne quitte l'appareil.

Voir la vue d'ensemble du concept dans [SILVERBRAIN.md](SILVERBRAIN.md).

---

## 1. Principe : le profil est une hypothèse, pas une vérité

Chaque élément de profil est un **trait** : une affirmation *probable* sur la personne,
assortie d'une **confiance**, d'une **fraîcheur** et d'une **source**. Rien n'est figé :
un trait se renforce, s'affaiblit, s'oublie, ou se corrige d'un mot à l'oral. Ce cadre
évite deux écueils : l'assistant qui « croit tout savoir » et le formulaire figé.

Trois règles fondatrices :

- **Consentement avant usage** — un trait n'influence une proposition qu'après avoir été
  confirmé (explicitement ou implicitement, voir §5).
- **Réversibilité** — « oublie ça », « non, plus maintenant » suffit à retirer un trait.
- **Localité** — le profil ne sert qu'à SilverBrain, sur la machine ; jamais d'export
  cloud, jamais de partage sans accord.

---

## 2. Anatomie d'un trait

```jsonc
{
  "id": "trait_0142",
  "type": "centre_interet",       // voir §3
  "cle": "jardinage",             // valeur normalisée (slug)
  "libelle": "le jardinage",      // formulation naturelle pour l'oral
  "confiance": 0.80,              // [0..1] — voir §4
  "vu_count": 4,                  // nombre d'observations concordantes
  "premiere_obs": "2026-05-02",
  "derniere_obs": "2026-07-11",   // sert au calcul de fraîcheur (§4)
  "source": "inference",          // "inference" | "declaration" | "correction"
  "consentement": "confirme",     // "propose" | "confirme" | "refuse"
  "preuves": [                    // extraits qui ont fondé le trait (audit local)
    { "date": "2026-05-02", "citation": "mon mari cultivait des tomates" },
    { "date": "2026-07-11", "citation": "j'aimerais bien un rappel pour arroser" }
  ],
  "sensibilite": "normale"        // "normale" | "sensible" (santé, deuil, finances)
}
```

**Champs clés.**
- `source` distingue ce que la personne **a dit d'elle-même** (`declaration`), ce que
  l'assistant **a déduit** (`inference`), et ce qu'elle **a rectifié** (`correction`, la
  plus haute autorité).
- `consentement` gouverne l'usage : seul `confirme` autorise une proposition proactive.
- `preuves` garde la trace **locale** de *pourquoi* un trait existe — indispensable pour
  expliquer (« vous m'aviez dit… ») et pour un audit par un proche de confiance.
- `sensibilite: "sensible"` déclenche des règles de prudence renforcées (§6).

---

## 3. Typologie des traits

| Type              | Rôle                              | Exemples de clés                         |
|-------------------|-----------------------------------|------------------------------------------|
| `centre_interet`  | Oriente les thématiques LibraryBrain | jardinage, histoire_locale, cuisine, football |
| `rythme`          | Cale les rappels sur la vie réelle | leve_tot, sieste_apres_dejeuner, couche_tard |
| `proche`          | Carnet nommé en clair             | fille:Marie, medecin:Dr_Martin, voisin:Paul |
| `sante_routine`   | Rappels de soin (sensible)        | comprime_tension_matin, gouttes_18h      |
| `expression`      | Alimente le contrat de style (§ pilier 4) | vouvoiement, phrases_courtes, prenom:Jeanne |
| `aversion`        | Ce qu'il faut **éviter**          | pas_de_notifications_sonores, evite_sujet_deuil |
| `capacite`        | Contraintes sensorielles/motrices | malentendant_leger, vue_basse            |

Le type `aversion` est aussi important que les préférences : il encode ce que l'assistant
**ne doit pas** faire ou dire.

---

## 4. Confiance & fraîcheur (renforcement / décroissance)

**Renforcement.** Chaque nouvelle observation concordante augmente la confiance avec un
**rendement décroissant** (on ne dépasse jamais 1.0) :

```
confiance ← confiance + (1 − confiance) × poids_source
poids_source :  declaration 0.5 · correction 0.7 · inference 0.25
```

**Décroissance (oubli naturel).** Un trait non revu perd en confiance avec le temps, à un
rythme dépendant du type (un centre d'intérêt s'estompe vite, un proche presque pas) :

```
confiance_effective = confiance × exp( −Δjours / demi_vie[type] )

demi_vie (jours) :  centre_interet 120 · rythme 90 · expression 180
                    proche 3650 · sante_routine ∞ (jamais par le temps seul)
```

- Sous un **seuil de silence** (`confiance_effective < 0.15`), le trait passe en
  sommeil : il n'influence plus rien, mais reste consultable jusqu'à un éventuel élagage.
- `sante_routine` ne s'oublie **jamais** par simple décroissance : seule une correction
  explicite le retire (on ne « périme » pas un traitement en silence).

**Seuils d'usage.**
| Confiance effective | Comportement |
|---------------------|--------------|
| ≥ 0.75              | Utilisable proactivement (si `consentement = confirme`) |
| 0.40 – 0.75         | Utilisable en **question fermée** (« vous aimez le jardinage, c'est ça ? ») |
| 0.15 – 0.40         | Latent : n'influence pas, peut resurgir à la prochaine observation |
| < 0.15              | En sommeil |

---

## 5. Pipeline d'extraction

De la parole au trait, en cinq étapes — **toutes locales** :

```
1. Transcription (VocalBrain STT)
2. Détection d'indices     → l'énoncé contient-il un signal de profil ?
3. Extraction de trait     → {type, clé, libellé, preuve} candidat
4. Fusion / rapprochement  → nouveau trait, ou renforcement d'un existant (dédup par clé)
5. Politique de consentement → "propose" par défaut ; usage seulement si "confirme"
```

- **Étape 2/3** : réalisées par Klody sous contrainte de schéma (sortie structurée), pour
  garantir des traits bien formés plutôt que du texte libre.
- **Étape 4** : la déduplication se fait sur `(type, cle)` normalisée ; une observation
  qui contredit un trait (« je ne jardine plus ») crée une **correction** qui prime.
- **Signaux implicites** : au-delà des déclarations, l'usage nourrit le profil — un proche
  souvent appelé renforce `proche`, un rappel toujours reporté à la même heure ajuste
  `rythme`.

### Confirmation explicite vs implicite
- **Explicite** : « je vous proposerai des lectures sur le jardinage, d'accord ? » → oui.
- **Implicite** : la personne accepte plusieurs fois une proposition liée au trait → le
  `consentement` passe de `propose` à `confirme` après *k* acceptations (proposé : k = 2),
  jamais pour un trait `sensible`.

---

## 6. Traits sensibles — prudence renforcée

Pour `sensibilite: "sensible"` (santé, deuil, finances, isolement) :

- **Jamais** de passage automatique à `confirme` : la confirmation doit être explicite.
- **Jamais** de proposition « à froid » sur un sujet douloureux ; l'assistant suit les
  `aversion` (ex. `evite_sujet_deuil`).
- Ces traits **n'apparaissent pas** dans la vue « proche aidant » sans un accord distinct
  de l'utilisateur.
- Chiffrement au repos comme le reste, mais élagage plus conservateur (on préfère mettre
  en sommeil que supprimer, en cas de retour du sujet).

---

## 7. Contrôle utilisateur — tout à l'oral

Le profil est pilotable sans écran :

| Intention orale                         | Effet |
|-----------------------------------------|-------|
| « qu'est-ce que tu sais de moi ? »      | Énonce les traits `confirme` les plus frais, simplement |
| « oublie le jardinage »                 | Retire le trait (sommeil immédiat + marqueur *ne pas réinférer avant N jours*) |
| « non, je préfère qu'on se tutoie »     | `correction` sur `expression` |
| « ne me parle plus de ça »              | Crée une `aversion` |
| « pourquoi tu me proposes ça ? »        | Restitue la `preuve` (« vous m'aviez dit… ») |

Un **oubli demandé** pose un verrou temporaire : l'assistant ne re-déduit pas le trait
avant un délai, pour ne pas « reproposer » ce que la personne vient d'écarter.

---

## 8. Stockage & sécurité

- **SQLite local**, chiffré au repos ; `preuves` et traits `sensible` dans la même
  enveloppe chiffrée.
- **Recherche thématique** : les `centre_interet` confirmés deviennent des requêtes vers
  **LibraryBrain** (hybride sqlite-vec + FTS5) — le profil filtre et classe la
  bibliothèque, il ne duplique pas son contenu.
- **Aucune synchronisation** : pas de cloud, pas de télémétrie. Une sauvegarde locale
  chiffrée (clé détenue par l'utilisateur ou un proche de confiance) est le seul export
  prévu.
- **Journal d'audit local** : création/renforcement/oubli horodatés, consultables par un
  proche autorisé — la transparence est un gage de confiance pour ce public.

---

## 9. Schéma relationnel (esquisse)

```sql
CREATE TABLE trait (
  id            TEXT PRIMARY KEY,
  type          TEXT NOT NULL,
  cle           TEXT NOT NULL,
  libelle       TEXT NOT NULL,
  confiance     REAL NOT NULL DEFAULT 0.25,
  vu_count      INTEGER NOT NULL DEFAULT 1,
  premiere_obs  TEXT NOT NULL,
  derniere_obs  TEXT NOT NULL,
  source        TEXT NOT NULL CHECK (source IN ('inference','declaration','correction')),
  consentement  TEXT NOT NULL CHECK (consentement IN ('propose','confirme','refuse')),
  sensibilite   TEXT NOT NULL DEFAULT 'normale',
  UNIQUE (type, cle)
);

CREATE TABLE trait_preuve (
  trait_id  TEXT NOT NULL REFERENCES trait(id) ON DELETE CASCADE,
  date      TEXT NOT NULL,
  citation  TEXT NOT NULL
);

-- confiance_effective (décroissance) calculée à la lecture, pas stockée,
-- pour rester exacte sans tâche de fond.
```

`confiance_effective` est **dérivée à la lecture** (§4) : pas de tâche planifiée qui
« périme » des lignes en silence — cohérent avec le fonctionnement hors-ligne.
