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
//
// Retours de l'utilisateur (28/09/2026) :
//   • « une voix féminine naturelle, qui suit les syllabes » : le modèle se dit
//     d'abord syllabe par syllabe, chaque wagon s'allumant avec SA syllabe et le
//     fourgon s'accrochant sur la consonne finale, puis le mot entier (voix choisie
//     par `VoiceCatalog`, prononciation imposée par l'API du lexique) ;
//   • « un décompte pour le nombre de fois que l'enfant doit répéter » : l'adulte
//     règle le nombre de répétitions (3 par défaut) ; chaque mot bien dit allume une
//     lanterne (`RepetitionMeter`), la voix annonce « Encore 2 fois ! » et le micro
//     se rouvre ; le train part quand le décompte est fini — ou, pas de boucle
//     d'échec, après trop d'essais ;
//   • « plus c'est bien répété, plus de points » : chaque essai rapporte des étoiles
//     de jeu (`Stars.earned` : mot entier 3, sans la fin 2, syllabe en moins 1), qui
//     s'envolent du train vers le compteur — jamais un score de langage, jamais de perte ;
//   • « entendre les syllabes quand on les touche » : toucher un wagon fait dire SA
//     syllabe (`wagonSegments`), le fourgon sa consonne et sa vapeur — hors écoute ;
//   • « chaque syllabe bien prononcée émet un son de validation » : dès la fin de
//     l'écoute (le micro ne doit jamais entendre le jeu), un ding par wagon allumé, en
//     arpège, puis le « chhh » du fourgon accroché.
// Fin de séance ritualisée (`SessionPolicy`) + une « mission » hors écran.
//
// Livres des sons (28/09/2026) : le même train. D'abord sans micro (`judge: .adult`,
// docs/EVEIL.md § 4.7 : le détecteur ne juge que la fin des mots en « ch » ou « s », et dans un
// livre le son est au début, au milieu ou à la fin) ; puis, retour de l'utilisateur sur l'iPad
// (« quand on répète il ne se passe rien, ça n'agit pas comme le petit train ») : le micro écoute
// COMME dans le petit train (`judge: .listenAndAdult` — wagons allumés à la voix, verdict sur les
// syllabes, décompte, étoiles), et l'adulte garde « Il l'a dit ! », seul juge du son travaillé.
// Le wagon du son est marqué et ses lettres colorées.
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

/// Qui dit que le mot est bien dit : le détecteur (micro), l'adulte, ou les deux (livres des sons :
/// le micro juge les syllabes, l'adulte peut toujours dire « Il l'a dit ! »).
public enum PracticeJudge: Sendable {
    case listen
    case adult
    case listenAndAdult

    /// Le micro s'ouvre après le mot modèle.
    public var listens: Bool { self != .adult }
    /// Le bouton « Il l'a dit ! » est là.
    public var adultJudges: Bool { self != .listen }
}

/// Le son travaillé dans un mot (livres des sons) : son wagon et ses lettres.
public struct WordTarget: Equatable, Sendable {
    public let wagon: Int
    public let letters: String

    public init(wagon: Int, letters: String) {
        self.wagon = wagon
        self.letters = letters
    }
}

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
    public let judge: PracticeJudge
    /// Livres des sons : le son travaillé dans chaque mot (par identifiant de mot).
    public let targets: [String: WordTarget]
    /// Livres des sons : le titre du livre (« Le livre du « ch » »), en haut.
    public let title: String?

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("eveil.demoMode") private var demoMode = false
    @AppStorage(ListeningSettings.adultTrialKey) private var adultTrial = false
    /// Où reprendre (un curseur par liste : le petit train, et chaque livre des sons).
    private let cursorKey: String
    @AppStorage("eveil.world") private var worldRaw = 0
    @AppStorage(VoiceCatalog.settingKey) private var voiceId = ""
    @AppStorage(ListeningSettings.syllableModelKey) private var syllableModel = true
    @AppStorage(Repetitions.settingKey) private var repetitions = Repetitions.defaultCount
    @AppStorage(Stars.settingKey) private var starsOn = true
    @AppStorage(Stars.totalKey) private var starsTotal = 0
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
    /// Pendant le modèle syllabe par syllabe : combien de wagons la voix a allumés (nil sinon).
    @State private var modelLit: Int?
    @State private var modelHooked = false
    /// Le décompte du mot en cours.
    @State private var plan = RepetitionPlan()
    /// Étoiles de la séance, et la volée en vol (du train vers le compteur).
    @State private var sessionStars = 0
    @State private var burst: StarBurst?
    /// Le wagon (ou le fourgon) que l'enfant vient de toucher : il s'allume seul pendant sa syllabe.
    @State private var touchedWagon: Int?
    @State private var touchedCaboose = false

    public init(words: [TargetWord], locale: String, cabooseSounds: [String: CabooseSound],
                policy: SessionPolicy = SessionPolicy(), parentButtonHidden: Bool = false,
                onHome: (() -> Void)? = nil, judge: PracticeJudge = .listen,
                targets: [String: WordTarget] = [:], title: String? = nil,
                cursorKey: String = WordDeck.cursorKey) {
        precondition(!words.isEmpty, "liste de mots vide")
        self.words = words
        self.locale = locale
        self.cabooseSounds = cabooseSounds
        self.policy = policy
        self.parentButtonHidden = parentButtonHidden
        self.onHome = onHome
        self.judge = judge
        self.targets = targets
        self.title = title
        self.cursorKey = cursorKey
        // Le voyage reprend où la séance précédente l'a laissé (mot et monde).
        let defaults = UserDefaults.standard
        _index = State(initialValue: max(0, defaults.integer(forKey: cursorKey)) % words.count)
        _firstWorld = State(initialValue: World(rawValue: defaults.integer(forKey: "eveil.world")) ?? .countryside)
    }

    private var word: TargetWord { words[index % words.count] }
    private var scene: WordScene { WordScene.forWord(word) }
    private var world: World { World(rawValue: worldRaw) ?? .countryside }
    private var fr: Bool { locale.hasPrefix("fr") }
    private var listening: Bool { listener.phase == .listening }
    /// « Il l'a dit ! » compte : pas pendant le modèle ni le voyage, et pas deux fois le même mot
    /// (ni pendant la fête d'une répétition, ni quand le train va partir).
    private var adultCanJudge: Bool {
        judge.adultJudges && !modelPlaying && !traveling && feedback?.message != .again && feedback?.advance != true
    }
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
                SessionEndView(step: step, locale: locale, cue: word.coda.flatMap { cabooseSounds[$0]?.cue },
                               stars: starsOn ? sessionStars : nil, treasure: starsTotal)
            }
            VStack(spacing: 0) {
                topBar
                Spacer()
                if demoMode && step == .continue { demoBar }
            }
            if let burst {
                GeometryReader { geo in
                    StarBurstLayer(burst: burst,
                                   from: CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.7),
                                   to: CGPoint(x: geo.size.width - (parentButtonHidden ? 95 : 165), y: 52))
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .id(burst.id)
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
            plan = RepetitionPlan(target: repetitions)
            try? await Task.sleep(nanoseconds: 1_500_000_000)      // le train entre en gare
            await present(word)
        }
        .onChange(of: listener.phase) { _, phase in
            if case let .finished(verdict) = phase { handle(verdict) }
        }
        .onChange(of: soundsAllowed, initial: true) { _, allowed in
            SoundBoard.shared.isSuspended = !allowed
        }
        .onDisappear {
            voice.stop()
            listener.reset()
            SoundBoard.shared.stopAll()
            SoundBoard.shared.isSuspended = false         // les autres jeux retrouvent leurs sons
        }
    }

    // MARK: Écran

    private var topBar: some View {
        HStack(spacing: 16) {
            if let onHome {
                Button {
                    voice.stop()
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
            if let title {
                Text(title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(WagonCar.soundColor.opacity(0.85)))
                    .lineLimit(1)
            }
            if step == .continue {
                JourneyStrip(stations: stations, current: wordsDone, locale: locale)
            }
            Spacer()
            if starsOn && step == .continue {
                StarCounter(count: sessionStars)
            }
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
            let trainScale = min(wide ? 1.45 : 1.5, (w - 60) / trainBase)   // paysage : le train ne mord pas sur la carte
            VStack(spacing: 0) {
                Spacer(minLength: 90)
                HStack(alignment: .center, spacing: wide ? 44 : 22) {
                    WordPicture(word: word, size: card, pulse: picturePulse, onDark: world.isDark, onTap: tapPicture)
                    HStack(alignment: .center, spacing: 6) {
                        // Pendant le modèle, c'est le chat qui dit le mot.
                        MascotView(action: modelPlaying && feedback == nil ? MascotAction.modelWord : feedback?.mascot,
                                   isListening: listening, size: cat)
                        SpeechBubble(bubbleText)
                            .frame(maxWidth: wide ? 380 : 300)
                    }
                    .allowsHitTesting(false)
                }
                .opacity(departing ? 0 : 1)
                .animation(.easeInOut(duration: 0.4), value: departing)
                Spacer(minLength: 20)
                TrainView(wagons: word.wagons, lit: litWagons, cabooseLabel: word.caboose,
                          caboose: cabooseState, scale: trainScale, departing: departing,
                          onTapWagon: hearWagon, onTapCaboose: hearCaboose,
                          targetWagon: targets[word.id]?.wagon, targetLetters: targets[word.id]?.letters)
                    .id(word.id)
                    .frame(maxWidth: .infinity)
                HStack(spacing: 24) {
                    if plan.target > 1 {
                        RepetitionMeter(plan: plan, locale: locale)
                            .opacity(traveling ? 0.4 : 1)
                    }
                    if !judge.listens {
                        Button {
                            Task { await present(word) }
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 30, weight: .bold))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(KidButtonStyle(color: EveilPalette.ink.opacity(0.55)))
                        .disabled(modelPlaying || traveling)
                        .accessibilityLabel(fr ? "Réécouter le mot" : "Listen again")
                    }
                    Button {
                        if !judge.listens {
                            adultHeard()
                        } else {
                            Task { await present(word) }
                        }
                    } label: {
                        if !judge.listens {
                            Label(fr ? "Il l'a dit !" : "Said it!", systemImage: "hand.thumbsup.fill")
                        } else if listening {
                            // Le train entend : des barres qui bougent avec la voix (le niveau, jamais le son).
                            HStack(spacing: 14) {
                                LevelBars(db: listener.inputLevelDb)
                                Text(fr ? "Je t'écoute…" : "Listening…")
                            }
                        } else {
                            Label(fr ? "À toi !" : "Your turn!", systemImage: "ear.fill")
                        }
                    }
                    .buttonStyle(KidButtonStyle())
                    // Pendant la fête d'une répétition, le micro se rouvre tout seul (« Encore ! »).
                    .disabled(listening || modelPlaying || traveling || feedback?.message == .again)
                    .opacity(traveling ? 0.4 : 1)
                    if judge == .listenAndAdult {
                        // Le micro compte les syllabes ; le son du livre, c'est l'adulte qui l'entend.
                        Button(action: adultHeard) {
                            Label(fr ? "Il l'a dit !" : "Said it!", systemImage: "hand.thumbsup.fill")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .frame(height: 56)
                                .background(Capsule().fill(EveilPalette.ink.opacity(0.55)))
                        }
                        .buttonStyle(.plain)
                        .disabled(!adultCanJudge)
                        .opacity(traveling ? 0.4 : adultCanJudge ? 1 : 0.5)
                    }
                }
                .padding(.top, 22)
                Spacer(minLength: demoMode ? 110 : 36)
            }
            .frame(width: w, height: h)
        }
    }

    private var bubbleText: String {
        if traveling { return fr ? "Tchou-tchou ! En route !" : "Choo-choo! All aboard!" }
        if modelLit != nil { return fr ? "Écoute bien le train…" : "Listen to the train…" }
        switch feedback?.message {
        case nil, .invite?: return Repetitions.inviteText(count: plan.remaining, locale: locale)
        case .again?: return Repetitions.againText(remaining: plan.remaining, locale: locale)
        case let message?: return message.defaultText(locale: locale)
        }
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

    // Le modèle allume les wagons avec ses syllabes ; aperçu en direct pendant l'écoute ;
    // retour final ensuite.
    private var litWagons: [Bool] {
        if let touchedWagon { return word.wagons.indices.map { $0 == touchedWagon } }
        if let feedback { return feedback.litWagons }
        if let modelLit { return word.wagons.indices.map { $0 < modelLit } }
        return word.wagons.indices.map { $0 < listener.litWagons }
    }

    private var cabooseState: CabooseState {
        guard word.coda != nil else { return .none }
        if touchedCaboose { return .hooked }
        if let feedback { return feedback.caboose }
        if modelLit != nil { return modelHooked ? .hooked : .waiting }
        return listener.cabooseHeard ? .hooked : .waiting
    }

    // MARK: Boucle d'un mot

    private func present(_ w: TargetWord) async {
        guard step == .continue else { return }
        feedback = nil
        touchedWagon = nil
        touchedCaboose = false
        listener.reset()
        SoundBoard.shared.isSuspended = true           // le mot modèle, puis l'écoute : silence
        let wordScene = WordScene.forWord(w)
        SoundBoard.shared.preload([wordScene.sound, .whistle] + [WordScene.hookSound(coda: w.coda)].compactMap { $0 })
        SoundBoard.shared.preload([WordScene.sound(of: wordScene.critter)], variants: Array(0..<wordScene.count))
        SoundBoard.shared.preload([.twinkle], variants: Array(0..<Stars.max))
        SoundBoard.shared.preload([.ding], variants: Self.syllableNotes)
        modelPlaying = true
        voice.voiceIdentifier = voiceId
        // TODO(contenu) : remplacer par les enregistrements validés (voix humaine FR/EN).
        let wholeIPA = w.ipa.map { $0.replacingOccurrences(of: ".", with: "") }
        if syllableModel {
            // « mi · nou(ch) » : chaque wagon s'allume avec sa syllabe, le fourgon sur la fin.
            let segments = w.voiceSegments
            modelHooked = false
            modelLit = 0
            await voice.speakSegments(segments, locale: locale) { k in modelLit = k + 1 }
            if w.coda != nil { modelHooked = true }
            try? await Task.sleep(nanoseconds: 350_000_000)
            // Puis le mot entier, d'une traite (un mot d'une syllabe vient d'être dit entier).
            if segments.count > 1 && !Task.isCancelled {
                await voice.speak(w.text, locale: locale, ipa: wholeIPA)
            }
        } else {
            await voice.speak(w.text, locale: locale, ipa: wholeIPA)
        }
        modelLit = nil                                 // le train s'éteint : à l'enfant de l'allumer
        modelHooked = false
        guard !Task.isCancelled else {
            modelPlaying = false
            return
        }
        if judge.listens && !demoMode && !traveling && step == .continue {
            listener.config = ListeningSettings.detectorConfig(adultTrial: adultTrial)
            listener.listen(for: w)                    // l'écoute démarre AVANT de rendre les sons
        }
        modelPlaying = false
    }

    /// Le juge adulte : l'enfant a bien dit le mot (livres des sons). Si le micro écoutait, il se
    /// ferme : le verdict de l'adulte passe avant (jamais deux fêtes pour un mot).
    private func adultHeard() {
        guard adultCanJudge else { return }
        if listening { listener.reset() }
        handle(.adultHeard(wagons: word.wagons.count, hasCaboose: word.coda != nil))
    }

    /// Le décompte continue : la voix annonce ce qui reste, puis le micro se rouvre
    /// (sans rejouer le modèle : l'enfant vient de le dire).
    private func listenAgainForCountdown(_ w: TargetWord) async {
        guard step == .continue, !traveling, w.id == word.id else { return }
        if !judge.listens {
            // Pas de micro : on relance juste le décompte (« Encore ! »), l'adulte juge.
            feedback = nil
            voice.voiceIdentifier = voiceId
            await voice.speak(fr ? "Encore !" : "Again!", locale: locale)
            return
        }
        feedback = nil
        listener.reset()
        SoundBoard.shared.isSuspended = true
        modelPlaying = true
        voice.voiceIdentifier = voiceId
        await voice.speak(fr ? "Encore !" : "Again!", locale: locale)
        guard !Task.isCancelled, !traveling, step == .continue, w.id == word.id else {
            modelPlaying = false
            return
        }
        listener.config = ListeningSettings.detectorConfig(adultTrial: adultTrial)
        listener.listen(for: w)
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
                                         hasCaboose: word.coda != nil, attempt: attempt,
                                         repetitionsLeft: plan.leftAfterSuccess)
        feedback = fb
        let current = word
        if verdict.kind == .complete {
            plan.recordSuccess()                      // une lanterne s'allume
            attempt = 1                               // chaque répétition a ses essais
            // La démo n'est pas un enfant : rien n'entre dans le journal local de progression.
            if !demoMode { recordHook(current.id) }
        } else if !fb.advance {
            attempt += 1                              // la relance vient de l'enfant (« À toi ! »)
        }
        let hook = verdict.kind == .complete ? WordScene.hookSound(coda: current.coda) : nil
        let validated = fb.litWagons.filter { $0 }.count
        giveStars(Stars.earned(for: verdict, hasCaboose: current.coda != nil))
        Task {
            // L'écoute est finie : le train « rejoue » ses wagons, un ding par syllabe bien dite.
            SoundBoard.shared.isSuspended = false
            for k in 0..<validated {
                SoundBoard.shared.play(.ding, variant: Self.syllableNotes[k % Self.syllableNotes.count])
                try? await Task.sleep(nanoseconds: 170_000_000)
            }
            if let hook {
                try? await Task.sleep(nanoseconds: validated > 0 ? 80_000_000 : 250_000_000)
                SoundBoard.shared.play(hook)          // « chhh » : le fourgon s'accroche
            }
            if fb.mascot == .modelWord {
                modelPlaying = true
                voice.voiceIdentifier = voiceId
                await voice.speak(current.text, locale: locale,
                                  ipa: current.ipa.map { $0.replacingOccurrences(of: ".", with: "") })
                modelPlaying = false
            }
            if fb.message == .again {
                // Le décompte n'est pas fini : la fête, puis « Encore ! » et le micro se rouvre.
                // En démo, c'est le présentateur qui relance (les boutons de la barre).
                guard !demoMode else { return }
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                await listenAgainForCountdown(current)
                return
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
        plan = RepetitionPlan(target: repetitions)    // nouveau mot, nouveau décompte
        let elapsed = Date().timeIntervalSince(sessionStart)
        let next = policy.nextStep(wordsDone: wordsDone, sessionSeconds: elapsed,
                                   todaySeconds: PracticeStore.secondsToday(in: context) + elapsed)
        UserDefaults.standard.set((index + 1) % words.count, forKey: cursorKey)
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
        try? await Task.sleep(nanoseconds: reduceMotion ? 200_000_000 : 1_500_000_000)   // entrée en gare
        traveling = false
        await present(word)
    }

    /// Les notes des syllabes validées : do, mi, sol, do (arpège montant de la gamme de `ding`).
    static let syllableNotes = [0, 2, 3, 5]

    /// L'enfant touche un wagon : la voix dit SA syllabe, le wagon s'allume seul le temps de la dire.
    /// Jamais pendant l'écoute ni pendant le modèle (tour de parole).
    private func hearWagon(_ k: Int) {
        guard !listening, !modelPlaying, !traveling, word.wagonSegments.indices.contains(k) else { return }
        let segment = word.wagonSegments[k]
        let current = word.id
        touchedCaboose = false
        touchedWagon = k
        Task {
            voice.voiceIdentifier = voiceId
            await voice.speak(segment.text, locale: locale, ipa: segment.ipa, pace: .syllable)
            if touchedWagon == k && word.id == current { touchedWagon = nil }
        }
    }

    /// L'enfant touche le fourgon : sa vapeur (« chhh ») ou son serpent (« sss »), puis la voix
    /// dit la consonne.
    private func hearCaboose() {
        guard !listening, !modelPlaying, !traveling, let segment = word.cabooseSegment else { return }
        let current = word.id
        touchedWagon = nil
        touchedCaboose = true
        if let hook = WordScene.hookSound(coda: word.coda) { SoundBoard.shared.play(hook) }
        Task {
            voice.voiceIdentifier = voiceId
            await voice.speak(segment.text, locale: locale, ipa: segment.ipa, pace: .syllable)
            if word.id == current { touchedCaboose = false }
        }
    }

    /// Les étoiles d'un essai s'envolent du train ; le compteur monte à chaque étoile posée.
    /// La démo n'est pas un enfant : elle montre la volée, mais ne touche pas au trésor.
    private func giveStars(_ earned: Int) {
        guard starsOn, earned > 0 else { return }
        let volley = StarBurst(count: earned, start: Date())
        burst = volley
        if !demoMode { starsTotal += earned }
        Task {
            for k in 0..<earned {
                let landing = StarBurst.flight + StarBurst.stagger * Double(k)
                let wait = landing - Date().timeIntervalSince(volley.start)
                if wait > 0 { try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
                sessionStars += 1
                SoundBoard.shared.play(.twinkle, variant: k)
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            if burst == volley { burst = nil }
        }
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
    /// Ciel sombre (l'espace) : le mot écrit sous la carte passe en clair.
    var onDark = false
    var onTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            PictoView(id: word.id, size: size * 0.9, pulse: pulse)
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
                .foregroundStyle(onDark ? Color.white.opacity(0.85) : EveilPalette.ink.opacity(0.7))   // pour l'adulte
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(word.id.hasPrefix("fr") ? "Touche l'image pour entendre son bruit" : "Tap the picture to hear its sound")
    }
}

/// Cinq barres qui dansent avec la voix pendant l'écoute : « le train t'entend ».
struct LevelBars: View {
    let db: Double

    var body: some View {
        // −55 dBFS (silence d'une pièce calme) → barres basses ; −15 dBFS (voix proche) → hautes.
        let level = min(1, max(0, (db + 55) / 40))
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                let shape = [0.55, 0.8, 1.0, 0.8, 0.55][i]
                Capsule().fill(.white)
                    .frame(width: 6, height: 8 + 26 * CGFloat(level * shape))
            }
        }
        .frame(height: 36)
        .animation(.easeOut(duration: 0.12), value: level)
        .accessibilityHidden(true)
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
    /// Étoiles de la séance (nil : étoiles masquées par l'adulte) et le trésor.
    var stars: Int? = nil
    var treasure: Int = 0
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
            if let stars, stars > 0 {
                VStack(spacing: 12) {
                    StarCounter(count: stars, size: 40)
                    Text(fr ? "étoiles gagnées pendant ce voyage — ton trésor : \(treasure) étoiles"
                            : "stars earned on this trip — your treasure: \(treasure) stars")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
            }
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
