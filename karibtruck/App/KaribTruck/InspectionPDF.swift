import UIKit
import KaribTruckCore

/// Mise en page A4 du « dossier de contrôle » présenté à la DDPP : synthèse,
/// alertes d'abord, puis une table par registre. Chaque ligne porte le début de
/// son empreinte ; l'en-tête porte l'empreinte complète du journal.
struct InspectionPDF {
    let entries: [JournalEntry]
    let from: Date
    let to: Date
    let totalEntries: Int
    let headHash: String
    let isValid: Bool
    let enclosures: [Enclosure]
    let photoCheck: (String) -> Bool

    private let page = CGRect(x: 0, y: 0, width: 595, height: 842)   // A4 en points
    private let margin: CGFloat = 40

    func render() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: page, format: {
            let f = UIGraphicsPDFRendererFormat()
            f.documentInfo = [kCGPDFContextTitle as String: "Dossier de contrôle HACCP — KaribTruck",
                              kCGPDFContextCreator as String: "KaribTruck"]
            return f
        }())
        return renderer.pdfData { ctx in
            var w = Writer(ctx: ctx, page: page, margin: margin,
                           header: "KaribTruck — Dossier de contrôle HACCP · du \(Fmt.day(from)) au \(Fmt.day(to.addingTimeInterval(-1)))",
                           footer: "Empreinte du journal : \(headHash.prefix(16))…")
            w.newPage()
            cover(&w)
            tables(&w)
            method(&w)
        }
    }

    // MARK: - Sections

    private func cover(_ w: inout Writer) {
        w.text("Dossier de contrôle HACCP", font: .boldSystemFont(ofSize: 24))
        w.text("Food truck KaribTruck — registres d'hygiène (PMS)", font: .systemFont(ofSize: 13), color: .darkGray)
        w.space(10)
        let alerts = entries.filter { $0.payload["status"] == "alert" }
        let now = Store.iso.string(from: Date())
        w.keyValues([
            ("Période", "du \(Fmt.day(from)) au \(Fmt.day(to.addingTimeInterval(-1))) inclus"),
            ("Généré le", Fmt.dateTime(now)),
            ("Enregistrements sur la période", "\(entries.count) (dont \(alerts.count) en alerte)"),
            ("Intégrité du journal", isValid ? "VÉRIFIÉE — \(totalEntries) enregistrements chaînés, aucune altération"
                                              : "COMPROMISE — le journal a été altéré"),
            ("Empreinte du journal (SHA-256)", headHash),
        ], valueColor: { $0 == "Intégrité du journal" ? (isValid ? .systemGreen : .systemRed) : .black })
        w.space(8)
        var counts: [String: Int] = [:]
        for e in entries { counts[e.kind, default: 0] += 1 }
        w.table(title: "Synthèse", columns: [("Registre", 0.6), ("Enregistrements", 0.2), ("Alertes", 0.2)],
                rows: kinds.map { k in
                    let n = counts[k] ?? 0
                    let a = entries.filter { $0.kind == k && $0.payload["status"] == "alert" }.count
                    return Row(cells: [Fmt.kindLabel(k), "\(n)", "\(a)"], alert: a > 0)
                })
    }

    private let kinds = ["enclosure.reading", "checklist.run", "reception",
                         "frying-oil.check", "nonconformity", "market.schedule"]

    private func tables(_ w: inout Writer) {
        let alerts = entries.filter { $0.payload["status"] == "alert" }
        if !alerts.isEmpty {
            w.table(title: "Alertes de la période (\(alerts.count))",
                    columns: [("Date / heure", 0.18), ("Registre", 0.16), ("Détail", 0.54), ("Empreinte", 0.12)],
                    rows: alerts.map { e in
                        Row(cells: [Fmt.dateTime(e.timestamp), Fmt.kindLabel(e.kind),
                                    Fmt.summary(e, enclosures: enclosures), short(e)], alert: true)
                    })
        }

        let temps = of("enclosure.reading")
        w.table(title: "Relevés de température (\(temps.count))",
                columns: [("Date / heure", 0.2), ("Enceinte", 0.22), ("Mesure", 0.13), ("Limite", 0.15), ("Statut", 0.18), ("Empreinte", 0.12)],
                rows: temps.map { e in
                    let p = e.payload
                    let rule = p["rule"] == "max" ? "≤" : (p["rule"] == "min" ? "≥" : "?")
                    let alert = p["status"] == "alert"
                    return Row(cells: [Fmt.dateTime(e.timestamp), Fmt.enclosureName(p["enclosure"], in: enclosures),
                                       "\(Fmt.number(p["celsius"])) °C", "\(rule) \(Fmt.number(p["limit"])) °C",
                                       alert ? "ALERTE" : "conforme", short(e)], alert: alert)
                })

        let runs = of("checklist.run")
        w.table(title: "Checklists signées (\(runs.count))",
                columns: [("Date / heure", 0.18), ("Checklist", 0.18), ("Fait", 0.08), ("Opérateur", 0.14), ("Non fait", 0.3), ("Empreinte", 0.12)],
                rows: runs.map { e in
                    let p = e.payload
                    return Row(cells: [Fmt.dateTime(e.timestamp), Fmt.checklistName(p["checklist"]),
                                       "\(p["done"] ?? "?")/\(p["total"] ?? "?")", p["operator"] ?? "",
                                       p["missing"] ?? "—", short(e)], alert: p["status"] == "alert")
                })

        let recs = of("reception")
        w.table(title: "Réceptions — traçabilité (\(recs.count))",
                columns: [("Date / heure", 0.17), ("Produit", 0.17), ("Fournisseur", 0.18), ("Lot", 0.12), ("DLC", 0.12), ("Photo", 0.12), ("Empreinte", 0.12)],
                rows: recs.map { e in
                    let p = e.payload
                    let photo: String
                    if let sha = p["photo_sha256"] { photo = photoCheck(sha) ? "oui, intacte" : "ABSENTE/MODIFIÉE" }
                    else { photo = "—" }
                    return Row(cells: [Fmt.dateTime(e.timestamp), p["product"] ?? "", p["supplier"] ?? "",
                                       p["lot"] ?? "", Fmt.businessDay(p["dlc"] ?? ""), photo, short(e)],
                               alert: photo == "ABSENTE/MODIFIÉE")
                })

        let oils = of("frying-oil.check")
        w.table(title: "Huile de friture (\(oils.count))",
                columns: [("Date / heure", 0.18), ("Friteuse", 0.17), ("Action", 0.15), ("État", 0.14), ("Polaires", 0.12), ("Changée", 0.12), ("Empreinte", 0.12)],
                rows: oils.map { e in
                    let p = e.payload
                    return Row(cells: [Fmt.dateTime(e.timestamp), p["fryer"] ?? "",
                                       p["action"] == "changement" ? "changement" : "contrôle",
                                       Fmt.qualityLabel(p["quality"]),
                                       p["polar_percent"].map { "\(Fmt.number($0)) %" } ?? "—",
                                       p["changed"] == "true" ? "oui" : "non", short(e)],
                               alert: p["status"] == "alert")
                })

        let ncs = of("nonconformity")
        w.table(title: "Non-conformités et actions correctives (\(ncs.count))",
                columns: [("Date / heure", 0.18), ("Gravité", 0.11), ("Constat", 0.3), ("Action corrective", 0.29), ("Empreinte", 0.12)],
                rows: ncs.map { e in
                    let p = e.payload
                    return Row(cells: [Fmt.dateTime(e.timestamp), p["severity"] ?? "", p["what"] ?? "",
                                       p["action"] ?? "", short(e)], alert: false)
                })

        let plans = of("market.schedule")
        w.table(title: "Planning des emplacements (\(plans.count))",
                columns: [("Saisi le", 0.18), ("Jour", 0.14), ("Emplacement", 0.4), ("Créneau", 0.16), ("Empreinte", 0.12)],
                rows: plans.map { e in
                    let p = e.payload
                    return Row(cells: [Fmt.dateTime(e.timestamp), Fmt.businessDay(p["date"] ?? ""),
                                       p["place"] ?? "", p["slot"] ?? "", short(e)], alert: false)
                })
    }

    private func method(_ w: inout Writer) {
        w.space(12)
        w.text("Méthode de vérification", font: .boldSystemFont(ofSize: 13))
        w.text("""
        Chaque enregistrement est scellé au moment de la saisie par une empreinte SHA-256 calculée sur son \
        contenu, son horodatage et l'empreinte de l'enregistrement précédent (journal chaîné, en ajout seul). \
        Modifier, supprimer, réordonner ou antidater un enregistrement change toutes les empreintes suivantes \
        et fait échouer la vérification. Une erreur se corrige par un nouvel enregistrement, jamais par effacement. \
        Les photos d'étiquettes sont liées par leur empreinte. Le fichier CSV joint contient, pour chaque ligne, \
        l'empreinte complète et celle de la précédente.
        """, font: .systemFont(ofSize: 9), color: .darkGray)
    }

    private func of(_ kind: String) -> [JournalEntry] { entries.filter { $0.kind == kind } }
    private func short(_ e: JournalEntry) -> String { "#\(e.index) \(e.hash.prefix(8))" }
}

// MARK: - Moteur de mise en page (curseur vertical + tables paginées)

private struct Row {
    let cells: [String]
    let alert: Bool
}

private struct Writer {
    let ctx: UIGraphicsPDFRendererContext
    let page: CGRect
    let margin: CGFloat
    let header: String
    let footer: String
    var y: CGFloat = 0
    var pageNumber = 0

    init(ctx: UIGraphicsPDFRendererContext, page: CGRect, margin: CGFloat, header: String, footer: String) {
        self.ctx = ctx; self.page = page; self.margin = margin; self.header = header; self.footer = footer
    }

    private var width: CGFloat { page.width - 2 * margin }
    private var bottom: CGFloat { page.height - margin - 18 }

    mutating func newPage() {
        ctx.beginPage()
        pageNumber += 1
        let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray]
        (header as NSString).draw(in: CGRect(x: margin, y: 18, width: width, height: 12), withAttributes: small)
        let foot = "\(footer)    ·    Page \(pageNumber)"
        (foot as NSString).draw(in: CGRect(x: margin, y: page.height - margin + 6, width: width, height: 12), withAttributes: small)
        y = margin
    }

    mutating func ensure(_ h: CGFloat) { if y + h > bottom { newPage() } }
    mutating func space(_ h: CGFloat) { y += h }

    private func height(_ s: String, font: UIFont, width: CGFloat) -> CGFloat {
        ceil((s as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                                          attributes: [.font: font], context: nil).height)
    }

    mutating func text(_ s: String, font: UIFont, color: UIColor = .black) {
        let h = height(s, font: font, width: width)
        ensure(h)
        (s as NSString).draw(with: CGRect(x: margin, y: y, width: width, height: h),
                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                             attributes: [.font: font, .foregroundColor: color], context: nil)
        y += h + 4
    }

    mutating func keyValues(_ kv: [(String, String)], valueColor: (String) -> UIColor) {
        let keyW: CGFloat = 170
        for (k, v) in kv {
            let vf = k.contains("SHA-256") ? UIFont.monospacedSystemFont(ofSize: 8, weight: .regular) : UIFont.systemFont(ofSize: 10)
            let h = max(height(k, font: .boldSystemFont(ofSize: 10), width: keyW), height(v, font: vf, width: width - keyW))
            ensure(h)
            (k as NSString).draw(with: CGRect(x: margin, y: y, width: keyW, height: h), options: .usesLineFragmentOrigin,
                                 attributes: [.font: UIFont.boldSystemFont(ofSize: 10)], context: nil)
            (v as NSString).draw(with: CGRect(x: margin + keyW, y: y, width: width - keyW, height: h), options: .usesLineFragmentOrigin,
                                 attributes: [.font: vf, .foregroundColor: valueColor(k)], context: nil)
            y += h + 5
        }
    }

    mutating func table(title: String, columns: [(String, CGFloat)], rows: [Row]) {
        let pad: CGFloat = 3
        let font = UIFont.systemFont(ofSize: 8)
        let bold = UIFont.boldSystemFont(ofSize: 8)
        let widths = columns.map { $0.1 * width }

        let mono = UIFont.monospacedSystemFont(ofSize: 7, weight: .regular)
        // Police de chaque cellule : la dernière colonne (empreinte) est en mono
        // hors en-tête. Mesure et dessin utilisent la MÊME police.
        func cellFont(_ i: Int, _ count: Int, _ f: UIFont) -> UIFont { i == count - 1 && f == font ? mono : f }
        func rowHeight(_ cells: [String], _ f: UIFont) -> CGFloat {
            cells.enumerated().map { i, c in
                height(c, font: cellFont(i, cells.count, f), width: widths[i] - 2 * pad)
            }.max()! + 2 * pad
        }
        func draw(_ cells: [String], _ f: UIFont, fill: UIColor?, color: UIColor) {
            let h = rowHeight(cells, f)
            if let fill { fill.setFill(); UIRectFill(CGRect(x: margin, y: y, width: width, height: h)) }
            var x = margin
            for (i, c) in cells.enumerated() {
                let cf = cellFont(i, cells.count, f)
                (c as NSString).draw(with: CGRect(x: x + pad, y: y + pad, width: widths[i] - 2 * pad, height: h),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     attributes: [.font: cf, .foregroundColor: color], context: nil)
                x += widths[i]
            }
            UIColor(white: 0.85, alpha: 1).setFill()
            UIRectFill(CGRect(x: margin, y: y + h - 0.5, width: width, height: 0.5))
            y += h
        }

        let headerCells = columns.map(\.0)
        ensure(22 + rowHeight(headerCells, bold) + 16)
        space(10)
        text(title, font: .boldSystemFont(ofSize: 12))
        if rows.isEmpty {
            text("Aucun enregistrement sur la période.", font: .italicSystemFont(ofSize: 9), color: .gray)
            return
        }
        draw(headerCells, bold, fill: UIColor(white: 0.92, alpha: 1), color: .black)
        for r in rows {
            let h = rowHeight(r.cells, font)
            if y + h > bottom {
                newPage()
                draw(headerCells, bold, fill: UIColor(white: 0.92, alpha: 1), color: .black)
            }
            draw(r.cells, font, fill: r.alert ? UIColor.systemRed.withAlphaComponent(0.12) : nil,
                 color: r.alert ? UIColor(red: 0.6, green: 0, blue: 0, alpha: 1) : .black)
        }
    }
}
