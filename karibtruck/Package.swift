// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KaribTruck",
    products: [
        .library(name: "KaribTruckCore", targets: ["KaribTruckCore"]),
    ],
    targets: [
        // Cœur métier : pur, sans dépendance, portable Linux (CI) ↔ Apple (app).
        .target(name: "KaribTruckCore"),
        .testTarget(
            name: "KaribTruckCoreTests",
            dependencies: ["KaribTruckCore"]
        ),
    ]
)
