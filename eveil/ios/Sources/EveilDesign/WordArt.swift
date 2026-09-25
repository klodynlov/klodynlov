// WordArt.swift — le dessin de chaque mot du petit train.
//
// Contrat : l'objet est dessiné dans un carré `size` × `size`, fond transparent
// (la carte blanche est dessinée par l'écran de jeu). `pulse` augmente à chaque
// fois que l'enfant touche l'image : l'objet « fait son bruit » (la cloche se
// balance, la vache ouvre la bouche…) pendant que le son joue.
//
// Les 45 mots des lexiques fr-FR et en-US ont un dessin vectoriel (Canvas, aucune
// image) : voir `WordArtAnimals.swift`, `WordArtThings.swift`, `WordArtFood.swift`
// et `WordArtPlaces.swift` ; la boîte à crayons est dans `WordArtKit.swift`.
// Un identifiant inconnu garde le pictogramme système de repli.
//
// Le temps : AUCUNE animation SwiftUI (`withAnimation`, `repeatForever`) — une
// boucle démarrée dans `onAppear` peut capter l'animation d'un conteneur parent
// (la carte fond quand le train part) et clignoter sans fin. Tout est calculé à
// partir de l'heure dans un `TimelineView` :
//   • action (toucher) : `onChange(of: pulse)` note l'heure du toucher ; pendant
//     `actionDuration` le dessin reçoit t = 0 → 1, puis l'horloge s'arrête ;
//   • repos : clignement des yeux (calendrier creux, 2 images toutes les 4 s) ou
//     petit mouvement continu (vapeur, gouttes, bulles, drapeau) à 30 images/s ;
//   • « Réduire les animations » : dessin immobile, aucune action.

#if canImport(SwiftUI)
import SwiftUI

public struct WordArt: View {
    public let wordId: String
    public let size: CGFloat
    public let pulse: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Heure du dernier toucher, tant que l'action joue (nil = au repos).
    @State private var actionStart: Date?

    public init(wordId: String, size: CGFloat = 250, pulse: Int = 0) {
        self.wordId = wordId
        self.size = size
        self.pulse = pulse
    }

    /// Vrai si ce mot a un vrai dessin (sinon : pictogramme de repli).
    public static func isIllustrated(_ wordId: String) -> Bool {
        WordArtSubject(rawValue: wordId) != nil
    }

    public var body: some View {
        Group {
            if let subject = WordArtSubject(rawValue: wordId) {
                art(subject)
                    // Tout le mouvement vient de l'horloge : si l'écran incrémente `pulse` dans un
                    // `withAnimation`, le passage repos → action ne doit pas devenir un fondu enchaîné.
                    // (N'agit qu'ici dedans : le fondu de la carte par un parent reste animé.)
                    .transaction { $0.animation = nil }
                    .onChange(of: pulse) { _, _ in act(subject) }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: size * 0.48))
                    .foregroundStyle(Self.tints[wordId.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Self.tints.count])
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private static let tints: [Color] = [.blue, .orange, .pink, .purple, .teal, .indigo, .green, .red]

    // MARK: Le temps

    @ViewBuilder
    private func art(_ subject: WordArtSubject) -> some View {
        if reduceMotion {
            WordArtCanvas(subject: subject, pose: WordArtPose(), size: size)
        } else if actionStart != nil || subject.idle == .flow {
            // Pleine cadence pendant l'action ; 30 images/s pour le mouvement de repos.
            TimelineView(.animation(minimumInterval: actionStart == nil ? 1.0 / 30 : nil)) { timeline in
                WordArtCanvas(subject: subject, pose: pose(subject, at: timeline.date), size: size)
            }
        } else if subject.idle == .blink {
            TimelineView(WordArtBlinkSchedule()) { timeline in
                WordArtCanvas(subject: subject, pose: pose(subject, at: timeline.date), size: size)
            }
        } else {
            WordArtCanvas(subject: subject, pose: WordArtPose(), size: size)
        }
    }

    private func pose(_ subject: WordArtSubject, at date: Date) -> WordArtPose {
        var t = 0.0
        if let start = actionStart {
            let progress = date.timeIntervalSince(start) / subject.actionDuration
            if progress > 0 && progress < 1 { t = progress }
        }
        let clock = date.timeIntervalSinceReferenceDate
        // +1 : l'horloge de repos ne vaut jamais 0 (0 = immobile, cf. `WordArtPose.idle`).
        let idle = subject.idle == .flow ? clock.truncatingRemainder(dividingBy: 3600) + 1 : 0
        let blink = subject.hasEyes && t == 0 && WordArtBlinkSchedule.isClosed(at: clock)
        return WordArtPose(t: t, blink: blink, idle: idle)
    }

    /// Le toucher : l'action (re)part, sauf si la précédente vient à peine de commencer
    /// (un enfant qui tapote ne fait pas « sauter » le dessin en plein geste).
    private func act(_ subject: WordArtSubject) {
        guard !reduceMotion else { return }
        let now = Date()
        if let start = actionStart, now.timeIntervalSince(start) < subject.actionDuration * 0.4 { return }
        actionStart = now
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((subject.actionDuration + 0.05) * 1_000_000_000))
            if actionStart == now { actionStart = nil }
        }
    }
}

/// Un dessin figé dans une pose (utilisé par `WordArt`, et par les planches de relecture).
struct WordArtCanvas: View {
    let subject: WordArtSubject
    let pose: WordArtPose
    let size: CGFloat

    var body: some View {
        Canvas { context, area in
            let k = min(area.width, area.height) / 200
            var g = context
            // Un Canvas ne découpe PAS son contenu : sans ceci, la manche de « push » déborderait de la carte.
            g.clip(to: Path(CGRect(origin: .zero, size: area)))
            g.translateBy(x: (area.width - 200 * k) / 2, y: (area.height - 200 * k) / 2)
            g.scaleBy(x: k, y: k)
            WordArtPaint.paint(subject, WordArtBrush(g), pose)
        }
        .frame(width: size, height: size)
    }
}

/// Calendrier creux du clignement : on ne redessine qu'aux deux bords de chaque
/// clignement (paupières qui se ferment, qui se rouvrent), pas 30 fois par seconde.
/// Chaque date tombe 2 ms À L'INTÉRIEUR de son intervalle : une erreur d'arrondi ne
/// peut pas laisser un œil fermé jusqu'au clignement suivant.
struct WordArtBlinkSchedule: TimelineSchedule {
    static let period: Double = 4
    static let closed: Double = 0.14
    private static let margin: Double = 0.002

    static func isClosed(at clock: TimeInterval) -> Bool {
        let phase = clock - (clock / period).rounded(.down) * period
        return phase > margin / 2 && phase < closed + margin / 2
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> UnfoldFirstSequence<Date> {
        let p = Self.period, c = Self.closed, m = Self.margin
        return sequence(first: startDate) { previous in
            let t = previous.timeIntervalSinceReferenceDate
            let k = (t / p).rounded(.down)
            let start = k * p + m, end = k * p + c + m
            let next = t < start - 1e-4 ? start : (t < end - 1e-4 ? end : (k + 1) * p + m)
            return Date(timeIntervalSinceReferenceDate: max(next, t + 0.01))
        }
    }
}

/// Mouvement de repos d'un dessin.
enum WordArtIdle: Sendable {
    case still      // immobile
    case blink      // les yeux clignent (animaux)
    case flow       // mouvement continu : vapeur, gouttes, bulles, ailes, drapeau…
}

/// Les mots dessinés (identifiant du lexique → dessin).
enum WordArtSubject: String, CaseIterable, Sendable {
    // Français (fr-FR.json)
    case douche = "fr.douche", bouche = "fr.bouche", niche = "fr.niche", ruche = "fr.ruche"
    case mouche = "fr.mouche", vache = "fr.vache", biche = "fr.biche", tasse = "fr.tasse"
    case minouche = "fr.minouche", perruche = "fr.perruche", saucisse = "fr.saucisse"
    case trousse = "fr.trousse", mousse = "fr.mousse", buche = "fr.buche", tache = "fr.tache"
    case peche = "fr.peche", os = "fr.os", police = "fr.police", caniche = "fr.caniche"
    case limace = "fr.limace", carrosse = "fr.carrosse", cactus = "fr.cactus", cloche = "fr.cloche"
    case glace = "fr.glace", fleche = "fr.fleche", brosse = "fr.brosse", autruche = "fr.autruche"
    case princesse = "fr.princesse"
    // English (en-US.json)
    case fish = "en.fish", dish = "en.dish", push = "en.push", wash = "en.wash", goose = "en.goose"
    case moose = "en.moose", ice = "en.ice", piece = "en.piece", bus = "en.bus", radish = "en.radish"
    case tennis = "en.tennis", brush = "en.brush", mouse = "en.mouse", juice = "en.juice"
    case house = "en.house", circus = "en.circus", splash = "en.splash"

    /// Durée de l'action déclenchée par le toucher (secondes, 0,6 à 1,2).
    var actionDuration: Double {
        switch self {
        case .tache, .os, .piece: return 0.7
        case .peche, .tasse, .buche, .ice, .tennis, .splash, .mouse, .perruche: return 0.9
        case .cloche, .douche, .ruche, .police, .carrosse, .mousse, .limace, .wash, .circus: return 1.2
        case .autruche, .vache, .moose, .princesse, .push, .house: return 1.1
        default: return 1.0
        }
    }

    /// Les yeux clignent au repos (et se ferment dans la pose « blink »). Pas la mouche :
    /// ses gros yeux à facettes ne clignent pas.
    var hasEyes: Bool {
        switch self {
        case .niche, .ruche, .vache, .biche, .minouche, .perruche, .caniche, .limace,
             .autruche, .princesse, .fish, .goose, .moose, .mouse:
            return true
        default:
            return false
        }
    }

    var idle: WordArtIdle {
        switch self {
        case .douche, .ruche, .mouche, .tasse, .saucisse, .mousse, .fish, .wash, .house, .circus:
            return .flow
        default:
            return hasEyes ? .blink : .still
        }
    }
}

extension WordArtPaint {
    /// Aiguillage : chaque mot vers son dessin.
    static func paint(_ subject: WordArtSubject, _ b: WordArtBrush, _ p: WordArtPose) {
        switch subject {
        case .douche: douche(b, p)
        case .bouche: bouche(b, p)
        case .niche: niche(b, p)
        case .ruche: ruche(b, p)
        case .mouche: mouche(b, p)
        case .vache: vache(b, p)
        case .biche: biche(b, p)
        case .tasse: tasse(b, p)
        case .minouche: minouche(b, p)
        case .perruche: perruche(b, p)
        case .saucisse: saucisse(b, p)
        case .trousse: trousse(b, p)
        case .mousse: mousse(b, p)
        case .buche: buche(b, p)
        case .tache: tache(b, p)
        case .peche: peche(b, p)
        case .os: os(b, p)
        case .police: police(b, p)
        case .caniche: caniche(b, p)
        case .limace: limace(b, p)
        case .carrosse: carrosse(b, p)
        case .cactus: cactus(b, p)
        case .cloche: cloche(b, p)
        case .glace: glace(b, p)
        case .fleche: fleche(b, p)
        case .brosse: brosse(b, p)
        case .autruche: autruche(b, p)
        case .princesse: princesse(b, p)
        case .fish: fish(b, p)
        case .dish: dish(b, p)
        case .push: push(b, p)
        case .wash: wash(b, p)
        case .goose: goose(b, p)
        case .moose: moose(b, p)
        case .ice: ice(b, p)
        case .piece: piece(b, p)
        case .bus: bus(b, p)
        case .radish: radish(b, p)
        case .tennis: tennis(b, p)
        case .brush: brush(b, p)
        case .mouse: mouse(b, p)
        case .juice: juice(b, p)
        case .house: house(b, p)
        case .circus: circus(b, p)
        case .splash: splash(b, p)
        }
    }
}
#endif
