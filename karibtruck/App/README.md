# App iPad KaribTruck (SwiftUI)

Échafaudage de l'app iPad. **Se compile sur Mac avec Xcode** (SwiftUI n'existe
pas sur Linux). Le cœur métier `KaribTruckCore` est, lui, testé en CI.

## Fichiers

- `project.yml` — spec **XcodeGen** : génère le projet Xcode automatiquement.
- `generate.sh` — script d'aide (installe XcodeGen au besoin, puis génère).
- `KaribTruck/KaribTruckApp.swift` — point d'entrée (`@main`).
- `KaribTruck/Store.swift` — liaison UI ↔ cœur : horloge (`Date()`), persistance
  JSON chiffrée au repos (`.completeFileProtection`), les 6 actions métier.
- `KaribTruck/ContentView.swift` — écran de saisie d'un relevé de température +
  bandeau d'intégrité + historique + export (`ShareLink`).

## Option A — Génération automatique (recommandé)

```bash
cd karibtruck/App
./generate.sh                 # installe XcodeGen si besoin, puis génère le projet
open KaribTruck.xcodeproj
```

Ou à la main :

```bash
cd karibtruck/App
brew install xcodegen         # une seule fois
xcodegen generate
open KaribTruck.xcodeproj
```

Dans Xcode ensuite (une fois) :

1. Sélectionnez la cible **KaribTruck ▸ Signing & Capabilities**.
2. **Team** = votre équipe développeur (celle du compte payant), **Automatically
   manage signing** coché. (Vous pouvez aussi figer votre Team ID directement dans
   `project.yml`, champ `DEVELOPMENT_TEAM`, puis régénérer.)
3. Branchez l'iPad, choisissez-le comme destination, **Run ▶**. Première fois sur
   l'iPad : **Réglages ▸ Général ▸ VPN et gestion de l'appareil** → faire confiance.

Le `.xcodeproj` est **régénérable** (et gitignoré) : la source de vérité reste
`project.yml`. Après avoir ajouté un fichier Swift, relancez `xcodegen generate`.

Le bundle identifier par défaut est **`fr.karibtruck.haccp`** (modifiable dans
`project.yml`).

## Option B — Création manuelle du projet (sans XcodeGen)

1. Xcode → **File ▸ New ▸ Project… ▸ App** (interface **SwiftUI**), nommé
   `KaribTruck`, cible **iPad** (iOS 16+).
2. Supprimer les `App`/`ContentView` générés et **glisser** les fichiers de
   `App/KaribTruck/` dans le projet.
3. **File ▸ Add Package Dependencies… ▸ Add Local…**, choisir le dossier
   `karibtruck/` (celui du `Package.swift`), lier le produit **`KaribTruckCore`**.
4. Build & Run.

## À suivre (au-delà du M0)

- Écrans dédiés pour checklists, réception (photo d'étiquette via `PhotosPicker` /
  caméra), huile de friture, non-conformités, planning marché — chacun appelle une
  action déjà prête du `Store`.
- Export **PDF** du dossier de contrôle (mise en page côté app, la donnée vient de
  `InspectionExport`).
- Verrouillage Face ID (LocalAuthentication) et sauvegarde chiffrée exportable.
