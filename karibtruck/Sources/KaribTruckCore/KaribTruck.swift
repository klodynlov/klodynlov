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

    /// Une checklist signée. Les points non faits sont journalisés (`missing`)
    /// et la signature passe en alerte : une checklist incomplète se voit au
    /// contrôle au lieu de disparaître. Les clés `missing`/`status` ne sont
    /// écrites que si des points manquent (chaîne de la fixture inchangée).
    @discardableResult
    public mutating func recordChecklistRun(checklist: String, done: Int, total: Int,
                                            operator op: String,
                                            missing: [String] = [],
                                            at timestamp: String) -> JournalEntry {
        var payload = [
            "checklist": checklist,
            "done": "\(done)",
            "total": "\(total)",
            "operator": op,
        ]
        if !missing.isEmpty {
            payload["missing"] = missing.joined(separator: KaribTruck.listSeparator)
            payload["status"] = ReadingStatus.alert.rawValue
        }
        return journal.append(kind: "checklist.run", timestamp: timestamp, payload: payload)
    }

    /// Séparateur des listes dans une valeur de payload (ex. points manquants).
    public static let listSeparator = " ; "

    // MARK: - 3. Traçabilité réception

    /// Réception d'une marchandise. `photoSHA256` = empreinte de la photo de
    /// l'étiquette : la photo vit hors du journal, mais son empreinte scellée
    /// prouve qu'elle n'a pas été remplacée.
    @discardableResult
    public mutating func recordReception(supplier: String, lot: String, dlc: String,
                                         product: String,
                                         photoSHA256: String? = nil,
                                         at timestamp: String) -> JournalEntry {
        var payload = [
            "supplier": supplier,
            "lot": lot,
            "dlc": dlc,
            "product": product,
        ]
        if let photoSHA256 { payload["photo_sha256"] = photoSHA256 }
        return journal.append(kind: "reception", timestamp: timestamp, payload: payload)
    }

    // MARK: - 5. Huile de friture

    /// Limite de composés polaires d'une huile de friture (en %). Au-delà,
    /// l'huile est impropre. Valeur de départ, à confirmer dans le PMS.
    public static let polarLimitPercent = 25.0

    /// Contrôle ou changement d'huile. Si le taux de composés polaires est
    /// mesuré (testeur), il est scellé et évalué contre `polarLimitPercent`
    /// (limite inclusive). Sans mesure, pas de statut (contrôle visuel).
    @discardableResult
    public mutating func recordFryingOilCheck(fryer: String, action: String,
                                              quality: String, changed: Bool,
                                              polarPercent: Double? = nil,
                                              at timestamp: String) -> JournalEntry {
        var payload = [
            "fryer": fryer,
            "action": action,
            "quality": quality,
            "changed": changed ? "true" : "false",
        ]
        if let polarPercent {
            payload["polar_percent"] = KaribTruck.num(polarPercent)
            payload["limit"] = KaribTruck.num(KaribTruck.polarLimitPercent)
            let ok = polarPercent <= KaribTruck.polarLimitPercent
            payload["status"] = (ok ? ReadingStatus.ok : ReadingStatus.alert).rawValue
        }
        return journal.append(kind: "frying-oil.check", timestamp: timestamp, payload: payload)
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

    /// Entrées dont l'horodatage est dans `[from, to[` (bornes ISO-8601 UTC au
    /// même format que les entrées : l'ordre lexicographique est alors l'ordre
    /// chronologique). L'app calcule les bornes (journée locale, période…).
    public func entries(from: String, to: String) -> [JournalEntry] {
        journal.entries.filter { $0.timestamp >= from && $0.timestamp < to }
    }

    /// Dernier relevé d'une enceinte dans `[from, to[`, ou `nil`.
    public func lastReading(enclosureID: String, from: String, to: String) -> JournalEntry? {
        entries(from: from, to: to).last {
            $0.kind == "enclosure.reading" && $0.payload["enclosure"] == enclosureID
        }
    }

    /// Dernière signature d'une checklist dans `[from, to[`, ou `nil`.
    public func lastChecklistRun(checklist: String, from: String, to: String) -> JournalEntry? {
        entries(from: from, to: to).last {
            $0.kind == "checklist.run" && $0.payload["checklist"] == checklist
        }
    }

    /// Vérifie l'intégrité complète du journal.
    public func verify() throws { try journal.verify() }
    public var isValid: Bool { journal.isValid }
}
