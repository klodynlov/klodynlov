import SwiftUI
import KaribTruckCore

/// Écrans de l'app, accessibles depuis les tuiles de l'accueil.
enum Screen: Hashable {
    case temperature(String?)          // enceinte présélectionnée
    case checklists(String?)           // checklist présélectionnée
    case reception
    case frying
    case nonConformity(String?)        // constat prérempli (ex. relevé en alerte)
    case planning
    case meat(MeatTab)
    case history
    case inspection
}

/// Accueil : l'état du jour en un coup d'œil, puis une tuile par geste.
struct HomeView: View {
    @EnvironmentObject private var store: Store
    @State private var path: [Screen] = []

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 18)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let w = store.storageWarning {
                        Label(w, systemImage: "externaldrive.badge.exclamationmark")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.alert.opacity(0.15)))
                    }
                    today
                    Text("Au quotidien").font(.title3.bold()).foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: 18) {
                        Tile(title: "Températures", icon: "thermometer.medium", color: .blue) {
                            path.append(.temperature(nil))
                        }
                        Tile(title: "Checklists", icon: "checklist", color: .teal) {
                            path.append(.checklists(nil))
                        }
                        Tile(title: "Viandes", icon: "fork.knife", color: .pink) {
                            path.append(.meat(.reception))
                        }
                        Tile(title: "Huile de friture", icon: "drop", color: .yellow) {
                            path.append(.frying)
                        }
                    }
                    Text("Au besoin").font(.title3.bold()).foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: 18) {
                        Tile(title: "Incident", icon: "exclamationmark.bubble", color: .red) {
                            path.append(.nonConformity(nil))
                        }
                        Tile(title: "Réception (autres)", icon: "shippingbox", color: .brown) {
                            path.append(.reception)
                        }
                        Tile(title: "Planning marchés", icon: "calendar", color: .purple) {
                            path.append(.planning)
                        }
                        Tile(title: "Dossier de contrôle", icon: "doc.richtext", color: .indigo) {
                            path.append(.inspection)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KaribTruck")
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .temperature(let id): TemperatureView(preselected: id, path: $path)
                case .checklists(let id): ChecklistsView(preselected: id)
                case .reception: ReceptionView()
                case .frying: FryingOilView()
                case .nonConformity(let what): NonConformityView(prefilledWhat: what)
                case .planning: PlanningView()
                case .meat(let tab): MeatView(tab: tab, path: $path)
                case .history: HistoryView()
                case .inspection: InspectionView()
                }
            }
        }
    }

    // MARK: - Aujourd'hui

    private var today: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 20) {
                Text(Fmt.longDay(Date())).font(.title2.bold())
                Spacer()
                let n = store.alertsToday.count
                if n > 0 {
                    Label("\(n) alerte\(n > 1 ? "s" : "") aujourd'hui", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline).foregroundStyle(Theme.alert)
                }
                Button { path.append(.history) } label: {
                    Label("Historique", systemImage: "clock.arrow.circlepath").font(.headline)
                }
                IntegrityBadge()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.enclosures) { enc in
                        let last = store.lastReadingToday(enc.id)
                        StatusCard(
                            title: enc.name,
                            value: last.map { "\(Fmt.number($0.payload["celsius"])) °C" } ?? "À relever",
                            caption: last.map { "à \(Fmt.time($0.timestamp)) · \(Fmt.ruleLabel(enc.threshold))" }
                                ?? Fmt.ruleLabel(enc.threshold),
                            state: last == nil ? .todo : (last?.payload["status"] == "alert" ? .alert : .ok)
                        ) { path.append(.temperature(enc.id)) }
                    }
                    let open = store.openMeatLots
                    let expired = open.filter { $0.isExpired(on: store.todayDay) }.count
                    StatusCard(
                        title: "Lots viande",
                        value: "\(open.count) en cours",
                        caption: expired > 0 ? "\(expired) DLC dépassée\(expired > 1 ? "s" : "") — à jeter" : "traçabilité",
                        state: open.isEmpty ? .todo : (expired > 0 ? .alert : .ok)
                    ) { path.append(.meat(expired > 0 ? .lots : .preparation)) }
                    ForEach(store.checklists.filter { $0.id != "nettoyage" }) { t in
                        let run = store.lastChecklistToday(t.id)
                        StatusCard(
                            title: t.name,
                            value: run == nil ? "À faire" : "\(run!.payload["done"] ?? "?")/\(run!.payload["total"] ?? "?")",
                            caption: run.map { "signée à \(Fmt.time($0.timestamp))" } ?? "checklist",
                            state: run == nil ? .todo : (run?.payload["status"] == "alert" ? .alert : .ok)
                        ) { path.append(.checklists(t.id)) }
                    }
                }
            }
        }
    }
}

// MARK: - Composants de l'accueil

private struct Tile: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(height: 48, alignment: .leading)
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: Theme.tileCorner).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}

private struct StatusCard: View {
    enum State { case ok, alert, todo }
    let title: String
    let value: String
    let caption: String
    let state: State
    let action: () -> Void

    private var color: Color {
        switch state {
        case .ok: return Theme.ok
        case .alert: return Theme.alert
        case .todo: return .secondary
        }
    }
    private var icon: String {
        switch state {
        case .ok: return "checkmark.circle.fill"
        case .alert: return "exclamationmark.triangle.fill"
        case .todo: return "circle.dashed"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon).font(.headline).foregroundStyle(color)
                Text(value).font(.title.bold()).foregroundStyle(.primary)
                Text(caption).font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(width: 210, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(state == .todo ? Color.clear : color, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

/// Pastille d'intégrité du journal ; touche = revérification complète.
struct IntegrityBadge: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        Button { store.reverify(); Haptics.tap() } label: {
            Label(store.isValid ? "Journal vérifié" : "Journal COMPROMIS",
                  systemImage: store.isValid ? "lock.shield.fill" : "xmark.shield.fill")
                .font(.headline)
                .foregroundStyle(store.isValid ? Theme.ok : Theme.alert)
        }
    }
}
