// EarGamesView.swift — les jeux d'écoute : le loto des bruits et « Où est… ? ».
//
// Deux petits jeux sans micro (voir `EarGames`) :
//   • le loto des bruits : le chat fait entendre un bruit ; trois images ; on touche celle qui
//     fait ce bruit — toucher une image la fait toujours sonner (on compare, on explore) ;
//   • « Où est… ? » : la voix demande « Où est la pêche ? » ; on touche l'image.
// La bonne image : « Oui ! C'est la vache ! », elle s'anime, des dings, une étoile. Une autre
// image : la voix la NOMME (« Ça, c'est le chat. ») et on réécoute — jamais « non », jamais
// « faux ». Les manches suivent un ordre fixe et reprennent où on s'était arrêté.

#if canImport(SwiftUI) && canImport(AVFoundation)
import EveilDesign
import EveilSounds
import PhraseCore
import SwiftUI
import WordEndAudio
import WordEndCore

@MainActor
public struct EarGamesView: View {
    public let locale: String
    public let parentButtonHidden: Bool
    public let onHome: (() -> Void)?

    enum Game: String, CaseIterable {
        case loto, find
    }

    @AppStorage("eveil.ear.game") private var gameRaw = Game.loto.rawValue
    @AppStorage("eveil.ear.lotoRound") private var lotoRound = 0
    @AppStorage("eveil.ear.findRound") private var findRound = 0
    @AppStorage("eveil.ear.findCount") private var findCount = 3
    @AppStorage(VoiceCatalog.settingKey) private var voiceId = ""
    @AppStorage(Stars.settingKey) private var starsOn = true
    @AppStorage(Stars.totalKey) private var starsTotal = 0
    @AppStorage("eveil.demoMode") private var demoMode = false

    @State private var voice = ModelVoicePlayer()
    @State private var found = false
    @State private var pulses: [String: Int] = [:]
    @State private var bubble = ""
    @State private var sessionStars = 0
    @State private var burst: StarBurst?
    @State private var showGate = false
    @State private var showParentZone = false
    @State private var started = false
    @State private var busy = false

    public init(locale: String, parentButtonHidden: Bool = false, onHome: (() -> Void)? = nil) {
        self.locale = locale
        self.parentButtonHidden = parentButtonHidden
        self.onHome = onHome
    }

    private var fr: Bool { locale.hasPrefix("fr") }
    private var game: Game { Game(rawValue: gameRaw) ?? .loto }
    private var current: EarRound {
        game == .loto ? EarGames.lotoRound(lotoRound) : EarGames.findRound(findRound, count: findCount)
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let count = CGFloat(current.choices.count)
            let side = min(260, (w - 80 - (count - 1) * 24) / count, h * 0.34)
            ZStack {
                SceneryView()
                VStack(spacing: 20) {
                    topBar
                    Spacer(minLength: 0)
                    HStack(alignment: .center, spacing: 10) {
                        CatStationMaster(mood: found ? .cheering : (busy ? .speaking : .hello), size: min(200, h * 0.2))
                        SpeechBubble(bubble)
                    }
                    Button {
                        Task { await replay() }
                    } label: {
                        Label(fr ? "Écoute !" : "Listen!", systemImage: game == .loto ? "ear.fill" : "speaker.wave.2.fill")
                    }
                    .buttonStyle(KidButtonStyle(color: EveilPalette.ink.opacity(0.6)))
                    .disabled(busy)
                    HStack(spacing: 24) {
                        ForEach(Array(current.choices.enumerated()), id: \.offset) { k, id in
                            card(id: id, index: k, side: side)
                        }
                    }
                    .id("\(gameRaw)-\(lotoRound)-\(findRound)-\(findCount)")
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 30)
                .padding(.top, 16)
                .padding(.bottom, 24)
                if let burst {
                    StarBurstLayer(burst: burst, from: CGPoint(x: w / 2, y: h * 0.7),
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
            SoundBoard.shared.preload(EarGames.lotoItems.map(\.sound))
            SoundBoard.shared.preload([.ding], variants: [0, 2, 3, 5])
            try? await Task.sleep(nanoseconds: 500_000_000)
            await startRound()
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
            Spacer(minLength: 8)
            ForEach(Game.allCases, id: \.self) { g in
                Button {
                    guard g != game, !busy else { return }
                    gameRaw = g.rawValue
                    Task { await startRound() }
                } label: {
                    Label(g == .loto ? (fr ? "Le loto des bruits" : "Sound lotto") : (fr ? "Où est… ?" : "Where is…?"),
                          systemImage: g == .loto ? "music.note" : "magnifyingglass")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(g == game ? .white : EveilPalette.ink)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(Capsule().fill(g == game ? EveilPalette.go : Color.white.opacity(0.7)))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(g == game ? .isSelected : [])
            }
            if game == .find {
                // Combien d'images : 2, 3 ou 4.
                HStack(spacing: 6) {
                    ForEach(2...4, id: \.self) { n in
                        Button {
                            guard n != findCount, !busy else { return }
                            findCount = n
                            Task { await startRound() }
                        } label: {
                            Text("\(n)")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(n == findCount ? .white : EveilPalette.ink)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(n == findCount ? EveilPalette.loco : Color.white.opacity(0.7)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(fr ? "\(n) images" : "\(n) pictures")
                    }
                }
            }
            Spacer(minLength: 8)
            if starsOn { StarCounter(count: sessionStars) }
            if !parentButtonHidden {
                Button { showGate = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(EveilPalette.ink.opacity(0.25)))
                }
                .accessibilityLabel(fr ? "Espace des grands" : "Grown-ups area")
            }
        }
    }

    // MARK: Les images

    private func card(id: String, index: Int, side: CGFloat) -> some View {
        let drawing = game == .loto ? id : (PhraseLexicon.noun(id)?.drawing ?? id)
        let isAnswer = index == current.answer
        return Button {
            touch(id: id, drawing: drawing, isAnswer: isAnswer)
        } label: {
            PictoView(id: drawing, size: side * 0.86, pulse: pulses[drawing] ?? 0)
                .frame(width: side, height: side)
                .background(
                    RoundedRectangle(cornerRadius: side * 0.14, style: .continuous).fill(.white)
                        .overlay(RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                            .stroke(found && isAnswer ? EveilPalette.go : .clear, lineWidth: 8))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                )
                .scaleEffect(found && isAnswer ? 1.08 : 1)
                .animation(.spring(duration: 0.35, bounce: 0.5), value: found)
        }
        .buttonStyle(.plain)
        .disabled(found)
        .accessibilityLabel(name(of: id))
    }

    private func name(of id: String) -> String {
        if game == .loto { return EarGames.lotoItem(id)?.name(locale: locale) ?? id }
        return PhraseLexicon.noun(id).map { PhraseGrammar.nounPhrase($0, locale: locale) } ?? id
    }

    // MARK: Le jeu

    private func startRound() async {
        found = false
        voice.stop()
        switch game {
        case .loto:
            bubble = fr ? "Écoute bien… Qui fait ce bruit ?" : "Listen… What makes this sound?"
        case .find:
            let target = current.choices[current.answer]
            bubble = PhraseLexicon.noun(target).map { EarGames.findQuestion($0, locale: locale) } ?? ""
        }
        await replay()
    }

    /// Réécouter : le bruit mystère (loto), ou la question (« Où est… ? »).
    private func replay() async {
        busy = true
        voice.voiceIdentifier = voiceId
        switch game {
        case .loto:
            await voice.speak(fr ? "Qui fait ce bruit ?" : "What makes this sound?", locale: locale, pace: .sentence)
            if let item = EarGames.lotoItem(current.choices[current.answer]) {
                SoundBoard.shared.play(item.sound)
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
        case .find:
            await voice.speak(bubble, locale: locale, pace: .sentence)
        }
        busy = false
    }

    private func touch(id: String, drawing: String, isAnswer: Bool) {
        guard !found else { return }
        pulses[drawing, default: 0] += 1                     // l'image s'anime
        if game == .loto, let item = EarGames.lotoItem(id) { SoundBoard.shared.play(item.sound) }
        let spoken = name(of: id)
        Task {
            voice.stop()
            voice.voiceIdentifier = voiceId
            if isAnswer {
                found = true
                bubble = EarGames.yes(spoken, locale: locale)
                if game == .loto { try? await Task.sleep(nanoseconds: 600_000_000) }
                giveStar()
                await voice.speak(bubble, locale: locale, pace: .sentence)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if game == .loto { lotoRound += 1 } else { findRound += 1 }
                await startRound()
            } else {
                // Jamais « non » : on nomme ce qu'il a touché, puis on réécoute.
                if game == .loto { try? await Task.sleep(nanoseconds: 700_000_000) }
                await voice.speak(EarGames.thatIs(spoken, locale: locale), locale: locale, pace: .sentence)
                await replay()
            }
        }
    }

    private func giveStar() {
        for (k, note) in [0, 2, 3, 5].enumerated() {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(k) * 150_000_000)
                SoundBoard.shared.play(.ding, variant: note)
            }
        }
        guard starsOn else { return }
        let volley = StarBurst(count: 1, start: Date())
        burst = volley
        if !demoMode { starsTotal += 1 }
        Task {
            try? await Task.sleep(nanoseconds: UInt64(StarBurst.flight * 1_000_000_000))
            sessionStars += 1
            SoundBoard.shared.play(.twinkle)
            try? await Task.sleep(nanoseconds: 200_000_000)
            if burst == volley { burst = nil }
        }
    }
}
#endif
