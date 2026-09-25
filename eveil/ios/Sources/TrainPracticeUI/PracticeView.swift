// PracticeView.swift — l'écran d'entraînement : modèle → écoute → retour.
//
// Boucle d'un mot :
//   1. le mot MODÈLE est joué (voix enregistrée ; repli : synthèse système) ;
//   2. le micro s'ouvre (tour de parole strict) ; les wagons s'allument EN DIRECT ;
//   3. le verdict final passe par `FeedbackPolicy` (jamais « faux ») ;
//   4. on avance, ou l'enfant relance lui-même en touchant « À toi ! ».
// Fin de séance ritualisée (`SessionPolicy`) + une « mission » hors écran.
//
// Mode démo (espace parent, ou argument de lancement `-eveil.demoMode 1`) : pas de
// micro ; une barre de présentation fait « parler » le train avec une pseudo-parole
// synthétique (`DemoScenario`) qui passe par le vrai détecteur.

#if canImport(SwiftUI) && canImport(SwiftData) && canImport(AVFoundation) && canImport(Observation)
import SwiftData
import EveilDesign
import SwiftUI
import WordEndAudio
import WordEndCore

@MainActor
public struct PracticeView: View {
    public let words: [TargetWord]
    public let locale: String
    public let policy: SessionPolicy
    public let cabooseSounds: [String: CabooseSound]
    /// Masqué quand le parent a verrouillé l'espace des grands via l'Accès guidé.
    public let parentButtonHidden: Bool
    /// Retour à l'accueil de la suite (absent : pas de bouton).
    public let onHome: (() -> Void)?

    @Environment(\.modelContext) private var context
    @AppStorage("eveil.demoMode") private var demoMode = false
    @State private var listener = ListeningController()
    @State private var voice = ModelVoicePlayer()
    @State private var index = 0
    @State private var attempt = 1
    @State private var feedback: Feedback?
    @State private var wordsDone = 0
    @State private var sessionStart = Date()
    @State private var step: SessionStep = .continue
    @State private var showGate = false
    @State private var showParentZone = false
    @State private var modelPlaying = false

    public init(words: [TargetWord], locale: String, cabooseSounds: [String: CabooseSound],
                policy: SessionPolicy = SessionPolicy(), parentButtonHidden: Bool = false,
                onHome: (() -> Void)? = nil) {
        precondition(!words.isEmpty, "liste de mots vide")
        self.words = words
        self.locale = locale
        self.cabooseSounds = cabooseSounds
        self.policy = policy
        self.parentButtonHidden = parentButtonHidden
        self.onHome = onHome
    }

    private var word: TargetWord { words[index % words.count] }
    private var fr: Bool { locale.hasPrefix("fr") }
    private var listening: Bool { listener.phase == .listening }

    public var body: some View {
        ZStack {
            SceneryView(night: step != .continue)
            if step == .continue {
                practice
            } else {
                SessionEndView(step: step, locale: locale, cue: word.coda.flatMap { cabooseSounds[$0]?.cue })
            }
            VStack(spacing: 0) {
                topBar
                Spacer()
                if demoMode && step == .continue { demoBar }
            }
        }
        .sheet(isPresented: $showGate) {
            ParentGateView(locale: locale,
                           onPassed: { showGate = false; showParentZone = true },
                           onCancel: { showGate = false })
        }
        .sheet(isPresented: $showParentZone) { ParentZoneView(locale: locale) }
        .task { await present(word) }
        .onChange(of: listener.phase) { _, phase in
            if case let .finished(verdict) = phase { handle(verdict) }
        }
        .onDisappear { listener.reset() }
    }

    // MARK: Écran

    private var topBar: some View {
        HStack(spacing: 16) {
            if let onHome {
                Button {
                    listener.reset()
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
            Spacer()
            if demoMode {
                Label(fr ? "Démo" : "Demo", systemImage: "play.rectangle.fill")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.purple.opacity(0.75)))
            }
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
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    private var practice: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let wide = w > h
            let card = min(wide ? 300 : 250, h * 0.26)
            let cat = min(wide ? 250 : 210, h * 0.24)
            let trainBase = TrainView.baseWidth(wagons: word.wagons.count, hasCaboose: word.coda != nil)
            let trainScale = min(wide ? 1.75 : 1.5, (w - 60) / trainBase)
            VStack(spacing: 0) {
                Spacer(minLength: 90)
                HStack(alignment: .center, spacing: wide ? 44 : 22) {
                    WordPicture(word: word, size: card)
                    HStack(alignment: .center, spacing: 6) {
                        MascotView(action: feedback?.mascot, isListening: listening, size: cat)
                        SpeechBubble(bubbleText)
                            .frame(maxWidth: wide ? 380 : 300)
                    }
                }
                Spacer(minLength: 20)
                TrainView(wagons: word.wagons, lit: litWagons, cabooseLabel: word.caboose,
                          caboose: cabooseState, scale: trainScale)
                    .id(word.id)
                    .frame(maxWidth: .infinity)
                Button {
                    Task { await present(word) }
                } label: {
                    Label(listening ? (fr ? "Je t'écoute…" : "Listening…") : (fr ? "À toi !" : "Your turn!"),
                          systemImage: listening ? "waveform" : "ear.fill")
                }
                .buttonStyle(KidButtonStyle())
                .disabled(listening || modelPlaying)
                .padding(.top, 22)
                Spacer(minLength: demoMode ? 110 : 36)
            }
            .frame(width: w, height: h)
        }
    }

    private var bubbleText: String { (feedback?.message ?? .invite).defaultText(locale: locale) }

    /// Barre de présentation du mode démo (pour l'adulte qui montre l'app).
    private var demoBar: some View {
        HStack(spacing: 14) {
            Text(fr ? "Faire dire au train :" : "Make the train hear:")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            ForEach(DemoScenario.allCases.filter { $0.isAvailable(for: word) }) { scenario in
                Button {
                    runDemo(scenario)
                } label: {
                    Label(scenario.label(locale: locale), systemImage: scenario.symbol)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(.white))
                        .foregroundStyle(Color.purple)
                }
                .disabled(listening || modelPlaying)
            }
            Button {
                Task { await nextWord() }
            } label: {
                Label(fr ? "Mot suivant" : "Next word", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.purple.opacity(0.35)))
                    .foregroundStyle(.white)
            }
            .disabled(listening || modelPlaying)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Capsule().fill(Color.purple.opacity(0.8)))
        .padding(.bottom, 26)
    }

    // Aperçu en direct pendant l'écoute ; retour final ensuite.
    private var litWagons: [Bool] {
        if let feedback { return feedback.litWagons }
        return word.wagons.indices.map { $0 < listener.litWagons }
    }

    private var cabooseState: CabooseState {
        if let feedback { return feedback.caboose }
        guard word.coda != nil else { return .none }
        return listener.cabooseHeard ? .hooked : .waiting
    }

    // MARK: Boucle d'un mot

    private func present(_ w: TargetWord) async {
        feedback = nil
        listener.reset()
        modelPlaying = true
        // TODO(contenu) : remplacer par les enregistrements validés (voix humaine FR/EN).
        await voice.speak(w.text, locale: locale)
        modelPlaying = false
        if !demoMode { listener.listen(for: w) }
    }

    private func runDemo(_ scenario: DemoScenario) {
        guard let samples = scenario.samples(for: word) else { return }
        feedback = nil
        listener.reset()
        listener.listenDemo(for: word, samples: samples)
    }

    private func handle(_ verdict: Verdict) {
        let fb = FeedbackPolicy.feedback(for: verdict, wagons: word.wagons.count,
                                         hasCaboose: word.coda != nil, attempt: attempt)
        feedback = fb
        // La démo n'est pas un enfant : rien n'entre dans le journal local de progression.
        if verdict.kind == .complete && !demoMode { recordHook(word.id) }
        Task {
            if fb.mascot == .modelWord { await voice.speak(word.text, locale: locale) }
            // En démo, c'est le présentateur qui avance (« Mot suivant ») : le résultat reste affiché.
            guard !demoMode else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if fb.advance {
                await nextWord()
            } else {
                attempt += 1            // la relance vient de l'enfant (bouton « À toi ! »)
            }
        }
    }

    private func nextWord() async {
        wordsDone += 1
        attempt = 1
        index += 1
        let elapsed = Date().timeIntervalSince(sessionStart)
        step = policy.nextStep(wordsDone: wordsDone, sessionSeconds: elapsed,
                               todaySeconds: PracticeStore.secondsToday(in: context) + elapsed)
        if step == .continue {
            await present(word)
        } else if !demoMode {
            context.insert(PracticeSession(startedAt: sessionStart, seconds: elapsed,
                                           wordsPracticed: wordsDone, locale: locale))
            try? context.save()
        }
    }

    private func recordHook(_ wordId: String) {
        let descriptor = FetchDescriptor<WordProgress>(predicate: #Predicate { $0.wordId == wordId })
        if let existing = try? context.fetch(descriptor).first {
            existing.hookedCount += 1
            existing.lastPracticed = .now
        } else {
            context.insert(WordProgress(wordId: wordId, hookedCount: 1))
        }
    }
}

/// Illustration du mot (placeholders SF Symbols — illustrations à commander).
struct WordPicture: View {
    let word: TargetWord
    var size: CGFloat = 280

    private static let symbols: [String: String] = [
        "fr.douche": "shower.fill", "fr.bouche": "mouth.fill", "fr.niche": "house.fill",
        "fr.ruche": "hexagon.fill", "fr.mouche": "ladybug.fill", "fr.vache": "pawprint.fill",
        "fr.biche": "leaf.fill", "fr.tasse": "cup.and.saucer.fill", "fr.minouche": "cat.fill",
        "fr.perruche": "bird.fill", "fr.saucisse": "fork.knife", "fr.trousse": "pencil.and.ruler.fill",
        "en.fish": "fish.fill", "en.dish": "fork.knife", "en.push": "hand.point.right.fill",
        "en.wash": "drop.fill", "en.goose": "bird.fill", "en.moose": "pawprint.fill",
        "en.ice": "snowflake", "en.piece": "puzzlepiece.fill", "en.bus": "bus.fill",
        "en.radish": "carrot.fill", "en.tennis": "tennisball.fill", "en.brush": "paintbrush.fill",
    ]
    private static let tints: [Color] = [.blue, .orange, .pink, .purple, .teal, .indigo, .green, .red]

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: Self.symbols[word.id] ?? "photo")
                .font(.system(size: size * 0.48))
                .foregroundStyle(Self.tints[word.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Self.tints.count])
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.14, style: .continuous).fill(.white)
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                )
            Text(word.text)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(EveilPalette.ink.opacity(0.7))          // pour l'adulte qui accompagne
        }
        .accessibilityElement(children: .combine)
    }
}

/// Fin de séance : le chat s'endort, et une mission HORS ÉCRAN pour la famille.
struct SessionEndView: View {
    let step: SessionStep
    let locale: String
    let cue: String?
    private var fr: Bool { locale.hasPrefix("fr") }

    var body: some View {
        VStack(spacing: 28) {
            CatStationMaster(mood: .sleeping, size: 260)
            Text(step == .restToday
                 ? (fr ? "Le petit train dort. À demain !" : "The little train is asleep. See you tomorrow!")
                 : (fr ? "Le train rentre au dépôt. Bravo pour ce voyage !" : "The train goes home. What a trip!"))
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if let cue {
                Text(fr ? "Mission pour ce soir : jouez ensemble — \(cue) !"
                        : "Mission for tonight: play together — \(cue)!")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(48)
    }
}
#endif
