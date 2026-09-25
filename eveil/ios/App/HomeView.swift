// HomeView.swift — l'accueil de la suite : le chat chef de gare propose deux jeux.
//
// Deux grandes cartes (le Petit Train des mots, l'Atelier de coloriage), un seul
// geste pour entrer, une maison pour revenir. L'espace des grands reste derrière
// le contrôle parental (et disparaît pendant l'Accès guidé).

import EveilDesign
import SwiftData
import SwiftUI
import ColoringUI
import TrainPracticeUI
import WordEndCore

struct HomeView: View {
    let parentAreaLocked: Bool
    @AppStorage("eveil.language") private var language = "fr-FR"
    @AppStorage(WordDeck.maxLevelKey) private var maxLevel = 3
    @State private var destination: Destination?
    @State private var showGate = false
    @State private var showParentZone = false
    @Environment(\.modelContext) private var context

    enum Destination: String, Identifiable {
        case train, coloring
        var id: String { rawValue }
    }

    private var locale: String { language == "en-US" ? "en-US" : "fr-FR" }
    private var fr: Bool { locale.hasPrefix("fr") }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            ZStack {
                SceneryView()
                VStack(spacing: wide ? 36 : 48) {
                    Spacer(minLength: 40)
                    HStack(alignment: .center, spacing: 8) {
                        CatStationMaster(mood: .hello, size: wide ? 230 : 250)
                        SpeechBubble(fr ? "Bonjour ! À quoi on joue ?" : "Hello! What shall we play?")
                    }
                    let cards = Group {
                        GameCard(title: fr ? "Le petit train des mots" : "The little word train",
                                 color: EveilPalette.loco) { destination = .train } art: {
                            TrainView(wagons: ["mi", "nou"], lit: [true, true], cabooseLabel: "ch",
                                      caboose: .hooked, scale: 0.62)
                        }
                        GameCard(title: fr ? "L'atelier de coloriage" : "The coloring workshop",
                                 color: Color.purple) { destination = .coloring } art: {
                            ColoringArt()
                        }
                    }
                    if wide {
                        HStack(spacing: 44) { cards }
                    } else {
                        VStack(spacing: 36) { cards }
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 40)
                if !parentAreaLocked {
                    VStack {
                        HStack {
                            Spacer()
                            Button { showGate = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(EveilPalette.ink.opacity(0.55))
                                    .frame(width: 56, height: 56)
                            }
                            .accessibilityLabel(fr ? "Espace des grands" : "Grown-ups area")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                }
            }
        }
        .fullScreenCover(item: $destination) { dest in
            switch dest {
            case .train:
                if let lexicon = LexiconLoader.load(locale),
                   case let deck = WordDeck.ordered(lexicon.words, maxLevel: maxLevel), !deck.isEmpty {
                    PracticeView(words: deck,
                                 locale: lexicon.locale,
                                 cabooseSounds: lexicon.cabooseSounds,
                                 parentButtonHidden: parentAreaLocked,
                                 onHome: { destination = nil })
                        .modelContext(context)
                } else {
                    Text("Lexique introuvable dans le paquet de l'app.")
                }
            case .coloring:
                ColoringView(locale: locale, onHome: { destination = nil })
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

/// Une grande carte de jeu : une illustration, un titre, toute la carte est touchable.
struct GameCard<Art: View>: View {
    let title: String
    let color: Color
    let action: () -> Void
    @ViewBuilder let art: () -> Art

    var body: some View {
        Button(action: action) {
            VStack(spacing: 18) {
                art()
                    .frame(height: 170)
                Text(title)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .padding(28)
            .frame(width: 440, height: 320)
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
