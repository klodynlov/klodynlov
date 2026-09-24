// PracticeView.swift — l'écran d'entraînement : modèle → écoute → retour.
//
// Boucle d'un mot :
//   1. le mot MODÈLE est joué (voix enregistrée ; repli : synthèse système) ;
//   2. le micro s'ouvre (tour de parole strict) ; les wagons s'allument EN DIRECT ;
//   3. le verdict final passe par `FeedbackPolicy` (jamais « faux ») ;
//   4. on avance, ou l'enfant relance lui-même en touchant l'oreille.
// Fin de séance ritualisée (`SessionPolicy`) + une « mission » hors écran.

#if canImport(SwiftUI) && canImport(SwiftData) && canImport(AVFoundation) && canImport(Observation)
import SwiftData
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

    @Environment(\.modelContext) private var context
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

    public init(words: [TargetWord], locale: String, cabooseSounds: [String: CabooseSound],
                policy: SessionPolicy = SessionPolicy(), parentButtonHidden: Bool = false) {
        precondition(!words.isEmpty, "liste de mots vide")
        self.words = words
        self.locale = locale
        self.cabooseSounds = cabooseSounds
        self.policy = policy
        self.parentButtonHidden = parentButtonHidden
    }

    private var word: TargetWord { words[index % words.count] }
    private var fr: Bool { locale.hasPrefix("fr") }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            if step == .continue {
                practice
            } else {
                SessionEndView(step: step, locale: locale, cue: word.coda.flatMap { cabooseSounds[$0]?.cue })
            }
            if !parentButtonHidden {
                Button { showGate = true } label: {
                    Image(systemName: "gearshape.fill").font(.title2).padding(20)
                }
                .accessibilityLabel(fr ? "Espace des grands" : "Grown-ups area")
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
    }

    private var practice: some View {
        VStack(spacing: 36) {
            WordPicture(word: word)
            TrainView(wagons: word.wagons, lit: litWagons, cabooseLabel: word.caboose, caboose: cabooseState)
            MascotView(action: feedback?.mascot, isListening: listener.phase == .listening)
            Text((feedback?.message ?? .invite).defaultText(locale: locale))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Button {
                Task { await present(word) }
            } label: {
                Label(fr ? "À toi !" : "Your turn!", systemImage: "ear.fill")
                    .font(.title.bold())
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(listener.phase == .listening)
        }
        .padding(40)
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

    private func present(_ w: TargetWord) async {
        feedback = nil
        listener.reset()
        // TODO(contenu) : remplacer par les enregistrements validés (voix humaine FR/EN).
        await voice.speak(w.text, locale: locale)
        listener.listen(for: w)
    }

    private func handle(_ verdict: Verdict) {
        let fb = FeedbackPolicy.feedback(for: verdict, wagons: word.wagons.count,
                                         hasCaboose: word.coda != nil, attempt: attempt)
        feedback = fb
        if verdict.kind == .complete { recordHook(word.id) }
        Task {
            if fb.mascot == .modelWord { await voice.speak(word.text, locale: locale) }
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
        } else {
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
    private static let symbols: [String: String] = [
        "fr.douche": "shower.fill", "fr.bouche": "mouth.fill", "fr.niche": "house.fill",
        "fr.tasse": "cup.and.saucer.fill", "fr.minouche": "cat.fill", "fr.vache": "hare.fill",
        "en.fish": "fish.fill", "en.bus": "bus.fill", "en.ice": "snowflake", "en.goose": "bird.fill",
    ]

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: Self.symbols[word.id] ?? "photo")
                .font(.system(size: 120))
                .foregroundStyle(.tint)
            Text(word.text)
                .font(.headline)
                .foregroundStyle(.secondary)          // pour l'adulte qui accompagne
        }
        .accessibilityElement(children: .combine)
    }
}

/// Fin de séance : le train rentre au dépôt, et une mission HORS ÉCRAN pour la famille.
struct SessionEndView: View {
    let step: SessionStep
    let locale: String
    let cue: String?
    private var fr: Bool { locale.hasPrefix("fr") }

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "moon.stars.fill").font(.system(size: 96)).foregroundStyle(.indigo)
            Text(step == .restToday
                 ? (fr ? "Le petit train dort. À demain !" : "The little train is asleep. See you tomorrow!")
                 : (fr ? "Le train rentre au dépôt. Bravo pour ce voyage !" : "The train goes home. What a trip!"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            if let cue {
                Text(fr ? "Mission pour ce soir : jouez ensemble — \(cue) !"
                        : "Mission for tonight: play together — \(cue)!")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(48)
    }
}
#endif
