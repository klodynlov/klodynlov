import Foundation
import CryptoKit
import KaribTruckCore

/// Liaison entre l'UI et le cœur métier. C'est ici — et seulement ici — qu'on
/// touche au monde réel : l'horloge (`Date()`) et le disque. Le cœur, lui, reste
/// pur et testé. Le journal est persisté en JSON, chiffré au repos par la
/// protection de fichier iOS (`.completeFileProtection`).
@MainActor
final class Store: ObservableObject {
    @Published private(set) var truck: KaribTruck
    /// Résultat de la dernière vérification complète de la chaîne. Calculé au
    /// chargement et à la demande, pas à chaque rendu : un ajout ne peut pas
    /// casser une chaîne valide.
    @Published private(set) var isValid: Bool
    /// Problème de disque à montrer à l'écran (jamais avalé en silence).
    @Published private(set) var storageWarning: String?

    private let fileURL: URL
    let photosDir: URL

    // ISO8601DateFormatter est thread-safe : partageable hors du MainActor.
    nonisolated(unsafe) static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]   // ex. "2026-08-18T07:00:00Z"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("karibtruck-journal.json")
        photosDir = dir.appendingPathComponent("photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)

        var warning: String?
        var loaded = KaribTruck()
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL),
               let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) {
                loaded = KaribTruck(journal: Journal(entries: entries))
            } else {
                // Ne JAMAIS repartir à vide par-dessus la preuve : on met le
                // fichier illisible de côté, intact, avant tout nouvel ajout.
                let stamp = Self.iso.string(from: Date()).replacingOccurrences(of: ":", with: "-")
                let aside = dir.appendingPathComponent("karibtruck-journal.illisible-\(stamp).json")
                try? FileManager.default.moveItem(at: fileURL, to: aside)
                warning = "Journal précédent illisible : mis de côté (\(aside.lastPathComponent)). Un nouveau journal a démarré."
            }
        }
        truck = loaded
        isValid = loaded.isValid
        storageWarning = warning
    }

    // MARK: - Lectures pour les vues
    var enclosures: [Enclosure] { truck.enclosures }
    var checklists: [ChecklistTemplate] { ChecklistTemplate.defaultsM0 }
    var entries: [JournalEntry] { truck.journal.entries }
    var headHash: String { truck.journal.headHash }

    func entries(from: Date, to: Date) -> [JournalEntry] {
        truck.entries(from: Self.iso.string(from: from), to: Self.iso.string(from: to))
    }

    func lastReadingToday(_ enclosureID: String) -> JournalEntry? {
        let (a, b) = Self.today()
        return truck.lastReading(enclosureID: enclosureID,
                                 from: Self.iso.string(from: a), to: Self.iso.string(from: b))
    }

    func lastChecklistToday(_ checklistID: String) -> JournalEntry? {
        let (a, b) = Self.today()
        return truck.lastChecklistRun(checklist: checklistID,
                                      from: Self.iso.string(from: a), to: Self.iso.string(from: b))
    }

    var alertsToday: [JournalEntry] {
        let (a, b) = Self.today()
        return entries(from: a, to: b).filter { $0.payload["status"] == "alert" }
    }

    /// Valeurs déjà saisies pour une clé (suggestions : fournisseurs, lieux…),
    /// de la plus récente à la plus ancienne, sans doublon.
    func recentValues(kind: String, key: String, limit: Int = 6,
                      matching filter: [String: String] = [:]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for e in entries.reversed() where e.kind == kind
            && filter.allSatisfy({ e.payload[$0.key] == $0.value }) {
            guard let v = e.payload[key], !v.isEmpty, seen.insert(v).inserted else { continue }
            out.append(v)
            if out.count == limit { break }
        }
        return out
    }

    /// Journée locale en cours `[minuit, minuit+1[` (le camion vit à l'heure locale).
    static func today(_ now: Date = Date()) -> (Date, Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        return (start, cal.date(byAdding: .day, value: 1, to: start)!)
    }

    func reverify() { isValid = truck.isValid }

    private func now() -> String { Self.iso.string(from: Date()) }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(truck.journal.entries)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            storageWarning = "Échec d'enregistrement sur l'iPad : \(error.localizedDescription)"
        }
    }

    // MARK: - Actions (chaque action scelle une entrée puis persiste)

    @discardableResult
    func recordTemperature(enclosureID: String, celsius: Double) -> ReadingStatus {
        let status = truck.recordTemperature(enclosureID: enclosureID, celsius: celsius, at: now())
        persist()
        return status
    }

    func recordChecklistRun(checklist: String, done: Int, total: Int,
                            operator op: String, missing: [String]) {
        truck.recordChecklistRun(checklist: checklist, done: done, total: total,
                                 operator: op, missing: missing, at: now())
        persist()
    }

    func recordReception(supplier: String, lot: String, dlc: String, product: String,
                         photoSHA256: String?) {
        truck.recordReception(supplier: supplier, lot: lot, dlc: dlc, product: product,
                              photoSHA256: photoSHA256, at: now())
        persist()
    }

    func recordFryingOilCheck(fryer: String, action: String, quality: String,
                              changed: Bool, polarPercent: Double?) {
        truck.recordFryingOilCheck(fryer: fryer, action: action, quality: quality,
                                   changed: changed, polarPercent: polarPercent, at: now())
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

    // MARK: - Traçabilité viande

    /// Jour local en cours au format métier « yyyy-MM-dd » (DLC, fournées).
    var todayDay: String { Fmt.isoDay.string(from: Date()) }
    var meatLots: [MeatLot] { truck.meatLots }
    var openMeatLots: [MeatLot] { truck.openMeatLots }
    func meatLot(_ id: String) -> MeatLot? { truck.meatLot(id) }
    func searchMeatLots(_ q: String) -> [MeatLot] { truck.searchMeatLots(q) }
    var originBoardToday: [(species: MeatSpecies, origins: [String])] { truck.originBoard(day: todayDay) }

    /// Retourne le statut du contrôle de température et la référence du lot créé.
    @discardableResult
    func recordMeatReception(species: MeatSpecies, state: MeatState, product: String, supplier: String,
                             lot: String, dlc: String, agrement: String, origin: MeatOrigin,
                             celsius: Double, photoSHA256: String?) throws -> (status: ReadingStatus, lotID: String) {
        let r = try truck.recordMeatReception(species: species, state: state, product: product,
                                              supplier: supplier, lot: lot, dlc: dlc, agrement: agrement,
                                              origin: origin, celsius: celsius,
                                              photoSHA256: photoSHA256, at: now())
        persist()
        return (r.status, r.entry.hash)
    }

    func recordMeatPreparation(name: String, lots: [String], dlc: String, operator op: String) throws {
        try truck.recordMeatPreparation(name: name, lots: lots, day: todayDay, dlc: dlc,
                                        operator: op, at: now())
        persist()
    }

    func closeMeatLot(_ id: String, reason: MeatLotClosure, note: String = "") throws {
        try truck.closeMeatLot(id, reason: reason, note: note, at: now())
        persist()
    }

    // MARK: - Photos d'étiquettes (hors journal, liées par empreinte SHA-256)

    /// Enregistre la photo sous son empreinte et retourne celle-ci.
    func savePhoto(_ jpeg: Data) throws -> String {
        let sha = CryptoKit.SHA256.hash(data: jpeg).map { String(format: "%02x", $0) }.joined()
        let url = photoURL(sha)
        if !FileManager.default.fileExists(atPath: url.path) {
            try jpeg.write(to: url, options: [.atomic, .completeFileProtection])
        }
        return sha
    }

    func photoURL(_ sha: String) -> URL { photosDir.appendingPathComponent("\(sha).jpg") }

    /// La photo existe-t-elle et correspond-elle toujours à l'empreinte scellée ?
    func photoMatches(_ sha: String) -> Bool {
        guard let data = try? Data(contentsOf: photoURL(sha)) else { return false }
        return CryptoKit.SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() == sha
    }

    #if targetEnvironment(simulator)
    /// Données de démonstration, SIMULATEUR UNIQUEMENT (`-karibtruck.seedDemo YES`,
    /// journal vide). Jamais compilé pour l'iPad réel : on n'antidate pas un vrai journal.
    func seedDemoIfRequested() {
        guard UserDefaults.standard.bool(forKey: "karibtruck.seedDemo"), truck.journal.entries.isEmpty else { return }
        let cal = Calendar.current
        func at(_ daysAgo: Int, _ h: Int, _ m: Int) -> String {
            let d = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: Date()))!
            return Self.iso.string(from: cal.date(bySettingHour: h, minute: m, second: 0, of: d)!)
        }
        let ouverture = ChecklistTemplate.ouverture.items
        for day in stride(from: 6, through: 1, by: -1) {
            truck.recordChecklistRun(checklist: "ouverture", done: ouverture.count, total: ouverture.count,
                                     operator: "Démo", at: at(day, 9, 0))
            truck.recordTemperature(enclosureID: "frigo", celsius: day == 3 ? 6.5 : 3.0, at: at(day, 9, 5))
            if day == 3 {
                truck.recordNonConformity(severity: "majeure", what: "Frigo à 6,5 °C (limite ≤ 4 °C)",
                                          action: "Produits déplacés au froid ; Enceinte réglée, recontrôle dans 1 h", at: at(day, 9, 10))
                truck.recordTemperature(enclosureID: "frigo", celsius: 3.5, at: at(day, 10, 10))
            }
            truck.recordTemperature(enclosureID: "vitrine-chaude", celsius: 68.0, at: at(day, 11, 30))
            if day == 5 {
                truck.recordReception(supplier: "Antilles Frais", lot: "LOT-2509", dlc: "2026-10-02",
                                      product: "Poulet", at: at(day, 8, 30))
            }
            if day == 2 {
                truck.recordFryingOilCheck(fryer: "Friteuse 1", action: "controle", quality: "a-surveiller",
                                           changed: false, polarPercent: 22.0, at: at(day, 15, 0))
            }
            truck.recordChecklistRun(checklist: "fermeture", done: day == 4 ? 8 : 9, total: 9, operator: "Démo",
                                     missing: day == 4 ? ["Eaux usées vidangées"] : [], at: at(day, 21, 0))
        }
        func day(_ daysAgo: Int, plus: Int = 0) -> String {
            Fmt.isoDay.string(from: cal.date(byAdding: .day, value: plus - daysAgo, to: Date())!)
        }
        let poulet = try? truck.recordMeatReception(
            species: .volaille, state: .fraiche, product: "Cuisses de poulet", supplier: "Antilles Frais",
            lot: "V-2509", dlc: day(5, plus: 6), agrement: "FR 97.213.001 CE",
            origin: MeatOrigin(raised: "France", slaughtered: "France"), celsius: 3.2, at: at(5, 8, 40)).entry.hash
        let porc = try? truck.recordMeatReception(
            species: .porc, state: .fraiche, product: "Échine", supplier: "Boucherie du Lamentin",
            lot: "P-7781", dlc: day(4, plus: 8), agrement: "FR 97.209.004 CE",
            origin: MeatOrigin(raised: "Espagne", slaughtered: "France"), celsius: 5.5, at: at(4, 8, 30)).entry.hash
        _ = try? truck.recordMeatReception(
            species: .boeuf, state: .surgelee, product: "Paleron", supplier: "Import Caraïbes",
            lot: "B-IE-332", dlc: day(1, plus: 120), agrement: "IE 1234 EC",
            origin: MeatOrigin(born: "Irlande", raised: "Irlande", slaughtered: "France"), celsius: -19, at: at(1, 9, 30))
        if let poulet, let porc {
            _ = try? truck.recordMeatPreparation(name: "Colombo de poulet", lots: [poulet], day: day(4),
                                                 dlc: day(4), operator: "Démo", at: at(4, 10, 30))
            _ = try? truck.recordMeatPreparation(name: "Porc boucané", lots: [porc], day: day(2),
                                                 dlc: day(2), operator: "Démo", at: at(2, 10, 0))
            _ = try? truck.recordMeatPreparation(name: "Colombo de poulet", lots: [poulet], day: day(2),
                                                 dlc: day(2), operator: "Démo", at: at(2, 10, 20))
            _ = try? truck.closeMeatLot(poulet, reason: .termine, at: at(2, 21, 30))
        }
        truck.recordMarketSchedule(date: Fmt.isoDay.string(from: cal.date(byAdding: .day, value: 2, to: Date())!),
                                   place: "Marché de Fort-de-France", slot: "08:00-14:00", at: at(1, 18, 0))
        isValid = truck.isValid
        persist()
    }
    #endif

    // MARK: - Export « dossier de contrôle »
    func exportCSV(_ entries: [JournalEntry]) -> String { InspectionExport.csv(entries) }
}
