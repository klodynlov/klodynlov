// TrainView.swift — le petit train : une locomotive, un wagon par syllabe
// ORALE, et le fourgon de queue pour la consonne finale.
//
// Métaphore choisie : quand l'enfant produit la fin du mot, le fourgon
// « s'accroche » au train. S'il manque, il est « resté en gare » : une image
// concrète, non culpabilisante, et le son du fourgon (« chhh », la vapeur ;
// « sss », le serpent) est un symbole sonore classique en orthophonie.
//
// États du fourgon (cf. `CabooseState`) : accroché, montré (seulement sur un
// verdict SÛR), en attente (neutre), absent (mot sans consonne finale).
// Le train entre en gare à chaque nouveau mot (la vue est recréée par mot), et
// repart vers la gauche (`departing`) pour rejoindre un autre monde.

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI
import WordEndCore

public struct TrainView: View {
    public let wagons: [String]
    public let lit: [Bool]
    public let cabooseLabel: String?
    public let caboose: CabooseState
    public var showsLetters = true            // lettres pour l'adulte ; l'enfant voit les couleurs
    public var scale: CGFloat = 1
    /// Vrai : le train quitte la gare (vers la gauche) — le voyage vers un autre monde.
    public var departing = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Mouvement piloté par l'HORLOGE : l'instant d'entrée en gare et de départ.
    /// Pas d'animation SwiftUI sur le déplacement — combinée aux horloges internes
    /// (vapeur, fourgon qui respire), elle faisait trembler ou clignoter le train.
    @State private var enteredAt: Date?
    @State private var leftAt: Date?
    @State private var moving = true

    static let enterDuration = 1.5
    static let leaveDuration = 1.1

    public init(wagons: [String], lit: [Bool], cabooseLabel: String?, caboose: CabooseState,
                showsLetters: Bool = true, scale: CGFloat = 1, departing: Bool = false) {
        self.wagons = wagons
        self.lit = lit
        self.cabooseLabel = cabooseLabel
        self.caboose = caboose
        self.showsLetters = showsLetters
        self.scale = scale
        self.departing = departing
    }

    // Dimensions de base (avant `scale`).
    static let locoWidth: CGFloat = 196
    static let wagonWidth: CGFloat = 128
    static let cabooseWidth: CGFloat = 120
    static let height: CGFloat = 176

    /// Largeur du train avant mise à l'échelle (pour ajuster `scale` à l'écran).
    public static func baseWidth(wagons: Int, hasCaboose: Bool) -> CGFloat {
        locoWidth + CGFloat(wagons) * wagonWidth + (hasCaboose ? cabooseWidth + 96 : 0) + 40
    }

    private var hasCaboose: Bool { cabooseLabel != nil && caboose != .none }
    private var cabooseGap: CGFloat {
        switch caboose {
        case .hooked: return 0
        case .waiting: return 34
        case .pointed: return 96
        case .none: return 0
        }
    }
    private var baseWidth: CGFloat { Self.baseWidth(wagons: wagons.count, hasCaboose: hasCaboose) }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !moving || reduceMotion)) { context in
            let x = offset(at: context.date)
            ZStack(alignment: .bottomLeading) {
                RailsView(width: baseWidth)
                HStack(alignment: .bottom, spacing: 0) {
                    LocomotiveView(travel: x, steaming: moving || caboose == .hooked)
                    ForEach(Array(wagons.enumerated()), id: \.offset) { index, label in
                        WagonCar(label: label, lit: lit.indices.contains(index) && lit[index],
                                 showsLetters: showsLetters, travel: x)
                    }
                    .animation(reduceMotion ? nil : .spring(duration: 0.45), value: lit)
                    if let cabooseLabel, hasCaboose {
                        // Le fourgon resté en gare « respire » doucement (horloge, pas de boucle d'animation).
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: caboose != .pointed || reduceMotion)) { inner in
                            let breath = caboose == .pointed && !reduceMotion
                                ? (1 - cos(inner.date.timeIntervalSinceReferenceDate * 2 * .pi / 1.6)) / 2 : 0
                            CabooseCar(label: cabooseLabel, state: caboose, showsLetters: showsLetters, travel: x)
                                .scaleEffect(1 + 0.06 * breath, anchor: .bottom)
                        }
                        .padding(.leading, cabooseGap)
                        .animation(reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.35), value: caboose)
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 10)
                .offset(x: x)
                .opacity(reduceMotion && leftAt != nil ? 0 : 1)
            }
        }
        .frame(width: baseWidth, height: Self.height, alignment: .bottomLeading)
        .scaleEffect(scale, anchor: .bottomLeading)
        .frame(width: baseWidth * scale, height: Self.height * scale, alignment: .bottomLeading)
        .onAppear {
            guard enteredAt == nil else { return }
            enteredAt = Date()
            settle(after: Self.enterDuration)
        }
        .onChange(of: departing) { _, leaving in
            guard leaving, leftAt == nil else { return }
            leftAt = Date()
            moving = true
            settle(after: Self.leaveDuration)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Décalage horizontal (repère de base) : entrée par la droite en freinant,
    /// départ par la gauche en accélérant. « Réduire les animations » : pas de trajet.
    private func offset(at date: Date) -> CGFloat {
        if let leftAt {
            if reduceMotion { return -(1400 + baseWidth) }
            let p = min(1, max(0, date.timeIntervalSince(leftAt) / Self.leaveDuration))
            return -(1400 + baseWidth) * CGFloat(p * p * p)
        }
        guard let enteredAt, !reduceMotion else { return reduceMotion ? 0 : 1400 }
        let p = min(1, max(0, date.timeIntervalSince(enteredAt) / Self.enterDuration))
        return 1400 * CGFloat(pow(1 - p, 3))
    }

    /// Arrête l'horloge du trajet une fois le mouvement fini (le train est à quai, ou parti).
    private func settle(after seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((seconds + 0.1) * 1_000_000_000))
            moving = false
        }
    }

    private var accessibilityDescription: String {
        let cars = wagons.enumerated().map { i, w in
            "wagon \(w) " + (lit.indices.contains(i) && lit[i] ? "allumé" : "éteint")
        }
        var parts = ["Le petit train"] + cars
        if let cabooseLabel {
            switch caboose {
            case .hooked: parts.append("fourgon \(cabooseLabel) accroché")
            case .pointed: parts.append("fourgon \(cabooseLabel) resté en gare")
            case .waiting: parts.append("fourgon \(cabooseLabel) en attente")
            case .none: break
            }
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Pièces du train (repère de base, hauteur 176)

struct RailsView: View {
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 22) {
                ForEach(0..<Int(width / 40) + 1, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2).fill(EveilPalette.rail.opacity(0.75))
                        .frame(width: 18, height: 12)
                }
            }
            .frame(width: width, alignment: .leading)
            .clipped()
            Rectangle().fill(EveilPalette.rail).frame(width: width, height: 5).offset(y: -8)
        }
        .frame(width: width, height: 14)
        .accessibilityHidden(true)
    }
}

/// Une roue qui ROULE sans glisser : son angle suit la distance parcourue.
struct Wheel: View {
    let diameter: CGFloat
    let travel: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color(white: 0.22))
            Circle().stroke(Color(white: 0.45), lineWidth: 3).padding(5)
            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(Color(white: 0.55)).frame(width: 3, height: diameter - 12)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
            Circle().fill(EveilPalette.sun).frame(width: diameter * 0.26, height: diameter * 0.26)
        }
        .frame(width: diameter, height: diameter)
        .rotationEffect(.degrees(-Double(travel) / (Double.pi * Double(diameter)) * 360))
    }
}

/// Bouffées de vapeur au-dessus de la cheminée (ou du fourgon accroché).
///
/// Mouvement piloté par l'HORLOGE (TimelineView), pas par une animation
/// `repeatForever` lancée dans `onAppear` : insérée pendant une transition,
/// celle-ci « capturait » l'entrée du train, qui clignotait alors sans fin.
struct SteamPuffs: View {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !active)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let rise = reduceMotion ? 0 : (1 - cos(t * 2 * .pi / 2.2)) / 2      // 0 → 1 → 0 en 2,2 s
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(.white.opacity(active ? 0.9 - Double(i) * 0.2 : 0))
                        .frame(width: CGFloat(22 + i * 10), height: CGFloat(22 + i * 10))
                        .offset(x: CGFloat(i) * 18 + 10 * rise, y: -CGFloat(i) * 22 - 16 * rise)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct LocomotiveView: View {
    let travel: CGFloat
    let steaming: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Chaudière et avant arrondi (la locomotive regarde vers la gauche)
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(EveilPalette.loco)
                .frame(width: 124, height: 64).offset(x: 12, y: 60)
            Circle().fill(EveilPalette.locoDark).frame(width: 46, height: 46).offset(x: 2, y: 69)
            Circle().fill(EveilPalette.sun).frame(width: 16, height: 16).offset(x: 6, y: 64)
            // Cheminée
            Path { p in
                p.move(to: CGPoint(x: 36, y: 18)); p.addLine(to: CGPoint(x: 78, y: 18))
                p.addLine(to: CGPoint(x: 68, y: 62)); p.addLine(to: CGPoint(x: 46, y: 62)); p.closeSubpath()
            }.fill(Color(white: 0.2))
            SteamPuffs(active: steaming).offset(x: 44, y: -8)
            // Dôme doré
            Capsule().fill(EveilPalette.sun).frame(width: 30, height: 22).offset(x: 88, y: 48)
            // Cabine
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(EveilPalette.loco)
                .frame(width: 70, height: 106).offset(x: 124, y: 18)
            RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.2))
                .frame(width: 84, height: 14).offset(x: 117, y: 8)
            RoundedRectangle(cornerRadius: 8).fill(EveilPalette.skyLight)
                .frame(width: 38, height: 34).offset(x: 140, y: 34)
            // Chasse-pierres et châssis
            Path { p in
                p.move(to: CGPoint(x: 0, y: 150)); p.addLine(to: CGPoint(x: 28, y: 124))
                p.addLine(to: CGPoint(x: 28, y: 150)); p.closeSubpath()
            }.fill(Color(white: 0.3))
            RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.25))
                .frame(width: 176, height: 14).offset(x: 20, y: 122)
            Wheel(diameter: 40, travel: travel).offset(x: 34, y: 126)
            Wheel(diameter: 40, travel: travel).offset(x: 84, y: 126)
            Wheel(diameter: 52, travel: travel).offset(x: 134, y: 114)
        }
        .frame(width: TrainView.locoWidth, height: TrainView.height, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

struct Coupling: View {
    var dashed = false
    var body: some View {
        Capsule()
            .stroke(Color(white: 0.3), style: StrokeStyle(lineWidth: 5, dash: dashed ? [4, 5] : []))
            .frame(width: 14, height: 6)
    }
}

struct WagonCar: View {
    let label: String
    let lit: Bool
    let showsLetters: Bool
    let travel: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Coupling().offset(x: -6, y: 124)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(lit ? EveilPalette.wagonLit : EveilPalette.wagonOff)
                .shadow(color: lit ? EveilPalette.wagonLit.opacity(0.8) : .clear, radius: lit ? 16 : 0)
                .frame(width: 116, height: 84).offset(x: 8, y: 40)
            RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.35))
                .frame(width: 100, height: 10).offset(x: 16, y: 48)
            Text(showsLetters ? label : " ")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(lit ? EveilPalette.ink : Color.gray)
                .minimumScaleFactor(0.5)
                .frame(width: 116, height: 70).offset(x: 8, y: 56)
            RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.25))
                .frame(width: 110, height: 10).offset(x: 11, y: 124)
            Wheel(diameter: 34, travel: travel).offset(x: 22, y: 128)
            Wheel(diameter: 34, travel: travel).offset(x: 80, y: 128)
            if lit {
                Image(systemName: "sparkles").font(.system(size: 30))
                    .foregroundStyle(EveilPalette.sun)
                    .offset(x: 92, y: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: TrainView.wagonWidth, height: TrainView.height, alignment: .topLeading)
    }
}

struct CabooseCar: View {
    let label: String
    let state: CabooseState
    let showsLetters: Bool
    let travel: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if state == .pointed {
                // Le quai de la gare, où le fourgon attend.
                RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.62))
                    .frame(width: 124, height: 16).offset(x: -2, y: 164)
                VStack(spacing: 0) {
                    Text("GARE")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color(red: 0.16, green: 0.23, blue: 0.47)))
                    Rectangle().fill(Color(white: 0.35)).frame(width: 5, height: 26)
                }
                .offset(x: 92, y: 0)
            } else {
                Coupling(dashed: state == .waiting).offset(x: -6, y: 124)
            }
            RoundedRectangle(cornerRadius: 6).fill(state == .hooked ? EveilPalette.locoDark : Color(white: 0.7))
                .frame(width: 44, height: 22).offset(x: 40, y: 32)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(state == .hooked ? EveilPalette.caboose : EveilPalette.caboose.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(EveilPalette.caboose, style: StrokeStyle(lineWidth: 3, dash: state == .hooked ? [] : [8, 6]))
                )
                .frame(width: 108, height: 72).offset(x: 8, y: 52)
            Text(showsLetters ? label : " ")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(state == .hooked ? .white : EveilPalette.caboose)
                .frame(width: 108, height: 72).offset(x: 8, y: 52)
            RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.25))
                .frame(width: 100, height: 10).offset(x: 12, y: 124)
            Wheel(diameter: 34, travel: travel).offset(x: 20, y: 128)
            Wheel(diameter: 34, travel: travel).offset(x: 72, y: 128)
            if state == .hooked {
                // La vapeur du « chhh » quand le fourgon s'accroche.
                SteamPuffs(active: true).offset(x: 30, y: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: TrainView.cabooseWidth, height: TrainView.height, alignment: .topLeading)
    }
}

#Preview("Fin manquante") {
    TrainView(wagons: ["mi", "nou"], lit: [true, true], cabooseLabel: "ch", caboose: .pointed)
        .padding()
}

#Preview("Complet") {
    TrainView(wagons: ["dou"], lit: [true], cabooseLabel: "ch", caboose: .hooked, scale: 1.4)
        .padding()
}
#endif
