import SwiftUI

/// A richly textured card using the wood grain palette.
struct WoodCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = DesignCornerRadius.card, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(DesignSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                DesignTexture.wood.preview
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(DesignColor.ink.opacity(0.25), lineWidth: 1)
                            .blendMode(.multiply)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DesignColor.ink.opacity(0.15), lineWidth: 1)
            )
    }
}

/// A parchment styled surface for text heavy content.
struct ParchmentPage<Content: View>: View {
    private let content: Content
    private let inset: CGFloat

    init(inset: CGFloat = DesignSpacing.lg, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.inset = inset
    }

    var body: some View {
        content
            .padding(inset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                DesignTexture.parchment.preview
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                            .stroke(DesignColor.ink.opacity(0.08), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.soft, style: .continuous))
            .shadow(color: DesignColor.deepWalnut.opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

/// A glowing call-to-action button shell with subtle depth.
struct GlowButton: View {
    enum Style {
        case aqua
        case amber

        var background: LinearGradient {
            switch self {
            case .aqua:
                return LinearGradient(
                    colors: [DesignColor.aquaGlow.opacity(0.95), Color.white.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .amber:
                return LinearGradient(
                    colors: [DesignColor.amberGlow.opacity(0.95), Color.white.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        var halo: Color {
            switch self {
            case .aqua:
                return DesignColor.aquaGlow
            case .amber:
                return DesignColor.amberGlow
            }
        }
    }

    let title: String
    var icon: String?
    var style: Style = .aqua
    var isEnabled: Bool = true
    var isPressed: Bool = false

    var body: some View {
        let opacity = isEnabled ? 1.0 : 0.5

        ZStack {
            RoundedRectangle(cornerRadius: DesignCornerRadius.pill)
                .fill(Color.clear)
                .shadow(color: style.halo.opacity(isPressed ? 0.35 : 0.55), radius: isPressed ? 12 : 18, x: 0, y: isPressed ? 4 : 12)
                .opacity(opacity)

            RoundedRectangle(cornerRadius: DesignCornerRadius.pill)
                .fill(style.background)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignCornerRadius.pill)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignCornerRadius.pill)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        .blur(radius: 1)
                        .offset(y: 1)
                        .mask(RoundedRectangle(cornerRadius: DesignCornerRadius.pill))
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .opacity(opacity)
                .overlay(buttonLabel.padding(.horizontal, DesignSpacing.md))
        }
        .frame(height: 54)
    }

    private var buttonLabel: some View {
        HStack(spacing: DesignSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignColor.ink.opacity(isEnabled ? 0.95 : 0.6))
            }
            Text(title)
                .font(DesignTypography.Title.font)
                .foregroundColor(DesignColor.ink.opacity(isEnabled ? 0.95 : 0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

/// Circular progress indicator styled like an enchanted ring.
struct ProgressRing: View {
    var progress: Double
    var showsPercentage: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let lineWidth = geometry.size.width * 0.12
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
                    .overlay(
                        Circle()
                            .stroke(DesignColor.deepWalnut.opacity(0.35), lineWidth: lineWidth)
                            .blur(radius: 4)
                    )
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [DesignColor.aquaGlow, DesignColor.amberGlow, DesignColor.aquaGlow]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: DesignColor.aquaGlow.opacity(0.6), radius: 6, x: 0, y: 0)
                    .shadow(color: DesignColor.amberGlow.opacity(0.3), radius: 12, x: 0, y: 0)
                if showsPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(DesignTypography.Title.font)
                        .foregroundColor(DesignColor.agedParchment)
                        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Decorative badge tile representing achievement state.
struct BadgeTile: View {
    enum State {
        case locked
        case unlocked
    }

    var title: String
    var subtitle: String
    var state: State

    var body: some View {
        VStack(spacing: DesignSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                    .fill(tileBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                            .stroke(DesignColor.ink.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: DesignColor.deepWalnut.opacity(0.35), radius: 8, x: 0, y: 6)
                badgeIcon
            }
            .frame(height: 100)

            VStack(spacing: DesignSpacing.xs) {
                Text(title)
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(DesignTypography.Caption.font)
                    .foregroundColor(DesignColor.ink.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DesignSpacing.sm)
        }
        .padding(DesignSpacing.md)
        .background(DesignColor.agedParchment)
        .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.card, style: .continuous))
    }

    private var tileBackground: some View {
        LinearGradient(
            colors: state == .unlocked
                ? [DesignColor.aquaGlow.opacity(0.75), DesignColor.amberGlow.opacity(0.6)]
                : [DesignColor.deepWalnut.opacity(0.6), DesignColor.deepWalnut.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var badgeIcon: some View {
        if state == .unlocked {
            Image(systemName: "seal.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color.white, DesignColor.amberGlow)
                .shadow(color: DesignColor.amberGlow.opacity(0.6), radius: 10, x: 0, y: 0)
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundColor(DesignColor.agedParchment.opacity(0.85))
                .shadow(color: Color.black.opacity(0.45), radius: 6, x: 0, y: 2)
        }
    }
}

/// A decorative slider track with gears; interactions are intentionally omitted.
struct GearSlider: View {
    var value: Double

    var body: some View {
        VStack(spacing: DesignSpacing.sm) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignColor.agedParchment.opacity(0.3))
                    .frame(height: 14)
                    .overlay(
                        Capsule()
                            .stroke(DesignColor.ink.opacity(0.15), lineWidth: 1)
                    )
                Capsule()
                    .fill(LinearGradient(colors: [DesignColor.aquaGlow, DesignColor.amberGlow], startPoint: .leading, endPoint: .trailing))
                    .frame(width: CGFloat(max(min(value, 1), 0)) * 220, height: 14)
                    .clipShape(Capsule())
                gear
                    .offset(x: CGFloat(max(min(value, 1), 0)) * 220 - 18)
            }
            .frame(width: 240)

            Text("Tune the arcane dial")
                .font(DesignTypography.Caption.font)
                .foregroundColor(DesignColor.agedParchment.opacity(0.8))
        }
    }

    private var gear: some View {
        ZStack {
            Circle()
                .fill(DesignColor.deepWalnut)
                .frame(width: 36, height: 36)
                .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 4)
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(DesignColor.agedParchment.opacity(0.9))
                    .frame(width: 6, height: 12)
                    .offset(y: -24)
                    .rotationEffect(.degrees(Double(index) / 8.0 * 360.0))
            }
            Circle()
                .stroke(DesignColor.agedParchment.opacity(0.8), lineWidth: 2)
                .frame(width: 22, height: 22)
        }
    }
}

/// Placeholder particle system for future magical sparkles.
struct StarParticles: View {
    private let count = 12

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    let point = position(for: index, in: size)
                    Circle()
                        .fill(index.isMultiple(of: 3) ? DesignColor.amberGlow : DesignColor.aquaGlow)
                        .frame(width: diameter(for: index), height: diameter(for: index))
                        .position(point)
                        .opacity(0.65)
                }
            }
        }
        .frame(width: 120, height: 120)
        .background(Color.clear)
    }

    private func position(for index: Int, in size: CGSize) -> CGPoint {
        let angle = Double(index) / Double(max(count, 1)) * 2 * .pi
        let radius = min(size.width, size.height) / 2 * (0.35 + 0.45 * pseudoRandom(for: index, seed: 31))
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let x = center.x + CGFloat(cos(angle)) * radius
        let y = center.y + CGFloat(sin(angle)) * radius
        return CGPoint(x: x, y: y)
    }

    private func diameter(for index: Int) -> CGFloat {
        3 + CGFloat(pseudoRandom(for: index, seed: 53)) * 4
    }

    private func pseudoRandom(for index: Int, seed: Int) -> Double {
        var hasher = Hasher()
        hasher.combine(index)
        hasher.combine(seed)
        let hash = hasher.finalize()
        let unsigned = UInt64(bitPattern: Int64(hash))
        return Double(unsigned % 10_000) / 10_000.0
    }
}

// MARK: - Previews

struct WoodCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSpacing.lg) {
            WoodCard {
                Text("Wood Card – Default")
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.agedParchment)
            }
            WoodCard(cornerRadius: DesignCornerRadius.soft) {
                VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                    Text("Custom Radius")
                        .font(DesignTypography.Title.font)
                        .foregroundColor(DesignColor.agedParchment)
                    Text("Supports flexible content layouts with the wood texture background.")
                        .font(DesignTypography.Body.font)
                        .foregroundColor(DesignColor.agedParchment.opacity(0.9))
                }
            }
        }
        .padding()
        .background(DesignColor.deepWalnut)
        .previewLayout(.sizeThatFits)
    }
}

struct ParchmentPage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSpacing.lg) {
            ParchmentPage {
                Text("Lore Entry")
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                Text("Parchment pages provide a soft reading surface for narrative content and annotations.")
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink.opacity(0.85))
            }
            ParchmentPage(inset: DesignSpacing.xl) {
                Text("Wide Insets")
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                Text("Adjustable padding supports diagrams and illustrations with breathing room.")
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink.opacity(0.75))
            }
        }
        .padding()
        .background(DesignColor.deepWalnut)
        .previewLayout(.sizeThatFits)
    }
}

struct GlowButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSpacing.lg) {
            GlowButton(title: "Begin Quest", icon: "flame.fill", style: .aqua, isEnabled: true, isPressed: false)
            GlowButton(title: "Craft Potion", icon: "hammer.fill", style: .amber, isEnabled: true, isPressed: true)
            GlowButton(title: "Coming Soon", icon: "clock.fill", style: .aqua, isEnabled: false, isPressed: false)
        }
        .padding()
        .background(DesignColor.deepWalnut)
        .previewLayout(.sizeThatFits)
    }
}

struct ProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: DesignSpacing.xl) {
            ProgressRing(progress: 0.25)
                .frame(width: 120)
            ProgressRing(progress: 0.66)
                .frame(width: 120)
            ProgressRing(progress: 1.0, showsPercentage: false)
                .frame(width: 120)
        }
        .padding()
        .background(DesignColor.deepWalnut)
        .previewLayout(.sizeThatFits)
    }
}

struct BadgeTile_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: DesignSpacing.lg) {
            BadgeTile(title: "Lore Master", subtitle: "Unlocked by collecting 50 codex entries.", state: .unlocked)
                .frame(width: 220)
            BadgeTile(title: "Beast Whisperer", subtitle: "Unlock by decoding the hidden bestiary.", state: .locked)
                .frame(width: 220)
        }
        .padding()
        .background(DesignColor.deepWalnut)
        .previewLayout(.sizeThatFits)
    }
}

struct GearSlider_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSpacing.lg) {
            GearSlider(value: 0.2)
            GearSlider(value: 0.5)
            GearSlider(value: 0.85)
        }
        .padding()
        .background(DesignColor.deepWalnut)
        .previewLayout(.sizeThatFits)
    }
}

struct StarParticles_Previews: PreviewProvider {
    static var previews: some View {
        StarParticles()
            .padding()
            .background(DesignColor.deepWalnut)
            .previewLayout(.sizeThatFits)
    }
}
