import Foundation
import KaribTruckCore

/// Liaison entre l'UI et le cœur métier. C'est ici — et seulement ici — qu'on
/// touche au monde réel : l'horloge (`Date()`) et le disque. Le cœur, lui, reste
/// pur et testé. Le journal est persisté en JSON, chiffré au repos par la
/// protection de fichier iOS (`.completeFileProtection`).
@MainActor
final class Store: ObservableObject {
    @Published private(set) var truck: KaribTruck

    private let fileURL: URL

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]   // ex. "2026-08-18T07:00:00Z"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("karibtruck-journal.json")

        if let data = try? Data(contentsOf: fileURL),
           let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            truck = KaribTruck(journal: Journal(entries: entries))
        } else {
            truck = KaribTruck()
        }
    }

    // MARK: - Lectures pour les vues
    var enclosures: [Enclosure] { truck.enclosures }
    var entries: [JournalEntry] { truck.journal.entries }
    var alerts: [JournalEntry] { truck.alerts }
    var isValid: Bool { truck.isValid }
    var headHash: String { truck.journal.headHash }

    private func now() -> String { Self.iso.string(from: Date()) }

    private func persist() {
        guard let data = try? JSONEncoder().encode(truck.journal.entries) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    // MARK: - Actions (chaque action scelle une entrée puis persiste)

    @discardableResult
    func recordTemperature(enclosureID: String, celsius: Double) -> ReadingStatus {
        let status = truck.recordTemperature(enclosureID: enclosureID, celsius: celsius, at: now())
        persist()
        return status
    }

    func recordChecklistRun(checklist: String, done: Int, total: Int, operator op: String) {
        truck.recordChecklistRun(checklist: checklist, done: done, total: total, operator: op, at: now())
        persist()
    }

    func recordReception(supplier: String, lot: String, dlc: String, product: String) {
        truck.recordReception(supplier: supplier, lot: lot, dlc: dlc, product: product, at: now())
        persist()
    }

    func recordFryingOilCheck(fryer: String, action: String, quality: String, changed: Bool) {
        truck.recordFryingOilCheck(fryer: fryer, action: action, quality: quality, changed: changed, at: now())
        persist()
    }

    func recordNonConformity(severity: String, what: String, action: String) {
        truck.recordNonConformity(severity: severity, what: what, action: action, at: now())
        persist()
    }

    func recordMarketSchedule(date: String, place: String, slot: String) {
        truck.recordMarketSchedule(date: date, place: place, slot: slot, at: now())
        persist()
    }

    // MARK: - Export « dossier de contrôle »
    func exportCSV() -> String { InspectionExport.csv(truck.journal) }
    func exportSummary() -> String { InspectionExport.summary(truck.journal) }
}
