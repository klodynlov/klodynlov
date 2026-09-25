import SwiftUI
import KaribTruckCore

/// Checklists ouverture / fermeture / nettoyage : un tap par point, puis signature.
/// Les points non faits sont scellés tels quels (la signature passe en alerte).
struct ChecklistsView: View {
    @EnvironmentObject private var store: Store
    let preselected: String?

    @AppStorage("operatorName") private var operatorName = ""
    @State private var templateID = ""
    @State private var checked: Set<String> = []
    @State private var confirmIncomplete = false
    @State private var banner: (ok: Bool, title: String, detail: String)?

    private var template: ChecklistTemplate? { store.checklists.first { $0.id == templateID } }
    private var missing: [String] { template?.items.filter { !checked.contains($0) } ?? [] }
    private var canSign: Bool {
        template != nil && !operatorName.trimmingCharacters(in: .whitespaces).isEmpty && !checked.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    ForEach(store.checklists) { t in
                        let done = store.lastChecklistToday(t.id) != nil
                        ChipButton(title: t.name,
                                   systemImage: done ? "checkmark.circle.fill" : nil,
                                   selected: t.id == templateID, color: .teal) {
                            select(t.id)
                        }
                    }
                }

                if let banner { ResultBanner(ok: banner.ok, title: banner.title, detail: banner.detail) }

                if let t = template {
                    if let run = store.lastChecklistToday(t.id) {
                        Label("Déjà signée aujourd'hui à \(Fmt.time(run.timestamp)) (\(run.payload["done"] ?? "?")/\(run.payload["total"] ?? "?")) — vous pouvez la refaire.",
                              systemImage: "info.circle")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 10) {
                        ForEach(t.items, id: \.self) { item in
                            ItemRow(title: item, checked: checked.contains(item)) {
                                if checked.contains(item) { checked.remove(item) } else { checked.insert(item) }
                                Haptics.tap()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Opérateur").font(.headline)
                        TextField("Votre prénom", text: $operatorName)
                            .font(.title3)
                            .textInputAutocapitalization(.words)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                    }

                    Button {
                        missing.isEmpty ? sign() : (confirmIncomplete = true)
                    } label: {
                        Label("Signer (\(checked.count)/\(t.items.count))", systemImage: "signature")
                    }
                    .buttonStyle(BigButtonStyle(color: missing.isEmpty ? Theme.ok : Theme.accent))
                    .disabled(!canSign)
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Checklists")
        .onAppear {
            if templateID.isEmpty {
                select(preselected
                       ?? store.checklists.first { store.lastChecklistToday($0.id) == nil }?.id
                       ?? store.checklists.first?.id ?? "")
            }
        }
        .confirmationDialog("\(missing.count) point\(missing.count > 1 ? "s" : "") non fait\(missing.count > 1 ? "s" : "")",
                            isPresented: $confirmIncomplete, titleVisibility: .visible) {
            Button("Signer quand même (scellé en alerte)", role: .destructive) { sign() }
            Button("Continuer la checklist", role: .cancel) {}
        } message: {
            Text(missing.joined(separator: "\n"))
        }
    }

    private func select(_ id: String) {
        templateID = id
        checked = []
        banner = nil
    }

    private func sign() {
        guard let t = template else { return }
        let miss = missing
        store.recordChecklistRun(checklist: t.id, done: t.items.count - miss.count,
                                 total: t.items.count,
                                 operator: operatorName.trimmingCharacters(in: .whitespaces),
                                 missing: miss)
        banner = miss.isEmpty
            ? (true, "\(t.name) signée", "\(t.items.count)/\(t.items.count) — \(operatorName)")
            : (false, "\(t.name) signée incomplète", "Non fait : \(miss.joined(separator: ", "))")
        miss.isEmpty ? Haptics.success() : Haptics.warning()
        checked = []
    }
}

private struct ItemRow: View {
    let title: String
    let checked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 34))
                    .foregroundStyle(checked ? Theme.ok : .secondary)
                Text(title)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 68)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}
