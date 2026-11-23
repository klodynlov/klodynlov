// ParentGateView.swift — contrôle parental (« parental gate ») de l'espace parent.
//
// App Store (catégorie Enfants, règles 1.3 et 5.1.4 — vérifiées) : liens,
// réglages et achats derrière une tâche d'adulte. Le contrôle parental ne VAUT
// PAS consentement parental. Pour un enfant qui ne lit pas encore, Apple
// recommande une invite vocale pour aller chercher un adulte.

#if canImport(SwiftUI)
import SwiftUI

public struct ParentGateView: View {
    public let locale: String
    public let onPassed: () -> Void
    public let onCancel: () -> Void

    @State private var a = Int.random(in: 6...9)
    @State private var b = Int.random(in: 6...9)
    @State private var choices: [Int] = []
    @State private var failed = false

    public init(locale: String, onPassed: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.locale = locale
        self.onPassed = onPassed
        self.onCancel = onCancel
    }

    private var fr: Bool { locale.hasPrefix("fr") }

    public var body: some View {
        VStack(spacing: 24) {
            Label(fr ? "Espace des grands" : "Grown-ups only", systemImage: "lock.fill")
                .font(.title.bold())
            Text(fr ? "Pour continuer, combien font \(a) × \(b) ?" : "To continue, what is \(a) × \(b)?")
                .font(.title2)
            HStack(spacing: 16) {
                ForEach(choices, id: \.self) { value in
                    Button("\(value)") { check(value) }
                        .font(.title.monospacedDigit())
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }
            if failed {
                Text(fr ? "Ce n'est pas ça — demande à un grand !" : "Not quite — ask a grown-up!")
                    .foregroundStyle(.secondary)
            }
            Button(fr ? "Retour au jeu" : "Back to the game", action: onCancel)
        }
        .padding(40)
        .onAppear(perform: shuffle)
    }

    private func shuffle() {
        let right = a * b
        let wrong = Set([right + b, right - a, right + 10, right - 1]).subtracting([right])
        choices = ([right] + wrong.shuffled().prefix(2)).shuffled()
    }

    private func check(_ value: Int) {
        if value == a * b {
            onPassed()
        } else {
            failed = true
            a = Int.random(in: 6...9)
            b = Int.random(in: 6...9)
            shuffle()
        }
    }
}
#endif
