// MicTestView.swift — « Tester le micro », dans l'espace des grands.
//
// Né du premier essai sur iPad (25/09/2026 : « le micro doit être plus
// réceptif »). Un adulte choisit un mot, le dit, et voit : l'accès au micro,
// le niveau sonore en direct, le petit train qui s'allume, puis en clair ce que
// le détecteur a entendu et pourquoi il a pu rester prudent (`ListeningDiagnosis`).
// C'est aussi ici qu'on DEMANDE l'accès au micro, après une explication pour
// l'adulte — plutôt qu'en plein jeu, devant l'enfant.
//
// Rien n'est enregistré : le son est analysé en mémoire, puis oublié.

#if canImport(SwiftUI) && canImport(AVFoundation) && canImport(Observation)
import AVFoundation
import EveilDesign
import SwiftUI
import WordEndAudio
import WordEndCore
#if os(iOS)
import UIKit
#endif

public struct MicTestView: View {
    public let locale: String

    @AppStorage(ListeningSettings.adultTrialKey) private var adultTrial = false
    @State private var listener = ListeningController(stream: ListeningSettings.streamingConfig())
    @State private var words: [TargetWord] = []
    @State private var wordIndex = 0
    @State private var permission: AVAudioApplication.recordPermission = .undetermined
    @State private var diagnosis: ListeningDiagnosis?
    @State private var failure: String?
    @State private var run = 0
    @Environment(\.openURL) private var openURL

    public init(locale: String) { self.locale = locale }

    private var fr: Bool { locale.hasPrefix("fr") }
    private var listening: Bool { listener.phase == .listening }
    private var word: TargetWord? { words.indices.contains(wordIndex) ? words[wordIndex] : words.first }

    public var body: some View {
        Form {
            Section {
                permissionRow
            } header: {
                Text(fr ? "Accès au micro" : "Microphone access")
            } footer: {
                Text(fr ? "Le micro sert uniquement à entendre le mot, sur l'iPad. Aucun son n'est enregistré ni envoyé."
                        : "The microphone is only used to hear the word, on the iPad. No sound is recorded or sent.")
            }
            if let word {
                Section {
                    Picker(fr ? "Mot à dire" : "Word to say", selection: $wordIndex) {
                        ForEach(words.indices, id: \.self) { i in Text(words[i].text).tag(i) }
                    }
                    Toggle(fr ? "Essai par un adulte (voix grave acceptée)" : "Adult trial (deep voices accepted)",
                           isOn: $adultTrial)
                    Button(action: start) {
                        Label(listening ? (fr ? "J'écoute… dites « \(word.text) »" : "Listening… say \"\(word.text)\"")
                                        : (fr ? "Écouter" : "Listen"),
                              systemImage: listening ? "waveform" : "mic.fill")
                            .font(.headline)
                    }
                    .disabled(listening || permission == .denied)
                    LevelMeter(db: listener.inputLevelDb, active: listening, locale: locale)
                    TrainView(wagons: word.wagons, lit: lit(for: word), cabooseLabel: word.caboose,
                              caboose: caboose(for: word), scale: 0.5)
                        .id("\(word.id)-\(run)")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    if let diagnosis { DiagnosisCard(diagnosis: diagnosis) }
                    if let failure {
                        Text(failure).font(.callout).foregroundStyle(.red)
                    }
                } header: {
                    Text(fr ? "Essayer avec votre voix" : "Try it with your voice")
                } footer: {
                    Text(fr ? "Ce test vérifie que le micro et les réglages vous entendent ; ce n'est pas une évaluation. Pensez à couper « Essai par un adulte » avant de laisser jouer l'enfant."
                            : "This checks that the microphone and settings hear you; it is not an assessment. Turn \"Adult trial\" off before your child plays.")
                }
            }
        }
        .navigationTitle(fr ? "Tester le micro" : "Test the microphone")
        .onAppear {
            refreshPermission()
            if words.isEmpty { words = BundledLexicon.words(locale: locale) }
        }
        .onDisappear { listener.reset() }
        .onChange(of: listener.phase) { _, phase in
            switch phase {
            case let .finished(verdict):
                if let word { diagnosis = ListeningDiagnosis(verdict: verdict, word: word, locale: locale) }
            case let .failed(message):
                failure = (fr ? "Le micro n'a pas pu démarrer : " : "The microphone could not start: ") + message
            default:
                break
            }
        }
    }

    // MARK: Accès au micro

    @ViewBuilder private var permissionRow: some View {
        switch permission {
        case .granted:
            Label(fr ? "Autorisé" : "Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .denied:
            Label(fr ? "Refusé : le train ne peut pas entendre." : "Denied: the train cannot hear.",
                  systemImage: "mic.slash.fill").foregroundStyle(.red)
            #if os(iOS)
            Button(fr ? "Ouvrir les Réglages de l'iPad" : "Open iPad Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            #endif
        default:
            Label(fr ? "Pas encore demandé" : "Not asked yet", systemImage: "mic.badge.plus")
            Button(fr ? "Autoriser le micro" : "Allow the microphone") {
                Task {
                    _ = await ListeningController.requestMicrophone()
                    refreshPermission()
                }
            }
        }
    }

    private func refreshPermission() {
        permission = AVAudioApplication.shared.recordPermission
    }

    // MARK: Écoute

    private func start() {
        guard let word else { return }
        diagnosis = nil
        failure = nil
        run += 1
        listener.reset()
        listener.config = ListeningSettings.detectorConfig(adultTrial: adultTrial)
        listener.listen(for: word)
        refreshPermission()
    }

    private func lit(for word: TargetWord) -> [Bool] {
        if case let .finished(verdict) = listener.phase {
            return word.wagons.indices.map { $0 < verdict.heardNuclei }
        }
        return word.wagons.indices.map { $0 < listener.litWagons }
    }

    private func caboose(for word: TargetWord) -> CabooseState {
        guard word.coda != nil else { return .none }
        if case let .finished(verdict) = listener.phase {
            if verdict.kind == .complete { return .hooked }
            return verdict.kind == .missingFinalConsonant ? .pointed : .waiting
        }
        return listener.cabooseHeard ? .hooked : .waiting
    }
}

/// Vumètre : le niveau du micro en direct (vert, puis orange, rouge si ça sature).
struct LevelMeter: View {
    let db: Double
    let active: Bool
    let locale: String

    var body: some View {
        let fraction = active ? min(1, max(0, (db + 60) / 60)) : 0
        HStack(spacing: 12) {
            Image(systemName: "mic.fill").foregroundStyle(active ? .green : .secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.18))
                    Capsule().fill(db > -6 ? Color.red : (db > -20 ? Color.orange : Color.green))
                        .frame(width: geo.size.width * fraction)
                        .animation(.linear(duration: 0.08), value: fraction)
                }
            }
            .frame(height: 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(locale.hasPrefix("fr") ? "Niveau du micro" : "Microphone level")
        .accessibilityValue("\(Int(db.rounded())) dB")
    }
}

/// Le résultat du test, en clair.
struct DiagnosisCard: View {
    let diagnosis: ListeningDiagnosis

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(diagnosis.headline, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(color)
            ForEach(diagnosis.details, id: \.self) { Text($0).font(.callout) }
            ForEach(diagnosis.advice, id: \.self) { line in
                Label(line, systemImage: "lightbulb.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var symbol: String {
        switch diagnosis.tone {
        case .good: return "checkmark.seal.fill"
        case .neutral: return "info.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch diagnosis.tone {
        case .good: return .green
        case .neutral: return .blue
        case .caution: return .orange
        }
    }
}
#endif
