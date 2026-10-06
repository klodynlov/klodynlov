// LouGesture.swift — Lou montre les gestes de Borel-Maisonny, ANIMÉS (un geste par son).
//
// Gestes validés par une orthophoniste le 06/10/2026, tels que dessinés sur la planche
// (`docs/ui/eveil-app/11-gestes-lou.png`). Décision de l'utilisateur : Lou, en grand, en portrait,
// les montre en mouvement ; sa bouche montre comment dire le son, sa main à cinq doigts fait le
// geste ; l'adulte choisit la couleur de peau (`LouSkin`).
//
// Référence : `eveil/outils/gestes/animation.py` (chronologies, testées) → `generer.py` →
// `LouGestureArt.swift` + `LouGestureData.swift` (générés). Le bras et la main sont calculés à
// chaque image (`LouGestureMotion.swift`, `LouGesturePainter.swift`).
// Tout mouvement est piloté par l'horloge (`TimelineView`) ; « Réduire les animations » : la pose
// de chaque son est tenue, sans trajectoire.

#if canImport(SwiftUI)
import SwiftUI

/// Une couleur de peau de Lou (au choix de l'adulte) : les cinq de `PEAUX`, même ordre.
public struct LouSkin: Hashable, Sendable, CaseIterable, Identifiable {
    /// « claire », « doree », « lou », « brune », « foncee ».
    public let id: String
    /// « #FCDCC0 »…
    public let hex: String
    let french: String
    let english: String

    init(id: String, hex: String, french: String, english: String) {
        self.id = id
        self.hex = hex
        self.french = french
        self.english = english
    }

    /// « peau claire »… (une locale qui commence par « fr ») ; sinon « light skin »…
    public func name(locale: String) -> String {
        locale.lowercased().hasPrefix("fr") ? french : english
    }

    /// La peau actuelle de Lou (#B8784E).
    public static let lou: LouSkin = LouSkin.with(id: "lou")!

    public static func with(id: String) -> LouSkin? {
        allCases.first { $0.id == id }
    }
}

/// Les sons qui ont un geste.
public enum LouGestures {
    /// Les étiquettes `son` qui ont un geste (« a », « ou », « ch »…), dans l'ordre de la planche.
    public static var keys: [String] { LouChronology.gestureKeys }

    /// Durée d'UNE exécution, du repos au repos (s). Un son sans geste (« ui ») : sa bouche seule
    /// (1 s) ; une étiquette inconnue : Lou au repos (1 s).
    public static func duration(of key: String) -> Double {
        LouChronology.of(key).duration
    }

    public static func has(_ key: String) -> Bool {
        LouChronology.gestures[key] != nil
    }
}

/// Une suite de sons à montrer, à partir d'un instant (les sons sans geste — ex. « ui » — ne
/// montrent que la bouche).
public struct LouPerformance: Equatable, Sendable {
    public var keys: [String]
    public var start: Date

    public init(keys: [String], start: Date) {
        self.keys = keys
        self.start = start
    }

    /// Somme des durées (s).
    public var duration: Double {
        keys.reduce(0) { $0 + LouGestures.duration(of: $1) }
    }

    /// Le son en cours (nil : pas encore commencé, ou fini).
    public func key(at date: Date) -> String? {
        locate(date)?.key
    }

    /// Le son en cours, son rang et le temps écoulé dans ce son.
    func locate(_ date: Date) -> (index: Int, key: String, local: Double)? {
        let t = date.timeIntervalSince(start)
        guard t >= 0 else { return nil }
        var begin = 0.0
        for (i, key) in keys.enumerated() {
            let end = begin + LouGestures.duration(of: key)
            if t < end - 1e-9 { return (i, key, max(0, t - begin)) }   // 1e-9 : arrondis des dates
            begin = end
        }
        return nil
    }

    /// L'image de Lou à `date` ; `reduceMotion` : la pose du son en cours, tenue.
    func frame(at date: Date, reduceMotion: Bool) -> LouFrame {
        guard let (_, key, local) = locate(date) else { return .rest }
        let chronology = LouChronology.of(key)
        var frame = chronology.frame(at: reduceMotion ? chronology.posed : local)
        frame.pulse = reduceMotion ? nil : date.timeIntervalSince(start)
        return frame
    }
}

/// Lou en grand, en portrait, qui montre les gestes d'une suite de sons.
public struct LouGestureView: View {
    let performance: LouPerformance?
    let skin: LouSkin
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished: LouRunID?

    /// `performance` nil : Lou au repos (bouche fermée, souriant). `size` = largeur ; hauteur = size × 300/260.
    public init(performance: LouPerformance?, skin: LouSkin, size: CGFloat) {
        self.performance = performance
        self.skin = skin
        self.size = size
    }

    public var body: some View {
        content
            .frame(width: size, height: size * 300 / 260)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var content: some View {
        let colors = LouColors(hex: skin.hex)
        if let performance, performance.duration > 0, finished != LouRunID(performance) {
            // L'horloge d'affichage (comme le petit train) ; animations réduites : la pose de chaque son,
            // quelques images par seconde suffisent.
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.2 : 1.0 / 60)) { timeline in
                LouCanvas(frame: performance.frame(at: timeline.date, reduceMotion: reduceMotion), colors: colors)
            }
            .task(id: LouRunID(performance)) {
                // À la fin de la suite, l'horloge s'arrête : Lou reste au repos sans redessiner.
                let left = performance.start.addingTimeInterval(performance.duration).timeIntervalSinceNow
                if left > 0 { try? await Task.sleep(nanoseconds: UInt64((left + 0.05) * 1_000_000_000)) }
                if !Task.isCancelled { finished = LouRunID(performance) }
            }
        } else {
            LouCanvas(frame: .rest, colors: colors)
        }
    }
}

/// Le portrait à un instant (cadre 260 × 300 mis à l'échelle de la place).
struct LouCanvas: View {
    let frame: LouFrame
    let colors: LouColors

    var body: some View {
        Canvas { context, area in
            let k = min(area.width / LouArt.frame.width, area.height / LouArt.frame.height)
            var g = context
            g.translateBy(x: (area.width - LouArt.frame.width * k) / 2, y: (area.height - LouArt.frame.height * k) / 2)
            g.scaleBy(x: k, y: k)
            g.clip(to: Path(CGRect(origin: .zero, size: LouArt.frame)))
            LouPainter.paint(frame, colors: colors, in: g)
        }
    }
}

/// Une suite donnée (pour savoir si elle est finie).
struct LouRunID: Hashable, Sendable {
    let start: Date
    let keys: [String]

    init(_ performance: LouPerformance) {
        start = performance.start
        keys = performance.keys
    }
}
#endif
