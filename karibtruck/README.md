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
| 🏠 Accueil terrain : état du jour (relevés, checklists, alertes) + tuiles | ✅ UI |
| 🌡️ Relevés de température (frigo `≤ 4 °C`, vitrine chaude `≥ 63 °C`), pavé numérique géant, action corrective en 1 tap si alerte | ✅ cœur + UI |
| ✅ Checklists ouverture / fermeture / nettoyage — points non faits scellés, signature en alerte | ✅ cœur + UI |
| 📦 Traçabilité réception (produit, fournisseur, lot, DLC) + **photo d'étiquette liée par empreinte SHA-256** | ✅ cœur + UI |
| 🥩 **Traçabilité viande** (volaille, porc, bœuf, mouton, cabri) : réception (origine, estampille, T° selon l'état), fournées liées aux lots, lots clos, rappel fournisseur, affiche « Origine de nos viandes » (écran client + PDF) | ✅ cœur + UI |
| ⚠️ Non-conformités + action corrective (modèles en un tap) | ✅ cœur + UI |
| 🍟 Huile de friture (contrôle / changement, % composés polaires `≤ 25 %`) | ✅ cœur + UI |
| 🗺️ Planning marché (date, emplacement, créneau) | ✅ cœur + UI |
| 🕘 Historique filtrable + détail scellé d'une entrée (contrôle d'intégrité de la photo) | ✅ UI |
| 📄 Dossier de contrôle par période : **PDF A4** (alertes d'abord, une table par registre, empreintes) + CSV | ✅ cœur + UI |
| 🔒 Journal inviolable SHA-256 + vérification d'intégrité | ✅ cœur |

Les valeurs de départ (limites, points de checklist, modèles d'incident) sont à
ajuster avec le PMS du camion.

Règles viande encodées (vérifiées le 2026-09-25) : mention d'origine au format du
décret n° 2002-1465 modifié (pérennisé par le décret n° 2025-141, y compris à
emporter) ; limites de température à réception selon le règlement CE 853/2004 et
l'arrêté du 21/12/2009 (haché 2 °C, abats 3 °C, volaille et préparations 4 °C,
découpes 7 °C, surgelé −18 °C avec 3 °C de tolérance au transport). Une fournée
refuse un lot inconnu, clos ou à DLC dépassée.

## Structure

```
karibtruck/
├── Package.swift                 # Swift Package (cœur, sans dépendance)
├── Sources/KaribTruckCore/       # cœur métier pur (Linux ↔ Apple)
│   ├── SHA256.swift              #   SHA-256 en Swift pur (FIPS 180-4)
│   ├── Journal.swift             #   journal append-only chaîné, tamper-evident
│   ├── Thresholds.swift          #   règle de seuil (max=froid / min=chaud)
│   ├── Enclosures.swift          #   enceintes + préréglages M0
│   ├── Checklists.swift          #   modèles de checklists (préréglages M0)
│   ├── Meat.swift                #   traçabilité viande (origine, limites, fournées, rappel)
│   ├── KaribTruck.swift          #   façade métier (les 6 actions + lectures par période)
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

> Vérifié sur Mac (Xcode 27, Swift 6.4) : `swift test` 53/53, oracle + garde-fou
> OK, app compilée sans avertissement, testée au simulateur et installée sur iPad.
