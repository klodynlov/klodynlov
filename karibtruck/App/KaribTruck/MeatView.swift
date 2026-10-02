import SwiftUI
import UIKit
import KaribTruckCore

/// Traçabilité viande : réception → fournées → clôture, rappel, affiche client.
enum MeatTab: String, CaseIterable, Hashable, Identifiable {
    case reception = "Réception", preparation = "Fournée", lots = "Lots en cours",
         recall = "Rappel", board = "Affiche origine"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .reception: return "shippingbox.fill"
        case .preparation: return "flame.fill"
        case .lots: return "tray.full.fill"
        case .recall: return "magnifyingglass"
        case .board: return "megaphone.fill"
        }
    }
}

struct MeatView: View {
    @State var tab: MeatTab
    @Binding var path: [Screen]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MeatTab.allCases) { t in
                        ChipButton(title: t.rawValue, systemImage: t.icon, selected: tab == t, color: .pink) { tab = t }
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 12)
            }
            Divider()
            switch tab {
            case .reception: MeatReceptionForm(path: $path)
            case .preparation: MeatPreparationForm()
            case .lots: MeatLotsList()
            case .recall: MeatRecallView()
            case .board: OriginBoardView()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Viandes")
    }
}

// MARK: - Réception d'un lot

private struct MeatReceptionForm: View {
    @EnvironmentObject private var store: Store
    @Binding var path: [Screen]

    @State private var species: MeatSpecies = .volaille
    @State private var state: MeatState = .fraiche
    @State private var product = ""
    @State private var supplier = ""
    @State private var lot = ""
    @State private var dlc = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    @State private var agrement = ""
    @State private var sameCountry = true
    @State private var born = "France"
    @State private var raised = "France"
    @State private var slaughtered = "France"
    @State private var celsius = ""
    @State private var photo: UIImage?
    @State private var photoData: Data?
    @State private var prefillNote: String?
    @State private var result: (ok: Bool, title: String, detail: String, lotID: String?, incident: String?)?
    @State private var error: String?

    private var threshold: Threshold { MeatRules.receptionThreshold(species: species, state: state) }
    private var value: Double? { Double(celsius.replacingOccurrences(of: ",", with: ".")) }
    private var origin: MeatOrigin {
        sameCountry
            ? MeatOrigin(born: raised, raised: raised, slaughtered: raised)
            : MeatOrigin(born: species.tracksBirth ? born : nil, raised: raised, slaughtered: slaughtered)
    }
    private var dlcExpired: Bool { Calendar.current.startOfDay(for: dlc) < Calendar.current.startOfDay(for: Date()) }
    private func blank(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespaces).isEmpty }

    private var labelDone: Bool { !blank(product) && !blank(supplier) && !blank(lot) }
    private var originDone: Bool { !blank(raised) && (sameCountry || !blank(slaughtered)) }
    private var missing: [String] {
        var m: [String] = []
        if blank(product) { m.append("produit") }
        if blank(supplier) { m.append("fournisseur") }
        if blank(lot) { m.append("n° de lot") }
        if !originDone { m.append("origine") }
        if value == nil { m.append("température") }
        return m
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let r = result { resultBlock(r) }

                StepCard(number: 1, title: "Quelle viande ?", done: true) {
                    HStack(spacing: 12) {
                        ForEach(MeatSpecies.allCases, id: \.self) { s in
                            SpeciesTile(species: s, selected: species == s) { select(s) }
                        }
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(MeatState.allCases, id: \.self) { st in
                            ChipButton(title: st.label, selected: state == st, color: .pink) { state = st }
                        }
                    }
                }

                StepCard(number: 2, title: "L'étiquette", done: labelDone) {
                    PhotoCapture(photo: $photo, photoData: $photoData, color: .pink)
                    Field(title: "Produit / morceau", text: $product, placeholder: "ex. cuisses, échine, paleron…",
                          suggestions: store.recentValues(kind: "meat.reception", key: "product",
                                                          matching: ["species": species.rawValue]))
                    Field(title: "Fournisseur", text: $supplier, placeholder: "ex. Antilles Frais",
                          suggestions: store.recentValues(kind: "meat.reception", key: "supplier"))
                    HStack(alignment: .top, spacing: 18) {
                        Field(title: "N° de lot", text: $lot, placeholder: "sur l'étiquette", suggestions: [])
                        Field(title: "Estampille (ovale)", text: $agrement, placeholder: "FR 97.213.001 CE",
                              suggestions: [])
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DLC").font(.headline)
                        HStack(spacing: 10) {
                            ForEach([1, 3, 5, 7], id: \.self) { d in
                                ChipButton(title: "J+\(d)", selected: Calendar.current.isDate(
                                    dlc, inSameDayAs: Calendar.current.date(byAdding: .day, value: d, to: Date())!),
                                           color: .pink) {
                                    dlc = Calendar.current.date(byAdding: .day, value: d, to: Date())!
                                }
                            }
                            DatePicker("", selection: $dlc, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "fr_FR"))
                                .scaleEffect(1.2).padding(.leading, 12)
                        }
                        if dlcExpired {
                            Label("DLC dépassée : refuser la marchandise.", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline).foregroundStyle(Theme.alert)
                        }
                    }
                }

                StepCard(number: 3, title: "L'origine", done: originDone) {
                    if let prefillNote {
                        Label(prefillNote, systemImage: "arrow.uturn.backward.circle")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Toggle(isOn: $sameCountry) {
                        Text(species.tracksBirth ? "Né, élevé et abattu dans le même pays" : "Élevé et abattu dans le même pays")
                            .font(.headline)
                    }
                    .toggleStyle(.switch)
                    if sameCountry {
                        CountryPicker(title: "Pays", value: $raised)
                    } else {
                        if species.tracksBirth { CountryPicker(title: "Né", value: $born) }
                        CountryPicker(title: "Élevé", value: $raised)
                        CountryPicker(title: "Abattu", value: $slaughtered)
                    }
                    Label("Affiché aux clients : « \(origin.label(for: species)) »", systemImage: "megaphone.fill")
                        .font(.headline).foregroundStyle(.pink)
                    if !species.originDisplayRequired {
                        Text("Le cabri n'est pas visé par l'obligation d'affichage ; l'origine reste tracée.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                StepCard(number: 4, title: "La température", done: value != nil) {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sonde dans le produit. Limite : \(Fmt.ruleLabel(threshold))").font(.headline)
                            HStack(alignment: .firstTextBaseline) {
                                Text(celsius.isEmpty ? "—" : celsius)
                                    .font(.system(size: 72, weight: .bold, design: .rounded)).monospacedDigit()
                                    .foregroundStyle(celsius.isEmpty ? .tertiary : .primary)
                                Text("°C").font(.title).foregroundStyle(.secondary)
                                if let v = value {
                                    let ok = threshold.evaluate(v) == .ok
                                    Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .font(.system(size: 40)).foregroundStyle(ok ? Theme.ok : Theme.alert)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        NumericKeypad(text: $celsius, allowsNegative: true).frame(width: 300)
                    }
                }

                if let error { Text(error).font(.headline).foregroundStyle(Theme.alert) }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            SaveBar(title: "Enregistrer le lot", systemImage: "square.and.arrow.down.fill", color: .pink,
                    missing: missing) { save() }
        }
        .onAppear { if product.isEmpty && supplier.isEmpty { select(species) } }
    }

    @ViewBuilder
    private func resultBlock(_ r: (ok: Bool, title: String, detail: String, lotID: String?, incident: String?)) -> some View {
        ResultBanner(ok: r.ok, title: r.title, detail: r.detail)
        if !r.ok, let id = r.lotID {
            HStack(spacing: 14) {
                Button { refuse(id) } label: { Label("Refuser le lot", systemImage: "xmark.bin.fill") }
                    .buttonStyle(BigButtonStyle(color: Theme.alert))
                if let text = r.incident {
                    Button { path.append(.nonConformity(text)) } label: {
                        Label("Déclarer un incident", systemImage: "exclamationmark.bubble.fill")
                    }
                    .buttonStyle(BigButtonStyle(color: .orange))
                }
            }
        }
    }

    /// Choisir l'espèce reprend fournisseur, estampille et origine du dernier
    /// lot de cette espèce (le même fournisseur revient presque toujours).
    private func select(_ s: MeatSpecies) {
        species = s
        Haptics.tap()
        guard let last = store.meatLots.last(where: { $0.species == s }) else {
            prefillNote = nil
            return
        }
        let p = last.reception.payload
        raised = p["raised"] ?? raised
        slaughtered = p["slaughtered"] ?? slaughtered
        born = p["born"] ?? raised
        sameCountry = raised == slaughtered && (!s.tracksBirth || born == raised)
        if blank(supplier) { supplier = p["supplier"] ?? "" }
        if blank(agrement) { agrement = p["agrement"] ?? "" }
        prefillNote = "Repris du dernier lot (\(Fmt.dateTime(last.reception.timestamp))) — vérifiez l'étiquette."
    }

    private func save() {
        error = nil
        guard let v = value else { return }
        var sha: String?
        if let data = photoData {
            do { sha = try store.savePhoto(data) } catch {
                self.error = "Photo non enregistrée : \(error.localizedDescription)"
                return
            }
        }
        do {
            let p = product.trimmingCharacters(in: .whitespaces)
            let lotRef = lot.trimmingCharacters(in: .whitespaces)
            let r = try store.recordMeatReception(species: species, state: state, product: p,
                                                  supplier: supplier.trimmingCharacters(in: .whitespaces),
                                                  lot: lotRef, dlc: Fmt.isoDay.string(from: dlc),
                                                  agrement: agrement, origin: origin, celsius: v, photoSHA256: sha)
            let shown = Fmt.number(String(v))
            let ok = r.status == .ok && !dlcExpired
            let what = Fmt.meatTitle(species: species, state: state, product: p)
            result = (ok: ok,
                      title: ok ? "Lot enregistré : \(p)" : "Lot à refuser : \(p)",
                      detail: "\(shown) °C (limite \(Fmt.ruleLabel(threshold))) — \(origin.label(for: species))\(dlcExpired ? " — DLC dépassée" : "")",
                      lotID: r.lotID,
                      incident: ok ? nil : "Réception \(what), lot \(lotRef) : \(shown) °C (limite \(Fmt.ruleLabel(threshold)))\(dlcExpired ? ", DLC dépassée" : "")")
            ok ? Haptics.success() : Haptics.warning()
            product = ""; lot = ""; celsius = ""; photo = nil; photoData = nil
        } catch {
            self.error = Fmt.meatError(error, store: store)
        }
    }

    private func refuse(_ id: String) {
        do {
            try store.closeMeatLot(id, reason: .jete, note: "Refusé à la réception")
            result = (ok: true, title: "Lot refusé et clos", detail: "Il ne sera pas proposé dans les fournées.",
                      lotID: nil, incident: nil)
            Haptics.success()
        } catch {
            self.error = Fmt.meatError(error, store: store)
        }
    }
}

/// Grosse tuile d'espèce (emoji + nom).
private struct SpeciesTile: View {
    let species: MeatSpecies
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(Fmt.speciesEmoji(species)).font(.system(size: 44))
                Text(species == .ovin ? "Mouton" : species.label).font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .foregroundStyle(selected ? .white : .primary)
            .background(RoundedRectangle(cornerRadius: 18).fill(selected ? Color.pink : Color(.tertiarySystemFill)))
        }
        .buttonStyle(.plain)
    }
}

/// Choix d'un pays : puces des pays courants + saisie libre.
private struct CountryPicker: View {
    let title: String
    @Binding var value: String

    private static let common = ["France", "Brésil", "Espagne", "Pays-Bas", "Irlande", "Pologne", "Allemagne",
                                 "Belgique", "Italie", "Royaume-Uni", "Uruguay", "Argentine", "Nouvelle-Zélande"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline).frame(width: 70, alignment: .leading)
                TextField("Autre pays", text: $value)
                    .font(.title3)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemFill)))
                    .frame(maxWidth: 320)
            }
            FlowLayout(spacing: 8) {
                ForEach(Self.common, id: \.self) { c in
                    ChipButton(title: c, selected: value == c, color: .pink) { value = c }
                }
            }
        }
    }
}

// MARK: - Fournée (préparation liée aux lots)

private struct MeatPreparationForm: View {
    @EnvironmentObject private var store: Store
    @AppStorage("operatorName") private var operatorName = ""

    @State private var name = ""
    @State private var selected: Set<String> = []
    @State private var dlcDays = 0
    @State private var banner: (ok: Bool, title: String, detail: String)?
    @State private var error: String?

    private var lots: [MeatLot] { store.openMeatLots.reversed() }
    private var missing: [String] {
        var m: [String] = []
        if name.trimmingCharacters(in: .whitespaces).isEmpty { m.append("nom de la préparation") }
        if selected.isEmpty { m.append("au moins un lot") }
        if operatorName.trimmingCharacters(in: .whitespaces).isEmpty { m.append("opérateur") }
        return m
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let banner { ResultBanner(ok: banner.ok, title: banner.title, detail: banner.detail) }

                StepCard(number: 1, title: "Quelle préparation ?", done: !name.trimmingCharacters(in: .whitespaces).isEmpty) {
                    Field(title: "", text: $name, placeholder: "ex. Colombo de poulet",
                          suggestions: store.recentValues(kind: "meat.preparation", key: "name", limit: 8))
                }

                StepCard(number: 2, title: "Avec quels lots ?", done: !selected.isEmpty) {
                    if lots.isEmpty {
                        Text("Aucun lot en cours : enregistrez d'abord une réception.").foregroundStyle(.secondary)
                    }
                    ForEach(MeatSpecies.allCases, id: \.self) { sp in
                        let group = lots.filter { $0.species == sp }
                        if !group.isEmpty {
                            Text("\(Fmt.speciesEmoji(sp)) \(sp.label)").font(.headline).padding(.top, 4)
                            ForEach(group) { lot in
                                let expired = lot.isExpired(on: store.todayDay)
                                Button {
                                    guard !expired else { return }
                                    if selected.contains(lot.id) { selected.remove(lot.id) } else { selected.insert(lot.id) }
                                    Haptics.tap()
                                } label: {
                                    LotRow(lot: lot, checked: selected.contains(lot.id), expired: expired)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                StepCard(number: 3, title: "À consommer jusqu'au", done: true) {
                    FlowLayout {
                        ForEach(0...3, id: \.self) { d in
                            ChipButton(title: d == 0 ? "Aujourd'hui" : "J+\(d)", selected: dlcDays == d, color: .pink) { dlcDays = d }
                        }
                    }
                    Field(title: "Préparé par", text: $operatorName, placeholder: "Votre prénom", suggestions: [])
                }

                if let error { Text(error).font(.headline).foregroundStyle(Theme.alert) }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            SaveBar(title: "Enregistrer la fournée (\(selected.count) lot\(selected.count > 1 ? "s" : ""))",
                    systemImage: "flame.fill", color: .pink, missing: missing) { save() }
        }
        .onChange(of: name) { reuseLots(for: $0) }
    }

    /// Préparation déjà faite : pré-sélectionne, pour chaque espèce utilisée
    /// la dernière fois, le seul lot en cours de cette espèce (s'il n'y en a qu'un).
    private func reuseLots(for name: String) {
        guard let last = store.entries.last(where: { $0.kind == "meat.preparation" && $0.payload["name"] == name })
        else { return }
        let species = Set(KaribTruck.lotIDs(of: last).compactMap { store.meatLot($0)?.species })
        for sp in species {
            let candidates = lots.filter { $0.species == sp && !$0.isExpired(on: store.todayDay) }
            if candidates.count == 1 { selected.insert(candidates[0].id) }
        }
    }

    private func save() {
        error = nil
        let n = name.trimmingCharacters(in: .whitespaces)
        let dlc = Calendar.current.date(byAdding: .day, value: dlcDays, to: Date())!
        // Ordre stable : celui de la liste affichée.
        let ids = lots.map(\.id).filter(selected.contains)
        do {
            try store.recordMeatPreparation(name: n, lots: ids, dlc: Fmt.isoDay.string(from: dlc),
                                            operator: operatorName.trimmingCharacters(in: .whitespaces))
            banner = (true, "Fournée enregistrée : \(n)", "\(ids.count) lot\(ids.count > 1 ? "s" : "") — DLC \(Fmt.day(dlc))")
            Haptics.success()
            name = ""; selected = []; dlcDays = 0
        } catch {
            self.error = Fmt.meatError(error, store: store)
            Haptics.warning()
        }
    }
}

private struct LotRow: View {
    let lot: MeatLot
    var checked: Bool? = nil
    var expired = false

    var body: some View {
        HStack(spacing: 16) {
            if let checked {
                Image(systemName: expired ? "nosign" : (checked ? "checkmark.square.fill" : "square"))
                    .font(.system(size: 32))
                    .foregroundStyle(expired ? Theme.alert : (checked ? Theme.ok : .secondary))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(lot.species?.label ?? "?") · \(lot.reception.payload["product"] ?? "")")
                    .font(.title3.bold())
                Text("Lot \(lot.reception.payload["lot"] ?? "") — \(lot.reception.payload["supplier"] ?? "") — reçu le \(Fmt.dateTime(lot.reception.timestamp))")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(lot.origin).font(.subheadline).foregroundStyle(.pink)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("DLC \(Fmt.businessDay(lot.dlc))")
                    .font(.headline)
                    .foregroundStyle(expired ? Theme.alert : .primary)
                if expired { Text("DLC dépassée — à jeter").font(.caption.bold()).foregroundStyle(Theme.alert) }
                Text("#\(lot.reception.index) · \(lot.preparations.count) fournée\(lot.preparations.count > 1 ? "s" : "")")
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(expired ? Theme.alert : Color(.separator),
                                                           lineWidth: expired ? 2 : 1))
        .opacity(expired && checked != nil ? 0.7 : 1)
    }
}

// MARK: - Lots en cours

private struct MeatLotsList: View {
    @EnvironmentObject private var store: Store
    @State private var closing: (lot: MeatLot, reason: MeatLotClosure)?
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let error { Text(error).font(.headline).foregroundStyle(Theme.alert) }
                let open = store.openMeatLots
                if open.isEmpty { Text("Aucun lot en cours.").foregroundStyle(.secondary) }
                ForEach(MeatSpecies.allCases, id: \.self) { sp in
                    let lots = open.filter { $0.species == sp }
                    if !lots.isEmpty {
                        Text(sp.label).font(.title2.bold()).padding(.top, 6)
                        ForEach(lots) { lot in
                            VStack(spacing: 10) {
                                LotRow(lot: lot, expired: lot.isExpired(on: store.todayDay))
                                HStack(spacing: 12) {
                                    Button { closing = (lot, .termine) } label: { Label("Terminé", systemImage: "checkmark.circle") }
                                        .buttonStyle(BigButtonStyle(color: Theme.ok))
                                    Button { closing = (lot, .jete) } label: { Label("Jeté", systemImage: "trash") }
                                        .buttonStyle(BigButtonStyle(color: Theme.alert))
                                }
                            }
                        }
                    }
                }
                let closed = store.meatLots.filter { !$0.isOpen }.suffix(10).reversed()
                if !closed.isEmpty {
                    Text("Clos récemment").font(.title2.bold()).padding(.top, 12)
                    ForEach(Array(closed)) { lot in
                        HStack {
                            Text("\(lot.species?.label ?? "?") · \(lot.reception.payload["product"] ?? "") — lot \(lot.reception.payload["lot"] ?? "")")
                                .font(.headline)
                            Spacer()
                            Text("\(MeatLotClosure(rawValue: lot.closure?.payload["reason"] ?? "")?.label ?? "") le \(Fmt.dateTime(lot.closure?.timestamp ?? ""))")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                    }
                }
            }
            .padding(24)
        }
        .confirmationDialog(closing.map { "\($0.reason.label) : \($0.lot.reception.payload["product"] ?? "") (lot \($0.lot.reception.payload["lot"] ?? ""))" } ?? "",
                            isPresented: Binding(get: { closing != nil }, set: { if !$0 { closing = nil } }),
                            titleVisibility: .visible) {
            Button(closing?.reason == .jete ? "Jeter ce lot" : "Clore ce lot",
                   role: closing?.reason == .jete ? .destructive : nil) {
                guard let c = closing else { return }
                do { try store.closeMeatLot(c.lot.id, reason: c.reason); Haptics.success() }
                catch { self.error = Fmt.meatError(error, store: store) }
                closing = nil
            }
            Button("Annuler", role: .cancel) { closing = nil }
        } message: {
            Text("La clôture est scellée : le lot ne pourra plus être utilisé dans une fournée.")
        }
    }
}

// MARK: - Rappel / recherche

private struct MeatRecallView: View {
    @EnvironmentObject private var store: Store
    @State private var query = ""
    @State private var error: String?
    @State private var recalling: MeatLot?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Retrouver un lot (rappel fournisseur, contrôle)").font(.title3.bold())
                HStack {
                    Image(systemName: "magnifyingglass").font(.title2).foregroundStyle(.secondary)
                    TextField("N° de lot, produit, fournisseur ou estampille", text: $query)
                        .font(.title3)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))

                if let error { Text(error).font(.headline).foregroundStyle(Theme.alert) }

                // Sans recherche : les derniers lots, pour parcourir sans taper.
                let searching = !query.trimmingCharacters(in: .whitespaces).isEmpty
                let results = searching ? store.searchMeatLots(query) : Array(store.meatLots.reversed().prefix(20))
                Text(searching ? "\(results.count) résultat\(results.count > 1 ? "s" : "")" : "Derniers lots reçus")
                    .font(.headline).foregroundStyle(.secondary)
                if searching && results.isEmpty {
                    Text("Aucun lot trouvé.").foregroundStyle(.secondary)
                }
                ForEach(results) { lot in traceCard(lot) }
            }
            .padding(24)
        }
        .confirmationDialog(recalling.map { "Bloquer pour rappel : \(Fmt.lotLabel($0))" } ?? "",
                            isPresented: Binding(get: { recalling != nil }, set: { if !$0 { recalling = nil } }),
                            titleVisibility: .visible) {
            Button("Bloquer ce lot", role: .destructive) { confirmRecall() }
            Button("Annuler", role: .cancel) { recalling = nil }
        } message: {
            Text("Le lot est clos (motif « rappel ») de façon définitive et scellée : il ne pourra plus servir. Isolez la marchandise restante.")
        }
    }

    private func traceCard(_ lot: MeatLot) -> some View {
        let p = lot.reception.payload
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Fmt.speciesEmoji(lot.species)) \(Fmt.meatTitle(species: lot.species, state: lot.state, product: p["product"] ?? ""))")
                    .font(.title2.bold())
                Spacer()
                Text(lot.isOpen ? "EN COURS" : (MeatLotClosure(rawValue: lot.closure?.payload["reason"] ?? "")?.label.uppercased() ?? "CLOS"))
                    .font(.caption.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(lot.isOpen ? Color.pink : Color.gray))
            }
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                row("Reçu le", Fmt.dateTime(lot.reception.timestamp))
                row("Fournisseur", p["supplier"] ?? "")
                row("Lot fournisseur", p["lot"] ?? "")
                row("Estampille", p["agrement"] ?? "—")
                row("Origine", lot.origin)
                row("Température", "\(Fmt.number(p["celsius"])) °C (limite ≤ \(Fmt.number(p["limit"])) °C)\(p["status"] == "alert" ? " — ALERTE" : "")")
                row("DLC", Fmt.businessDay(lot.dlc))
                if let c = lot.closure { row("Clos le", "\(Fmt.dateTime(c.timestamp)) — \(MeatLotClosure(rawValue: c.payload["reason"] ?? "")?.label ?? "")\(c.payload["note"].map { " (\($0))" } ?? "")") }
            }
            .font(.headline)

            Text("Fournées (\(lot.preparations.count))").font(.title3.bold()).padding(.top, 4)
            if lot.preparations.isEmpty { Text("Aucune fournée n'a utilisé ce lot.").foregroundStyle(.secondary) }
            ForEach(lot.preparations, id: \.hash) { prep in
                HStack {
                    Image(systemName: "flame.fill").foregroundStyle(.pink)
                    Text(prep.payload["name"] ?? "").font(.headline)
                    Spacer()
                    Text("\(Fmt.dateTime(prep.timestamp)) · DLC \(Fmt.businessDay(prep.payload["dlc"] ?? "")) · \(prep.payload["operator"] ?? "")")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                ShareLink(item: Fmt.traceText(lot)) {
                    Label("Partager la fiche", systemImage: "square.and.arrow.up").font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.tertiarySystemFill)))
                if lot.isOpen {
                    Button { recalling = lot } label: {
                        Label("Bloquer (rappel)", systemImage: "hand.raised.fill").font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(.white)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.alert))
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
    }

    private func confirmRecall() {
        guard let lot = recalling else { return }
        do { try store.closeMeatLot(lot.id, reason: .rappel, note: "Rappel fournisseur"); Haptics.warning() }
        catch { self.error = Fmt.meatError(error, store: store) }
        recalling = nil
    }

    private func row(_ k: String, _ v: String) -> some View {
        GridRow {
            Text(k).foregroundStyle(.secondary)
            Text(v)
        }
    }
}

// MARK: - Affiche « Origine de nos viandes »

private struct OriginBoardView: View {
    @EnvironmentObject private var store: Store
    @State private var fullScreen = false
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Viandes en service aujourd'hui : lots en cours non périmés et lots utilisés dans une fournée du jour. L'affichage de l'origine est obligatoire, y compris à emporter.")
                    .font(.subheadline).foregroundStyle(.secondary)
                OriginBoard(board: store.originBoardToday, large: false)
                HStack(spacing: 14) {
                    Button { fullScreen = true } label: {
                        Label("Montrer aux clients", systemImage: "rectangle.inset.filled")
                    }
                    .buttonStyle(BigButtonStyle(color: .pink))
                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            Label("PDF à imprimer", systemImage: "printer.fill")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity, minHeight: Theme.bigButtonHeight)
                        }
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.tertiarySystemFill)))
                    }
                }
                .disabled(store.originBoardToday.isEmpty)
            }
            .padding(24)
        }
        .task(id: store.entries.count) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("KaribTruck-origine-viandes.pdf")
            if (try? OriginPosterPDF(board: store.originBoardToday).render().write(to: url, options: .atomic)) != nil {
                pdfURL = url
            }
        }
        .fullScreenCover(isPresented: $fullScreen) {
            ZStack {
                Color.white.ignoresSafeArea()
                OriginBoard(board: store.originBoardToday, large: true).padding(60)
            }
            .environment(\.colorScheme, .light)
            .onTapGesture { fullScreen = false }
        }
    }
}

private struct OriginBoard: View {
    let board: [(species: MeatSpecies, origins: [String])]
    let large: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: large ? 36 : 16) {
            Text("Origine de nos viandes")
                .font(.system(size: large ? 64 : 30, weight: .heavy, design: .rounded))
            if board.isEmpty {
                Text("Aucun lot de viande en service.").font(large ? .largeTitle : .headline).foregroundStyle(.secondary)
            }
            ForEach(board, id: \.species) { item in
                VStack(alignment: .leading, spacing: large ? 8 : 4) {
                    Text(item.species.label)
                        .font(.system(size: large ? 48 : 24, weight: .bold, design: .rounded))
                    ForEach(item.origins, id: \.self) { o in
                        Text(o).font(.system(size: large ? 40 : 20, weight: .regular, design: .rounded))
                    }
                }
            }
            if large {
                Spacer()
                Text("Touchez l'écran pour revenir").font(.title3).foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(large ? 0 : 20)
        .background(RoundedRectangle(cornerRadius: 18).fill(large ? Color.clear : Color.white))
    }
}

/// Affiche A4 imprimable « Origine de nos viandes ».
struct OriginPosterPDF {
    let board: [(species: MeatSpecies, origins: [String])]

    func render() -> Data {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        return UIGraphicsPDFRenderer(bounds: page).pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 70
            func draw(_ s: String, _ font: UIFont, _ color: UIColor = .black, gap: CGFloat) {
                let rect = CGRect(x: 60, y: y, width: page.width - 120, height: 400)
                let h = ceil((s as NSString).boundingRect(with: rect.size, options: .usesLineFragmentOrigin,
                                                           attributes: [.font: font], context: nil).height)
                (s as NSString).draw(with: rect, options: .usesLineFragmentOrigin,
                                     attributes: [.font: font, .foregroundColor: color], context: nil)
                y += h + gap
            }
            draw("Origine de nos viandes", .systemFont(ofSize: 38, weight: .heavy), gap: 36)
            for item in board {
                draw(item.species.label, .systemFont(ofSize: 28, weight: .bold), gap: 6)
                for o in item.origins { draw(o, .systemFont(ofSize: 22), gap: 4) }
                y += 22
            }
            draw("Mis à jour le \(Fmt.day(Date())) — KaribTruck", .systemFont(ofSize: 11), .gray, gap: 0)
        }
    }
}
