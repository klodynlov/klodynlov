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
//   ColoringUI       l'Atelier de coloriage (app 2) : pochoirs à colorier au doigt.
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
        .target(
            name: "TrainPracticeUI",
            dependencies: [.product(name: "WordEndCore", package: "WordEndCore"), "WordEndAudio", "EveilDesign"]
        ),
        .target(name: "ColoringUI", dependencies: ["EveilDesign"]),
        // Le mode démo montre ce qu'il annonce, pour chaque mot (macOS : `swift test` ici).
        .testTarget(
            name: "EveilTrainTests",
            dependencies: ["TrainPracticeUI", .product(name: "WordEndCore", package: "WordEndCore")]
        ),
    ]
)
