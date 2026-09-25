import SwiftUI
import KaribTruckCore

/// Historique scellé, filtrable par type, groupé par jour (heure locale).
struct HistoryView: View {
    @EnvironmentObject private var store: Store
    @State private var kind: String? = nil
    @State private var selected: JournalEntry?

    private let kinds = ["enclosure.reading", "checklist.run", "reception",
                         "frying-oil.check", "nonconformity", "market.schedule"]

    private var groups: [(day: Date, entries: [JournalEntry])] {
        let cal = Calendar.current
        let filtered = store.entries.reversed().filter { kind == nil || $0.kind == kind }
        var out: [(Date, [JournalEntry])] = []
        for e in filtered {
            guard let d = Fmt.date(e.timestamp) else { continue }
            let day = cal.startOfDay(for: d)
            if let last = out.last, last.0 == day { out[out.count - 1].1.append(e) } else { out.append((day, [e])) }
        }
        return out.map { (day: $0.0, entries: $0.1) }
    }

    var body: some View {
        List {
            Section {
                FlowLayout {
                    ChipButton(title: "Tout", selected: kind == nil, color: .gray) { kind = nil }
                    ForEach(kinds, id: \.self) { k in
                        ChipButton(title: Fmt.kindLabel(k), systemImage: Fmt.kindIcon(k),
                                   selected: kind == k, color: .gray) { kind = k }
                    }
                }
                .padding(.vertical, 6)
            }
            ForEach(groups, id: \.day) { g in
                Section(Fmt.longDay(g.day) + " " + Fmt.day(g.day).suffix(4)) {
                    ForEach(g.entries, id: \.hash) { e in
                        Button { selected = e } label: { EntryRow(entry: e) }
                            .buttonStyle(.plain)
                    }
                }
            }
            if groups.isEmpty {
                Text("Rien d'enregistré pour l'instant.").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Historique (\(store.entries.count))")
        .sheet(item: Binding(get: { selected.map(IdentifiedEntry.init) },
                             set: { selected = $0?.entry })) { item in
            EntryDetail(entry: item.entry)
        }
    }
}

private struct IdentifiedEntry: Identifiable {
    let entry: JournalEntry
    var id: String { entry.hash }
}

struct EntryRow: View {
    @EnvironmentObject private var store: Store
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: Fmt.kindIcon(entry.kind))
                .font(.title2)
                .frame(width: 36)
                .foregroundStyle(entry.payload["status"] == "alert" ? Theme.alert : .accentColor)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(Fmt.kindLabel(entry.kind)).font(.headline)
                    if entry.payload["status"] == "alert" {
                        Text("ALERTE").font(.caption.bold()).foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.alert))
                    }
                }
                Text(Fmt.summary(entry, enclosures: store.enclosures))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(Fmt.time(entry.timestamp)).font(.headline.monospacedDigit())
                Text("#\(entry.index) · \(entry.hash.prefix(8))").font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

/// Détail d'une entrée : tous les champs scellés + empreintes (+ photo).
private struct EntryDetail: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry

    var body: some View {
        NavigationStack {
            List {
                Section("Enregistrement") {
                    LabeledContent("Type", value: Fmt.kindLabel(entry.kind))
                    LabeledContent("Horodatage", value: Fmt.dateTime(entry.timestamp))
                    LabeledContent("N° dans le journal", value: "\(entry.index)")
                }
                Section("Contenu scellé") {
                    ForEach(entry.payload.keys.sorted(), id: \.self) { k in
                        LabeledContent(k, value: entry.payload[k] ?? "")
                    }
                }
                if let sha = entry.payload["photo_sha256"] {
                    Section("Photo de l'étiquette") {
                        if let img = UIImage(contentsOfFile: store.photoURL(sha).path) {
                            Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 360)
                        }
                        Label(store.photoMatches(sha) ? "Photo intacte (empreinte conforme)" : "Photo absente ou modifiée",
                              systemImage: store.photoMatches(sha) ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .foregroundStyle(store.photoMatches(sha) ? Theme.ok : Theme.alert)
                    }
                }
                Section("Preuve d'intégrité") {
                    Text("Empreinte : \(entry.hash)").font(.caption.monospaced())
                    Text("Précédente : \(entry.previousHash)").font(.caption.monospaced())
                }
            }
            .navigationTitle(Fmt.kindLabel(entry.kind))
            .toolbar { Button("Fermer") { dismiss() } }
        }
    }
}
