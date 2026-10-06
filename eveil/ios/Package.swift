// swift-tools-version:5.9
// Suite Éveil — couche app du Petit Train des mots (Apple uniquement).
//
//   WordEndCore      paquet autonome ./WordEndCore (Swift pur : détecteur, flux,
//                    pédagogie, lexiques, synthèse de test) — c'est LUI qu'on teste :
//                    `cd WordEndCore && swift test`.
//   WordEndAudio     AVFoundation : session `.measurement`, micro 24 kHz, écoute.
//   TrainPracticeUI  SwiftUI : le train, l'écran d'entraînement, le mode démo,
//                    l'espace parent, le journal local (SwiftData).
//   EveilDesign      l'univers visuel commun : décor, gros boutons, la mascotte
//                    (chat chef de gare, choix provisoire).
//   ColoringUI       l'Atelier de coloriage (app 2) : zones délimitées par les traits,
//                    remplir au doigt ou peindre au pinceau-pochoir.
//   EveilSounds      les bruitages, SYNTHÉTISÉS sur l'appareil (aucun fichier son,
//                    rien d'enregistré) : train, bestioles, objets des mots.
//   PhraseCore       le train des phrases (Swift pur) : lexique qui/fait quoi/quoi/où,
//                    grammaire FR/EN, niveaux et plateaux — parité avec eveil/outils/phrases.
//
// Les cibles sont protégées par `#if canImport(...)` : hors plateformes Apple
// elles compilent à vide. Xcode 16+ recommandé (SwiftUI `View` isolée MainActor).

import PackageDescription

let package = Package(
    name: "EveilTrain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WordEndAudio", targets: ["WordEndAudio"]),
        .library(name: "TrainPracticeUI", targets: ["TrainPracticeUI"]),
        .library(name: "EveilDesign", targets: ["EveilDesign"]),
        .library(name: "ColoringUI", targets: ["ColoringUI"]),
        .library(name: "EveilSounds", targets: ["EveilSounds"]),
    ],
    dependencies: [
        .package(path: "WordEndCore"),
    ],
    targets: [
        .target(
            name: "WordEndAudio",
            dependencies: [.product(name: "WordEndCore", package: "WordEndCore")]
        ),
        .target(name: "EveilDesign"),
        .target(name: "EveilSounds"),
        .target(name: "PhraseCore"),
        .target(
            name: "TrainPracticeUI",
            dependencies: [.product(name: "WordEndCore", package: "WordEndCore"), "WordEndAudio", "EveilDesign",
                           "EveilSounds", "PhraseCore"],
            // La planche des gestes de Lou (Borel-Maisonny), page « Gestes (à valider) » de l'espace des
            // grands, 06/10/2026 : générée par `python3 -m gestes.planche` (eveil/outils).
            resources: [.copy("Resources/gestes-lou.pdf")]
        ),
        // Mode interactif (28/09/2026) : la voix nomme les couleurs, chaque couleur a sa note.
        .target(name: "ColoringUI", dependencies: ["EveilDesign", "EveilSounds", "WordEndAudio"]),
        // Le mode démo montre ce qu'il annonce, pour chaque mot (macOS : `swift test` ici).
        .testTarget(
            name: "EveilTrainTests",
            dependencies: ["TrainPracticeUI", "EveilSounds", "EveilDesign", "WordEndAudio", "PhraseCore",
                           .product(name: "WordEndCore", package: "WordEndCore")]
        ),
        // Chaque bruitage se calcule, reste fini, audible et sans saturation.
        .testTarget(name: "EveilSoundsTests", dependencies: ["EveilSounds"]),
        // Décors, bestioles, dessins des mots : rendus en PNG pour les relire (EVEIL_RENDER_DIR).
        .testTarget(name: "EveilDesignTests", dependencies: ["EveilDesign"]),
        // Zones du coloriage : ce que les traits délimitent, et rien d'autre.
        .testTarget(name: "ColoringUITests", dependencies: ["ColoringUI", "EveilDesign"]),
        // Le train des phrases : mêmes phrases et mêmes plateaux que la référence Python.
        .testTarget(name: "PhraseCoreTests", dependencies: ["PhraseCore"], exclude: ["Resources"]),
    ]
)
