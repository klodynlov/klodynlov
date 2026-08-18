import Foundation

/// Export « dossier de contrôle » : ce que l'on présente à la DDPP. Le CSV est
/// universel (tableur, comptable) ; le hash de chaque ligne et le hash de tête
/// rendent le dossier **vérifiable** et non rétro-datable. La mise en forme PDF
/// est faite côté app iOS ; le cœur produit la donnée brute et fiable.
public enum InspectionExport {

    /// Échappe un champ CSV (RFC 4180) : guillemets si virgule, guillemet ou saut de ligne.
    static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    /// Détails lisibles d'une entrée (payload trié, hors `status` déjà en colonne).
    static func details(_ e: JournalEntry) -> String {
        e.payload.keys.sorted()
            .filter { $0 != "status" }
            .map { "\($0)=\(e.payload[$0]!)" }
            .joined(separator: " | ")
    }

    /// Journal complet en CSV, une ligne par entrée, en-tête inclus.
    public static func csv(_ journal: Journal) -> String {
        var lines = ["index,timestamp,kind,status,details,previous_hash,hash"]
        for e in journal.entries {
            let row = [
                "\(e.index)",
                csvField(e.timestamp),
                csvField(e.kind),
                csvField(e.payload["status"] ?? ""),
                csvField(details(e)),
                csvField(e.previousHash),
                csvField(e.hash),
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Résumé Markdown lisible (couverture, alertes, empreinte du dossier).
    public static func summary(_ journal: Journal) -> String {
        let total = journal.entries.count
        let alerts = journal.entries.filter { $0.payload["status"] == "alert" }
        var counts: [String: Int] = [:]
        for e in journal.entries { counts[e.kind, default: 0] += 1 }

        var out = "# Dossier de contrôle KaribTruck\n\n"
        out += "- Entrées : \(total)\n"
        out += "- Alertes : \(alerts.count)\n"
        out += "- Intégrité : \(journal.isValid ? "vérifiée ✓" : "COMPROMISE ✗")\n"
        out += "- Empreinte du dossier (hash de tête) : `\(journal.headHash)`\n\n"

        out += "## Répartition\n\n"
        for kind in counts.keys.sorted() {
            out += "- \(kind) : \(counts[kind]!)\n"
        }

        if !alerts.isEmpty {
            out += "\n## Alertes\n\n"
            for e in alerts {
                out += "- [\(e.timestamp)] \(e.kind) — \(InspectionExport.details(e))\n"
            }
        }
        return out
    }
}
