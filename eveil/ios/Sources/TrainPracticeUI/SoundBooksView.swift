// SoundBooksView.swift — la bibliothèque des sons : un livre par son.
//
// Demande de l'utilisateur (28/09/2026) : « au niveau d'OrthoPicto, voire plus ». OrthoPicto a un
// livre par son ; ici chaque livre est calculé à partir des mots dessinés qui contiennent le son
// (`SoundBooks`, généré par eveil/outils/livres). On choisit un livre sur l'étagère, et le petit
// train le parcourt mot après mot : la voix dit le mot syllabe par syllabe, le wagon du son porte
// une étoile et ses lettres sont colorées ; toucher un wagon redit sa syllabe ; l'adulte touche
// « Il l'a dit ! » (le détecteur ne juge que la fin des mots en « ch » ou « s ») ; décompte,
// étoiles, mondes et bestioles comme dans le petit train. Chaque livre reprend où on l'a laissé.
// « Pour les grands » : l'image sonore du son et une idée de jeu hors écran (propositions à
// valider par des orthophonistes).

#if canImport(SwiftUI) && canImport(SwiftData) && canImport(AVFoundation) && canImport(Observation)
import EveilDesign
import PhraseCore
import SwiftData
import SwiftUI
import WordEndCore

@MainActor
public struct SoundBooksView: View {
    public let locale: String
    public let parentButtonHidden: Bool
    public let onHome: (() -> Void)?

    @State private var open: SoundBook?
    @State private var tips: SoundBook?
    @Environment(\.modelContext) private var context

    public init(locale: String, parentButtonHidden: Bool = false, onHome: (() -> Void)? = nil) {
        self.locale = locale
        self.parentButtonHidden = parentButtonHidden
        self.onHome = onHome
    }

    private var fr: Bool { locale.hasPrefix("fr") }
    private var books: [SoundBook] { SoundBooks.books(locale: locale) }

    public var body: some View {
        GeometryReader { geo in
            let columns = geo.size.width > geo.size.height ? 6 : 4
            let side = min(170, (geo.size.width - 60 - CGFloat(columns - 1) * 18) / CGFloat(columns))
            ZStack {
                SceneryView()
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        if let onHome {
                            Button(action: onHome) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 64, height: 64)
                                    .background(Circle().fill(EveilPalette.ink.opacity(0.35)))
                            }
                            .accessibilityLabel(fr ? "Retour à l'accueil" : "Back home")
                        }
                        Text(fr ? "Les livres des sons" : "The sound books")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(EveilPalette.ink)
                        Spacer()
                    }
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(side), spacing: 18), count: columns),
                                  spacing: 22) {
                            ForEach(books) { book in
                                BookCover(book: book, side: side, locale: locale,
                                          onOpen: { open = book }, onTips: { tips = book })
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 16)
            }
        }
        .fullScreen(item: $open) { book in
            PracticeView(words: book.words.map(Self.targetWord), locale: book.locale, cabooseSounds: [:],
                         parentButtonHidden: parentButtonHidden, onHome: { open = nil }, judge: .adult,
                         targets: Dictionary(book.words.map {
                             ($0.drawing, WordTarget(wagon: $0.targetWagon, letters: $0.letters))
                         }, uniquingKeysWith: { first, _ in first }),
                         title: SoundBooks.title(book), cursorKey: "eveil.book.\(book.id)")
                .modelContext(context)
        }
        .sheet(item: $tips) { book in
            BookTips(book: book, locale: locale)
        }
    }

    /// Un mot de livre pour le petit train : l'identifiant est son dessin.
    static func targetWord(_ w: SoundBookWord) -> TargetWord {
        .bookWord(id: w.drawing, text: w.text, ipa: w.ipa, wagons: w.wagons)
    }
}

private extension View {
    /// Plein écran sur iPad ; en feuille ailleurs (macOS n'a pas `fullScreenCover`, `swift test`).
    @ViewBuilder
    func fullScreen<Item: Identifiable, Content: View>(
        item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

/// La couverture d'un livre : sa lettre, trois de ses images, et « pour les grands ».
struct BookCover: View {
    let book: SoundBook
    let side: CGFloat
    let locale: String
    let onOpen: () -> Void
    let onTips: () -> Void

    static let colors: [Color] = [
        Color(red: 0.89, green: 0.2, blue: 0.24), Color(red: 1.0, green: 0.55, blue: 0.1),
        Color(red: 0.13, green: 0.62, blue: 0.47), Color(red: 0.22, green: 0.36, blue: 0.85),
        Color(red: 0.58, green: 0.34, blue: 0.86), Color(red: 0.9, green: 0.3, blue: 0.6),
        Color(red: 0.16, green: 0.55, blue: 0.78), Color(red: 0.55, green: 0.35, blue: 0.2),
    ]

    private var color: Color {
        let k = book.sound.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.colors[k % Self.colors.count]
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 6) {
                Text(book.label)
                    .font(.system(size: side * 0.34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                HStack(spacing: 2) {
                    ForEach(Array(book.words.prefix(3).enumerated()), id: \.offset) { _, w in
                        PictoView(id: w.drawing, size: side * 0.27)
                            .background(Circle().fill(.white.opacity(0.9)))
                    }
                }
                Text("\(book.words.count) " + (locale.hasPrefix("fr") ? "mots" : "words"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: side, height: side * 1.25)
            .background(
                RoundedRectangle(cornerRadius: side * 0.1, style: .continuous).fill(color.gradient)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(.black.opacity(0.15)).frame(width: side * 0.08)   // le dos du livre
                    }
                    .clipShape(RoundedRectangle(cornerRadius: side * 0.1, style: .continuous))
                    .shadow(color: color.opacity(0.4), radius: 8, y: 5)
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button(action: onTips) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white, EveilPalette.ink.opacity(0.5))
                    .padding(6)
            }
            .accessibilityLabel(locale.hasPrefix("fr") ? "Pour les grands" : "For grown-ups")
        }
        .accessibilityLabel(SoundBooks.title(book))
    }
}

/// « Pour les grands » : l'image sonore du son et une idée de jeu hors écran.
struct BookTips: View {
    let book: SoundBook
    let locale: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let fr = locale.hasPrefix("fr")
        NavigationStack {
            Form {
                Section(fr ? "Le son" : "The sound") { Text(book.image) }
                Section(fr ? "Une idée de jeu, sans écran" : "A screen-free game idea") { Text(book.game) }
                Section {
                    Text(fr ? "Des images sonores et des jeux : des propositions, à valider par des orthophonistes. Ce jeu n'évalue pas le langage de votre enfant ; en cas de doute, parlez-en à votre médecin ou à un orthophoniste."
                            : "Sound pictures and games: proposals, to be validated by speech-language pathologists. This game does not assess your child's speech; if in doubt, talk to your doctor or a speech-language pathologist.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(SoundBooks.title(book))
            .toolbar { Button(fr ? "Fermer" : "Close") { dismiss() } }
        }
    }
}
#endif
