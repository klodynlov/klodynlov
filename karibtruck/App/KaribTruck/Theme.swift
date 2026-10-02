import SwiftUI
import UIKit
import KaribTruckCore

/// Charte « terrain » : gros, contrasté, utilisable d'une main en plein service.
enum Theme {
    static let ok = Color.green
    static let alert = Color.red
    static let accent = Color.orange          // couleur du camion
    static let tileCorner: CGFloat = 22
    static let bigButtonHeight: CGFloat = 72
}

/// Gros bouton d'action pleine largeur (enregistrer, signer…).
struct BigButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.bold))
            .frame(maxWidth: .infinity, minHeight: Theme.bigButtonHeight)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 18)
                .fill(isEnabled ? color : Color.gray.opacity(0.4)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Bouton « puce » sélectionnable (gravité, qualité, modèle d'incident…).
struct ChipButton: View {
    let title: String
    var systemImage: String? = nil
    let selected: Bool
    var color: Color = Theme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.headline)
            .padding(.horizontal, 18)
            .frame(minHeight: 52)
            .foregroundStyle(selected ? .white : .primary)
            .background(Capsule().fill(selected ? color : Color(.secondarySystemBackground)))
            .overlay(Capsule().stroke(selected ? color : Color(.separator), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Mise en page à puces qui passe à la ligne (iOS 16 : `Layout`).
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxX, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Barre d'enregistrement fixée en bas de l'écran : toujours atteignable au
/// pouce, et elle dit ce qui manque au lieu d'un bouton grisé muet.
struct SaveBar: View {
    let title: String
    let systemImage: String
    var color: Color = Theme.accent
    let missing: [String]
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if !missing.isEmpty {
                Label("À compléter : " + missing.joined(separator: " · "), systemImage: "hand.point.up.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button(action: action) { Label(title, systemImage: systemImage) }
                .buttonStyle(BigButtonStyle(color: color))
                .disabled(!missing.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

/// Étape numérotée d'un formulaire (① Viande, ② Étiquette…).
struct StepCard<Content: View>: View {
    let number: Int
    let title: String
    var done = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(done ? Theme.ok : Color.pink).frame(width: 34, height: 34)
                    if done {
                        Image(systemName: "checkmark").font(.headline.bold()).foregroundStyle(.white)
                    } else {
                        Text("\(number)").font(.headline.bold()).foregroundStyle(.white)
                    }
                }
                Text(title).font(.title2.bold())
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }
}

/// Bandeau de confirmation après une saisie (vert = conforme, rouge = alerte).
struct ResultBanner: View {
    let ok: Bool
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: ok ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.bold())
                if let detail { Text(detail).font(.subheadline) }
            }
            Spacer()
        }
        .padding(18)
        .foregroundStyle(.white)
        .background(RoundedRectangle(cornerRadius: 18).fill(ok ? Theme.ok : Theme.alert))
    }
}

extension View {
    /// Champ de saisie : fond blanc + bordure, lisible sur fond gris comme dans une carte blanche.
    func inputBox() -> some View {
        background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 1))
    }
}

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

// MARK: - Libellés et formats

enum Fmt {
    private static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd/MM/yyyy HH:mm"
        return f
    }()
    private static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH:mm"
        return f
    }()
    private static let day: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()
    private static let longDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()
    /// Dates « métier » (DLC, jour de marché) : jour civil, sans fuseau.
    static let isoDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func date(_ iso: String) -> Date? { Store.iso.date(from: iso) }
    static func dateTime(_ iso: String) -> String { date(iso).map(dateTime.string) ?? iso }
    static func time(_ iso: String) -> String { date(iso).map(time.string) ?? iso }
    static func day(_ d: Date) -> String { day.string(from: d) }
    /// "vendredi 25 septembre" → "Vendredi 25 septembre" (majuscule initiale seulement).
    static func longDay(_ d: Date) -> String {
        let s = longDay.string(from: d)
        return s.prefix(1).uppercased() + s.dropFirst()
    }
    /// "2026-10-01" → "01/10/2026".
    static func businessDay(_ s: String) -> String { isoDay.date(from: s).map(day.string) ?? s }

    /// "3.5" → "3,5".
    static func number(_ s: String?) -> String { (s ?? "").replacingOccurrences(of: ".", with: ",") }

    static func kindLabel(_ kind: String) -> String {
        switch kind {
        case "enclosure.reading": return "Température"
        case "checklist.run": return "Checklist"
        case "reception": return "Réception"
        case "frying-oil.check": return "Huile de friture"
        case "nonconformity": return "Non-conformité"
        case "market.schedule": return "Planning"
        case "meat.reception": return "Réception viande"
        case "meat.preparation": return "Fournée"
        case "meat.lot.close": return "Lot viande clos"
        default: return kind
        }
    }

    static func kindIcon(_ kind: String) -> String {
        switch kind {
        case "enclosure.reading": return "thermometer.medium"
        case "checklist.run": return "checklist"
        case "reception": return "shippingbox"
        case "frying-oil.check": return "drop"
        case "nonconformity": return "exclamationmark.bubble"
        case "market.schedule": return "calendar"
        case "meat.reception": return "fork.knife"
        case "meat.preparation": return "flame"
        case "meat.lot.close": return "archivebox"
        default: return "doc"
        }
    }

    static func ruleLabel(_ t: Threshold) -> String {
        let limit = number(String(t.limitCelsius))
        return t.rule == .max ? "≤ \(limit) °C" : "≥ \(limit) °C"
    }

    static func enclosureName(_ id: String?, in enclosures: [Enclosure]) -> String {
        enclosures.first { $0.id == id }?.name ?? (id ?? "?")
    }

    static func checklistName(_ id: String?) -> String {
        ChecklistTemplate.defaultsM0.first { $0.id == id }?.name ?? (id ?? "?")
    }

    /// Résumé lisible d'une entrée, pour l'historique et le PDF.
    static func summary(_ e: JournalEntry, enclosures: [Enclosure]) -> String {
        let p = e.payload
        switch e.kind {
        case "enclosure.reading":
            let rule = p["rule"] == "max" ? "≤" : (p["rule"] == "min" ? "≥" : "?")
            return "\(enclosureName(p["enclosure"], in: enclosures)) : \(number(p["celsius"])) °C (limite \(rule) \(number(p["limit"])) °C)"
        case "checklist.run":
            var s = "\(checklistName(p["checklist"])) : \(p["done"] ?? "?")/\(p["total"] ?? "?") — \(p["operator"] ?? "")"
            if let m = p["missing"] { s += " — non fait : \(m)" }
            return s
        case "reception":
            var s = "\(p["product"] ?? "") — \(p["supplier"] ?? "") — lot \(p["lot"] ?? "") — DLC \(businessDay(p["dlc"] ?? ""))"
            if p["photo_sha256"] != nil { s += " — photo" }
            return s
        case "frying-oil.check":
            var s = "\(p["fryer"] ?? "") : \(p["action"] == "changement" ? "changement" : "contrôle"), \(qualityLabel(p["quality"]))"
            if let pc = p["polar_percent"] { s += ", \(number(pc)) % polaires" }
            if p["changed"] == "true" { s += ", huile changée" }
            return s
        case "nonconformity":
            return "[\(p["severity"] ?? "")] \(p["what"] ?? "") → \(p["action"] ?? "")"
        case "market.schedule":
            return "\(businessDay(p["date"] ?? "")) — \(p["place"] ?? "") — \(p["slot"] ?? "")"
        case "meat.reception":
            let sp = MeatSpecies(rawValue: p["species"] ?? "")
            return "\(speciesEmoji(sp)) \(meatTitle(species: sp, state: MeatState(rawValue: p["state"] ?? ""), product: p["product"] ?? "")) — lot \(p["lot"] ?? "") — \(number(p["celsius"])) °C — \(p["origin"] ?? "")"
        case "meat.preparation":
            let n = KaribTruck.lotIDs(of: e).count
            return "\(p["name"] ?? "") — \(n) lot\(n > 1 ? "s" : "") — DLC \(businessDay(p["dlc"] ?? "")) — \(p["operator"] ?? "")"
        case "meat.lot.close":
            return "\(MeatLotClosure(rawValue: p["reason"] ?? "")?.label ?? "")\(p["note"].map { " — \($0)" } ?? "")"
        default:
            return p.keys.sorted().map { "\($0)=\(p[$0]!)" }.joined(separator: " | ")
        }
    }

    /// "Bœuf — Paleron (viande surgelée)" : l'état qualifie la viande (accord correct).
    static func meatTitle(species: MeatSpecies?, state: MeatState?, product: String) -> String {
        var s = "\(species?.label ?? "?") — \(product)"
        if let state { s += " (viande \(state.label.lowercased()))" }
        return s
    }

    static func speciesEmoji(_ s: MeatSpecies?) -> String {
        switch s {
        case .volaille: return "🐔"
        case .porc: return "🐖"
        case .boeuf: return "🐄"
        case .ovin: return "🐑"
        case .caprin: return "🐐"
        case nil: return "🥩"
        }
    }

    /// "🐔 Volaille · Cuisses — lot V-1".
    static func lotLabel(_ lot: MeatLot) -> String {
        "\(speciesEmoji(lot.species)) \(lot.species?.label ?? "?") · \(lot.reception.payload["product"] ?? "") — lot \(lot.reception.payload["lot"] ?? "")"
    }

    /// Message clair pour une erreur de traçabilité viande.
    @MainActor
    static func meatError(_ error: Error, store: Store) -> String {
        func name(_ id: String) -> String { store.meatLot(id).map(lotLabel) ?? "lot inconnu" }
        switch error as? MeatError {
        case .incompleteOrigin: return "Origine incomplète : indiquez le pays d'élevage et d'abattage."
        case .noLot: return "Choisissez au moins un lot."
        case .unknownLot(let id): return "Lot introuvable : \(name(id))."
        case .lotClosed(let id): return "Ce lot est déjà clos : \(name(id))."
        case .lotExpired(let id): return "DLC dépassée, lot à jeter : \(name(id))."
        case nil: return error.localizedDescription
        }
    }

    /// Fiche de traçabilité d'un lot, en texte (partage : mail, message, AirDrop).
    static func traceText(_ lot: MeatLot) -> String {
        let p = lot.reception.payload
        var out = "Fiche de traçabilité — KaribTruck\n\n"
        out += meatTitle(species: lot.species, state: lot.state, product: p["product"] ?? "") + "\n"
        out += "Reçu le : \(dateTime(lot.reception.timestamp))\n"
        out += "Fournisseur : \(p["supplier"] ?? "")\n"
        out += "Lot fournisseur : \(p["lot"] ?? "")\n"
        out += "Estampille : \(p["agrement"] ?? "—")\n"
        out += "Origine : \(lot.origin)\n"
        out += "Température à réception : \(number(p["celsius"])) °C (limite ≤ \(number(p["limit"])) °C)\n"
        out += "DLC : \(businessDay(lot.dlc))\n"
        if let c = lot.closure {
            out += "Clos le : \(dateTime(c.timestamp)) — \(MeatLotClosure(rawValue: c.payload["reason"] ?? "")?.label ?? "")\n"
        } else {
            out += "Statut : en cours\n"
        }
        out += "\nFournées (\(lot.preparations.count)) :\n"
        for prep in lot.preparations {
            out += "- \(dateTime(prep.timestamp)) : \(prep.payload["name"] ?? "") (DLC \(businessDay(prep.payload["dlc"] ?? "")), \(prep.payload["operator"] ?? ""))\n"
        }
        out += "\nEmpreinte de la réception : \(lot.reception.hash)\n"
        return out
    }

    static func qualityLabel(_ q: String?) -> String {
        switch q {
        case "bonne": return "bonne"
        case "a-surveiller": return "à surveiller"
        case "a-changer": return "à changer"
        default: return q ?? ""
        }
    }
}
