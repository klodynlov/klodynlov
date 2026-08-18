# App iPad KaribTruck (SwiftUI)

Échafaudage de l'app iPad. **Se compile sur Mac avec Xcode** (SwiftUI n'existe
pas sur Linux). Le cœur métier `KaribTruckCore` est, lui, testé en CI.

## Fichiers

- `KaribTruck/KaribTruckApp.swift` — point d'entrée (`@main`).
- `KaribTruck/Store.swift` — liaison UI ↔ cœur : horloge (`Date()`), persistance
  JSON chiffrée au repos (`.completeFileProtection`), les 6 actions métier.
- `KaribTruck/ContentView.swift` — écran de saisie d'un relevé de température +
  bandeau d'intégrité + historique + export (`ShareLink`).

## Créer le projet Xcode (une fois)

1. Xcode → **File ▸ New ▸ Project… ▸ App** (interface **SwiftUI**), nommé
   `KaribTruck`, cible **iPad** (iOS 16+ recommandé pour `NavigationStack` /
   `ShareLink`).
2. Supprimer les `App`/`ContentView` générés et **glisser** les fichiers de
   `App/KaribTruck/` dans le projet.
3. Ajouter le cœur en package local : **File ▸ Add Package Dependencies… ▸ Add
   Local…**, choisir le dossier `karibtruck/` (celui du `Package.swift`), puis
   lier le produit **`KaribTruckCore`** à la cible de l'app.
4. Build & Run sur le simulateur iPad ou l'iPad.

## À suivre (au-delà du M0)

- Écrans dédiés pour checklists, réception (avec photo d'étiquette via
  `PhotosPicker` / caméra), huile de friture, non-conformités, planning marché —
  chacun appelle une action déjà prête du `Store`.
- Export **PDF** du dossier de contrôle (mise en page côté app, la donnée vient
  de `InspectionExport`).
- Verrouillage Face ID (LocalAuthentication) et sauvegarde chiffrée exportable.
