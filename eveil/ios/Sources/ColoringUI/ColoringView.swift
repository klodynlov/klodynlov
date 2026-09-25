// ColoringView.swift — l'Atelier de coloriage (app 2), ébauche « mode écran ».
//
// Pour les 3 ans et + : réussir à tous les coups. Deux gestes seulement —
// TOUCHER une forme la remplit ; le PINCEAU trace au doigt sans jamais déborder
// (le trait reste dans la forme où il a commencé : pochoir). Grosses pastilles de
// couleur, annuler, tout effacer, page suivante. Rien n'est enregistré ni envoyé.
// Le « mode papier » (photo d'un coloriage réel) viendra ensuite (cf. EVEIL.md).

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI

public struct ColoringView: View {
    public let locale: String
    public let onHome: (() -> Void)?

    @State private var pageIndex = 0
    @State private var fills: [Int: Color] = [:]
    @State private var strokes: [PaintStroke] = []
    @State private var current: PaintStroke?
    @State private var history: [Step] = []
    @State private var colorIndex = 0
    @State private var tool: Tool = .fill
    @State private var cheer = false

    public init(locale: String = "fr-FR", onHome: (() -> Void)? = nil) {
        self.locale = locale
        self.onHome = onHome
    }

    enum Tool { case fill, brush }

    struct PaintStroke {
        var region: Int
        var color: Color
        var points: [CGPoint]            // coordonnées unité
    }

    enum Step {
        case fill(region: Int, previous: Color?)
        case stroke
    }

    static let palette: [Color] = [
        Color(red: 0.93, green: 0.20, blue: 0.22), Color(red: 1.0, green: 0.55, blue: 0.10),
        Color(red: 1.0, green: 0.84, blue: 0.10), Color(red: 0.40, green: 0.78, blue: 0.25),
        Color(red: 0.20, green: 0.70, blue: 0.95), Color(red: 0.22, green: 0.36, blue: 0.85),
        Color(red: 0.58, green: 0.34, blue: 0.86), Color(red: 1.0, green: 0.55, blue: 0.75),
        Color(red: 0.55, green: 0.35, blue: 0.20), Color(white: 0.97),
    ]

    private var fr: Bool { locale.hasPrefix("fr") }
    private var page: ColoringPage { ColoringPages.all[pageIndex] }
    private var color: Color { Self.palette[colorIndex] }

    public var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            let side = min(wide ? geo.size.height - 250 : geo.size.width - 200, wide ? geo.size.width - 360 : geo.size.height - 420)
            ZStack {
                LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.90), Color(red: 0.99, green: 0.92, blue: 0.84)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 18) {
                    header
                    HStack(alignment: .center, spacing: 26) {
                        tools
                        canvas(side: max(side, 300))
                    }
                    palette
                }
                .padding(.bottom, 24)
            }
        }
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
                .accessibilityLabel(fr ? "Retour à l'accueil" : "Back home")
            }
            CatStationMaster(mood: cheer ? .cheering : .hello, size: 92)
            Text(page.title(locale: locale))
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(EveilPalette.ink)
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
    }

    // MARK: Outils

    private var tools: some View {
        VStack(spacing: 18) {
            toolButton("hand.tap.fill", selected: tool == .fill, label: fr ? "Remplir" : "Fill") { tool = .fill }
            toolButton("paintbrush.pointed.fill", selected: tool == .brush, label: fr ? "Pinceau" : "Brush") { tool = .brush }
            Divider().frame(width: 60)
            toolButton("arrow.uturn.backward", selected: false, label: fr ? "Annuler" : "Undo", action: undo)
                .disabled(history.isEmpty)
            toolButton("sparkles", selected: false, label: fr ? "Tout effacer" : "Clear all", action: clearPage)
            toolButton("arrow.right", selected: false, label: fr ? "Page suivante" : "Next page", action: nextPage)
        }
    }

    private func toolButton(_ symbol: String, selected: Bool, label: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(selected ? .white : EveilPalette.ink)
                .frame(width: 76, height: 76)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(selected ? EveilPalette.go : .white)
                        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
                )
        }
        .accessibilityLabel(label)
    }

    // MARK: Palette

    private var palette: some View {
        HStack(spacing: 16) {
            ForEach(Self.palette.indices, id: \.self) { i in
                Button {
                    colorIndex = i
                } label: {
                    Circle().fill(Self.palette[i])
                        .overlay(Circle().stroke(i == colorIndex ? EveilPalette.ink : Color.black.opacity(0.15),
                                                 lineWidth: i == colorIndex ? 5 : 2))
                        .frame(width: 64, height: 64)
                        .scaleEffect(i == colorIndex ? 1.22 : 1)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .animation(.spring(duration: 0.25), value: colorIndex)
                }
                .accessibilityLabel(fr ? "Couleur \(i + 1)" : "Color \(i + 1)")
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 14)
        .background(Capsule().fill(.white.opacity(0.85)))
    }

    // MARK: Page à colorier

    private func canvas(side: CGFloat) -> some View {
        Canvas { ctx, size in
            let t = CGAffineTransform(scaleX: size.width, y: size.height)
            let brush = StrokeStyle(lineWidth: size.width * 0.05, lineCap: .round, lineJoin: .round)
            for (i, region) in page.regions.enumerated() {
                let shape = region.applying(t)
                ctx.fill(shape, with: .color(fills[i] ?? .white))
                let painted = strokes.filter { $0.region == i } + (current.map { $0.region == i ? [$0] : [] } ?? [])
                if !painted.isEmpty {
                    ctx.drawLayer { layer in
                        layer.clip(to: shape)
                        for s in painted {
                            layer.stroke(Self.path(for: s.points).applying(t), with: .color(s.color), style: brush)
                        }
                    }
                }
            }
            for region in page.regions {
                ctx.stroke(region.applying(t), with: .color(EveilPalette.ink),
                           style: StrokeStyle(lineWidth: max(3, size.width * 0.007), lineJoin: .round))
            }
        }
        .frame(width: side, height: side)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 14, y: 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in touch(value.location, side: side, ended: false) }
                .onEnded { value in touch(value.location, side: side, ended: true) }
        )
        .accessibilityLabel(fr ? "Page à colorier : \(page.title(locale: locale))" : "Coloring page: \(page.title(locale: locale))")
    }

    private static func path(for points: [CGPoint]) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        if points.count == 1 { p.addLine(to: CGPoint(x: first.x + 0.0001, y: first.y)) }
        for q in points.dropFirst() { p.addLine(to: q) }
        return p
    }

    // MARK: Gestes

    private func touch(_ location: CGPoint, side: CGFloat, ended: Bool) {
        let u = CGPoint(x: location.x / side, y: location.y / side)
        switch tool {
        case .fill:
            guard ended, let region = page.region(at: u) else { return }
            history.append(.fill(region: region, previous: fills[region]))
            fills[region] = color
            celebrate()
        case .brush:
            if current == nil {
                guard let region = page.region(at: u) else { return }
                current = PaintStroke(region: region, color: color, points: [u])
            } else {
                current?.points.append(u)
            }
            if ended, let done = current {
                strokes.append(done)
                history.append(.stroke)
                current = nil
                celebrate()
            }
        }
    }

    private func celebrate() {
        cheer = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            cheer = false
        }
    }

    private func undo() {
        guard let last = history.popLast() else { return }
        switch last {
        case let .fill(region, previous): fills[region] = previous
        case .stroke: if !strokes.isEmpty { strokes.removeLast() }
        }
    }

    private func clearPage() {
        fills = [:]
        strokes = []
        history = []
    }

    private func nextPage() {
        clearPage()
        pageIndex = (pageIndex + 1) % ColoringPages.all.count
    }
}

#Preview {
    ColoringView()
}
#endif
