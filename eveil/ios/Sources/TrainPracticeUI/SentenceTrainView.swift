// SentenceTrainView.swift — le train des phrases : qui ? fait quoi ? quoi ? où ?
//
// Demande de l'utilisateur (28/09/2026) : « upgrade l'app au niveau d'OrthoPicto, voire
// plus ». Le cœur d'OrthoPicto (orthophoniste, Symbolicone) : l'enfant construit une
// phrase simple avec des pictos, et l'image s'anime. Ici :
//   • la phrase est un TRAIN : la locomotive porte « qui ? », puis un wagon par morceau
//     (« fait quoi ? », « quoi ? », « où ? ») — trois niveaux : 2, 3 wagons, puis « où ? »
//     avec dans / sur / sous / devant / derrière ;
//   • le plateau propose au plus 6 pictos pour le wagon à remplir ; la voix pose la question
//     avec ce qui est déjà choisi (« Que fait le chat ? », « Le chat mange quoi ? ») et
//     nomme chaque picto choisi (« la pêche ») ;
//   • la phrase complète se dit morceau par morceau (chaque wagon s'allume avec le sien),
//     puis d'une traite, pendant que la scène la JOUE (`SentenceStage`) — n'importe quelle
//     phrase, même « la vache nage dans la baignoire » : on rit, on ne se trompe jamais ;
//   • toucher un wagon rempli le fait redire, et rouvre son plateau pour le changer ;
//   • éveil à la lecture : la phrase écrite (couleurs des wagons), en capitales au choix ;
//   • « Bravo ! » : l'adulte l'appuie quand l'enfant a redit la phrase (juge adulte,
//     docs/EVEIL.md § 4.7) — des étoiles, jamais de note. Aucun micro ici.
// Tout se tait et rien ne se touche pendant que la voix parle.

#if canImport(SwiftUI) && canImport(AVFoundation)
import EveilDesign
import EveilSounds
import PhraseCore
import SwiftUI
import WordEndAudio
import WordEndCore

@MainActor
public struct SentenceTrainView: View {
    public let locale: String
    public let parentButtonHidden: Bool
    public let onHome: (() -> Void)?

    @AppStorage("eveil.sentence.level") private var level = 1
    @AppStorage("eveil.sentence.round") private var round = 0
    @AppStorage(SuiteSettings.writtenWordsKey) private var written = SuiteSettings.writtenWordsDefault
    @AppStorage(SuiteSettings.capitalsKey) private var capitals = SuiteSettings.capitalsDefault
    @AppStorage(VoiceCatalog.settingKey) private var voiceId = ""
    @AppStorage(Stars.settingKey) private var starsOn = true
    @AppStorage(Stars.totalKey) private var starsTotal = 0
    @AppStorage("eveil.demoMode") private var demoMode = false

    @State private var slots: [PhraseCard?] = [nil, nil]
    @State private var editing = 0
    @State private var trayOpen = true
    @State private var playStart: Date?
    @State private var voice = ModelVoicePlayer()
    @State private var speaking = false
    @State private var litSlot: Int?
    @State private var bravoGiven = false
    @State private var sessionStars = 0
    @State private var burst: StarBurst?
    @State private var showGate = false
    @State private var showParentZone = false
    @State private var started = false

    public init(locale: String, parentButtonHidden: Bool = false, onHome: (() -> Void)? = nil) {
        self.locale = locale
        self.parentButtonHidden = parentButtonHidden
        self.onHome = onHome
    }

    private var fr: Bool { locale.hasPrefix("fr") }
    private var roles: [PhraseRole] { PhraseLevels.roles(level: level) }
    private var complete: Bool { slots.count == roles.count && slots.allSatisfy { $0 != nil } }
    private var chosen: [PhraseCard] { slots.compactMap { $0 } }
    private var chosenVerb: String { slots.count > 1 ? (slots[1]?.key ?? "") : "" }

    private var tray: [PhraseCard] {
        guard trayOpen, roles.indices.contains(editing) else { return [] }
        return PhraseLevels.tray(roles[editing], level: level, round: round, verb: chosenVerb)
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let trainScale = min(0.95, (w - 60) / PhraseTrain.baseWidth(wagons: roles.count - 1))
            let trayCard = min(136, (w - 60 - 5 * 14) / 6)
            let stageHeight = max(200, min((w - 60) / 2, h - 96 - PhraseTrain.height * trainScale - trayCard - 150))
            ZStack {
                LinearGradient(colors: [EveilPalette.skyLight, Color(red: 1.0, green: 0.97, blue: 0.9)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 14) {
                    topBar
                    SentenceStage(scene: scene, playStart: playStart)
                        .frame(width: stageHeight * 2, height: stageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                        .contentShape(Rectangle())
                        .onTapGesture { if complete && !speaking { Task { await playSentence() } } }
                        .accessibilityElement()
                        .accessibilityLabel(complete ? PhraseGrammar.sentence(chosen, locale: locale)
                                                     : (fr ? "La scène" : "The scene"))
                    if written && complete {
                        SentenceStrip(cards: chosen, locale: locale, capitals: capitals, lit: litSlot)
                            .transition(.opacity)
                    }
                    PhraseTrain(roles: roles, slots: slots, editing: trayOpen ? editing : nil, lit: litSlot,
                                locale: locale, written: written, capitals: capitals, onTap: touchWagon)
                        .scaleEffect(trainScale, anchor: .bottomLeading)
                        .frame(width: PhraseTrain.baseWidth(wagons: roles.count - 1) * trainScale,
                               height: PhraseTrain.height * trainScale, alignment: .bottomLeading)
                    bottom(cardSide: trayCard)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                if let burst {
                    StarBurstLayer(burst: burst, from: CGPoint(x: w / 2, y: h * 0.6),
                                   to: CGPoint(x: w - (parentButtonHidden ? 95 : 165), y: 52))
                        .allowsHitTesting(false)
                        .id(burst.id)
                }
            }
        }
        .sheet(isPresented: $showGate) {
            ParentGateView(locale: locale,
                           onPassed: { showGate = false; showParentZone = true },
                           onCancel: { showGate = false })
        }
        .sheet(isPresented: $showParentZone) { ParentZoneView(locale: locale) }
        .task {
            guard !started else { return }
            started = true
            SoundBoard.shared.isSuspended = false
            SoundBoard.shared.preload([.crunch, .slurp, .whooshSoft, .splash, .pop, .sparkle, .pok, .bell, .whistle])
            SoundBoard.shared.preload([.ding], variants: [0, 2, 3, 5])
            reset()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await ask()
        }
        .onDisappear {
            voice.stop()
            SoundBoard.shared.stopAll()
        }
    }

    // MARK: En-tête

    private var topBar: some View {
        HStack(spacing: 16) {
            if let onHome {
                Button {
                    voice.stop()
                    SoundBoard.shared.stopAll()
                    onHome()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(EveilPalette.ink.opacity(0.35)))
                }
                .accessibilityLabel(fr ? "Retour à l'accueil" : "Back home")
            }
            Text(fr ? "Le train des phrases" : "The sentence train")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(EveilPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 8)
            levelPicker
            if starsOn { StarCounter(count: sessionStars) }
            if !parentButtonHidden {
                Button { showGate = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(EveilPalette.ink.opacity(0.55))
                        .frame(width: 56, height: 56)
                }
                .accessibilityLabel(fr ? "Espace des grands" : "Grown-ups area")
            }
        }
        .frame(height: 70)
    }

    /// Trois niveaux : un wagon de plus à chaque fois (2 wagons, 3 wagons, et « où ? »).
    private var levelPicker: some View {
        HStack(spacing: 8) {
            ForEach(PhraseLevels.levels, id: \.self) { n in
                Button {
                    guard n != level, !speaking else { return }
                    level = n
                    reset()
                    Task { await ask() }
                } label: {
                    HStack(spacing: 3) {
                        ForEach(Array(PhraseLevels.roles(level: n).enumerated()), id: \.offset) { k, role in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(k == 0 ? EveilPalette.loco : PhraseTrain.color(role))
                                .frame(width: 12, height: 14)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(Capsule().fill(n == level ? Color.white : Color.white.opacity(0.4)))
                    .overlay(Capsule().stroke(n == level ? EveilPalette.go : .clear, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(fr ? "Niveau \(n)" : "Level \(n)")
                .accessibilityAddTraits(n == level ? .isSelected : [])
            }
        }
    }

    // MARK: Plateau, ou « Encore ! » quand la phrase est jouée

    @ViewBuilder
    private func bottom(cardSide: CGFloat) -> some View {
        if trayOpen, roles.indices.contains(editing) {
            VStack(spacing: 10) {
                Text(PhrasePrompts.question(for: roles[editing], cards: Array(chosen.prefix(editing)), locale: locale))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(EveilPalette.ink.opacity(0.8))
                HStack(spacing: 14) {
                    ForEach(tray) { card in
                        PictoCard(card: card, side: cardSide, locale: locale, written: written, capitals: capitals,
                                  color: PhraseTrain.color(card.role)) { choose(card) }
                            .disabled(speaking)
                    }
                }
            }
        } else {
            HStack(spacing: 22) {
                Button {
                    Task { await playSentence() }
                } label: {
                    Label(fr ? "Réécouter" : "Listen again", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(KidButtonStyle(color: EveilPalette.ink.opacity(0.55)))
                if starsOn && !bravoGiven {
                    Button(action: bravo) {
                        Label(fr ? "Il l'a dite !" : "Said it!", systemImage: "hand.thumbsup.fill")
                    }
                    .buttonStyle(KidButtonStyle(color: EveilPalette.wagonLit.opacity(0.95)))
                    .accessibilityHint(fr ? "Pour l'adulte : l'enfant a redit la phrase" : "For the grown-up: the child said the sentence")
                }
                Button(action: newSentence) {
                    Label(fr ? "Encore !" : "Again!", systemImage: "arrow.clockwise")
                }
                .buttonStyle(KidButtonStyle())
            }
            .disabled(speaking)
            .padding(.top, 8)
        }
    }

    // MARK: La scène

    private var scene: SentenceScene {
        var s = SentenceScene()
        for (k, slot) in slots.enumerated() {
            guard let card = slot, roles.indices.contains(k) else { continue }
            switch card.role {
            case .qui:
                if let n = PhraseLexicon.noun(card.key) { s.subject = n.drawing; s.subjectFacesLeft = n.facesLeft }
            case .verbe:
                s.verb = card.key
            case .quoi:
                if let n = PhraseLexicon.noun(card.key) { s.object = n.drawing; s.objectFacesLeft = n.facesLeft }
            case .ou:
                if let n = PhraseLexicon.noun(card.key) {
                    s.place = n.drawing
                    s.preposition = PictoPreposition(rawValue: card.preposition)
                }
            }
        }
        if !complete { s.verb = nil }                 // le verbe se joue quand la phrase est finie
        return s
    }

    // MARK: Gestes

    private func reset() {
        voice.stop()
        slots = Array(repeating: nil, count: roles.count)
        editing = 0
        trayOpen = true
        playStart = nil
        litSlot = nil
        bravoGiven = false
    }

    /// La voix pose la question du wagon à remplir (l'enfant peut choisir sans attendre la fin).
    private func ask() async {
        guard trayOpen, roles.indices.contains(editing) else { return }
        await say(PhrasePrompts.question(for: roles[editing], cards: Array(chosen.prefix(editing)), locale: locale),
                  blocking: false)
    }

    private func choose(_ card: PhraseCard) {
        guard !speaking, roles.indices.contains(editing) else { return }
        let k = editing
        let verbChanged = card.role == .verbe && slots[k]?.key != card.key
        voice.stop()                                  // la question en cours s'arrête : il a choisi
        slots[k] = card
        if verbChanged {
            // Le « quoi ? » et le « où ? » dépendent du verbe : on les refait.
            for j in (k + 1)..<slots.count { slots[j] = nil }
        }
        playStart = nil
        bravoGiven = false
        SoundBoard.shared.play(.pop)
        Task {
            litSlot = k
            await say(PhraseGrammar.chunk(card, locale: locale))
            litSlot = nil
            if let next = slots.firstIndex(where: { $0 == nil }) {
                editing = next
                await ask()
            } else {
                trayOpen = false
                await playSentence()
            }
        }
    }

    /// Toucher un wagon : il redit son morceau ; rempli, son plateau se rouvre pour le changer.
    private func touchWagon(_ k: Int) {
        guard !speaking, roles.indices.contains(k), slots.indices.contains(k) else { return }
        if let card = slots[k] {
            editing = k
            trayOpen = true
            Task {
                litSlot = k
                await say(PhraseGrammar.chunk(card, locale: locale))
                litSlot = nil
            }
        } else if slots[..<k].allSatisfy({ $0 != nil }) {
            editing = k
            trayOpen = true
            Task { await ask() }
        }
    }

    /// La phrase : morceau par morceau (chaque wagon s'allume avec le sien), puis la scène la
    /// joue pendant que la voix la dit d'une traite.
    private func playSentence() async {
        guard complete, !speaking else { return }
        let cards = chosen
        speaking = true
        for (k, card) in cards.enumerated() {
            litSlot = k
            await say(PhraseGrammar.chunk(card, locale: locale))
            guard !Task.isCancelled else { break }
        }
        litSlot = nil
        let start = Date()
        playStart = start
        SoundBoard.shared.play(.whistle)
        scheduleSounds(for: scene, start: start)
        await say(PhraseGrammar.sentence(cards, locale: locale))
        let left = SentenceStage.duration(of: scene) - Date().timeIntervalSince(start)
        if left > 0 { try? await Task.sleep(nanoseconds: UInt64(left * 1_000_000_000)) }
        speaking = false
    }

    private func newSentence() {
        guard !speaking else { return }
        round += 1
        reset()
        Task { await ask() }
    }

    /// Juge adulte : l'enfant a redit la phrase. Trois étoiles (une par wagon au niveau 1), des dings.
    private func bravo() {
        guard !bravoGiven else { return }
        bravoGiven = true
        let earned = min(Stars.max, roles.count + 1)
        Task {
            for (k, note) in [0, 2, 3, 5].prefix(roles.count).enumerated() {
                litSlot = k
                SoundBoard.shared.play(.ding, variant: note)
                try? await Task.sleep(nanoseconds: 170_000_000)
            }
            litSlot = nil
        }
        guard starsOn else { return }
        let volley = StarBurst(count: earned, start: Date())
        burst = volley
        if !demoMode { starsTotal += earned }
        Task {
            for k in 0..<earned {
                let wait = StarBurst.flight + StarBurst.stagger * Double(k) - Date().timeIntervalSince(volley.start)
                if wait > 0 { try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
                sessionStars += 1
                SoundBoard.shared.play(.twinkle, variant: k)
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            if burst == volley { burst = nil }
        }
    }

    // MARK: Voix et sons

    /// La voix du jeu. `blocking` : pendant ce qu'elle dit, on ne touche à rien (les morceaux,
    /// la phrase) ; une simple question, elle, peut être interrompue par un choix.
    private func say(_ text: String, blocking: Bool = true) async {
        let wasSpeaking = speaking
        if blocking { speaking = true }
        voice.voiceIdentifier = voiceId
        await voice.speak(text, locale: locale, pace: .sentence)
        if blocking { speaking = wasSpeaking }
    }

    private func scheduleSounds(for scene: SentenceScene, start: Date) {
        let subjectSound = scene.subject.flatMap { WordScene.table[$0]?.sound }
        for (time, cue) in SentenceStage.cues(of: scene) {
            let effect: SoundEffect?
            switch cue {
            case .bite: effect = .crunch
            case .slurp: effect = .slurp
            case .whoosh, .swish: effect = .whooshSoft
            case .splash: effect = .splash
            case .pop: effect = .pop
            case .sparkle: effect = .sparkle
            case .hop: effect = .pok
            case .bell: effect = .bell
            case .voice: effect = subjectSound
            case .snore: effect = nil
            }
            guard let effect else { continue }
            Task {
                try? await Task.sleep(nanoseconds: UInt64(max(0, time) * 1_000_000_000))
                if playStart == start { SoundBoard.shared.play(effect) }
            }
        }
    }
}

// MARK: - Le train de la phrase

/// La locomotive (qui ?) et un wagon par morceau ; les couleurs suivent les rôles (comme les
/// tableaux de communication : qui en jaune, fait quoi en vert, quoi en orange, où en bleu).
struct PhraseTrain: View {
    let roles: [PhraseRole]
    let slots: [PhraseCard?]
    let editing: Int?
    let lit: Int?
    let locale: String
    let written: Bool
    let capitals: Bool
    let onTap: (Int) -> Void

    static let height: CGFloat = 200
    static let carWidth: CGFloat = 176

    static func baseWidth(wagons: Int) -> CGFloat { carWidth * CGFloat(wagons + 1) + 40 }

    static func color(_ role: PhraseRole) -> Color {
        switch role {
        case .qui: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .verbe: return Color(red: 0.42, green: 0.8, blue: 0.37)
        case .quoi: return Color(red: 1.0, green: 0.6, blue: 0.26)
        case .ou: return Color(red: 0.36, green: 0.66, blue: 0.91)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RailsView(width: Self.baseWidth(wagons: roles.count - 1))
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(roles.enumerated()), id: \.offset) { k, role in
                    PhraseCar(role: role, card: slots.indices.contains(k) ? slots[k] : nil, isEngine: k == 0,
                              current: editing == k, lit: lit == k, locale: locale, written: written,
                              capitals: capitals)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(k) }
                }
            }
            .padding(.leading, 20)
            .padding(.bottom, 10)
        }
        .frame(width: Self.baseWidth(wagons: roles.count - 1), height: Self.height, alignment: .bottomLeading)
    }
}

/// Un wagon (ou la locomotive) : sa couleur de rôle, son picto (ou « ? »), son mot.
struct PhraseCar: View {
    let role: PhraseRole
    let card: PhraseCard?
    let isEngine: Bool
    let current: Bool
    let lit: Bool
    let locale: String
    let written: Bool
    let capitals: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let color = PhraseTrain.color(role)
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !current || card != nil || reduceMotion)) { timeline in
            // Le wagon à remplir « respire » doucement (horloge, pas de boucle d'animation).
            let breath = current && card == nil && !reduceMotion
                ? (1 - cos(timeline.date.timeIntervalSinceReferenceDate * 2 * .pi / 1.4)) / 2 : 0
            ZStack(alignment: .topLeading) {
                if !isEngine { Coupling().offset(x: -6, y: 150) }
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(color.opacity(card == nil ? 0.35 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(current ? EveilPalette.ink.opacity(0.6) : color,
                                    style: StrokeStyle(lineWidth: current ? 5 : 3, dash: card == nil ? [9, 7] : []))
                    )
                    .shadow(color: lit ? EveilPalette.wagonLit.opacity(0.9) : .clear, radius: lit ? 18 : 0)
                    .frame(width: 160, height: 138)
                    .offset(x: 8, y: 10)
                if let card {
                    PictoView(id: PhraseLexicon.drawing(of: card), size: written ? 96 : 116)
                        .frame(width: 160, height: written ? 104 : 130)
                        .offset(x: 8, y: written ? 12 : 14)
                    if written {
                        Text(capitals ? PhraseGrammar.chunk(card, locale: locale).uppercased()
                                      : PhraseGrammar.chunk(card, locale: locale))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(EveilPalette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(width: 150, height: 26)
                            .offset(x: 13, y: 118)
                    }
                } else {
                    Text(PhrasePrompts.label(for: role, locale: locale))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(EveilPalette.ink.opacity(0.6))
                        .frame(width: 160, height: 138)
                        .offset(x: 8, y: 10)
                }
                if isEngine {
                    // La cheminée de la locomotive, sur le wagon « qui ? ».
                    RoundedRectangle(cornerRadius: 4).fill(EveilPalette.locoDark)
                        .frame(width: 26, height: 22).offset(x: 20, y: -8)
                }
                RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.25))
                    .frame(width: 150, height: 10).offset(x: 13, y: 150)
                Wheel(diameter: 36, travel: 0).offset(x: 28, y: 156)
                Wheel(diameter: 36, travel: 0).offset(x: 112, y: 156)
            }
            .scaleEffect(1 + 0.04 * breath, anchor: .bottom)
            .frame(width: PhraseTrain.carWidth, height: PhraseTrain.height, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.map { PhraseGrammar.chunk($0, locale: locale) } ?? PhrasePrompts.label(for: role, locale: locale))
        .accessibilityAddTraits(.isButton)
    }
}

/// Un picto du plateau : grande carte blanche, le dessin, le mot (mode écrit).
struct PictoCard: View {
    let card: PhraseCard
    let side: CGFloat
    let locale: String
    let written: Bool
    let capitals: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                PictoView(id: PhraseLexicon.drawing(of: card), size: side * (written ? 0.78 : 0.92))
                if written {
                    Text(capitals ? PhraseGrammar.chunk(card, locale: locale).uppercased()
                                  : PhraseGrammar.chunk(card, locale: locale))
                        .font(.system(size: max(13, side * 0.14), weight: .bold, design: .rounded))
                        .foregroundStyle(EveilPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(width: side, height: side * (written ? 1.12 : 1))
            .background(
                RoundedRectangle(cornerRadius: side * 0.16, style: .continuous).fill(.white)
                    .overlay(RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                        .stroke(color, lineWidth: 4))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PhraseGrammar.chunk(card, locale: locale))
    }
}

/// La phrase écrite, chaque morceau dans la couleur de son wagon (éveil à la lecture).
struct SentenceStrip: View {
    let cards: [PhraseCard]
    let locale: String
    let capitals: Bool
    let lit: Int?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.offset) { k, card in
                let text = PhraseGrammar.chunk(card, locale: locale)
                let shown = (k == 0 ? text.prefix(1).uppercased() + text.dropFirst() : text)
                    + (k == cards.count - 1 ? "." : "")
                Text(capitals ? shown.uppercased() : shown)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(EveilPalette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 10).fill(PhraseTrain.color(card.role).opacity(lit == k ? 0.95 : 0.45)))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PhraseGrammar.sentence(cards, locale: locale))
    }
}
#endif
