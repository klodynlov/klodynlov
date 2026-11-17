// CritterLayer.swift — les petites bêtes qui volent derrière le mot, et qu'on attrape.
//
// « Pour le mot mouche : des mouches volent en arrière-plan ; quand l'enfant en
// attrape une, il entend le son que fait la mouche » (utilisateur, 25/09/2026).
//
// - Vol : trajectoires douces calculées à partir du temps (sommes de sinus,
//   montées de bulles, chutes de feuilles) — pas d'état par image, peu coûteux.
// - Attraper : toucher une bestiole la fait éclater en étoiles avec SON bruit ;
//   elle revient un peu plus tard. Grandes zones de toucher (3 ans).
// - Tour de parole strict : pendant le mot modèle et l'écoute (`hushed`), elles
//   ralentissent et se TAISENT — un toucher les fait seulement frétiller. Aucun
//   son ne doit jamais se mêler à la voix de l'enfant.
// - « Réduire les animations » : elles restent à leur place, et se touchent quand même.

#if canImport(SwiftUI)
import EveilDesign
import EveilSounds
import SwiftUI

struct CritterLayer: View {
    let scene: WordScene
    let hushed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var hushStart: Date?
    @State private var hushedTotal: TimeInterval = 0
    @State private var caughtAt: [Int: Date] = [:]
    @State private var wiggles: [Int: Int] = [:]

    /// Pendant l'écoute, le temps des bestioles s'écoule à 35 % : elles se calment.
    private static let hushedRate = 0.35
    private static let burst = 0.5          // durée de l'éclat quand on attrape
    private static let away = 2.6           // absence avant de revenir
    private static let comeback = 0.6       // retour en fondu

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let now = context.date
                let t = reduceMotion ? 0 : flightTime(now)
                ZStack {
                    ForEach(0..<scene.count, id: \.self) { i in
                        critter(i, t: t, now: now, in: geo.size)
                    }
                }
            }
        }
        .onAppear {
            start = Date()
            if hushed { hushStart = start }
        }
        .onChange(of: hushed) { _, isHushed in
            if isHushed {
                hushStart = Date()
            } else if let begin = hushStart {
                hushedTotal += Date().timeIntervalSince(begin)
                hushStart = nil
            }
        }
    }

    /// Temps de vol : continu (jamais de saut), ralenti pendant l'écoute.
    private func flightTime(_ now: Date) -> TimeInterval {
        let raw = now.timeIntervalSince(start)
        let hushedSoFar = hushedTotal + (hushStart.map { now.timeIntervalSince($0) } ?? 0)
        return raw - (1 - Self.hushedRate) * hushedSoFar
    }

    // MARK: Une bestiole

    @ViewBuilder
    private func critter(_ i: Int, t: TimeInterval, now: Date, in size: CGSize) -> some View {
        let unit = min(size.width, size.height) / 834
        let side = Self.baseSize(scene.critter) * (0.85 + 0.3 * Self.rand(i, 7)) * max(unit, 0.8)
        let p = position(i, t: t, in: size)
        let ahead = position(i, t: t + 0.05, in: size)
        let facingLeft = ahead.x < p.x
        let caught = caughtAt[i].map { now.timeIntervalSince($0) }
        let state = Self.catchState(caught)
        ZStack {
            if state.bursting {
                BurstRing(progress: state.burstProgress, color: Self.burstColor(scene.critter))
                    .frame(width: side * 2.2, height: side * 2.2)
            }
            CritterView(kind: scene.critter, size: side, flapping: !reduceMotion, tint: Self.tint(scene.critter, i))
                .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
                .rotationEffect(.degrees(spin(i, t: t)))
                .modifier(Wiggle(count: wiggles[i] ?? 0))
                .scaleEffect(state.scale)
                .opacity(state.opacity * entrance(now))
        }
        .frame(width: side * 1.8, height: side * 1.8)
        .contentShape(Circle())
        .onTapGesture { touch(i) }
        .allowsHitTesting(state.catchable)
        .position(p)
        .accessibilityHidden(true)
    }

    private func touch(_ i: Int) {
        if hushed {
            withAnimation(.easeOut(duration: 0.45)) { wiggles[i, default: 0] += 1 }   // elle frétille, sans bruit
            return
        }
        caughtAt[i] = Date()
        SoundBoard.shared.play(WordScene.sound(of: scene.critter), variant: i)
    }

    /// Les bestioles apparaissent doucement avec le mot.
    private func entrance(_ now: Date) -> Double {
        min(1, max(0, now.timeIntervalSince(start) / 0.8))
    }

    // MARK: Trajectoires

    private enum Motion { case wander(speed: Double), rise, fall }

    private static func motion(_ kind: CritterKind) -> Motion {
        switch kind {
        case .fly: return .wander(speed: 1.5)
        case .bee: return .wander(speed: 1.2)
        case .bird: return .wander(speed: 0.9)
        case .butterfly: return .wander(speed: 0.6)
        case .star: return .wander(speed: 0.35)
        case .bubble, .note, .spark, .heart: return .rise
        case .drop, .leaf, .snowflake, .paint, .feather: return .fall
        }
    }

    private func position(_ i: Int, t: TimeInterval, in size: CGSize) -> CGPoint {
        let w = size.width, h = size.height
        let r = { (k: Int) in Self.rand(i, k) }
        let tau = 2 * Double.pi
        switch Self.motion(scene.critter) {
        case let .wander(speed):
            let fx = (0.035 + 0.025 * r(1)) * speed
            let fy = (0.05 + 0.04 * r(2)) * speed
            var x = 0.5 + 0.40 * sin(tau * fx * t + tau * r(3)) + 0.06 * sin(tau * 2.7 * fx * t + tau * r(4))
            var y = (0.20 + 0.30 * r(5)) + 0.10 * sin(tau * fy * t + tau * r(6)) + 0.03 * sin(tau * 3.1 * fy * t)
            if scene.critter == .fly {                   // la mouche : petits zigzags
                x += 0.012 * sin(tau * 1.7 * t + tau * r(8))
                y += 0.010 * sin(tau * 2.3 * t + tau * r(9))
            }
            if scene.critter == .butterfly { y += 0.02 * sin(tau * 0.9 * t + tau * r(8)) }   // vol sautillant
            return CGPoint(x: w * x, y: h * y)
        case .rise:
            let period = 10 + 5 * r(1)
            let progress = Self.frac((t + period * Double(i) / Double(max(scene.count, 1))) / period)
            let x = (0.08 + 0.84 * Self.frac(r(2) + 0.37 * Double(i))) + 0.04 * sin(tau * 0.3 * t + tau * r(3))
            return CGPoint(x: w * x, y: h * (0.70 - 0.62 * progress))
        case .fall:
            let period = 11 + 6 * r(1)
            let progress = Self.frac((t + period * Double(i) / Double(max(scene.count, 1))) / period)
            let sway = (scene.critter == .leaf || scene.critter == .feather) ? 0.07 : 0.025
            let x = (0.08 + 0.84 * Self.frac(r(2) + 0.37 * Double(i))) + sway * sin(tau * 0.25 * t + tau * r(3))
            return CGPoint(x: w * x, y: h * (0.08 + 0.62 * progress))
        }
    }

    private func spin(_ i: Int, t: TimeInterval) -> Double {
        switch scene.critter {
        case .leaf, .feather: return 25 * sin(2 * .pi * 0.25 * t + 6.28 * Self.rand(i, 3))
        case .snowflake, .star: return t * 20 + 360 * Self.rand(i, 4)
        default: return 0
        }
    }

    // MARK: Attraper

    private struct CatchState {
        var opacity = 1.0
        var scale = 1.0
        var bursting = false
        var burstProgress = 0.0
        var catchable = true
    }

    private static func catchState(_ elapsed: TimeInterval?) -> CatchState {
        guard let e = elapsed else { return CatchState() }
        if e < burst {
            let k = e / burst
            return CatchState(opacity: 1 - k, scale: 1 + 0.6 * k, bursting: true, burstProgress: k, catchable: false)
        }
        if e < burst + away { return CatchState(opacity: 0, scale: 1, catchable: false) }
        if e < burst + away + comeback {
            let k = (e - burst - away) / comeback
            return CatchState(opacity: k, scale: 0.6 + 0.4 * k, catchable: false)
        }
        return CatchState()
    }

    // MARK: Tailles, couleurs, hasard déterministe

    private static func baseSize(_ kind: CritterKind) -> CGFloat {
        switch kind {
        case .fly, .bee: return 70
        case .bird, .butterfly: return 80
        case .bubble: return 72
        case .feather: return 70
        case .drop, .spark, .heart, .snowflake, .paint: return 54
        case .note, .leaf, .star: return 62
        }
    }

    private static let palette: [Color] = [
        Color(red: 0.93, green: 0.30, blue: 0.45), Color(red: 1.0, green: 0.62, blue: 0.15),
        Color(red: 0.25, green: 0.62, blue: 0.95), Color(red: 0.55, green: 0.40, blue: 0.90),
        Color(red: 0.25, green: 0.75, blue: 0.45), Color(red: 1.0, green: 0.80, blue: 0.20),
    ]

    private static func tint(_ kind: CritterKind, _ i: Int) -> Color? {
        switch kind {
        case .butterfly, .note, .paint: return palette[i % palette.count]
        default: return nil
        }
    }

    private static func burstColor(_ kind: CritterKind) -> Color {
        switch kind {
        case .bubble, .drop, .snowflake: return Color(red: 0.55, green: 0.85, blue: 1.0)
        case .heart: return Color(red: 1.0, green: 0.45, blue: 0.6)
        default: return EveilPalette.sun
        }
    }

    /// Hasard fixe par bestiole (SplitMix64) : mêmes trajectoires à chaque fois.
    private static func rand(_ i: Int, _ k: Int) -> Double {
        var z = UInt64(truncatingIfNeeded: i &* 1_000_003 &+ k &* 7_919) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }

    private static func frac(_ x: Double) -> Double { x - x.rounded(.down) }
}

/// Un anneau d'étoiles qui s'ouvre quand on attrape une bestiole.
private struct BurstRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2 * (0.3 + 0.7 * progress)
            ZStack {
                ForEach(0..<8, id: \.self) { k in
                    let a = Double(k) / 8 * 2 * .pi
                    Image(systemName: "sparkle")
                        .font(.system(size: 16 + 10 * (1 - progress), weight: .bold))
                        .foregroundStyle(color)
                        .position(x: geo.size.width / 2 + r * cos(a), y: geo.size.height / 2 + r * sin(a))
                }
            }
            .opacity(1 - progress)
        }
    }
}

/// Frétiller : une petite secousse à chaque toucher pendant l'écoute.
private struct Wiggle: ViewModifier, Animatable {
    var count: Int
    var animatableData: Double

    init(count: Int) {
        self.count = count
        animatableData = Double(count)
    }

    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(12 * sin(animatableData * .pi * 4)))
    }
}
#endif
