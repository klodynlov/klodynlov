// BookSentenceView.swift — les phrases d'un livre des sons : regarder, écouter, reconstruire.
//
// Suite d'« au niveau d'OrthoPicto » (28/09/2026). Dans OrthoPicto, une page de livre est une
// phrase illustrée que l'enfant reconstruit avec des pictos, puis l'image s'anime. Ici, pour
// chaque phrase du livre (`SoundBook.sentences(level:)`, choisies par eveil/outils/livres/phrases.py
// pour porter le son) :
//   1. l'image de la phrase finie (la scène immobile, le chat déjà DANS la niche) ; la voix la
//      lit, chaque wagon du train plein s'allume avec son morceau ;
//   2. « À toi ! » : le train se vide ; pour chaque wagon, trois pictos (le bon et deux autres du
//      même rôle ; pour « où ? », le même lieu avec une autre préposition, et un autre lieu — les
//      cartes « où ? » montrent le sujet à sa place : la préposition se voit) ; la voix pose la
//      question avec ce qui est déjà accroché (« Que fait le chat ? ») ;
//   3. le bon picto s'accroche ; un autre : la voix le NOMME (« Ça, c'est la bûche. ») et le bon
//      s'éclaire — jamais « non », jamais « faux », pas de boucle d'échec ;
//   4. la phrase complète : chaque wagon redit son morceau, puis la scène JOUE la phrase pendant
//      que la voix la dit d'une traite ; les lettres du son sont colorées (wagons, phrase écrite) ;
//   5. « Il l'a dite ! » (l'adulte, docs/EVEIL.md § 4.7) → étoiles de jeu ; « Encore ! » → la
//      phrase suivante. Chaque livre et chaque niveau reprend où on l'a laissé.
// Tout se tait et rien ne se touche pendant que la voix parle. Aucun micro, rien d'aléatoire.

#if canImport(SwiftUI) && canImport(AVFoundation)
import EveilDesign
import EveilSounds
import PhraseCore
import SwiftUI
import WordEndAudio
import WordEndCore

@MainActor
public struct BookSentenceView: View {
    public let book: SoundBook
    /// 2 : qui + fait quoi + quoi ; 3 : qui + fait quoi + où.
    public let level: Int
    public let onClose: () -> Void

    @AppStorage(SuiteSettings.writtenWordsKey) private var written = SuiteSettings.writtenWordsDefault
    @AppStorage(SuiteSettings.capitalsKey) private var capitals = SuiteSettings.capitalsDefault
    @AppStorage(VoiceCatalog.settingKey) private var voiceId = ""
    @AppStorage(Stars.settingKey) private var starsOn = true
    @AppStorage(Stars.totalKey) private var starsTotal = 0
    @AppStorage("eveil.demoMode") private var demoMode = false

    enum Step { case look, build, done }

    @State private var index: Int
    @State private var step: Step = .look
    @State private var slots: [PhraseCard?] = []
    @State private var hint: PhraseCard?
    @State private var voice = ModelVoicePlayer()
    @State private var speaking = false
    @State private var litSlot: Int?
    @State private var playStart: Date?
    @State private var bravoGiven = false
    @State private var sessionStars = 0
    @State private var burst: StarBurst?
    @State private var started = false

    private let cursorKey: String

    public init(book: SoundBook, level: Int, onClose: @escaping () -> Void) {
        self.book = book
        self.level = level
        self.onClose = onClose
        cursorKey = "eveil.book.\(book.id).level\(level)"
        let count = max(1, book.sentences(level: level).count)
        _index = State(initialValue: max(0, UserDefaults.standard.integer(forKey: cursorKey)) % count)
    }

    private var locale: String { book.locale }
    private var fr: Bool { locale.hasPrefix("fr") }
    private var sentences: [SoundBookSentence] { book.sentences(level: level) }
    private var sentence: SoundBookSentence? { sentences.isEmpty ? nil : sentences[index % sentences.count] }
    private var roles: [PhraseRole] { PhraseLevels.roles(level: level) }
    /// Le wagon à remplir (pendant la reconstruction).
    private var editing: Int? { step == .build ? slots.firstIndex(where: { $0 == nil }) : nil }
    private var subject: PhraseNoun? { sentence.flatMap { $0.cards.first }.flatMap { PhraseLexicon.noun($0.key) } }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let trainScale = min(0.95, (w - 60) / PhraseTrain.baseWidth(wagons: roles.count - 1))
            let cardSide = min(170, (w - 60 - 2 * 24) / 3, h * 0.2)
            let stageHeight = max(200, min((w - 60) / 2, h - 96 - PhraseTrain.height * trainScale - cardSide - 170))
            ZStack {
                LinearGradient(colors: [EveilPalette.skyLight, Color(red: 1.0, green: 0.97, blue: 0.9)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                if let sentence {
                    VStack(spacing: 14) {
                        topBar
                        SentenceStage(scene: SentenceScene(cards: sentence.cards), playStart: playStart, settled: true)
                            .frame(width: stageHeight * 2, height: stageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                            .accessibilityElement()
                            .accessibilityLabel(sentence.text)
                        if written && step == .done {
                            SentenceStrip(cards: sentence.cards, locale: locale, capitals: capitals, lit: litSlot,
                                          marks: sentence.marks)
                                .transition(.opacity)
                        }
                        PhraseTrain(roles: roles, slots: slots, editing: editing, lit: litSlot, locale: locale,
                                    written: written, capitals: capitals, marks: sentence.marks, onTap: touchWagon)
                            .scaleEffect(trainScale, anchor: .bottomLeading)
                            .frame(width: PhraseTrain.baseWidth(wagons: roles.count - 1) * trainScale,
                                   height: PhraseTrain.height * trainScale, alignment: .bottomLeading)
                        bottom(sentence: sentence, cardSide: cardSide)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                } else {
                    VStack(spacing: 20) {
                        topBar
                        Spacer()
                        Text(fr ? "Ce livre n'a pas encore de phrases." : "This book has no sentences yet.")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(EveilPalette.ink)
                        Spacer()
                    }
                    .padding(20)
                }
                if let burst {
                    StarBurstLayer(burst: burst, from: CGPoint(x: w / 2, y: h * 0.6), to: CGPoint(x: w - 95, y: 52))
                        .allowsHitTesting(false)
                        .id(burst.id)
                }
            }
        }
        .task {
            guard !started else { return }
            started = true
            SoundBoard.shared.isSuspended = false
            SoundBoard.shared.preload(SceneSounds.preloaded)
            SoundBoard.shared.preload([.ding], variants: [0, 2, 3, 5])
            try? await Task.sleep(nanoseconds: 400_000_000)
            await startPage()
        }
        .onDisappear {
            voice.stop()
            SoundBoard.shared.stopAll()
        }
    }

    // MARK: En-tête

    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                voice.stop()
                SoundBoard.shared.stopAll()
                onClose()
            } label: {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(EveilPalette.ink.opacity(0.35)))
            }
            .accessibilityLabel(fr ? "Retour aux livres" : "Back to the books")
            VStack(alignment: .leading, spacing: 0) {
                Text(SoundBooks.title(book))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(EveilPalette.ink)
                Text(Self.levelName(level, locale: locale))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(EveilPalette.ink.opacity(0.6))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Spacer(minLength: 8)
            if starsOn { StarCounter(count: sessionStars) }
        }
        .frame(height: 70)
    }

    /// Le nom d'un niveau des livres : les mots, les phrases, et où ?
    nonisolated static func levelName(_ level: Int, locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        switch level {
        case 1: return fr ? "Les mots" : "Words"
        case 2: return fr ? "Les phrases" : "Sentences"
        default: return fr ? "Et où ?" : "And where?"
        }
    }

    // MARK: Le bas de l'écran : écouter, les trois pictos, ou « Encore ! »

    @ViewBuilder
    private func bottom(sentence: SoundBookSentence, cardSide: CGFloat) -> some View {
        switch step {
        case .look:
            Label(fr ? "Écoute…" : "Listen…", systemImage: "ear.fill")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(EveilPalette.ink.opacity(0.7))
                .padding(.top, 14)
        case .build:
            if let k = editing, sentence.choices.indices.contains(k) {
                VStack(spacing: 10) {
                    HStack(spacing: 14) {
                        Text(PhrasePrompts.question(for: roles[k], cards: slots.compactMap { $0 }, locale: locale))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(EveilPalette.ink.opacity(0.8))
                        // Réentendre la phrase modèle, sans défaire ce qui est accroché.
                        Button {
                            voice.stop()
                            Task { await say(sentence.text) }
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(Circle().fill(EveilPalette.ink.opacity(0.45)))
                        }
                        .disabled(speaking)
                        .accessibilityLabel(fr ? "Réécouter la phrase" : "Hear the sentence again")
                    }
                    HStack(spacing: 24) {
                        ForEach(sentence.choices[k]) { card in
                            PictoCard(card: card, side: cardSide, locale: locale, written: written, capitals: capitals,
                                      color: PhraseTrain.color(card.role), subject: subject, hint: hint == card) {
                                choose(card, in: sentence)
                            }
                            .disabled(speaking)
                        }
                    }
                    .id("\(index)-\(k)")
                }
            }
        case .done:
            HStack(spacing: 22) {
                Button {
                    Task { await playSentence(sentence) }
                } label: {
                    Label(fr ? "Réécouter" : "Listen again", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(KidButtonStyle(color: EveilPalette.ink.opacity(0.55)))
                if starsOn && !bravoGiven {
                    Button(action: bravo) {
                        Label(fr ? "Il l'a dite !" : "Said it!", systemImage: "hand.thumbsup.fill")
                    }
                    .buttonStyle(KidButtonStyle(color: EveilPalette.wagonLit.opacity(0.95)))
                    .accessibilityHint(fr ? "Pour l'adulte : l'enfant a redit la phrase"
                                          : "For the grown-up: the child said the sentence")
                }
                Button(action: nextSentence) {
                    Label(fr ? "Encore !" : "Again!", systemImage: "arrow.right")
                }
                .buttonStyle(KidButtonStyle())
            }
            .disabled(speaking)
            .padding(.top, 8)
        }
    }

    // MARK: Le jeu

    /// Une page : l'image de la phrase, le train plein ; la voix la lit ; puis « À toi ! ».
    private func startPage() async {
        guard let sentence else { return }
        voice.stop()
        step = .look
        hint = nil
        playStart = nil
        bravoGiven = false
        slots = sentence.cards.map { Optional($0) }
        await readModel()
    }

    private func readModel() async {
        guard let sentence, step == .look, !speaking else { return }
        speaking = true
        await say(fr ? "Écoute !" : "Listen!")
        for (k, card) in sentence.cards.enumerated() {
            litSlot = k
            await say(PhraseGrammar.chunk(card, locale: locale))
        }
        litSlot = nil
        speaking = false
        guard step == .look else { return }
        try? await Task.sleep(nanoseconds: 400_000_000)
        // À toi : le train se vide, on reconstruit la phrase wagon par wagon.
        slots = Array(repeating: nil, count: sentence.cards.count)
        step = .build
        await say(fr ? "À toi !" : "Your turn!")
        await ask()
    }

    /// La voix pose la question du wagon à remplir (l'enfant peut choisir sans attendre la fin).
    private func ask() async {
        guard let k = editing else { return }
        await say(PhrasePrompts.question(for: roles[k], cards: slots.compactMap { $0 }, locale: locale), blocking: false)
    }

    private func choose(_ card: PhraseCard, in sentence: SoundBookSentence) {
        guard !speaking, let k = editing, sentence.cards.indices.contains(k) else { return }
        voice.stop()
        speaking = true                                // plus rien ne se touche jusqu'à la fin de la voix
        let right = sentence.cards[k]
        if card == right {
            hint = nil
            slots[k] = card
            SoundBoard.shared.play(.pop)
            Task {
                litSlot = k
                await say(PhraseGrammar.chunk(card, locale: locale))
                litSlot = nil
                speaking = false
                if editing == nil {
                    step = .done
                    await playSentence(sentence)
                } else {
                    await ask()
                }
            }
        } else {
            // Jamais « non » : on nomme ce qu'il a touché, la bonne carte s'éclaire, on redemande.
            Task {
                await say(EarGames.thatIs(PhraseGrammar.chunk(card, locale: locale), locale: locale))
                speaking = false
                hint = right
                await ask()
            }
        }
    }

    /// Toucher un wagon accroché : il redit son morceau.
    private func touchWagon(_ k: Int) {
        guard !speaking, slots.indices.contains(k), let card = slots[k] else { return }
        Task {
            litSlot = k
            await say(PhraseGrammar.chunk(card, locale: locale))
            litSlot = nil
        }
    }

    /// La phrase : morceau par morceau (chaque wagon s'allume), puis la scène la joue pendant que la
    /// voix la dit d'une traite.
    private func playSentence(_ sentence: SoundBookSentence) async {
        guard !speaking else { return }
        speaking = true
        for (k, card) in sentence.cards.enumerated() {
            litSlot = k
            await say(PhraseGrammar.chunk(card, locale: locale))
        }
        litSlot = nil
        let scene = SentenceScene(cards: sentence.cards)
        let start = Date()
        playStart = start
        SoundBoard.shared.play(.whistle)
        for (time, cue) in SentenceStage.cues(of: scene) {
            guard let effect = SceneSounds.effect(cue, subject: scene.subject) else { continue }
            Task {
                try? await Task.sleep(nanoseconds: UInt64(max(0, time) * 1_000_000_000))
                if playStart == start { SoundBoard.shared.play(effect) }
            }
        }
        await say(sentence.text)
        let left = SentenceStage.duration(of: scene) - Date().timeIntervalSince(start)
        if left > 0 { try? await Task.sleep(nanoseconds: UInt64(left * 1_000_000_000)) }
        speaking = false
    }

    private func nextSentence() {
        guard !speaking, !sentences.isEmpty else { return }
        index = (index + 1) % sentences.count
        UserDefaults.standard.set(index, forKey: cursorKey)
        Task { await startPage() }
    }

    /// Juge adulte : l'enfant a redit la phrase. Des dings (un par wagon), des étoiles de jeu.
    private func bravo() {
        guard !bravoGiven else { return }
        bravoGiven = true
        let earned = min(Stars.max, roles.count)
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

    /// La voix du jeu. `blocking` : pendant ce qu'elle dit, on ne touche à rien ; une simple
    /// question, elle, peut être interrompue par un choix.
    private func say(_ text: String, blocking: Bool = true) async {
        let wasSpeaking = speaking
        if blocking { speaking = true }
        voice.voiceIdentifier = voiceId
        await voice.speak(text, locale: locale, pace: .sentence)
        if blocking { speaking = wasSpeaking }
    }
}
#endif
