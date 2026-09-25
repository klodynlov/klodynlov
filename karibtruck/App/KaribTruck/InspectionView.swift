import SwiftUI
import KaribTruckCore

/// Dossier de contrôle : choisir une période, voir la synthèse, exporter PDF/CSV.
struct InspectionView: View {
    @EnvironmentObject private var store: Store

    enum Period: String, CaseIterable, Identifiable {
        case week = "7 derniers jours", month = "30 derniers jours", thisMonth = "Ce mois-ci", custom = "Personnalisée"
        var id: String { rawValue }
    }

    @State private var period: Period = .month
    @State private var customFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var customTo = Date()
    @State private var pdfURL: URL?
    @State private var csvURL: URL?
    @State private var error: String?

    /// Bornes `[début, fin[` en heure locale (journées entières).
    private var range: (Date, Date) {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        switch period {
        case .week: return (cal.date(byAdding: .day, value: -7, to: tomorrow)!, tomorrow)
        case .month: return (cal.date(byAdding: .day, value: -30, to: tomorrow)!, tomorrow)
        case .thisMonth:
            return (cal.date(from: cal.dateComponents([.year, .month], from: Date()))!, tomorrow)
        case .custom:
            let a = cal.startOfDay(for: min(customFrom, customTo))
            let b = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: max(customFrom, customTo)))!
            return (a, b)
        }
    }

    private var entries: [JournalEntry] { store.entries(from: range.0, to: range.1) }
    private var periodKey: String { "\(range.0.timeIntervalSince1970)-\(range.1.timeIntervalSince1970)-\(store.entries.count)" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Section2(title: "Période") {
                    ForEach(Period.allCases) { p in
                        ChipButton(title: p.rawValue, selected: period == p, color: .indigo) { period = p }
                    }
                }
                if period == .custom {
                    HStack(spacing: 24) {
                        DatePicker("Du", selection: $customFrom, displayedComponents: .date)
                        DatePicker("Au", selection: $customTo, displayedComponents: .date)
                    }
                    .font(.headline)
                    .environment(\.locale, Locale(identifier: "fr_FR"))
                    .frame(maxWidth: 600)
                }

                summary

                if let error { Text(error).foregroundStyle(Theme.alert) }

                HStack(spacing: 16) {
                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            Label("Exporter le PDF", systemImage: "doc.richtext.fill")
                                .frame(maxWidth: .infinity, minHeight: Theme.bigButtonHeight)
                        }
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.indigo))
                    }
                    if let csvURL {
                        ShareLink(item: csvURL) {
                            Label("CSV (comptable / tableur)", systemImage: "tablecells")
                                .frame(maxWidth: .infinity, minHeight: Theme.bigButtonHeight)
                        }
                        .font(.title3.bold())
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dossier de contrôle")
        .task(id: periodKey) { build() }
    }

    private var summary: some View {
        let es = entries
        let alerts = es.filter { $0.payload["status"] == "alert" }
        var counts: [String: Int] = [:]
        for e in es { counts[e.kind, default: 0] += 1 }
        return VStack(alignment: .leading, spacing: 14) {
            Text("Du \(Fmt.day(range.0)) au \(Fmt.day(range.1.addingTimeInterval(-1)))").font(.title2.bold())
            HStack(spacing: 14) {
                SummaryTile(value: "\(es.count)", label: "enregistrements", color: .indigo)
                SummaryTile(value: "\(alerts.count)", label: "alertes", color: alerts.isEmpty ? Theme.ok : Theme.alert)
                SummaryTile(value: store.isValid ? "✓" : "✗", label: store.isValid ? "journal vérifié" : "journal COMPROMIS",
                            color: store.isValid ? Theme.ok : Theme.alert)
            }
            FlowLayout {
                ForEach(counts.keys.sorted(), id: \.self) { k in
                    Label("\(Fmt.kindLabel(k)) : \(counts[k]!)", systemImage: Fmt.kindIcon(k))
                        .font(.headline)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(Color(.secondarySystemGroupedBackground)))
                }
            }
            Text("Empreinte du journal : \(store.headHash)")
                .font(.caption.monospaced()).foregroundStyle(.secondary)
        }
    }

    private func build() {
        error = nil
        let (from, to) = range
        let stamp = Fmt.isoDay.string(from: from) + "_" + Fmt.isoDay.string(from: to.addingTimeInterval(-1))
        let dir = FileManager.default.temporaryDirectory
        let pdf = dir.appendingPathComponent("KaribTruck-dossier-controle_\(stamp).pdf")
        let csv = dir.appendingPathComponent("KaribTruck-journal_\(stamp).csv")
        do {
            let report = InspectionPDF(entries: entries, from: from, to: to,
                                       totalEntries: store.entries.count,
                                       headHash: store.headHash, isValid: store.isValid,
                                       enclosures: store.enclosures,
                                       photoCheck: { store.photoMatches($0) })
            try report.render().write(to: pdf, options: .atomic)
            try store.exportCSV(entries).data(using: .utf8)!.write(to: csv, options: .atomic)
            pdfURL = pdf; csvURL = csv
        } catch {
            self.error = "Export impossible : \(error.localizedDescription)"
        }
    }
}

private struct SummaryTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.headline).foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
    }
}
