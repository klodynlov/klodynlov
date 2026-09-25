import SwiftUI
import KaribTruckCore

// MARK: - Huile de friture

/// Contrôle ou changement d'huile. La mesure au testeur (% de composés
/// polaires) est optionnelle ; si elle est saisie, le cœur l'évalue (≤ 25 %).
struct FryingOilView: View {
    @EnvironmentObject private var store: Store

    @State private var fryer = "Friteuse 1"
    @State private var action = "controle"
    @State private var quality = "bonne"
    @State private var withMeasure = false
    @State private var polar = ""
    @State private var banner: (ok: Bool, title: String, detail: String)?

    private var polarValue: Double? { Double(polar.replacingOccurrences(of: ",", with: ".")) }
    private var canSave: Bool {
        !fryer.trimmingCharacters(in: .whitespaces).isEmpty && (!withMeasure || polarValue != nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let banner { ResultBanner(ok: banner.ok, title: banner.title, detail: banner.detail) }

                Field(title: "Friteuse", text: $fryer, placeholder: "ex. Friteuse 1",
                      suggestions: store.recentValues(kind: "frying-oil.check", key: "fryer"))

                Section2(title: "Action") {
                    ChipButton(title: "Contrôle", systemImage: "eye", selected: action == "controle", color: .orange) { action = "controle" }
                    ChipButton(title: "Changement d'huile", systemImage: "arrow.triangle.2.circlepath",
                               selected: action == "changement", color: .orange) { action = "changement" }
                }

                Section2(title: action == "changement" ? "État de l'huile retirée" : "État de l'huile") {
                    ChipButton(title: "Bonne", selected: quality == "bonne", color: Theme.ok) { quality = "bonne" }
                    ChipButton(title: "À surveiller", selected: quality == "a-surveiller", color: .orange) { quality = "a-surveiller" }
                    ChipButton(title: "À changer", selected: quality == "a-changer", color: Theme.alert) { quality = "a-changer" }
                }

                Toggle(isOn: $withMeasure) {
                    Text("Mesure au testeur (% de composés polaires)").font(.headline)
                }
                .toggleStyle(.switch)

                if withMeasure {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(polar.isEmpty ? "—" : "\(polar) %")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(polarValue.map { $0 <= KaribTruck.polarLimitPercent ? Theme.ok : Theme.alert } ?? .secondary)
                            Text("Limite : ≤ \(Fmt.number(String(KaribTruck.polarLimitPercent))) %").font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        NumericKeypad(text: $polar, maxLength: 3).frame(width: 320)
                    }
                }

                Button { save() } label: {
                    Label("Enregistrer", systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(BigButtonStyle(color: .orange))
                .disabled(!canSave)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Huile de friture")
    }

    private func save() {
        let f = fryer.trimmingCharacters(in: .whitespaces)
        let measure = withMeasure ? polarValue : nil
        store.recordFryingOilCheck(fryer: f, action: action, quality: quality,
                                   changed: action == "changement", polarPercent: measure)
        let over = measure.map { $0 > KaribTruck.polarLimitPercent } ?? false
        let needsChange = (quality == "a-changer" || over) && action != "changement"
        banner = (!needsChange,
                  action == "changement" ? "Changement d'huile scellé" : "Contrôle scellé",
                  needsChange ? "Huile à changer avant le prochain service."
                              : "\(f) — \(Fmt.qualityLabel(quality))\(measure.map { " — \(Fmt.number(String($0))) %" } ?? "")")
        needsChange ? Haptics.warning() : Haptics.success()
        polar = ""
    }
}

// MARK: - Non-conformité (incident + action corrective)

struct NonConformityView: View {
    @EnvironmentObject private var store: Store
    let prefilledWhat: String?

    @State private var severity = "majeure"
    @State private var what = ""
    @State private var action = ""
    @State private var banner: (ok: Bool, title: String, detail: String)?

    private let templates = ["Coupure électrique", "Rupture de la chaîne du froid", "Température hors plage",
                             "DLC dépassée", "Réserve d'eau vide ou douteuse", "Nuisibles", "Produit abîmé à réception"]
    private let actions = ["Produits jetés", "Produits déplacés au froid", "Enceinte réglée, recontrôle dans 1 h",
                           "Marchandise refusée", "Fournisseur prévenu", "Réparation demandée", "Nettoyage et désinfection"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let banner { ResultBanner(ok: banner.ok, title: banner.title, detail: banner.detail) }

                Section2(title: "Gravité") {
                    ChipButton(title: "Mineure", selected: severity == "mineure", color: .orange) { severity = "mineure" }
                    ChipButton(title: "Majeure", selected: severity == "majeure", color: Theme.alert) { severity = "majeure" }
                    ChipButton(title: "Critique", selected: severity == "critique", color: .purple) { severity = "critique" }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Constat").font(.headline)
                    FlowLayout {
                        ForEach(templates, id: \.self) { t in
                            ChipButton(title: t, selected: what == t, color: Theme.alert) { what = t }
                        }
                    }
                    TextField("Ce qui s'est passé", text: $what, axis: .vertical)
                        .font(.title3).lineLimit(2...4)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Action corrective").font(.headline)
                    FlowLayout {
                        ForEach(actions, id: \.self) { a in
                            ChipButton(title: a, selected: action.contains(a), color: Theme.ok) { toggleAction(a) }
                        }
                    }
                    TextField("Ce qui a été fait", text: $action, axis: .vertical)
                        .font(.title3).lineLimit(2...4)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                }

                Button { save() } label: {
                    Label("Enregistrer l'incident", systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.alert))
                .disabled(what.trimmingCharacters(in: .whitespaces).isEmpty
                          || action.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Incident")
        .onAppear { if what.isEmpty, let prefilledWhat { what = prefilledWhat } }
    }

    private func toggleAction(_ a: String) {
        var parts = action.components(separatedBy: KaribTruck.listSeparator).filter { !$0.isEmpty }
        if let i = parts.firstIndex(of: a) { parts.remove(at: i) } else { parts.append(a) }
        action = parts.joined(separator: KaribTruck.listSeparator)
    }

    private func save() {
        let w = what.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = action.trimmingCharacters(in: .whitespacesAndNewlines)
        store.recordNonConformity(severity: severity, what: w, action: a)
        banner = (true, "Incident scellé (\(severity))", "\(w) → \(a)")
        Haptics.success()
        what = ""; action = ""
    }
}

// MARK: - Planning des marchés

struct PlanningView: View {
    @EnvironmentObject private var store: Store

    @State private var date = Date()
    @State private var place = ""
    @State private var start = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @State private var end = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
    @State private var banner: (ok: Bool, title: String, detail: String)?

    private static let hm: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "HH:mm"; return f
    }()

    /// Emplacements à venir (date ≥ aujourd'hui), triés par date.
    private var upcoming: [JournalEntry] {
        let today = Fmt.isoDay.string(from: Date())
        return store.entries
            .filter { $0.kind == "market.schedule" && ($0.payload["date"] ?? "") >= today }
            .sorted { ($0.payload["date"] ?? "", $0.payload["slot"] ?? "") < ($1.payload["date"] ?? "", $1.payload["slot"] ?? "") }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let banner { ResultBanner(ok: banner.ok, title: banner.title, detail: banner.detail) }

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jour").font(.headline)
                        DatePicker("", selection: $date, displayedComponents: .date).labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("De").font(.headline)
                        DatePicker("", selection: $start, displayedComponents: .hourAndMinute).labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("À").font(.headline)
                        DatePicker("", selection: $end, displayedComponents: .hourAndMinute).labelsHidden()
                    }
                }
                .environment(\.locale, Locale(identifier: "fr_FR"))

                Field(title: "Emplacement", text: $place, placeholder: "ex. Marché de Fort-de-France",
                      suggestions: store.recentValues(kind: "market.schedule", key: "place"))

                Button { save() } label: {
                    Label("Ajouter au planning", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(BigButtonStyle(color: .purple))
                .disabled(place.trimmingCharacters(in: .whitespaces).isEmpty || end <= start)

                Text("À venir").font(.title2.bold()).padding(.top, 8)
                if upcoming.isEmpty {
                    Text("Aucun emplacement prévu.").foregroundStyle(.secondary)
                }
                ForEach(upcoming, id: \.hash) { e in
                    HStack(spacing: 16) {
                        Image(systemName: "mappin.circle.fill").font(.largeTitle).foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.payload["place"] ?? "").font(.title3.bold())
                            Text("\(Fmt.businessDay(e.payload["date"] ?? "")) · \(e.payload["slot"] ?? "")")
                                .font(.headline).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Planning marchés")
    }

    private func save() {
        let p = place.trimmingCharacters(in: .whitespaces)
        let slot = "\(Self.hm.string(from: start))-\(Self.hm.string(from: end))"
        store.recordMarketSchedule(date: Fmt.isoDay.string(from: date), place: p, slot: slot)
        banner = (true, "Ajouté au planning", "\(Fmt.day(date)) — \(p) — \(slot)")
        Haptics.success()
        place = ""
    }
}

/// Titre + rangée de puces.
struct Section2<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            FlowLayout { content }
        }
    }
}
