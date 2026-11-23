// swift-tools-version:5.9
// WordEndCore — le cœur portable du Petit Train des mots (Swift pur, Foundation).
//
// Paquet AUTONOME, volontairement séparé de la couche AVFoundation / SwiftUI :
// `swift test` compile toutes les cibles d'un paquet (`.allIncludingTests`) ;
// isolé ici, le cœur et ses tests de parité avec la référence Python se
// compilent et tournent seuls — sur macOS, iOS et Linux — quoi qu'il arrive
// à l'interface.
//
//   cd eveil/ios/WordEndCore && swift test

import PackageDescription

let package = Package(
    name: "WordEndCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WordEndCore", targets: ["WordEndCore"]),
    ],
    targets: [
        .target(name: "WordEndCore"),
        .testTarget(
            name: "WordEndCoreTests",
            dependencies: ["WordEndCore"],
            exclude: ["Resources"]      // lu via #filePath (source unique, produite par Python)
        ),
    ]
)
