// CatStationMaster.swift — la mascotte de l'ébauche : un chat chef de gare.
//
// Choix PROVISOIRE (le panel d'experts pourra en changer) : un chat roux en
// casquette de chef de gare, clin d'œil à « minouche ». Dessin vectoriel en
// attendant un illustrateur. Il ne dit jamais « faux » : il salue, écoute, fait
// la fête, montre le fourgon resté en gare, répète le mot, ou s'endort.
//
// Mouvements pilotés par l'HORLOGE (TimelineView) et non par des animations
// `repeatForever` lancées dans `onAppear` : celles-ci peuvent « capturer » une
// transition en cours (fondu, entrée du train) et la rejouer sans fin.

#if canImport(SwiftUI)
import SwiftUI

public enum CatMood: Hashable, Sendable {
    case hello        // salue (invite)
    case listening    // tend l'oreille pendant que l'enfant parle
    case cheering     // fait la fête (mot complet)
    case pointing     // montre gentiment le fourgon resté en gare
    case speaking     // redit le mot
    case puzzled      // n'a pas bien entendu
    case sleeping     // fin de séance
}

public struct CatStationMaster: View {
    public let mood: CatMood
    public let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blink = false

    public init(mood: CatMood, size: CGFloat = 240) {
        self.mood = mood
        self.size = size
    }

    private static let fur = Color(red: 0.97, green: 0.62, blue: 0.24)
    private static let furDark = Color(red: 0.86, green: 0.45, blue: 0.13)
    private static let coat = Color(red: 0.16, green: 0.23, blue: 0.47)
    private static let gold = Color(red: 0.98, green: 0.80, blue: 0.22)
    private static let pink = Color(red: 0.98, green: 0.62, blue: 0.68)

    public var body: some View {
        let k = size / 240
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let s = reduceMotion ? 0 : swing(at: context.date)
            ZStack {
                tail
                body_
                feet
                arms(s)
                head
                    .rotationEffect(.degrees(mood == .puzzled ? -9 : 0), anchor: UnitPoint(x: 0.5, y: 0.7))
                extras(s)
            }
            .frame(width: 200, height: 240)
            .offset(y: mood == .cheering ? -12 * s : 0)
            .scaleEffect(k)
            .frame(width: 200 * k, height: 240 * k)
        }
        .task { await blinkLoop() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// Balancement 0 → 1 → 0, plus vif pour la fête, très lent pour le sommeil.
    private func swing(at date: Date) -> Double {
        let period: Double = mood == .cheering ? 0.7 : (mood == .sleeping ? 3.2 : 1.2)
        return (1 - cos(date.timeIntervalSinceReferenceDate * 2 * .pi / period)) / 2
    }

    // MARK: Parties du corps (repère 200 × 240)

    private var tail: some View {
        Path { p in
            p.move(to: CGPoint(x: 140, y: 222))
            p.addCurve(to: CGPoint(x: 186, y: 150), control1: CGPoint(x: 200, y: 222), control2: CGPoint(x: 150, y: 170))
        }
        .stroke(Self.fur, style: StrokeStyle(lineWidth: 16, lineCap: .round))
    }

    private var body_: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Self.coat)
                .frame(width: 112, height: 88)
                .position(x: 100, y: 196)
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(Self.gold).frame(width: 9, height: 9)
                    .position(x: 100, y: 172 + CGFloat(i) * 18)
            }
            // Le sifflet du chef de gare, au bout d'un cordon rouge.
            Path { p in
                p.move(to: CGPoint(x: 86, y: 160))
                p.addQuadCurve(to: CGPoint(x: 72, y: 196), control: CGPoint(x: 70, y: 172))
            }
            .stroke(.red, lineWidth: 3)
            Capsule().fill(Self.gold).frame(width: 18, height: 9).position(x: 70, y: 200)
        }
    }

    private var feet: some View {
        ZStack {
            Ellipse().fill(Self.fur).frame(width: 36, height: 17).position(x: 78, y: 238)
            Ellipse().fill(Self.fur).frame(width: 36, height: 17).position(x: 122, y: 238)
        }
    }

    @ViewBuilder private func arms(_ s: Double) -> some View {
        switch mood {
        case .hello:
            paw(at: CGPoint(x: 50, y: 206))
            raisedArm(angle: 22 - 30 * s, at: CGPoint(x: 166, y: 150))
        case .cheering:
            raisedArm(angle: 18 + 12 * s, at: CGPoint(x: 34, y: 150), mirrored: true)
            raisedArm(angle: -18 - 12 * s, at: CGPoint(x: 166, y: 150))
        case .listening:
            paw(at: CGPoint(x: 50, y: 206))
            // La patte en cornet derrière l'oreille.
            Capsule().fill(Self.fur).frame(width: 20, height: 70)
                .rotationEffect(.degrees(-12))
                .position(x: 160, y: 132)
            Circle().fill(Self.fur).frame(width: 26, height: 26).position(x: 166, y: 96)
        case .pointing:
            paw(at: CGPoint(x: 50, y: 206))
            // Le bras montre le train, en bas à droite.
            ZStack(alignment: .leading) {
                Capsule().fill(Self.fur).frame(width: 66, height: 20)
                Circle().fill(Self.fur).frame(width: 26, height: 26).offset(x: 50)
                Capsule().fill(Self.furDark).frame(width: 18, height: 8).offset(x: 70, y: -2)
            }
            .frame(width: 96, height: 30, alignment: .leading)
            .rotationEffect(.degrees(30 + 8 * s), anchor: .leading)
            .position(x: 190, y: 184)
        case .puzzled:
            paw(at: CGPoint(x: 50, y: 206))
            Circle().fill(Self.fur).frame(width: 26, height: 26).position(x: 128, y: 168)
        case .speaking, .sleeping:
            paw(at: CGPoint(x: 50, y: 206))
            paw(at: CGPoint(x: 150, y: 206))
        }
    }

    private func paw(at p: CGPoint) -> some View {
        Circle().fill(Self.fur).frame(width: 28, height: 28).position(p)
    }

    private func raisedArm(angle: Double, at p: CGPoint, mirrored: Bool = false) -> some View {
        ZStack(alignment: .top) {
            Capsule().fill(Self.fur).frame(width: 20, height: 62)
            Circle().fill(Self.fur).frame(width: 28, height: 28).offset(y: -8)
        }
        .frame(width: 30, height: 70)
        .rotationEffect(.degrees(angle), anchor: .bottom)
        .position(x: p.x, y: p.y - 10)
    }

    private var head: some View {
        ZStack {
            ear(left: true)
            ear(left: false)
            Ellipse().fill(Self.fur).frame(width: 150, height: 124).position(x: 100, y: 110)
            // Joues
            Circle().fill(Self.pink.opacity(0.45)).frame(width: 24, height: 24).position(x: 56, y: 134)
            Circle().fill(Self.pink.opacity(0.45)).frame(width: 24, height: 24).position(x: 144, y: 134)
            eyes
            // Nez
            Path { p in
                p.move(to: CGPoint(x: 92, y: 124)); p.addLine(to: CGPoint(x: 108, y: 124))
                p.addLine(to: CGPoint(x: 100, y: 133)); p.closeSubpath()
            }.fill(Self.pink)
            mouth
            whiskers
            cap
        }
    }

    private func ear(left: Bool) -> some View {
        let s: CGFloat = left ? 1 : -1
        let x0: CGFloat = left ? 0 : 200
        let tilt: Double = mood == .listening ? (left ? -8 : 8) : 0
        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: x0 + s * 38, y: 84)); p.addLine(to: CGPoint(x: x0 + s * 48, y: 22))
                p.addLine(to: CGPoint(x: x0 + s * 84, y: 60)); p.closeSubpath()
            }.fill(Self.fur)
            Path { p in
                p.move(to: CGPoint(x: x0 + s * 47, y: 74)); p.addLine(to: CGPoint(x: x0 + s * 52, y: 36))
                p.addLine(to: CGPoint(x: x0 + s * 74, y: 60)); p.closeSubpath()
            }.fill(Self.pink)
        }
        .rotationEffect(.degrees(tilt), anchor: UnitPoint(x: left ? 0.3 : 0.7, y: 0.35))
    }

    @ViewBuilder private var eyes: some View {
        let closed = mood == .sleeping || (blink && !reduceMotion)
        ForEach([CGFloat(72), 128], id: \.self) { x in
            if closed {
                Path { p in
                    p.move(to: CGPoint(x: x - 10, y: 110))
                    p.addQuadCurve(to: CGPoint(x: x + 10, y: 110), control: CGPoint(x: x, y: 118))
                }.stroke(.black, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            } else if mood == .cheering {
                Path { p in
                    p.move(to: CGPoint(x: x - 10, y: 114))
                    p.addQuadCurve(to: CGPoint(x: x + 10, y: 114), control: CGPoint(x: x, y: 100))
                }.stroke(.black, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            } else {
                ZStack {
                    Ellipse().fill(.black).frame(width: 17, height: mood == .listening ? 25 : 22)
                    Circle().fill(.white).frame(width: 6, height: 6).offset(x: -3, y: -5)
                }
                .position(x: x, y: 110)
            }
        }
    }

    @ViewBuilder private var mouth: some View {
        if mood == .cheering || mood == .speaking {
            Ellipse().fill(Color(red: 0.55, green: 0.10, blue: 0.14))
                .frame(width: 24, height: mood == .cheering ? 20 : 15)
                .overlay(Ellipse().fill(Self.pink).frame(width: 14, height: 7).offset(y: 5))
                .clipShape(Ellipse())
                .position(x: 100, y: 146)
        } else if mood == .puzzled {
            Path { p in
                p.move(to: CGPoint(x: 92, y: 144)); p.addLine(to: CGPoint(x: 108, y: 141))
            }.stroke(.black, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        } else {
            Path { p in
                p.move(to: CGPoint(x: 100, y: 133))
                p.addQuadCurve(to: CGPoint(x: 89, y: 140), control: CGPoint(x: 97, y: 142))
                p.move(to: CGPoint(x: 100, y: 133))
                p.addQuadCurve(to: CGPoint(x: 111, y: 140), control: CGPoint(x: 103, y: 142))
            }.stroke(.black, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }

    private var whiskers: some View {
        Path { p in
            for (dy, ey) in [(CGFloat(-4), CGFloat(-12)), (2, 2), (8, 16)] {
                p.move(to: CGPoint(x: 64, y: 130 + dy)); p.addLine(to: CGPoint(x: 26, y: 130 + ey))
                p.move(to: CGPoint(x: 136, y: 130 + dy)); p.addLine(to: CGPoint(x: 174, y: 130 + ey))
            }
        }
        .stroke(Color.black.opacity(0.55), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private var cap: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 52, y: 32)); p.addLine(to: CGPoint(x: 148, y: 32))
                p.addLine(to: CGPoint(x: 142, y: 72)); p.addLine(to: CGPoint(x: 58, y: 72)); p.closeSubpath()
            }.fill(Self.coat)
            Rectangle().fill(.red).frame(width: 86, height: 11).position(x: 100, y: 66)
            Circle().fill(Self.gold).frame(width: 16, height: 16).position(x: 100, y: 48)
            Capsule().fill(.black).frame(width: 108, height: 14).position(x: 106, y: 78)
        }
    }

    @ViewBuilder private func extras(_ s: Double) -> some View {
        switch mood {
        case .listening:
            ForEach(0..<2, id: \.self) { i in
                Circle().trim(from: 0.62, to: 0.88)
                    .stroke(Color.teal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: CGFloat(34 + i * 22), height: CGFloat(34 + i * 22))
                    .rotationEffect(.degrees(95))
                    .opacity(0.35 + 0.65 * s)
                    .position(x: 184, y: 80)
            }
        case .cheering:
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: CGFloat(18 + (i % 2) * 8)))
                    .foregroundStyle(Self.gold)
                    .position(x: [12, 188, 30, 176][i], y: [40, 36, 100, 104][i])
                    .scaleEffect(0.85 + 0.3 * s)
            }
        case .sleeping:
            Text("z Z")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .position(x: 176, y: 30 - 12 * s)
        case .puzzled:
            Text("?")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.teal)
                .position(x: 178, y: 40)
        default:
            EmptyView()
        }
    }

    // MARK: Mouvement

    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            blink = true
            try? await Task.sleep(nanoseconds: 160_000_000)
            blink = false
        }
    }

    private var accessibilityText: String {
        switch mood {
        case .hello: return "Le chat chef de gare te salue"
        case .listening: return "Le chat chef de gare t'écoute"
        case .cheering: return "Le chat chef de gare fait la fête"
        case .pointing: return "Le chat chef de gare montre le fourgon"
        case .speaking: return "Le chat chef de gare dit le mot"
        case .puzzled: return "Le chat chef de gare n'a pas bien entendu"
        case .sleeping: return "Le chat chef de gare dort"
        }
    }
}

#Preview("Humeurs") {
    HStack(spacing: 30) {
        ForEach([CatMood.hello, .listening, .cheering, .pointing, .speaking, .puzzled, .sleeping], id: \.self) {
            CatStationMaster(mood: $0, size: 160)
        }
    }
    .padding(40)
    .background(EveilPalette.skyLight)
}
#endif
