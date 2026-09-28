// ParentZoneView.swift — l'espace parent (derrière le contrôle parental).
//
// On y règle : la langue (FR, EN, ou les deux en alternance pour les familles
// bilingues), la voix du modèle (la meilleure voix féminine installée, ou une autre ;
// syllabe par syllabe ou non) et le nombre de répétitions par mot (le décompte), le
// micro (accès, test, essai par un adulte), les mots du train (jusqu'à quel niveau),
// le coloriage (remplir d'un toucher, ou pinceau seul), le temps d'écran quotidien,
// les mots de la famille. On
// y trouve : comment jouer AVEC l'enfant, et quand demander l'avis d'un professionnel.
// On n'y trouve PAS de score de langage : l'app est un jeu d'éveil, pas un bilan.

#if canImport(SwiftUI) && canImport(AVFoundation)
import EveilDesign
import SwiftUI
import WordEndAudio
import WordEndCore

public struct ParentZoneView: View {
    public let locale: String
    @AppStorage("eveil.language") private var language = "fr-FR"      // fr-FR | en-US | both
    @AppStorage("eveil.dailyMinutes") private var dailyMinutes = 15.0
    @AppStorage("eveil.lexicalCheck") private var lexicalCheck = false  // expérimental, OFF
    @AppStorage("eveil.demoMode") private var demoMode = false          // présentation, sans micro
    @AppStorage(ListeningSettings.adultTrialKey) private var adultTrial = false
    @AppStorage(WordDeck.maxLevelKey) private var maxLevel = 3
    @AppStorage(SuiteSettings.tapToFillKey) private var tapToFill = SuiteSettings.tapToFillDefault
    @AppStorage(VoiceCatalog.settingKey) private var voiceId = ""
    @AppStorage(ListeningSettings.syllableModelKey) private var syllableModel = true
    @AppStorage(Repetitions.settingKey) private var repetitions = Repetitions.defaultCount
    @AppStorage(Stars.settingKey) private var starsOn = true
    @AppStorage(Stars.totalKey) private var starsTotal = 0
    @State private var voices: [VoiceOption] = []
    @State private var canAskPersonalVoice = false
    @State private var voicePlayer = ModelVoicePlayer()
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
                voiceSection
                Section {
                    NavigationLink {
                        MicTestView(locale: locale)
                    } label: {
                        Label(fr ? "Tester le micro" : "Test the microphone", systemImage: "mic.fill")
                    }
                    Toggle(fr ? "Essai par un adulte (voix grave acceptée)" : "Adult trial (deep voices accepted)",
                           isOn: $adultTrial)
                } header: {
                    Text(fr ? "Micro" : "Microphone")
                } footer: {
                    Text(fr ? "Le train écarte exprès les voix graves d'adulte, pour ne pas prendre votre modèle pour la réponse de l'enfant. Pour essayer le jeu vous-même, activez « Essai par un adulte », puis coupez-le avant de laisser jouer l'enfant."
                            : "The train deliberately ignores deep adult voices, so your model is never taken for the child's answer. To try the game yourself, turn on \"Adult trial\", then turn it off before your child plays.")
                }
                Section {
                    Picker(fr ? "Mots du train" : "Train words", selection: $maxLevel) {
                        Text(fr ? "1 syllabe" : "1 syllable").tag(1)
                        Text(fr ? "+ 2 syllabes" : "+ 2 syllables").tag(2)
                        Text(fr ? "Tous" : "All").tag(3)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(fr ? "Mots du train" : "Train words")
                } footer: {
                    Text(fr ? "« Tous » ajoute les mots à groupe de consonnes (cloche, glace, brosse…). Les listes sont des propositions, à valider par des orthophonistes."
                            : "\"All\" adds words with consonant clusters (splash, brush…). The lists are proposals, to be validated by speech-language pathologists.")
                }
                Section {
                    Toggle(fr ? "Remplir d'un toucher" : "Tap to fill", isOn: $tapToFill)
                } header: {
                    Text(fr ? "Atelier de coloriage" : "Coloring workshop")
                } footer: {
                    Text(fr ? "Activé : toucher une zone la remplit d'un coup. Désactivé : l'enfant colorie au pinceau, qui ne déborde jamais de sa zone — plus de mouvements de la main, c'est tout l'intérêt du coloriage."
                            : "On: tapping an area fills it at once. Off: the child colors with the brush, which never leaves its area — more hand movement, which is the whole point of coloring.")
                }
                Section(fr ? "Présentation" : "Showcase") {
                    Toggle(fr ? "Mode démo (sans micro)" : "Demo mode (no microphone)", isOn: $demoMode)
                    Text(fr ? "Pour montrer le jeu : le micro reste fermé, et une barre fait « parler » le train avec une voix synthétique. Ce n'est pas une mesure de votre enfant."
                            : "To show the game: the microphone stays off, and a bar makes the train \"hear\" a synthetic voice. It does not measure your child.")
                        .font(.footnote).foregroundStyle(.secondary)
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
            .onAppear { refreshVoices() }
            .onDisappear { voicePlayer.stop() }
        }
    }

    /// La voix du modèle, le modèle syllabe par syllabe, le décompte des répétitions.
    private var voiceSection: some View {
        Section {
            Picker(fr ? "Voix" : "Voice", selection: $voiceId) {
                Text(automaticLabel).tag("")
                ForEach(voices) { v in
                    Text(voiceLabel(v)).tag(v.id)
                }
            }
            Button {
                Task {
                    voicePlayer.voiceIdentifier = voiceId
                    await voicePlayer.speak(fr ? "Bonjour ! Je suis la voix du petit train. Mi… nou… minouche !"
                                               : "Hello! I am the voice of the little train. Fi… fish!",
                                            locale: locale, pace: .sentence)
                }
            } label: {
                Label(fr ? "Écouter la voix" : "Listen to the voice", systemImage: "speaker.wave.2.fill")
            }
            if canAskPersonalVoice {
                Button {
                    Task {
                        _ = await VoiceCatalog.requestPersonalVoice()
                        refreshVoices()
                    }
                } label: {
                    Label(fr ? "Utiliser ma Voix personnelle" : "Use my Personal Voice", systemImage: "person.wave.2.fill")
                }
            }
            Toggle(fr ? "Le mot modèle syllabe par syllabe" : "Model word syllable by syllable", isOn: $syllableModel)
            Stepper(value: $repetitions, in: Repetitions.range) {
                Text(fr ? "Répétitions par mot : \(repetitions)" : "Repeats per word: \(repetitions)")
            }
            Toggle(fr ? "Étoiles à gagner (trésor : \(starsTotal))" : "Stars to earn (treasure: \(starsTotal))",
                   isOn: $starsOn)
            if starsTotal > 0 {
                Button(fr ? "Vider le trésor d'étoiles" : "Empty the star treasure", role: .destructive) {
                    starsTotal = 0
                }
            }
        } header: {
            Text(fr ? "Voix et répétitions" : "Voice and repeats")
        } footer: {
            Text(fr ? "Le jeu prend la meilleure voix féminine installée. Pour une voix plus naturelle, téléchargez une voix « Premium » ou « améliorée » : Réglages › Accessibilité › Contenu énoncé › Voix › Français. Syllabe par syllabe : chaque wagon s'allume avec sa syllabe, puis la voix dit le mot entier. Le décompte montre à l'enfant combien de fois il redit le mot ; seul un mot bien dit le fait avancer, et le train repart de toute façon après trois essais. Les étoiles récompensent l'essai et, davantage, le mot entier (3 étoiles) ; on n'en perd jamais. Ce ne sont pas des notes : elles ne mesurent pas le langage de votre enfant, et restent sur cet iPad."
                    : "The game picks the best female voice installed. For a more natural voice, download a \"Premium\" or \"Enhanced\" voice: Settings › Accessibility › Spoken Content › Voices › English. Syllable by syllable: each wagon lights up with its syllable, then the voice says the whole word. The countdown shows how many times your child says the word; only a well-said word moves it forward, and the train leaves anyway after three tries. Stars reward trying and, even more, the whole word (3 stars); they are never lost. They are not grades: they do not measure your child's speech, and they stay on this iPad.")
        }
    }

    private var automaticLabel: String {
        let best = VoiceCatalog.automaticChoice(voices, locale: locale)
        let name = best.map(voiceLabel) ?? (fr ? "voix du système" : "system voice")
        return fr ? "Automatique : \(name)" : "Automatic: \(name)"
    }

    private func voiceLabel(_ v: VoiceOption) -> String {
        var parts = [v.name, v.quality.label(locale: locale)]
        if v.language != locale { parts.append(v.language) }
        if v.isPersonal { parts.append(fr ? "voix personnelle" : "personal voice") }
        return parts.joined(separator: " · ")
    }

    private func refreshVoices() {
        voices = VoiceCatalog.voices(for: locale).filter { !$0.isNovelty || $0.id == voiceId }
        canAskPersonalVoice = VoiceCatalog.canAskForPersonalVoice
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
