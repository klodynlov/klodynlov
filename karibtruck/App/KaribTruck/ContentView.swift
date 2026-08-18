import SwiftUI
import KaribTruckCore

/// Écran principal (point de départ M0) : saisie rapide d'un relevé de
/// température (2 taps : enceinte + valeur), bandeau d'intégrité, et historique.
/// Volontairement minimal — les autres modules (checklists, réception, huile,
/// non-conformités, planning) suivent le même patron : un formulaire → une
/// action du `Store` → une entrée scellée.
struct ContentView: View {
    @EnvironmentObject private var store: Store

    @State private var selectedEnclosure: String = Enclosure.frigo.id
    @State private var celsiusText: String = ""
    @State private var lastStatus: ReadingStatus?

    var body: some View {
        NavigationStack {
            Form {
                Section("Relevé de température") {
                    Picker("Enceinte", selection: $selectedEnclosure) {
                        ForEach(store.enclosures) { enc in
                            Text(enc.name).tag(enc.id)
                        }
                    }
                    TextField("Température (°C)", text: $celsiusText)
                        .keyboardType(.numbersAndPunctuation)
                    Button("Enregistrer le relevé") { saveReading() }
                        .disabled(Double(normalized(celsiusText)) == nil)

                    if let s = lastStatus {
                        Label(s == .ok ? "Conforme" : "ALERTE hors-plage",
                              systemImage: s == .ok ? "checkmark.seal" : "exclamationmark.triangle")
                            .foregroundStyle(s == .ok ? .green : .red)
                    }
                }

                Section("Intégrité du dossier") {
                    Label(store.isValid ? "Journal vérifié" : "Journal COMPROMIS",
                          systemImage: store.isValid ? "lock.shield" : "xmark.shield")
                        .foregroundStyle(store.isValid ? .green : .red)
                    Text("Empreinte : \(store.headHash.prefix(16))…")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Section("Historique (\(store.entries.count))") {
                    ForEach(store.entries.reversed(), id: \.hash) { e in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(e.kind).font(.subheadline.bold())
                                Spacer()
                                if e.payload["status"] == "alert" {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            Text(e.timestamp).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("KaribTruck")
            .toolbar {
                ShareLink(item: store.exportCSV(),
                          preview: SharePreview("dossier-de-controle.csv")) {
                    Label("Exporter", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    /// Accepte la virgule française comme séparateur décimal.
    private func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
    }

    private func saveReading() {
        guard let celsius = Double(normalized(celsiusText)) else { return }
        lastStatus = store.recordTemperature(enclosureID: selectedEnclosure, celsius: celsius)
        celsiusText = ""
    }
}
