import Foundation

/// Traçabilité de la viande : réception (origine, estampille, température),
/// fournées liées aux lots utilisés, clôture des lots, recherche pour rappel,
/// affichage de l'origine au client.
///
/// Règles encodées (vérifiées le 2026-09-25, à confirmer dans le PMS) :
/// - Origine à afficher en restauration, y compris à emporter (décret
///   n° 2002-1465 modifié, pérennisé par le décret n° 2025-141) : bœuf, porc,
///   ovin, volaille. Mentions : « Origine : pays » si tout a lieu dans le même
///   pays ; sinon « Né et élevé : … et abattu : … » (bœuf) ou « Élevé : … et
///   abattu : … » (autres). Le caprin n'est pas visé mais se trace pareil.
/// - Températures maximales (règlement CE 853/2004, arrêté du 21/12/2009) :
///   viande hachée 2 °C, abats d'ongulés 3 °C, volaille et préparations de
///   viande 4 °C, découpes d'ongulés 7 °C, surgelé −18 °C avec tolérance de
///   3 °C admise au transport (d'où −15 °C à la réception).

public enum MeatSpecies: String, CaseIterable, Codable, Equatable {
    case volaille, porc, boeuf, ovin, caprin

    public var label: String {
        switch self {
        case .volaille: return "Volaille"
        case .porc: return "Porc"
        case .boeuf: return "Bœuf"
        case .ovin: return "Mouton / agneau"
        case .caprin: return "Cabri"
        }
    }

    /// L'origine doit-elle être affichée au client ?
    public var originDisplayRequired: Bool { self != .caprin }

    /// Le pays de naissance fait partie de la mention (bœuf seulement).
    public var tracksBirth: Bool { self == .boeuf }

    var isUngulate: Bool { self != .volaille }
}

public enum MeatState: String, CaseIterable, Codable, Equatable {
    case fraiche, hachee, abats, preparee, surgelee

    public var label: String {
        switch self {
        case .fraiche: return "Fraîche"
        case .hachee: return "Hachée"
        case .abats: return "Abats"
        case .preparee: return "Préparée / marinée"
        case .surgelee: return "Surgelée"
        }
    }
}

public enum MeatRules {
    /// Température maximale admise à la réception.
    public static func receptionThreshold(species: MeatSpecies, state: MeatState) -> Threshold {
        let limit: Double
        switch state {
        case .surgelee: limit = -15.0                     // −18 °C + 3 °C de tolérance transport
        case .hachee: limit = 2.0
        case .abats: limit = species.isUngulate ? 3.0 : 4.0
        case .preparee: limit = 4.0
        case .fraiche: limit = species.isUngulate ? 7.0 : 4.0
        }
        return Threshold(rule: .max, limitCelsius: limit)
    }
}

/// Pays de naissance (bœuf), d'élevage et d'abattage.
public struct MeatOrigin: Equatable {
    public let born: String?
    public let raised: String
    public let slaughtered: String

    public init(born: String? = nil, raised: String, slaughtered: String) {
        self.born = born
        self.raised = raised
        self.slaughtered = slaughtered
    }

    /// Mention à afficher au client, au format du décret.
    public func label(for species: MeatSpecies) -> String {
        let r = raised.trimmed, s = slaughtered.trimmed
        if species.tracksBirth {
            let b = (born ?? "").trimmed.isEmpty ? r : born!.trimmed
            if b == r && r == s { return "Origine : \(r)" }
            let bornRaised = b == r ? r : "\(b), \(r)"
            return "Né et élevé : \(bornRaised) et abattu : \(s)"
        }
        if r == s { return "Origine : \(r)" }
        return "Élevé : \(r) et abattu : \(s)"
    }

    var isComplete: Bool {
        !raised.trimmed.isEmpty && !slaughtered.trimmed.isEmpty
    }
}

public enum MeatLotClosure: String, Codable, Equatable {
    case termine, jete, rappel

    public var label: String {
        switch self {
        case .termine: return "Terminé"
        case .jete: return "Jeté"
        case .rappel: return "Rappel fournisseur"
        }
    }
}

public enum MeatError: Error, Equatable {
    case incompleteOrigin
    case noLot
    case unknownLot(String)
    case lotClosed(String)
    case lotExpired(String)
}

/// Vue d'un lot de viande : sa réception, les fournées qui l'utilisent, sa clôture.
public struct MeatLot: Equatable, Identifiable {
    public let reception: JournalEntry
    public let preparations: [JournalEntry]
    public let closure: JournalEntry?

    /// Référence interne du lot = empreinte de sa réception (scellée, unique).
    public var id: String { reception.hash }
    public var species: MeatSpecies? { MeatSpecies(rawValue: reception.payload["species"] ?? "") }
    public var state: MeatState? { MeatState(rawValue: reception.payload["state"] ?? "") }
    public var origin: String { reception.payload["origin"] ?? "" }
    public var dlc: String { reception.payload["dlc"] ?? "" }
    public var isOpen: Bool { closure == nil }

    /// DLC dépassée au jour `day` (dates « yyyy-MM-dd »).
    public func isExpired(on day: String) -> Bool { !dlc.isEmpty && dlc < day }
}

extension KaribTruck {
    static let meatReceptionKind = "meat.reception"
    static let meatPreparationKind = "meat.preparation"
    static let meatLotCloseKind = "meat.lot.close"
    /// Séparateur des références de lots dans une fournée (une empreinte n'en contient pas).
    static let lotSeparator = ","

    // MARK: - Écriture

    /// Réception d'un lot de viande. Retourne l'entrée scellée et le statut du
    /// contrôle de température (limite selon l'espèce et l'état).
    @discardableResult
    public mutating func recordMeatReception(species: MeatSpecies, state: MeatState,
                                             product: String, supplier: String,
                                             lot: String, dlc: String, agrement: String,
                                             origin: MeatOrigin, celsius: Double,
                                             photoSHA256: String? = nil,
                                             at timestamp: String) throws -> (entry: JournalEntry, status: ReadingStatus) {
        guard origin.isComplete else { throw MeatError.incompleteOrigin }
        let threshold = MeatRules.receptionThreshold(species: species, state: state)
        let status = threshold.evaluate(celsius)
        var payload = [
            "species": species.rawValue,
            "state": state.rawValue,
            "product": product,
            "supplier": supplier,
            "lot": lot,
            "dlc": dlc,
            "raised": origin.raised.trimmed,
            "slaughtered": origin.slaughtered.trimmed,
            "origin": origin.label(for: species),
            "celsius": KaribTruck.num(celsius),
            "rule": threshold.rule.rawValue,
            "limit": KaribTruck.num(threshold.limitCelsius),
            "status": status.rawValue,
        ]
        if !agrement.trimmed.isEmpty { payload["agrement"] = agrement.trimmed }
        if species.tracksBirth, let born = origin.born, !born.trimmed.isEmpty { payload["born"] = born.trimmed }
        if let photoSHA256 { payload["photo_sha256"] = photoSHA256 }
        let entry = journal.append(kind: KaribTruck.meatReceptionKind, timestamp: timestamp, payload: payload)
        return (entry, status)
    }

    /// Fournée (préparation) liée aux lots utilisés. Refuse un lot inconnu,
    /// déjà clos ou à DLC dépassée au jour `day` (« yyyy-MM-dd », jour local).
    @discardableResult
    public mutating func recordMeatPreparation(name: String, lots: [String], day: String,
                                               dlc: String, operator op: String,
                                               at timestamp: String) throws -> JournalEntry {
        guard !lots.isEmpty else { throw MeatError.noLot }
        for id in lots {
            guard let lot = meatLot(id) else { throw MeatError.unknownLot(id) }
            guard lot.isOpen else { throw MeatError.lotClosed(id) }
            guard !lot.isExpired(on: day) else { throw MeatError.lotExpired(id) }
        }
        return journal.append(kind: KaribTruck.meatPreparationKind, timestamp: timestamp, payload: [
            "name": name,
            "lots": lots.joined(separator: KaribTruck.lotSeparator),
            "day": day,
            "dlc": dlc,
            "operator": op,
        ])
    }

    /// Clôture d'un lot (terminé, jeté, rappel). Un lot ne se clôt qu'une fois.
    @discardableResult
    public mutating func closeMeatLot(_ id: String, reason: MeatLotClosure, note: String = "",
                                      at timestamp: String) throws -> JournalEntry {
        guard let lot = meatLot(id) else { throw MeatError.unknownLot(id) }
        guard lot.isOpen else { throw MeatError.lotClosed(id) }
        var payload = ["lot": id, "reason": reason.rawValue]
        if !note.trimmed.isEmpty { payload["note"] = note.trimmed }
        return journal.append(kind: KaribTruck.meatLotCloseKind, timestamp: timestamp, payload: payload)
    }

    // MARK: - Lectures

    /// Tous les lots de viande, du plus ancien au plus récent.
    public var meatLots: [MeatLot] {
        var preparations: [String: [JournalEntry]] = [:]
        var closures: [String: JournalEntry] = [:]
        for e in journal.entries {
            if e.kind == KaribTruck.meatPreparationKind {
                for id in KaribTruck.lotIDs(of: e) { preparations[id, default: []].append(e) }
            } else if e.kind == KaribTruck.meatLotCloseKind, let id = e.payload["lot"], closures[id] == nil {
                closures[id] = e
            }
        }
        return journal.entries
            .filter { $0.kind == KaribTruck.meatReceptionKind }
            .map { MeatLot(reception: $0, preparations: preparations[$0.hash] ?? [], closure: closures[$0.hash]) }
    }

    public func meatLot(_ id: String) -> MeatLot? { meatLots.first { $0.id == id } }

    public var openMeatLots: [MeatLot] { meatLots.filter(\.isOpen) }

    /// Références de lots d'une fournée.
    public static func lotIDs(of preparation: JournalEntry) -> [String] {
        (preparation.payload["lots"] ?? "")
            .split(separator: Character(lotSeparator)).map(String.init)
    }

    /// Recherche pour rappel : n° de lot fournisseur, produit, fournisseur ou
    /// estampille (insensible à la casse). Lots les plus récents d'abord.
    public func searchMeatLots(_ query: String) -> [MeatLot] {
        let q = query.trimmed.lowercased()
        guard !q.isEmpty else { return [] }
        return meatLots.reversed().filter { lot in
            ["lot", "product", "supplier", "agrement"].contains {
                (lot.reception.payload[$0] ?? "").lowercased().contains(q)
            }
        }
    }

    /// Affiche client : pour chaque espèce, les mentions d'origine des viandes
    /// en service le jour `day` — lots ouverts non périmés, plus les lots
    /// utilisés dans une fournée de ce jour (même clos depuis).
    public func originBoard(day: String) -> [(species: MeatSpecies, origins: [String])] {
        let lots = meatLots
        var inService = Set(lots.filter { $0.isOpen && !$0.isExpired(on: day) }.map(\.id))
        for e in journal.entries where e.kind == KaribTruck.meatPreparationKind && e.payload["day"] == day {
            inService.formUnion(KaribTruck.lotIDs(of: e))
        }
        return MeatSpecies.allCases.compactMap { sp in
            var seen = Set<String>()
            let origins = lots
                .filter { inService.contains($0.id) && $0.species == sp }
                .map(\.origin)
                .filter { seen.insert($0).inserted }
            return origins.isEmpty ? nil : (sp, origins)
        }
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
