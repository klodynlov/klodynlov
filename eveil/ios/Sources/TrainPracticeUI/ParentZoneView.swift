// ParentZoneView.swift — l'espace parent (derrière le contrôle parental).
//
// On y règle : la langue (FR, EN, ou les deux en alternance pour les familles
// bilingues), le temps d'écran quotidien, les mots de la famille. On y trouve :
// comment jouer AVEC l'enfant, et quand demander l'avis d'un professionnel.
// On n'y trouve PAS de score de langage : l'app est un jeu d'éveil, pas un bilan.

#if canImport(SwiftUI)
import SwiftUI
import WordEndCore

public struct ParentZoneView: View {
    public let locale: String
    @AppStorage("eveil.language") private var language = "fr-FR"      // fr-FR | en-US | both
    @AppStorage("eveil.dailyMinutes") private var dailyMinutes = 15.0
    @AppStorage("eveil.lexicalCheck") private var lexicalCheck = false  // expérimental, OFF
    @State private var familyText = ""
    @State private var familyWagons = ""
    @State private var familyCoda = "S"
    @State private var familyError: String?
    @Environment(\.dismiss) private var dismiss

    public init(locale: String) { self.locale = locale }
    private var fr: Bool { locale.hasPrefix("fr") }

    public var body: some View {
        NavigationStack {
            Form {
                Section(fr ? "Langue du jeu" : "Game language") {
                    Picker(fr ? "Langue" : "Language", selection: $language) {
                        Text("Français").tag("fr-FR")
                        Text("English").tag("en-US")
                        Text(fr ? "Les deux (alterner)" : "Both (alternate)").tag("both")
                    }
                    .pickerStyle(.segmented)
                }
                Section(fr ? "Temps d'écran" : "Screen time") {
                    Stepper(value: $dailyMinutes, in: 5...30, step: 5) {
                        Text(fr ? "Par jour : \(Int(dailyMinutes)) min" : "Per day: \(Int(dailyMinutes)) min")
                    }
                    Text(fr ? "Des séances courtes et fréquentes valent mieux qu'une longue."
                            : "Short, frequent sessions work better than a long one.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section(fr ? "Les mots de la famille" : "Family words") {
                    TextField(fr ? "Le mot (ex. Minouche)" : "The word (e.g. Moose)", text: $familyText)
                    TextField(fr ? "Les wagons, séparés par un tiret (ex. mi-nou)" : "Wagons, with dashes (e.g. moo)",
                              text: $familyWagons)
                    Picker(fr ? "Le son du fourgon" : "Caboose sound", selection: $familyCoda) {
                        Text(fr ? "« ch »" : "\"sh\"").tag("S")
                        Text("« s »").tag("s")
                    }
                    Button(fr ? "Ajouter" : "Add") { addFamilyWord() }
                    if let familyError { Text(familyError).foregroundStyle(.red) }
                    Text(fr ? "Ces mots restent sur cet iPad." : "These words stay on this iPad.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section(fr ? "Jouer ensemble" : "Playing together") {
                    Text(fr ? "Asseyez-vous à côté de votre enfant. Laissez le train dire le mot, puis encouragez sans répéter le mot pendant l'écoute. Si le fourgon reste en gare, dites-le vous-même en exagérant la fin (« dou-chhh »), sans demander de répéter plus de deux fois."
                            : "Sit next to your child. Let the train say the word, then cheer without saying the word during listening. If the caboose stays behind, say it yourself, stretching the end (\"fi-shhh\"), and never ask for more than two repeats.")
                }
                Section(fr ? "Quand demander un avis ?" : "When to ask for advice?") {
                    Text(fr ? "Ce jeu n'évalue pas le langage de votre enfant. Si vous avez un doute sur sa façon de parler ou d'être compris, parlez-en à votre médecin ou à un orthophoniste."
                            : "This game does not assess your child's speech. If you have concerns about how your child speaks or is understood, talk to your doctor or a speech-language pathologist.")
                }
                Section(fr ? "Réglages avancés" : "Advanced") {
                    Toggle(fr ? "Vérifier le mot avec la reconnaissance vocale de l'iPad (expérimental)"
                              : "Check the word with the iPad's speech recognition (experimental)",
                           isOn: $lexicalCheck)
                    Text(fr ? "Traitement sur l'iPad uniquement. Peut seulement rendre le jeu plus prudent."
                            : "On-device only. Can only make the game more cautious.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text(fr ? "Accès guidé : triple-clic sur le bouton latéral pour verrouiller l'iPad sur le jeu."
                            : "Guided Access: triple-click the side button to lock the iPad to the game.")
                        .font(.footnote)
                }
            }
            .navigationTitle(fr ? "Espace des grands" : "Grown-ups")
            .toolbar { Button(fr ? "Fermer" : "Close") { dismiss() } }
        }
    }

    private func addFamilyWord() {
        do {
            let wagons = familyWagons.split(separator: "-").map(String.init)
            _ = try customWord(text: familyText, wagons: wagons, coda: familyCoda, locale: locale)
            // TODO(persistance) : enregistrer le mot (SwiftData) et l'ajouter à la liste de jeu.
            familyText = ""
            familyWagons = ""
            familyError = nil
        } catch {
            familyError = fr ? "Vérifiez le mot et ses wagons (1 à 4)." : "Check the word and its wagons (1 to 4)."
        }
    }
}
#endif
