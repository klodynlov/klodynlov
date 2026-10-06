// AppIconArt.swift — l'icône de l'app, dessinée avec les pièces de l'app elle-même.
//
// Le chat chef de gare (mascotte provisoire) et la locomotive rouge de l'accueil, sur le ciel
// de l'app. Rendue en PNG 1024 × 1024 opaque par `AppIconTests` (EVEIL_APPICON_OUT) puis
// déposée dans `App/Assets.xcassets/AppIcon.appiconset/`.

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI

public struct AppIconArt: View {
    public enum Variant: String, CaseIterable, Sendable { case cat, catAndLoco, catOverTrain }
    public let variant: Variant
    public static let side: CGFloat = 1024

    public init(variant: Variant = .catAndLoco) { self.variant = variant }

    public var body: some View {
        let w = Self.side
        ZStack {
            LinearGradient(colors: [EveilPalette.sky, EveilPalette.skyLight], startPoint: .top, endPoint: .bottom)
            Circle().fill(EveilPalette.sun)
                .frame(width: 250, height: 250)
                .shadow(color: EveilPalette.sun.opacity(0.7), radius: 40)
                .position(x: w * 0.16, y: w * 0.15)
            CloudShape().fill(.white.opacity(0.9))
                .frame(width: 300, height: 114)
                .position(x: w * 0.74, y: w * 0.17)
            Ellipse().fill(EveilPalette.hill)
                .frame(width: w * 1.1, height: w * 0.42)
                .position(x: w * 0.2, y: w * 0.86)
            Ellipse().fill(EveilPalette.hill.opacity(0.85))
                .frame(width: w * 0.9, height: w * 0.36)
                .position(x: w * 0.92, y: w * 0.88)
            Rectangle().fill(EveilPalette.grass)
                .frame(width: w, height: w * 0.2)
                .position(x: w / 2, y: w * 0.9)
            subject
        }
        .frame(width: w, height: w)
        .clipped()
        .accessibilityHidden(true)
    }

    @ViewBuilder private var subject: some View {
        let w = Self.side
        switch variant {
        case .cat:
            CatStationMaster(mood: .hello, size: 1000)
                .position(x: w / 2, y: w * 0.56)
        case .catAndLoco:
            let k: CGFloat = 2.75
            rails(y: w * 0.88)
            LocomotiveView(travel: 0, steaming: true)
                .scaleEffect(k, anchor: .topLeading)
                .frame(width: TrainView.locoWidth * k, height: TrainView.height * k, alignment: .topLeading)
                .position(x: w * 0.71, y: w * 0.88 - TrainView.height * k / 2 + 8)
            CatStationMaster(mood: .hello, size: 700)
                .position(x: w * 0.245, y: w * 0.545)
        case .catOverTrain:
            CatStationMaster(mood: .hello, size: 760)
                .position(x: w / 2, y: w * 0.40)
            rails(y: w * 0.95)
            HStack(spacing: 0) {
                LocomotiveView(travel: 0, steaming: false)
                WagonCar(label: "mi", lit: true, showsLetters: true, travel: 0)
                CabooseCar(label: "ch", state: .hooked, showsLetters: true, travel: 0)
            }
            .scaleEffect(1.9, anchor: .topLeading)
            .frame(width: (TrainView.locoWidth + TrainView.wagonWidth + TrainView.cabooseWidth) * 1.9,
                   height: TrainView.height * 1.9, alignment: .topLeading)
            .position(x: w / 2 + 20, y: w * 0.95 - TrainView.height * 1.9 / 2 + 6)
        }
    }

    private func rails(y: CGFloat) -> some View {
        RailsView(width: Self.side / 3)
            .scaleEffect(3, anchor: .center)
            .frame(width: Self.side, height: 42)
            .position(x: Self.side / 2, y: y)
    }
}
#endif
