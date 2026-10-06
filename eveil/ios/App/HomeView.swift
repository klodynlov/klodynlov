// HomeView.swift — l'accueil de la suite : le chat chef de gare propose ses jeux.
//
// De grandes cartes (le Petit Train des mots, le Train des phrases, les Livres des sons,
// l'Atelier de coloriage, les Jeux d'écoute), un seul geste pour entrer, une maison pour revenir. L'espace des grands
// reste derrière le contrôle parental (et disparaît pendant l'Accès guidé).

import EveilDesign
import SwiftData
import SwiftUI
import ColoringUI
import TrainPracticeUI
import WordEndCore

struct HomeView: View {
    let parentAreaLocked: Bool
    @AppStorage("eveil.language") private var language = "fr-FR"
    @AppStorage(Stars.settingKey) private var starsOn = true
    @AppStorage(Stars.totalKey) private var starsTotal = 0
    @State private var destination: Destination?
    /// La séance du petit train, calculée UNE fois en entrant (le niveau ne change pas en cours de séance).
    @State private var trainSession: TrainSession?
    @State private var showGate = false
    @State private var showParentZone = false
    @Environment(\.modelContext) private var context

    enum Destination: String, Identifiable, CaseIterable {
        case train, sentences, books, coloring, ears
        var id: String { rawValue }
    }

    struct TrainSession {
        let lexicon: Lexicon
        let level: Int
        let deck: [TargetWord]
    }

    private var locale: String { language == "en-US" ? "en-US" : "fr-FR" }

    /// Entrer dans le petit train : le niveau gagné à la séance précédente s'ouvre maintenant
    /// (`TrainLevelStore.startSession`), puis les mots de ce niveau.
    private func openTrain() {
        if let lexicon = LexiconLoader.load(locale) {
            let level = TrainLevelStore.startSession(lexicon.words, locale: lexicon.locale)
            trainSession = TrainSession(lexicon: lexicon, level: level,
                                        deck: WordDeck.deck(lexicon.words, level: level))
        } else {
            trainSession = nil
        }
        destination = .train
    }
    private var fr: Bool { locale.hasPrefix("fr") }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            ZStack {
                SceneryView()
                // Les jeux sur deux rangées en paysage, deux colonnes en portrait.
                let columns = wide ? (Destination.allCases.count + 1) / 2 : 2
                let rows = (Destination.allCases.count + columns - 1) / columns
                let cardWidth = min(wide ? 360 : 380, (geo.size.width - 80 - CGFloat(columns - 1) * 22) / CGFloat(columns))
                let cardHeight = min(wide ? 250 : 240, (geo.size.height - (wide ? 230 : 300)) / CGFloat(rows) - 20)
                VStack(spacing: wide ? 18 : 26) {
                    Spacer(minLength: 16)
                    HStack(alignment: .center, spacing: 8) {
                        CatStationMaster(mood: .hello, size: wide ? 150 : 200)
                        SpeechBubble(fr ? "Bonjour ! À quoi on joue ?" : "Hello! What shall we play?")
                    }
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 22) {
                            ForEach(Array(Destination.allCases.enumerated()).filter { $0.offset / columns == row },
                                    id: \.offset) { _, game in
                                card(game, width: cardWidth, height: cardHeight)
                            }
                        }
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 40)
                VStack {
                    HStack {
                        // Le trésor d'étoiles gagnées au petit train (un total, rien d'autre).
                        if starsOn && starsTotal > 0 {
                            StarCounter(count: starsTotal)
                        }
                        Spacer()
                        if !parentAreaLocked {
                            Button { showGate = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(EveilPalette.ink.opacity(0.55))
                                    .frame(width: 56, height: 56)
                            }
                            .accessibilityLabel(fr ? "Espace des grands" : "Grown-ups area")
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
            }
        }
        .fullScreenCover(item: $destination) { dest in
            switch dest {
            case .train:
                if let session = trainSession, !session.deck.isEmpty {
                    let locale = session.lexicon.locale
                    PracticeView(words: session.deck,
                                 locale: locale,
                                 cabooseSounds: session.lexicon.cabooseSounds,
                                 parentButtonHidden: parentAreaLocked,
                                 onHome: { destination = nil },
                                 cursorKey: WordDeck.cursorKey(level: session.level),
                                 onWordSaid: { TrainLevelStore.recordSaid($0, locale: locale) })
                        .modelContext(context)
                } else {
                    Text("Lexique introuvable dans le paquet de l'app.")
                }
            case .sentences:
                SentenceTrainView(locale: locale, parentButtonHidden: parentAreaLocked,
                                  onHome: { destination = nil })
            case .books:
                SoundBooksView(locale: locale, parentButtonHidden: parentAreaLocked, onHome: { destination = nil })
                    .modelContext(context)
            case .coloring:
                ColoringView(locale: locale, onHome: { destination = nil })
            case .ears:
                EarGamesView(locale: locale, parentButtonHidden: parentAreaLocked, onHome: { destination = nil })
            }
        }
        .sheet(isPresented: $showGate) {
            ParentGateView(locale: locale,
                           onPassed: { showGate = false; showParentZone = true },
                           onCancel: { showGate = false })
        }
        .sheet(isPresented: $showParentZone) { ParentZoneView(locale: locale) }
    }
}

extension HomeView {
    /// La carte d'un jeu : titre, couleur, illustration.
    @ViewBuilder
    func card(_ game: Destination, width: CGFloat, height: CGFloat) -> some View {
        switch game {
        case .train:
            GameCard(title: fr ? "Le petit train des mots" : "The little word train",
                     color: EveilPalette.loco, width: width, height: height) { openTrain() } art: {
                TrainView(wagons: ["mi", "nou"], lit: [true, true], cabooseLabel: "ch", caboose: .hooked, scale: 0.5)
            }
        case .sentences:
            GameCard(title: fr ? "Le train des phrases" : "The sentence train",
                     color: EveilPalette.go, width: width, height: height) { destination = .sentences } art: {
                SentenceArt()
            }
        case .books:
            GameCard(title: fr ? "Les livres des sons" : "The sound books",
                     color: Color(red: 0.86, green: 0.16, blue: 0.3), width: width, height: height) {
                destination = .books
            } art: {
                BooksArt(locale: locale)
            }
        case .coloring:
            GameCard(title: fr ? "L'atelier de coloriage" : "The coloring workshop",
                     color: Color.purple, width: width, height: height) { destination = .coloring } art: {
                ColoringArt()
            }
        case .ears:
            GameCard(title: fr ? "Les jeux d'écoute" : "Listening games",
                     color: Color(red: 0.16, green: 0.55, blue: 0.78), width: width, height: height) {
                destination = .ears
            } art: {
                EarArt()
            }
        }
    }
}

/// Petite illustration des livres des sons : trois livres debout, « ch », « s », « r ».
struct BooksArt: View {
    let locale: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(zip(locale.hasPrefix("fr") ? ["ch", "s", "r"] : ["sh", "s", "r"],
                              [Color.orange, Color.yellow, Color.green]).enumerated()), id: \.offset) { k, item in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(item.1.gradient)
                    .frame(width: 70, height: CGFloat(110 + 14 * (k % 2)))
                    .overlay(Text(item.0).font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(.white))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            }
        }
    }
}

/// Une grande carte de jeu : une illustration, un titre, toute la carte est touchable.
struct GameCard<Art: View>: View {
    let title: String
    let color: Color
    var width: CGFloat = 440
    var height: CGFloat = 320
    let action: () -> Void
    @ViewBuilder let art: () -> Art

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                art()
                    .frame(height: height * 0.52)
                Text(title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
            }
            .padding(22)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.45), radius: 16, y: 10)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// Petite illustration du train des phrases : qui (le chat), fait quoi (mange), quoi (la pêche).
struct SentenceArt: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(zip(["fr.minouche", "verbe.manger", "fr.peche"],
                              [Color(red: 1.0, green: 0.8, blue: 0.2), Color(red: 0.42, green: 0.8, blue: 0.37),
                               Color(red: 1.0, green: 0.6, blue: 0.26)]).enumerated()), id: \.offset) { _, item in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(item.1)
                    .frame(width: 96, height: 96)
                    .overlay(PictoView(id: item.0, size: 84))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
        }
    }
}

/// Petite illustration des jeux d'écoute : une oreille, et la vache qui meugle.
struct EarArt: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "ear.fill")
                .font(.system(size: 90))
                .foregroundStyle(.white)
            Image(systemName: "music.note")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.yellow)
            PictoView(id: "fr.vache", size: 120)
        }
    }
}

/// Petite illustration de l'atelier : une palette et trois crayons.
struct ColoringArt: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 110))
                .foregroundStyle(.white, .yellow)
            VStack(spacing: 10) {
                ForEach([Color.red, .blue, .green], id: \.self) { c in
                    Capsule().fill(c).frame(width: 90, height: 22)
                        .overlay(alignment: .trailing) {
                            Triangle().fill(Color(red: 0.95, green: 0.85, blue: 0.65)).frame(width: 18, height: 22).offset(x: 14)
                        }
                }
            }
        }
    }
}

struct Triangle: SwiftUI.Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.closeSubpath()
        return p
    }
}
