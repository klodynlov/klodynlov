// PracticeView.swift — l'écran d'entraînement : modèle → écoute → retour → voyage.
//
// Boucle d'un mot :
//   1. le train entre en gare dans un monde ; le mot MODÈLE est joué (voix
//      enregistrée ; repli : synthèse système) ;
//   2. le micro s'ouvre (tour de parole strict) ; les wagons s'allument EN DIRECT ;
//   3. le verdict final passe par `FeedbackPolicy` (jamais « faux ») ;
//   4. mot bien dit : le fourgon s'accroche (« chhh » / « sss »), puis le train
//      siffle et part vers un AUTRE MONDE avec le mot suivant — on enchaîne
//      (retours de l'utilisateur, 25/09/2026). Sinon, l'enfant relance lui-même
//      en touchant « À toi ! » ; après `maxAttempts`, on félicite l'effort et le
//      train repart aussi (pas de boucle d'échec).
// Autour du mot : l'image fait le bruit de l'objet quand on la touche, et des
// petites bêtes volent derrière (on les attrape, elles font leur bruit) — mais
// TOUT se tait pendant le mot modèle et l'écoute (`SoundBoard.isSuspended`).
// Fin de séance ritualisée (`SessionPolicy`) + une « mission » hors écran.
//
// Mode démo (espace parent, ou argument de lancement `-eveil.demoMode 1`) : pas de
// micro ; une barre de présentation fait « parler » le train avec une pseudo-parole
// synthétique (`DemoScenario`) qui passe par le vrai détecteur.

#if canImport(SwiftUI) && canImport(SwiftData) && canImport(AVFoundation) && canImport(Observation)
import SwiftData
import EveilDesign
import EveilSounds
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("eveil.demoMode") private var demoMode = false
    @AppStorage(ListeningSettings.adultTrialKey) private var adultTrial = false
    @AppStorage(WordDeck.cursorKey) private var deckCursor = 0
    @AppStorage("eveil.world") private var worldRaw = 0
    @State private var listener = ListeningController(stream: ListeningSettings.streamingConfig())
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
    @State private var departing = false
    @State private var traveling = false
    @State private var picturePulse = 0
    @State private var firstWorld = World.countryside
    @State private var started = false

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
        // Le voyage reprend où la séance précédente l'a laissé (mot et monde).
        let defaults = UserDefaults.standard
        _index = State(initialValue: max(0, defaults.integer(forKey: WordDeck.cursorKey)) % words.count)
        _firstWorld = State(initialValue: World(rawValue: defaults.integer(forKey: "eveil.world")) ?? .countryside)
    }

    private var word: TargetWord { words[index % words.count] }
    private var scene: WordScene { WordScene.forWord(word) }
    private var world: World { World(rawValue: worldRaw) ?? .countryside }
    private var fr: Bool { locale.hasPrefix("fr") }
    private var listening: Bool { listener.phase == .listening }
    /// Tour de parole : aucun bruitage pendant le mot modèle ni pendant l'écoute.
    private var soundsAllowed: Bool { !listening && !modelPlaying }

    public var body: some View {
        ZStack {
            if step == .continue {
                WorldScenery(world: world)
                    .id(world)
                    .transition(reduceMotion ? .opacity : .push(from: .leading))
                if !departing {
                    CritterLayer(scene: scene, hushed: !soundsAllowed)
                        .id(word.id)
                        .transition(.opacity)
                }
                practice
            } else {
                SceneryView(night: true)
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
        .task {
            guard !started else { return }
            started = true
            try? await Task.sleep(nanoseconds: 1_200_000_000)      // le train entre en gare
            await present(word)
        }
        .onChange(of: listener.phase) { _, phase in
            if case let .finished(verdict) = phase { handle(verdict) }
        }
        .onChange(of: soundsAllowed, initial: true) { _, allowed in
            SoundBoard.shared.isSuspended = !allowed
        }
        .onDisappear {
            listener.reset()
            SoundBoard.shared.stopAll()
        }
    }

    // MARK: Écran

    private var topBar: some View {
        HStack(spacing: 16) {
            if let onHome {
                Button {
                    listener.reset()
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
            Spacer()
            if step == .continue {
                JourneyStrip(stations: stations, current: wordsDone, locale: locale)
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
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(EveilPalette.ink.opacity(0.25)))
                }
                .accessibilityLabel(fr ? "Espace des grands" : "Grown-ups area")
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    /// Les gares de la séance : un monde par mot, dans l'ordre du voyage.
    private var stations: [World] {
        var out: [World] = []
        var w = firstWorld
        for _ in 0..<policy.wordsPerSession {
            out.append(w)
            w = w.next
        }
        return out
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
                    WordPicture(word: word, size: card, pulse: picturePulse, onTap: tapPicture)
                    HStack(alignment: .center, spacing: 6) {
                        MascotView(action: feedback?.mascot, isListening: listening, size: cat)
                        SpeechBubble(bubbleText)
                            .frame(maxWidth: wide ? 380 : 300)
                    }
                    .allowsHitTesting(false)
                }
                .opacity(departing ? 0 : 1)
                .animation(.easeInOut(duration: 0.4), value: departing)
                Spacer(minLength: 20)
                TrainView(wagons: word.wagons, lit: litWagons, cabooseLabel: word.caboose,
                          caboose: cabooseState, scale: trainScale, departing: departing)
                    .id(word.id)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
                Button {
                    Task { await present(word) }
                } label: {
                    Label(listening ? (fr ? "Je t'écoute…" : "Listening…") : (fr ? "À toi !" : "Your turn!"),
                          systemImage: listening ? "waveform" : "ear.fill")
                }
                .buttonStyle(KidButtonStyle())
                .disabled(listening || modelPlaying || traveling)
                .opacity(traveling ? 0.4 : 1)
                .padding(.top, 22)
                Spacer(minLength: demoMode ? 110 : 36)
            }
            .frame(width: w, height: h)
        }
    }

    private var bubbleText: String {
        if traveling { return fr ? "Tchou-tchou ! En route !" : "Choo-choo! All aboard!" }
        return (feedback?.message ?? .invite).defaultText(locale: locale)
    }

    /// Barre de présentation du mode démo (pour l'adulte qui montre l'app).
    private var demoBar: some View {
        let scenarios = DemoScenario.allCases.filter { $0.isAvailable(for: word) }
        let compact = scenarios.count > 2               // quatre boutons : on resserre (iPad 11")
        let size: CGFloat = compact ? 16 : 18
        return HStack(spacing: compact ? 10 : 14) {
            Text(fr ? "Faire dire au train :" : "Make the train hear:")
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            ForEach(scenarios) { scenario in
                Button {
                    runDemo(scenario)
                } label: {
                    Label(scenario.label(locale: locale), systemImage: scenario.symbol)
                        .font(.system(size: size, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .padding(.horizontal, compact ? 12 : 16).padding(.vertical, 10)
                        .background(Capsule().fill(.white))
                        .foregroundStyle(Color.purple)
                }
                .disabled(listening || modelPlaying || traveling)
            }
            Button {
                Task { await travel() }
            } label: {
                Label(fr ? "Mot suivant" : "Next word", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .padding(.horizontal, compact ? 12 : 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.purple.opacity(0.35)))
                    .foregroundStyle(.white)
            }
            .disabled(listening || modelPlaying || traveling)
        }
        .minimumScaleFactor(0.7)
        .padding(.horizontal, compact ? 14 : 20).padding(.vertical, 12)
        .background(Capsule().fill(Color.purple.opacity(0.8)))
        .padding(.horizontal, 12)
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
        guard step == .continue else { return }
        feedback = nil
        listener.reset()
        SoundBoard.shared.isSuspended = true           // le mot modèle, puis l'écoute : silence
        SoundBoard.shared.preload([scene.sound, WordScene.sound(of: scene.critter), .whistle]
                                  + [WordScene.hookSound(coda: w.coda)].compactMap { $0 })
        modelPlaying = true
        // TODO(contenu) : remplacer par les enregistrements validés (voix humaine FR/EN).
        await voice.speak(w.text, locale: locale)
        if !demoMode && !traveling && step == .continue {
            listener.config = ListeningSettings.detectorConfig(adultTrial: adultTrial)
            listener.listen(for: w)                    // l'écoute démarre AVANT de rendre les sons
        }
        modelPlaying = false
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
        let hook = verdict.kind == .complete ? WordScene.hookSound(coda: word.coda) : nil
        if !fb.advance { attempt += 1 }               // la relance vient de l'enfant (« À toi ! »)
        Task {
            if let hook {
                try? await Task.sleep(nanoseconds: 250_000_000)
                SoundBoard.shared.play(hook)          // « chhh » : le fourgon s'accroche
            }
            if fb.mascot == .modelWord {
                modelPlaying = true
                await voice.speak(word.text, locale: locale)
                modelPlaying = false
            }
            // En démo, c'est le présentateur qui avance (« Mot suivant ») : le résultat reste affiché.
            guard !demoMode, fb.advance else { return }
            try? await Task.sleep(nanoseconds: 1_500_000_000)   // la fête, puis on enchaîne
            await travel()
        }
    }

    /// Le train siffle, quitte la gare, et entre dans le monde suivant avec le mot suivant.
    private func travel() async {
        guard !traveling, step == .continue else { return }
        traveling = true
        listener.reset()
        SoundBoard.shared.isSuspended = false
        SoundBoard.shared.play(.whistle)
        withAnimation(.easeInOut(duration: 0.3)) { departing = true }
        try? await Task.sleep(nanoseconds: reduceMotion ? 300_000_000 : 1_150_000_000)
        wordsDone += 1
        attempt = 1
        let elapsed = Date().timeIntervalSince(sessionStart)
        let next = policy.nextStep(wordsDone: wordsDone, sessionSeconds: elapsed,
                                   todaySeconds: PracticeStore.secondsToday(in: context) + elapsed)
        deckCursor = (index + 1) % words.count
        guard next == .continue else {
            index += 1                                  // la prochaine séance reprendra au mot suivant
            feedback = nil
            withAnimation(.easeInOut(duration: 0.8)) {
                step = next
                departing = false
            }
            traveling = false
            if !demoMode {
                context.insert(PracticeSession(startedAt: sessionStart, seconds: elapsed,
                                               wordsPracticed: wordsDone, locale: locale))
                try? context.save()
            }
            return
        }
        // En coulisses (tout est encore masqué) : le mot suivant, SANS animation — le
        // nouveau train fait lui-même son entrée en gare.
        index += 1
        feedback = nil
        withAnimation(.easeInOut(duration: 0.9)) { worldRaw = world.next.rawValue }
        try? await Task.sleep(nanoseconds: reduceMotion ? 100_000_000 : 450_000_000)
        withAnimation(.easeInOut(duration: 0.4)) { departing = false }
        try? await Task.sleep(nanoseconds: reduceMotion ? 200_000_000 : 1_000_000_000)   // entrée en gare
        traveling = false
        await present(word)
    }

    private func tapPicture() {
        guard soundsAllowed, !traveling else { return }
        picturePulse += 1
        SoundBoard.shared.play(scene.sound)
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

/// L'image du mot, sur sa carte blanche : on la touche, l'objet fait son bruit.
struct WordPicture: View {
    let word: TargetWord
    var size: CGFloat = 280
    var pulse = 0
    var onTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            WordArt(wordId: word.id, size: size * 0.9, pulse: pulse)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.14, style: .continuous).fill(.white)
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: size * 0.09, weight: .bold))
                        .foregroundStyle(EveilPalette.ink.opacity(0.35))
                        .padding(size * 0.06)
                }
                .contentShape(RoundedRectangle(cornerRadius: size * 0.14, style: .continuous))
                .onTapGesture(perform: onTap)
                .scaleEffect(pulse % 2 == 1 ? 1.04 : 1)
                .animation(.spring(duration: 0.3, bounce: 0.5), value: pulse)
            Text(word.text)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(EveilPalette.ink.opacity(0.7))          // pour l'adulte qui accompagne
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(word.id.hasPrefix("fr") ? "Touche l'image pour entendre son bruit" : "Tap the picture to hear its sound")
    }
}

/// La ligne du voyage : une gare par mot de la séance (le monde de chaque étape).
struct JourneyStrip: View {
    let stations: [World]
    let current: Int
    let locale: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(stations.enumerated()), id: \.offset) { k, world in
                if k > 0 {
                    Capsule().fill(.white.opacity(k <= current ? 0.95 : 0.45)).frame(width: 14, height: 4)
                }
                ZStack {
                    Circle().fill(k < current ? EveilPalette.go : (k == current ? .white : .white.opacity(0.35)))
                    Image(systemName: world.symbol)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(k < current ? .white : (k == current ? EveilPalette.ink : .white))
                }
                .frame(width: k == current ? 46 : 36, height: k == current ? 46 : 36)
                .shadow(color: .black.opacity(k == current ? 0.2 : 0), radius: 4, y: 2)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(EveilPalette.ink.opacity(0.18)))
        .animation(.spring(duration: 0.5), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(locale.hasPrefix("fr") ? "Voyage : étape \(current + 1) sur \(stations.count)"
                                                   : "Journey: stop \(current + 1) of \(stations.count)")
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
