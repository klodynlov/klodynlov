import SwiftUI
import KaribTruckCore

/// Relevé de température : enceinte (1 tap) → valeur au pavé → Enregistrer.
/// En cas d'alerte, l'action corrective est à un tap (fiche incident préremplie).
struct TemperatureView: View {
    @EnvironmentObject private var store: Store
    let preselected: String?
    @Binding var path: [Screen]

    @State private var enclosureID: String = ""
    @State private var input: String = ""
    @State private var last: (ok: Bool, title: String, detail: String, alertText: String?)?

    private var enclosure: Enclosure? { store.enclosures.first { $0.id == enclosureID } }
    private var value: Double? { Double(input.replacingOccurrences(of: ",", with: ".")) }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 820
            ScrollView {
                Group {
                    if wide {
                        HStack(alignment: .top, spacing: 28) {
                            leftColumn.frame(maxWidth: .infinity)
                            keypadColumn.frame(width: 380)
                        }
                    } else {
                        VStack(spacing: 24) { leftColumn; keypadColumn }
                    }
                }
                .padding(24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Températures")
        .onAppear {
            if enclosureID.isEmpty {
                // Présélection : l'enceinte demandée, sinon la 1re pas encore relevée aujourd'hui.
                enclosureID = preselected
                    ?? store.enclosures.first { store.lastReadingToday($0.id) == nil }?.id
                    ?? store.enclosures.first?.id ?? ""
            }
        }
    }

    // MARK: - Colonne gauche : enceintes, valeur, résultat

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                ForEach(store.enclosures) { enc in
                    Button {
                        enclosureID = enc.id; Haptics.tap()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(enc.name).font(.title2.bold())
                            Text(Fmt.ruleLabel(enc.threshold)).font(.headline)
                            if let r = store.lastReadingToday(enc.id) {
                                Text("Dernier : \(Fmt.number(r.payload["celsius"])) °C à \(Fmt.time(r.timestamp))")
                                    .font(.caption)
                            } else {
                                Text("Pas encore relevé aujourd'hui").font(.caption)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
                        .foregroundStyle(enc.id == enclosureID ? .white : .primary)
                        .background(RoundedRectangle(cornerRadius: 18)
                            .fill(enc.id == enclosureID ? Color.blue : Color(.secondarySystemGroupedBackground)))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(input.isEmpty ? "—" : input)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(input.isEmpty ? .secondary : .primary)
                Text("°C").font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if let enc = enclosure, let v = value {
                    let ok = enc.threshold.evaluate(v) == .ok
                    Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(ok ? Theme.ok : Theme.alert)
                }
            }
            .padding(.horizontal, 8)

            if let last {
                ResultBanner(ok: last.ok, title: last.title, detail: last.detail)
                if let text = last.alertText {
                    Button {
                        path.append(.nonConformity(text))
                    } label: {
                        Label("Déclarer l'action corrective", systemImage: "exclamationmark.bubble.fill")
                    }
                    .buttonStyle(BigButtonStyle(color: Theme.alert))
                }
            }
        }
    }

    // MARK: - Pavé numérique + enregistrer

    private var keypadColumn: some View {
        VStack(spacing: 16) {
            NumericKeypad(text: $input, allowsNegative: true)
            Button { save() } label: {
                Label("Enregistrer", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(BigButtonStyle(color: .blue))
            .disabled(value == nil || enclosure == nil)
        }
    }

    private func save() {
        guard let enc = enclosure, let v = value else { return }
        let status = store.recordTemperature(enclosureID: enc.id, celsius: v)
        let shown = Fmt.number(String(v))
        let ok = status == .ok
        last = (ok: ok,
                title: ok ? "\(enc.name) conforme" : "ALERTE \(enc.name)",
                detail: "\(shown) °C — limite \(Fmt.ruleLabel(enc.threshold)) — scellé à \(Fmt.time(Store.iso.string(from: Date())))",
                alertText: ok ? nil : "\(enc.name) à \(shown) °C (limite \(Fmt.ruleLabel(enc.threshold)))")
        ok ? Haptics.success() : Haptics.warning()
        input = ""
        // Enchaîne sur l'enceinte suivante pas encore relevée aujourd'hui.
        if ok, let next = store.enclosures.first(where: { store.lastReadingToday($0.id) == nil }) {
            enclosureID = next.id
        }
    }
}

/// Gros pavé numérique (virgule française, signe moins, effacement).
struct NumericKeypad: View {
    @Binding var text: String
    var allowsNegative = false
    var maxLength = 6

    private let rows: [[String]] = [["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"], ["±", "0", ","]]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
            Button { if !text.isEmpty { text.removeLast() }; Haptics.tap() } label: {
                Label("Effacer", systemImage: "delete.left.fill")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.tertiarySystemFill)))
        }
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        let disabled = key == "±" && !allowsNegative
        Button { press(key) } label: {
            Text(key == "±" ? "−" : key)
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 76)
                .foregroundStyle(disabled ? Color.secondary.opacity(0.4) : .primary)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1))
        .disabled(disabled)
    }

    private func press(_ key: String) {
        Haptics.tap()
        switch key {
        case "±":
            if text.hasPrefix("-") { text.removeFirst() } else { text = "-" + text }
        case ",":
            if !text.contains(",") { text += text.isEmpty || text == "-" ? "0," : "," }
        default:
            guard text.filter(\.isNumber).count < maxLength else { return }
            if text == "0" { text = key } else if text == "-0" { text = "-" + key } else { text += key }
        }
    }
}
