// Theme.swift — l'univers visuel du Petit Train : ciel, collines, rails, gros boutons.
//
// Ébauche : formes et couleurs vectorielles, en attendant les illustrations
// définitives (à confier à un illustrateur, comme la mascotte).

#if canImport(SwiftUI)
import SwiftUI

public enum EveilPalette {
    public static let sky = Color(red: 0.55, green: 0.80, blue: 0.97)
    public static let skyLight = Color(red: 0.87, green: 0.95, blue: 1.0)
    public static let nightTop = Color(red: 0.08, green: 0.10, blue: 0.27)
    public static let nightBottom = Color(red: 0.20, green: 0.21, blue: 0.45)
    public static let grass = Color(red: 0.56, green: 0.80, blue: 0.40)
    public static let hill = Color(red: 0.44, green: 0.69, blue: 0.33)
    public static let rail = Color(red: 0.42, green: 0.33, blue: 0.27)
    public static let sun = Color(red: 1.0, green: 0.82, blue: 0.24)
    public static let ink = Color(red: 0.18, green: 0.20, blue: 0.29)
    public static let go = Color(red: 0.13, green: 0.62, blue: 0.47)
    public static let wagonLit = Color(red: 1.0, green: 0.80, blue: 0.16)
    public static let wagonOff = Color(red: 0.86, green: 0.88, blue: 0.91)
    public static let caboose = Color(red: 0.98, green: 0.55, blue: 0.20)
    public static let loco = Color(red: 0.89, green: 0.20, blue: 0.24)
    public static let locoDark = Color(red: 0.62, green: 0.12, blue: 0.16)
}

/// Décor : ciel, soleil, nuages, collines et prairie. `night` pour la fin de séance.
public struct SceneryView: View {
    public var night: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    public init(night: Bool = false) { self.night = night }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                LinearGradient(colors: night ? [EveilPalette.nightTop, EveilPalette.nightBottom]
                                             : [EveilPalette.sky, EveilPalette.skyLight],
                               startPoint: .top, endPoint: .bottom)
                if night {
                    ForEach(0..<14, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: CGFloat(10 + (i * 7) % 14)))
                            .foregroundStyle(.yellow.opacity(0.85))
                            .position(x: w * CGFloat((i * 37) % 100) / 100,
                                      y: h * CGFloat(5 + (i * 23) % 45) / 100)
                    }
                    Circle().fill(Color(red: 1, green: 0.96, blue: 0.78))
                        .frame(width: 110, height: 110)
                        .overlay(Circle().fill(EveilPalette.nightTop).frame(width: 90, height: 90).offset(x: 28, y: -14))
                        .position(x: w * 0.82, y: h * 0.16)
                } else {
                    Circle().fill(EveilPalette.sun)
                        .frame(width: 130, height: 130)
                        .shadow(color: EveilPalette.sun.opacity(0.7), radius: 30)
                        .position(x: w * 0.10, y: h * 0.12)
                    CloudShape().fill(.white.opacity(0.9))
                        .frame(width: 210, height: 80)
                        .position(x: w * (drift ? 0.46 : 0.40), y: h * 0.13)
                    CloudShape().fill(.white.opacity(0.8))
                        .frame(width: 160, height: 62)
                        .position(x: w * (drift ? 0.74 : 0.80), y: h * 0.25)
                }
                Ellipse().fill(night ? EveilPalette.nightBottom.opacity(0.9) : EveilPalette.hill)
                    .frame(width: w * 0.9, height: h * 0.42)
                    .position(x: w * 0.18, y: h * 0.86)
                Ellipse().fill(night ? EveilPalette.nightBottom : EveilPalette.hill.opacity(0.85))
                    .frame(width: w * 0.8, height: h * 0.36)
                    .position(x: w * 0.88, y: h * 0.88)
                Rectangle().fill(night ? EveilPalette.nightTop.opacity(0.7) : EveilPalette.grass)
                    .frame(width: w, height: h * 0.24)
                    .position(x: w / 2, y: h * 0.88)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

/// Un nuage : trois bosses sur une base arrondie.
public struct CloudShape: Shape {
    public init() {}
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY + r.height * 0.45, width: r.width, height: r.height * 0.55),
                         cornerSize: CGSize(width: r.height * 0.27, height: r.height * 0.27))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.12, y: r.minY + r.height * 0.18, width: r.width * 0.34, height: r.height * 0.62))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.36, y: r.minY, width: r.width * 0.40, height: r.height * 0.80))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.62, y: r.minY + r.height * 0.24, width: r.width * 0.28, height: r.height * 0.56))
        return p
    }
}

/// Gros bouton d'enfant : large, arrondi, qui s'enfonce sous le doigt.
public struct KidButtonStyle: ButtonStyle {
    public var color: Color
    public init(color: Color = EveilPalette.go) { self.color = color }

    public func makeBody(configuration: Configuration) -> some View {
        KidButtonBody(configuration: configuration, color: color)
    }

    private struct KidButtonBody: View {
        let configuration: Configuration
        let color: Color
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 22)
                .background(
                    Capsule().fill(isEnabled ? color : Color.gray.opacity(0.55))
                        .shadow(color: .black.opacity(0.18), radius: configuration.isPressed ? 2 : 8,
                                y: configuration.isPressed ? 1 : 6)
                )
                .scaleEffect(configuration.isPressed ? 0.94 : 1)
                .animation(.spring(duration: 0.2), value: configuration.isPressed)
        }
    }
}

/// Bulle de dialogue (la queue pointe vers la gauche, vers la mascotte).
public struct SpeechBubble: View {
    public let text: String
    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text)
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundStyle(EveilPalette.ink)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 26)
            .padding(.vertical, 18)
            .background(
                BubbleShape().fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            )
            .frame(maxWidth: 420, alignment: .leading)
    }
}

struct BubbleShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(roundedRect: CGRect(x: r.minX + 16, y: r.minY, width: r.width - 16, height: r.height),
                     cornerRadius: 26, style: .continuous)
        p.move(to: CGPoint(x: r.minX + 18, y: r.midY - 14))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY + 4))
        p.addLine(to: CGPoint(x: r.minX + 18, y: r.midY + 12))
        p.closeSubpath()
        return p
    }
}
#endif
