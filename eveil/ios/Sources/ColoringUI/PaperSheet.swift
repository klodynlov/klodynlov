// PaperSheet.swift — le mode papier, côté écran : imprimer la page, la colorier aux vrais crayons,
// la photographier. La photo lue (PaperMode.swift), ses couleurs se posent sur la page de
// l'atelier et le dessin prend vie.
//
// Pour l'adulte ET l'enfant : trois étapes en images (l'imprimante, le crayon, l'appareil photo),
// de grands boutons, et la page telle qu'elle sortira de l'imprimante (ses quatre carrés noirs
// servent à redresser la photo). Jamais « raté » : une photo illisible, c'est « Je n'ai pas bien
// vu la page. On réessaie ? », avec un conseil pour les grands.
//
// iPad : la feuille d'impression d'iPadOS (UIPrintInteractionController ; le PDF reste en
// mémoire) et le scanner de documents de VisionKit (la feuille détectée, redressée, recadrée).
// Ailleurs (macOS, `swift test`), la carte s'affiche sans ces deux services.

#if canImport(SwiftUI) && canImport(AVFoundation)
import EveilDesign
import SwiftUI
#if os(iOS)
import UIKit
import VisionKit
#endif

struct PaperSheet: View {
    let page: ColoringPage
    let locale: String
    /// Lit la photo et pose ses couleurs sur sa page ; `false` si aucune page n'y est reconnue.
    let read: @MainActor (PaperPhoto) async -> Bool
    let say: @MainActor (String) -> Void
    let onClose: () -> Void

    @State private var state: ReadState
    @State private var scanning = false

    enum ReadState: Equatable { case ready, reading, unreadable }

    init(page: ColoringPage, locale: String, state: ReadState = .ready,
         read: @escaping @MainActor (PaperPhoto) async -> Bool,
         say: @escaping @MainActor (String) -> Void,
         onClose: @escaping () -> Void) {
        self.page = page
        self.locale = locale
        self.read = read
        self.say = say
        self.onClose = onClose
        _state = State(initialValue: state)
    }

    private var fr: Bool { locale.hasPrefix("fr") }

    /// Le scanner de documents est là (iPad ; pas le simulateur, pas le Mac).
    static var canScan: Bool {
        #if os(iOS)
        return DocumentScanner.isSupported
        #else
        return false
        #endif
    }

    static var canPrint: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width - 40, 860)
            let preview = min(250, (width - 56) * 0.32)
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { if state != .reading { onClose() } }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 22) {
                    header
                    HStack(alignment: .top, spacing: 28) {
                        PaperPreview(page: page, locale: locale)
                            .frame(width: preview, height: preview * PaperLayout.page.height / PaperLayout.page.width)
                        VStack(alignment: .leading, spacing: 18) {
                            step(1, symbol: "printer.fill", fr ? "On imprime la page." : "Print the page.") {
                                bigButton("printer.fill", fr ? "Imprimer la page" : "Print the page",
                                          primary: false, enabled: Self.canPrint && state != .reading, action: printPage)
                            }
                            step(2, symbol: "pencil.tip", fr ? "Tu la colories avec tes crayons."
                                                             : "Color it with your crayons.") { EmptyView() }
                            step(3, symbol: "camera.fill", fr ? "On la photographie : ton dessin prend vie !"
                                                              : "Take a photo: your picture comes alive!") {
                                bigButton("camera.fill", fr ? "Photographier le coloriage" : "Take a photo",
                                          primary: true, enabled: Self.canScan && state != .reading) { scanning = true }
                            }
                            status
                        }
                    }
                    Text(fr ? "La photo reste sur l'iPad, en mémoire, le temps de la lire : elle n'est jamais enregistrée ni envoyée."
                            : "The photo stays on the iPad, in memory, just long enough to read it: it is never saved or sent.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(EveilPalette.ink.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(28)
                .frame(width: width)
                .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Color(white: 0.99)))
                .compositingGroup()
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $scanning) {
            DocumentScanner { photo in
                scanning = false
                if let photo { Task { await readPhoto(photo) } }
            }
            .ignoresSafeArea()
        }
        #endif
    }

    private var header: some View {
        HStack {
            Text(fr ? "Colorier sur papier" : "Color on paper")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(EveilPalette.ink)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(EveilPalette.ink)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(white: 0.93)))
            }
            .buttonStyle(.plain)
            .disabled(state == .reading)
            .accessibilityLabel(fr ? "Fermer" : "Close")
        }
    }

    /// Une étape : son numéro, son image, sa phrase, et son bouton s'il y en a un.
    private func step<Action: View>(_ number: Int, symbol: String, _ text: String,
                                    @ViewBuilder action: () -> Action) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(EveilPalette.go))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    Text(text)
                        .font(.system(size: 23, weight: .heavy, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(EveilPalette.ink)
                .frame(minHeight: 44)
                action()
            }
        }
    }

    private func bigButton(_ symbol: String, _ label: String, primary: Bool, enabled: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 24, weight: .bold))
                Text(label).font(.system(size: 22, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(primary ? .white : EveilPalette.ink)
            .padding(.horizontal, 22)
            .frame(height: 60)
            .background(
                Capsule().fill(primary ? EveilPalette.go : .white)
                    .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
            )
            .overlay(Capsule().stroke(primary ? .clear : EveilPalette.ink.opacity(0.15), lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var status: some View {
        switch state {
        case .reading:
            HStack(spacing: 14) {
                ReadingDots()
                Text(fr ? "Je regarde ton dessin…" : "Let me look at your picture…")
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(EveilPalette.ink)
            .padding(.top, 4)
        case .unreadable:
            VStack(alignment: .leading, spacing: 6) {
                Text(fr ? "Je n'ai pas bien vu la page. On réessaie ?" : "I couldn't see the page well. Shall we try again?")
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
                Text(fr ? "Pour les grands : toute la feuille dans l'image, bien à plat et éclairée, avec ses quatre carrés noirs."
                        : "For grown-ups: the whole sheet in the picture, flat and well lit, with its four black squares.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(EveilPalette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
        case .ready:
            if !Self.canScan {
                Text(fr ? "Le scanner de documents n'est pas disponible sur cet appareil."
                        : "The document scanner isn't available on this device.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(EveilPalette.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func printPage() {
        #if os(iOS)
        PaperPrinter.present(page, locale: locale)
        #endif
    }

    /// La photo du scanner : lue par l'atelier (qui ferme la carte et fait la fête), ou l'on réessaie.
    private func readPhoto(_ photo: PaperPhoto) async {
        state = .reading
        say(fr ? "Je regarde ton dessin…" : "Let me look at your picture…")
        if await read(photo) { return }
        state = .unreadable
        say(fr ? "Je n'ai pas bien vu la page. On réessaie ?" : "I couldn't see the page well. Shall we try again?")
    }
}

/// Trois points qui sautent pendant la lecture de la photo — pilotés par l'horloge (TimelineView),
/// comme tout mouvement de l'app ; immobiles avec « Réduire les animations ».
struct ReadingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { k in
                    Circle()
                        .fill(EveilPalette.go)
                        .frame(width: 14, height: 14)
                        .offset(y: reduceMotion ? 0 : -8 * max(0, sin((t * 1.6 - Double(k) * 0.18) * 2 * .pi)))
                }
            }
            .frame(height: 30)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - La page imprimée, en petit

/// La page telle qu'elle sortira de l'imprimante : titre, dessin au trait, quatre repères.
struct PaperPreview: View {
    let page: ColoringPage
    let locale: String

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / PaperLayout.page.width
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            ctx.draw(Text(page.title(locale: locale))
                        .font(.system(size: PaperLayout.titleSize * k, weight: .heavy))
                        .foregroundStyle(EveilPalette.ink),
                     at: CGPoint(x: size.width / 2, y: PaperLayout.titleBaseline * k), anchor: .bottom)
            let art = page.lineArt
            let t = CGAffineTransform(translationX: PaperLayout.origin.x * k, y: PaperLayout.origin.y * k)
                .scaledBy(x: PaperLayout.side * k, y: PaperLayout.side * k)
            ctx.fill(Path(art.ink).applying(t), with: .color(EveilPalette.ink))
            ctx.stroke(Path(art.strokes).applying(t), with: .color(EveilPalette.ink),
                       style: StrokeStyle(lineWidth: art.lineWidth * PaperLayout.side * k,
                                          lineCap: .round, lineJoin: .round))
            let s = PaperLayout.marker * k
            for c in PaperLayout.markers {
                ctx.fill(Path(CGRect(x: c.x * k - s / 2, y: c.y * k - s / 2, width: s, height: s)),
                         with: .color(Color(white: 0.08)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .accessibilityElement()
        .accessibilityLabel(locale.hasPrefix("fr") ? "La page à imprimer : \(page.title(locale: locale))"
                                                   : "The page to print: \(page.title(locale: locale))")
    }
}

#if os(iOS)
// MARK: - L'imprimante

/// La feuille d'impression d'iPadOS, avec le PDF de la page (en mémoire, jamais écrit sur disque).
@MainActor
enum PaperPrinter {
    static func present(_ page: ColoringPage, locale: String) {
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .grayscale          // un dessin au trait : l'encre noire suffit
        info.orientation = .portrait
        info.jobName = page.title(locale: locale)
        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = PaperPrint.pdf(for: page, locale: locale)
        _ = controller.present(animated: true, completionHandler: nil)
    }
}

// MARK: - Le scanner de documents

/// Le scanner de documents de VisionKit : la feuille détectée, redressée, recadrée. Rend la
/// dernière page photographiée, à l'endroit (`nil` : annulé, ou échec).
struct DocumentScanner: UIViewControllerRepresentable {
    let onScan: (PaperPhoto?) -> Void

    static var isSupported: Bool { VNDocumentCameraViewController.isSupported }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    /// Les rappels du scanner arrivent sur le fil principal ; la photo se prépare sur place (à
    /// l'endroit, 2000 px au plus), puis l'écran la reçoit.
    @MainActor
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: (PaperPhoto?) -> Void

        init(onScan: @escaping (PaperPhoto?) -> Void) {
            self.onScan = onScan
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                                      didFinishWith scan: VNDocumentCameraScan) {
            let photo = scan.pageCount > 0 ? Self.upright(scan.imageOfPage(at: scan.pageCount - 1)) : nil
            Task { @MainActor in self.onScan(photo) }
        }

        nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in self.onScan(nil) }
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                                      didFailWithError error: Error) {
            Task { @MainActor in self.onScan(nil) }
        }

        /// La photo à l'endroit (l'orientation de l'UIImage appliquée), au plus 2000 px de côté.
        nonisolated static func upright(_ image: UIImage) -> PaperPhoto? {
            let longest = max(image.size.width, image.size.height)
            guard longest > 0 else { return nil }
            let k = min(1, 2000 / longest)
            let size = CGSize(width: (image.size.width * k).rounded(), height: (image.size.height * k).rounded())
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let drawn = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            return drawn.cgImage.map(PaperPhoto.init(image:))
        }
    }
}
#endif
#endif
