import Foundation

/// Façade métier du M0. Toute action opérationnelle (relevé, checklist,
/// réception, huile, non-conformité, planning) devient une **entrée scellée**
/// dans le journal inviolable. L'appelant fournit toujours l'horodatage : le
/// cœur reste sans horloge (donc déterministe et testable) ; c'est l'app iOS
/// qui injecte `Date()`.
public struct KaribTruck: Equatable {
    public private(set) var journal: Journal
    public var enclosures: [Enclosure]

    public init(enclosures: [Enclosure] = Enclosure.defaultsM0,
                journal: Journal = Journal()) {
        self.enclosures = enclosures
        self.journal = journal
    }

    /// Représentation numérique stable et sans locale (ex. 4 → "4.0", 3.5 → "3.5").
    static func num(_ d: Double) -> String { String(d) }

    // MARK: - 1. Relevés de température

    /// Enregistre un relevé et retourne le statut (ok / alerte hors-plage).
    /// Une enceinte inconnue est journalisée en alerte plutôt que perdue.
    @discardableResult
    public mutating func recordTemperature(enclosureID: String, celsius: Double,
                                           at timestamp: String) -> ReadingStatus {
        guard let enc = enclosures.first(where: { $0.id == enclosureID }) else {
            journal.append(kind: "enclosure.reading", timestamp: timestamp, payload: [
                "enclosure": enclosureID,
                "celsius": KaribTruck.num(celsius),
                "rule": "unknown",
                "limit": "",
                "status": ReadingStatus.alert.rawValue,
            ])
            return .alert
        }
        let status = enc.threshold.evaluate(celsius)
        journal.append(kind: "enclosure.reading", timestamp: timestamp, payload: [
            "enclosure": enc.id,
            "celsius": KaribTruck.num(celsius),
            "rule": enc.threshold.rule.rawValue,
            "limit": KaribTruck.num(enc.threshold.limitCelsius),
            "status": status.rawValue,
        ])
        return status
    }

    // MARK: - 2. Checklists (ouverture / fermeture / nettoyage)

    @discardableResult
    public mutating func recordChecklistRun(checklist: String, done: Int, total: Int,
                                            operator op: String,
                                            at timestamp: String) -> JournalEntry {
        journal.append(kind: "checklist.run", timestamp: timestamp, payload: [
            "checklist": checklist,
            "done": "\(done)",
            "total": "\(total)",
            "operator": op,
        ])
    }

    // MARK: - 3. Traçabilité réception

    @discardableResult
    public mutating func recordReception(supplier: String, lot: String, dlc: String,
                                         product: String,
                                         at timestamp: String) -> JournalEntry {
        journal.append(kind: "reception", timestamp: timestamp, payload: [
            "supplier": supplier,
            "lot": lot,
            "dlc": dlc,
            "product": product,
        ])
    }

    // MARK: - 5. Huile de friture

    @discardableResult
    public mutating func recordFryingOilCheck(fryer: String, action: String,
                                              quality: String, changed: Bool,
                                              at timestamp: String) -> JournalEntry {
        journal.append(kind: "frying-oil.check", timestamp: timestamp, payload: [
            "fryer": fryer,
            "action": action,
            "quality": quality,
            "changed": changed ? "true" : "false",
        ])
    }

    // MARK: - 4. Non-conformités

    @discardableResult
    public mutating func recordNonConformity(severity: String, what: String,
                                             action: String,
                                             at timestamp: String) -> JournalEntry {
        journal.append(kind: "nonconformity", timestamp: timestamp, payload: [
            "severity": severity,
            "what": what,
            "action": action,
        ])
    }

    // MARK: - 6. Planning marché

    @discardableResult
    public mutating func recordMarketSchedule(date: String, place: String, slot: String,
                                              at timestamp: String) -> JournalEntry {
        journal.append(kind: "market.schedule", timestamp: timestamp, payload: [
            "date": date,
            "place": place,
            "slot": slot,
        ])
    }

    // MARK: - Lectures utiles

    /// Toutes les entrées en alerte (relevés hors-plage, etc.).
    public var alerts: [JournalEntry] {
        journal.entries.filter { $0.payload["status"] == ReadingStatus.alert.rawValue }
    }

    /// Vérifie l'intégrité complète du journal.
    public func verify() throws { try journal.verify() }
    public var isValid: Bool { journal.isValid }
}
