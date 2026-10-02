import Foundation

/// Une entrée scellée du journal. Immuable une fois ajoutée.
public struct JournalEntry: Equatable, Codable {
    public let index: Int
    public let timestamp: String            // ISO-8601, fourni par l'appelant (pas d'horloge cachée → testable)
    public let kind: String
    public let payload: [String: String]
    public let previousHash: String
    public let hash: String
}

public enum JournalError: Error, Equatable {
    case brokenChain(atIndex: Int)          // previousHash ne correspond pas au maillon précédent
    case badHash(atIndex: Int)              // le contenu a été altéré (hash recalculé ≠ hash stocké)
}

/// Journal **append-only** chaîné en SHA-256, tamper-evident.
///
/// Chaque entrée référence le hash de la précédente. On ne peut ni modifier ni
/// rétro-dater un enregistrement sans casser toute la chaîne en aval — d'où sa
/// valeur de preuve devant un contrôle. Une correction se fait par une **nouvelle
/// entrée rectificative**, jamais par un effacement.
///
/// La sérialisation canonique est **préfixée en longueur** (nombre d'octets UTF-8
/// avant chaque champ), donc sans ambiguïté : aucune valeur ne peut contenir un
/// séparateur qui simulerait une autre structure. Spec partagée octet pour octet
/// avec `tools/oracle.py`.
public struct Journal: Equatable {
    public static let genesisPrevHash = String(repeating: "0", count: 64)

    public private(set) var entries: [JournalEntry]

    public init(entries: [JournalEntry] = []) { self.entries = entries }

    /// Hash de tête (celui de la dernière entrée), ou le hash de genèse si vide.
    public var headHash: String { entries.last?.hash ?? Journal.genesisPrevHash }

    // MARK: - Sérialisation canonique

    static func field(_ s: String) -> [UInt8] {
        let raw = Array(s.utf8)
        return Array("\(raw.count):".utf8) + raw
    }

    static func canonicalBytes(index: Int, timestamp: String, kind: String,
                               previousHash: String, payload: [String: String]) -> [UInt8] {
        var out = [UInt8]()
        out += field("\(index)")
        out += field(timestamp)
        out += field(kind)
        out += field(previousHash)
        out += field("\(payload.count)")
        // Tri par octets UTF-8 (== ordre des points de code == tri Python) pour
        // un résultat identique quelle que soit la plateforme.
        let keys = payload.keys.sorted { $0.utf8.lexicographicallyPrecedes($1.utf8) }
        for key in keys {
            out += field(key)
            out += field(payload[key]!)
        }
        return out
    }

    static func computeHash(index: Int, timestamp: String, kind: String,
                            previousHash: String, payload: [String: String]) -> String {
        SHA256.hexHash(canonicalBytes(index: index, timestamp: timestamp, kind: kind,
                                      previousHash: previousHash, payload: payload))
    }

    // MARK: - Écriture

    /// Ajoute une entrée scellée et la retourne.
    @discardableResult
    public mutating func append(kind: String, timestamp: String,
                                payload: [String: String]) -> JournalEntry {
        let index = entries.count
        let prev = headHash
        let hash = Journal.computeHash(index: index, timestamp: timestamp, kind: kind,
                                       previousHash: prev, payload: payload)
        let entry = JournalEntry(index: index, timestamp: timestamp, kind: kind,
                                 payload: payload, previousHash: prev, hash: hash)
        entries.append(entry)
        return entry
    }

    // MARK: - Vérification d'intégrité

    /// Revérifie hachages et chaînage. Lève à la première anomalie.
    public func verify() throws {
        var prev = Journal.genesisPrevHash
        for e in entries {
            guard e.previousHash == prev else { throw JournalError.brokenChain(atIndex: e.index) }
            let expected = Journal.computeHash(index: e.index, timestamp: e.timestamp,
                                               kind: e.kind, previousHash: prev,
                                               payload: e.payload)
            guard e.hash == expected else { throw JournalError.badHash(atIndex: e.index) }
            prev = e.hash
        }
    }

    public var isValid: Bool { (try? verify()) != nil }
}
