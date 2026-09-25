// ColoringView.swift — l'Atelier de coloriage (app 2), « mode écran ».
//
// Pour les 3 ans et + : réussir à tous les coups. Une page est un DESSIN AU
// TRAIT : chaque aire fermée par les traits est une zone, comme sur papier.
// Deux gestes seulement — TOUCHER remplit la zone sous le doigt ; le PINCEAU peint
// au doigt sans jamais déborder (pochoir : le trait reste dans la zone où il a
// commencé). Les couleurs passent SOUS les traits, qui restent nets et visibles :
// rien ne fusionne. Grosses pastilles, annuler, tout effacer (annulable), choisir
// une page parmi de grandes vignettes, page suivante. Rien n'est enregistré ni
// envoyé. Le « mode papier » (photo d'un coloriage réel) viendra ensuite.
//
// Mise en page : portrait = outils à gauche, palette en bas ; paysage = palette en
// colonne à droite, pour garder la plus grande page possible. Pastilles et
// boutons s'adaptent à la place (iPad 11" portrait = 834 pt de large).

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI

public struct ColoringView: View {
    public let locale: String
    public let onHome: (() -> Void)?

    @State private var studio: ColoringStudio
    @State private var colorIndex = 0
    @State private var tool: Tool = .fill
    @State private var cheer = false
    @State private var cheerTask: Task<Void, Never>?
    @State private var showPicker: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(locale: String = "fr-FR", onHome: (() -> Void)? = nil) {
        self.init(locale: locale, onHome: onHome, studio: ColoringStudio(), showPicker: false)
    }

    /// Pour les tests et les captures : un atelier déjà préparé.
    init(locale: String, onHome: (() -> Void)?, studio: ColoringStudio, showPicker: Bool) {
        self.locale = locale
        self.onHome = onHome
        _studio = State(initialValue: studio)
        _showPicker = State(initialValue: showPicker)
    }

    enum Tool { case fill, brush }

    nonisolated static let palette: [PaintColor] = [
        PaintColor(237, 51, 56, fr: "rouge", en: "red"),
        PaintColor(255, 140, 26, fr: "orange", en: "orange"),
        PaintColor(255, 214, 26, fr: "jaune", en: "yellow"),
        PaintColor(102, 199, 64, fr: "vert", en: "green"),
        PaintColor(51, 179, 242, fr: "bleu ciel", en: "sky blue"),
        PaintColor(56, 92, 217, fr: "bleu", en: "blue"),
        PaintColor(148, 87, 219, fr: "violet", en: "purple"),
        PaintColor(255, 140, 191, fr: "rose", en: "pink"),
        PaintColor(140, 89, 51, fr: "marron", en: "brown"),
        PaintColor(247, 247, 247, fr: "blanc", en: "white"),
    ]

    private var fr: Bool { locale.hasPrefix("fr") }
    private var color: PaintColor { Self.palette[colorIndex] }

    public var body: some View {
        GeometryReader { geo in
            let layout = WorkshopLayout(size: geo.size)
            ZStack {
                LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.90), Color(red: 0.99, green: 0.92, blue: 0.84)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                // L'en-tête reste en haut ; la page (et la palette) se centrent dans la place restante.
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: layout.gap)
                    if layout.portrait {
                        HStack(alignment: .center, spacing: layout.gap) {
                            tools(layout)
                            paper(layout)
                        }
                        Spacer(minLength: layout.gap)
                        palette(layout)
                    } else {
                        HStack(alignment: .center, spacing: layout.gap) {
                            tools(layout)
                            paper(layout)
                            palette(layout)
                        }
                    }
                    Spacer(minLength: layout.gap)
                }
                .padding(layout.margin)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if showPicker {
                    PagePicker(studio: studio, locale: locale,
                               onPick: { index in
                                   studio.open(index)
                                   closePicker()
                               },
                               onClose: closePicker)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
                }
            }
        }
        .onAppear { studio.start() }
    }

    // MARK: En-tête

    private var header: some View {
        HStack(spacing: 18) {
            if let onHome {
                Button(action: onHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(EveilPalette.ink.opacity(0.35)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(fr ? "Retour à l'accueil" : "Back home")
            }
            CatStationMaster(mood: cheer ? .cheering : .hello, size: 80)
            Text(studio.page.title(locale: locale))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(EveilPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
        }
        .frame(height: WorkshopLayout.headerHeight)
        .padding(.horizontal, 8)
    }

    // MARK: Outils

    private func tools(_ layout: WorkshopLayout) -> some View {
        VStack(spacing: layout.tool * 0.18) {
            toolButton("hand.tap.fill", selected: tool == .fill, size: layout.tool, label: fr ? "Remplir" : "Fill") {
                tool = .fill
            }
            toolButton("paintbrush.pointed.fill", selected: tool == .brush, size: layout.tool,
                       label: fr ? "Pinceau" : "Brush") { tool = .brush }
            divider(layout)
            toolButton("arrow.uturn.backward", selected: false, size: layout.tool, label: fr ? "Annuler" : "Undo") {
                studio.undo()
            }
            .disabled(!studio.canUndo)
            .opacity(studio.canUndo ? 1 : 0.45)
            toolButton("sparkles", selected: false, size: layout.tool, label: fr ? "Tout effacer" : "Clear all") {
                studio.clear()
            }
            divider(layout)
            toolButton("square.grid.2x2.fill", selected: false, size: layout.tool,
                       label: fr ? "Choisir un dessin" : "Pick a picture", action: openPicker)
            toolButton("arrow.right", selected: false, size: layout.tool, label: fr ? "Page suivante" : "Next page") {
                studio.nextPage()
            }
        }
    }

    private func divider(_ layout: WorkshopLayout) -> some View {
        Capsule().fill(EveilPalette.ink.opacity(0.15)).frame(width: layout.tool * 0.7, height: 3)
    }

    private func toolButton(_ symbol: String, selected: Bool, size: CGFloat, label: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(selected ? .white : EveilPalette.ink)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                        .fill(selected ? EveilPalette.go : .white)
                        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Palette

    @ViewBuilder
    private func palette(_ layout: WorkshopLayout) -> some View {
        let s = layout.swatch
        if layout.portrait {
            HStack(spacing: s * 0.22) {
                ForEach(Self.palette.indices, id: \.self) { swatch($0, size: s) }
            }
            .padding(.horizontal, s * 0.36)
            .padding(.vertical, s * 0.2)
            .background(Capsule().fill(.white.opacity(0.85)))
        } else {
            VStack(spacing: s * 0.22) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: s * 0.22) {
                        swatch(row * 2, size: s)
                        swatch(row * 2 + 1, size: s)
                    }
                }
            }
            .padding(s * 0.3)
            .background(RoundedRectangle(cornerRadius: s * 0.6, style: .continuous).fill(.white.opacity(0.85)))
        }
    }

    private func swatch(_ i: Int, size: CGFloat) -> some View {
        let selected = i == colorIndex
        let c = Self.palette[i]
        return Button {
            colorIndex = i
        } label: {
            Circle().fill(c.swiftUIColor)
                .overlay(Circle().stroke(selected ? EveilPalette.ink : Color.black.opacity(0.15),
                                         lineWidth: selected ? 5 : 2))
                .frame(width: size, height: size)
                .scaleEffect(selected ? 1.18 : 1)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .animation(reduceMotion ? nil : .spring(duration: 0.25), value: colorIndex)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(c.name(locale: locale))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Page à colorier

    private func paper(_ layout: WorkshopLayout) -> some View {
        PaperView(studio: studio, side: layout.side,
                  onBegin: touchBegan, onMove: touchMoved, onEnd: touchEnded)
            .accessibilityElement()
            .accessibilityLabel(fr ? "Page à colorier : \(studio.page.title(locale: locale))"
                                   : "Coloring page: \(studio.page.title(locale: locale))")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }

    // MARK: Gestes

    private func touchBegan(_ unit: CGPoint) {
        switch tool {
        case .fill:
            if studio.fill(at: unit, color: color) { celebrate() }
        case .brush:
            studio.beginStroke(at: unit, color: color)
        }
    }

    private func touchMoved(_ unit: CGPoint) {
        if tool == .brush { studio.continueStroke(to: unit) }
    }

    private func touchEnded(_ unit: CGPoint) {
        guard tool == .brush else { return }
        studio.continueStroke(to: unit)
        if studio.endStroke() { celebrate() }
    }

    private func celebrate() {
        cheerTask?.cancel()
        cheer = true
        cheerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if !Task.isCancelled { cheer = false }
        }
    }

    private func openPicker() {
        studio.refreshThumbnail()
        if reduceMotion { showPicker = true } else { withAnimation(.spring(duration: 0.3)) { showPicker = true } }
    }

    private func closePicker() {
        if reduceMotion { showPicker = false } else { withAnimation(.spring(duration: 0.3)) { showPicker = false } }
    }
}

// MARK: - Mise en page

/// Tailles calculées d'après la place disponible (points).
struct WorkshopLayout {
    static let headerHeight: CGFloat = 92
    /// Largeur de la palette en ligne (portrait), en pastilles : 10 + 9 écarts de 0,22 + marges de 0,36.
    static let rowPaletteSwatches: CGFloat = 12.7
    /// Palette en colonne (paysage), en pastilles : 2 × 5, écarts de 0,22, marges de 0,3.
    static let gridPaletteWidth: CGFloat = 2.82
    static let gridPaletteHeight: CGFloat = 6.48

    let portrait: Bool
    let margin: CGFloat = 20
    let gap: CGFloat = 18
    /// Côté d'un bouton d'outil, d'une pastille de couleur, de la page.
    let tool: CGFloat
    let swatch: CGFloat
    let side: CGFloat

    init(size: CGSize) {
        portrait = size.height >= size.width
        let middle: CGFloat
        if portrait {
            // La palette garde 40 pt de marge de chaque côté (iPad 11" portrait : 834 pt).
            swatch = min(64, max(40, (size.width - 80) / Self.rowPaletteSwatches))
            middle = size.height - 2 * margin - Self.headerHeight - swatch * 1.4 - 3 * gap
            tool = min(76, max(52, middle / 7.8))
            side = max(200, min(size.width - 2 * margin - tool - gap, middle))
        } else {
            middle = size.height - 2 * margin - Self.headerHeight - 2 * gap
            swatch = min(64, max(40, middle / Self.gridPaletteHeight))
            tool = min(76, max(52, middle / 7.8))
            side = max(200, min(middle, size.width - 2 * margin - tool - swatch * Self.gridPaletteWidth - 2 * gap))
        }
    }
}

// MARK: - Le papier

/// La page : papier blanc, couleurs de l'enfant, puis les traits nets par-dessus.
/// Un geste est reconnu à son point de départ : si le précédent a été interrompu
/// (geste système, sans « fin »), le toucher suivant repart bien d'un début.
struct PaperView: View {
    let studio: ColoringStudio
    let side: CGFloat
    let onBegin: (CGPoint) -> Void
    let onMove: (CGPoint) -> Void
    let onEnd: (CGPoint) -> Void
    @State private var gestureStart: CGPoint?

    private func unit(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x / side, y: p.y / side) }

    var body: some View {
        ZStack {
            Color.white
            if let image = studio.image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.medium)
            }
            LineArtView(page: studio.page)
                .equatable()
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * 0.04, style: .continuous))
        .compositingGroup()     // une seule ombre, celle de la feuille (pas une par trait)
        .shadow(color: .black.opacity(0.15), radius: 14, y: 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if gestureStart != value.startLocation {
                        gestureStart = value.startLocation
                        onBegin(unit(value.startLocation))
                        if value.location != value.startLocation { onMove(unit(value.location)) }
                    } else {
                        onMove(unit(value.location))
                    }
                }
                .onEnded { value in
                    gestureStart = nil
                    onEnd(unit(value.location))
                }
        )
    }
}

/// Les traits d'une page, en vectoriel (épaisseur proportionnelle à la taille).
struct LineArtView: View, Equatable {
    let page: ColoringPage

    /// Mêmes traits = même page : SwiftUI ne redessine pas les traits quand seules les couleurs changent.
    nonisolated static func == (a: LineArtView, b: LineArtView) -> Bool { a.page.id == b.page.id }

    var body: some View {
        let art = page.lineArt
        Canvas { ctx, size in
            let t = CGAffineTransform(scaleX: size.width, y: size.height)
            ctx.fill(Path(art.ink).applying(t), with: .color(EveilPalette.ink))
            ctx.stroke(Path(art.strokes).applying(t), with: .color(EveilPalette.ink),
                       style: StrokeStyle(lineWidth: art.lineWidth * size.width, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension PaintColor {
    var swiftUIColor: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: 1)
    }
}

#Preview {
    ColoringView()
}
#endif
