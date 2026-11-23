// GesturesSheetView.swift — la page « Gestes de Lou » de l'espace des grands.
//
// Conseil d'une orthophoniste (06/10/2026) : la méthode phonétique et gestuelle de Borel-Maisonny,
// un geste par son, montré par Lou. La planche, d'abord montrée ici « à valider », a été validée
// par l'orthophoniste le 06/10/2026 : Lou fait désormais les gestes dans le jeu ; cette page reste
// l'aide-mémoire de l'adulte, derrière le contrôle parental. C'est le même PDF que
// `docs/ui/eveil-app/11-gestes-lou.pdf` (`python3 -m gestes.planche` écrit les deux ; un test
// Python vérifie qu'ils sont identiques). Les gestes reformulés et les questions ouvertes :
// `docs/EVEIL-BOREL-MAISONNY.md`.

#if canImport(SwiftUI) && canImport(PDFKit)
import PDFKit
import SwiftUI

public enum GesturesSheet {
    /// Le PDF de la planche, livré avec l'app.
    public static var url: URL? { Bundle.module.url(forResource: "gestes-lou", withExtension: "pdf") }
}

struct GesturesSheetView: View {
    let locale: String
    private var fr: Bool { locale.hasPrefix("fr") }

    var body: some View {
        VStack(spacing: 0) {
            Text(fr ? "Les gestes de la méthode Borel-Maisonny, montrés par Lou (validés par une orthophoniste). Faites-les avec votre enfant : il les imite, puis les abandonne quand il n'en a plus besoin."
                    : "The Borel-Maisonny gestures, shown by Lou (validated by a speech-language pathologist). Do them with your child: they imitate them, then drop them when no longer needed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let url = GesturesSheet.url, let document = PDFDocument(url: url) {
                PDFSheet(document: document)
            } else {
                ContentUnavailableView(fr ? "Planche introuvable" : "Sheet not found", systemImage: "hand.raised")
            }
        }
        .navigationTitle(fr ? "Gestes de Lou" : "Lou's gestures")
    }
}

#if os(iOS)
private struct PDFSheet: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = document
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}
#else
private struct PDFSheet: NSViewRepresentable {
    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = document
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {}
}
#endif
#endif
