# KaribTruck — M0 (HACCP + exploitation, app iPad)

App iPad **local-first** pour piloter un food truck : hygiène/HACCP et
exploitation. **Pas de caisse** (domaine réglementé → logiciel du marché ;
cadrage dans [`../docs/KARIBTRUCK.md`](../docs/KARIBTRUCK.md)).

Architecture : un **cœur métier Swift pur et testé** (`KaribTruckCore`) partagé
par une **app SwiftUI** (`App/`). Toute action opérationnelle devient une entrée
**scellée** dans un journal append-only chaîné en SHA-256 — inviolable et non
rétro-datable, la preuve qu'on présente en contrôle DDPP.

## Ce que fait le M0

| Module | Statut |
|---|---|
| 🌡️ Relevés de température (frigo `≤ 4 °C`, vitrine chaude `≥ 63 °C`, alerte hors-plage) | ✅ cœur + UI |
| ✅ Checklists ouverture / fermeture / nettoyage | ✅ cœur |
| 📦 Traçabilité réception (fournisseur, lot, DLC, produit) | ✅ cœur |
| ⚠️ Non-conformités + action corrective | ✅ cœur |
| 🍟 Huile de friture (contrôle / changement) | ✅ cœur |
| 🗺️ Planning marché (date, emplacement, créneau) | ✅ cœur |
| 📄 Export « dossier de contrôle » (CSV + résumé Markdown) | ✅ cœur + partage UI |
| 🔒 Journal inviolable SHA-256 + vérification d'intégrité | ✅ cœur |

Les modules avec UI complète au-delà des relevés (checklists, réception, huile,
non-conformités, planning) suivent le même patron que `ContentView` : ils sont
prêts côté cœur, à brancher sur des formulaires SwiftUI.

## Structure

```
karibtruck/
├── Package.swift                 # Swift Package (cœur, sans dépendance)
├── Sources/KaribTruckCore/       # cœur métier pur (Linux ↔ Apple)
│   ├── SHA256.swift              #   SHA-256 en Swift pur (FIPS 180-4)
│   ├── Journal.swift             #   journal append-only chaîné, tamper-evident
│   ├── Thresholds.swift          #   règle de seuil (max=froid / min=chaud)
│   ├── Enclosures.swift          #   enceintes + préréglages M0
│   ├── KaribTruck.swift          #   façade métier (les 6 actions)
│   └── Export.swift              #   export dossier de contrôle (CSV + résumé)
├── Tests/KaribTruckCoreTests/    # XCTest (SHA-256, journal, seuils, altération, export)
├── tools/
│   ├── oracle.py                 # implémentation de référence (Python) + vecteurs
│   └── check_sync.py             # garde-fou : vecteurs Swift == oracle
└── App/                          # app SwiftUI (à compiler sur Mac/Xcode) — voir App/README.md
```

## Le « pro » : sécurité, tests, audit, harnais

- **Inviolabilité** : chaque enregistrement est scellé (SHA-256) et chaîné au
  précédent. Toute altération, réordonnancement ou suppression est détecté par
  `verify()`. Une correction se fait par **entrée rectificative**, jamais par
  effacement (cf. `TamperTests`).
- **Cœur pur, sans horloge** : les timestamps sont injectés → déterministe et
  testable. L'app injecte `Date()` ; les tests injectent des dates fixes.
- **Double implémentation** : la spec du journal est écrite en Swift **et** en
  Python (`tools/oracle.py`). Les tests Swift sont figés sur les vecteurs de
  l'oracle ; `check_sync.py` empêche toute dérive silencieuse.
- **Zéro dépendance** : SHA-256 en Swift pur (ADN « stdlib pur » du dépôt,
  portable Linux/CI ↔ Apple/app).
- **CI** : `.github/workflows/karibtruck.yml` compile et exécute `swift test`
  dans un conteneur `swift:6`, plus l'oracle et le garde-fou côté Python.

## Vérification

```bash
# Cœur métier Swift (nécessite la toolchain Swift ; fait tourner par la CI) :
swift test

# Oracle de référence + garde-fou (Python 3, sans dépendance) :
python3 tools/oracle.py       # self-test 5/5 + génère les vecteurs
python3 tools/check_sync.py   # vérifie que les tests Swift == oracle
```

> Note : l'environnement de développement (Linux, sans toolchain Swift ni
> macOS/Xcode) ne compile pas Swift. La preuve d'exécution du cœur passe donc par
> **la CI** (`swift:6`) et par **l'oracle Python** (lancé en local), qui figent
> indépendamment les mêmes empreintes. L'UI SwiftUI se compile sur Mac.
