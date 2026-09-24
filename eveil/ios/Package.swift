// swift-tools-version:5.9
// Suite Éveil — paquet Swift de l'app 1 (le petit train des mots).
//
//   WordEndCore      Swift pur (Foundation) : détecteur, flux, pédagogie, lexiques,
//                    synthèse de test. Compile sur iOS, macOS et Linux → `swift test`.
//   WordEndAudio     AVFoundation : session `.measurement`, micro 24 kHz, écoute.
//   TrainPracticeUI  SwiftUI : le train, la mascotte, l'écran d'entraînement,
//                    l'espace parent, le journal local (SwiftData).
//
// Les cibles Apple-only sont protégées par `#if canImport(...)` : sur Linux elles
// compilent à vide, ce qui garde `swift test` utilisable partout.

import PackageDescription

let package = Package(
    name: "EveilTrain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WordEndCore", targets: ["WordEndCore"]),
        .library(name: "WordEndAudio", targets: ["WordEndAudio"]),
        .library(name: "TrainPracticeUI", targets: ["TrainPracticeUI"]),
    ],
    targets: [
        .target(name: "WordEndCore"),
        .target(name: "WordEndAudio", dependencies: ["WordEndCore"]),
        .target(name: "TrainPracticeUI", dependencies: ["WordEndCore", "WordEndAudio"]),
        .testTarget(
            name: "WordEndCoreTests",
            dependencies: ["WordEndCore"],
            exclude: ["Resources"]      // lu via #filePath (source unique, produite par Python)
        ),
    ]
)
