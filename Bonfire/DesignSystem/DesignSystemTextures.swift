import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Texture tokens provide thematic backgrounds for surfaces.
/// They attempt to load an asset by name and gracefully fall back to
/// lightweight programmatic placeholders so binary textures can remain
/// out of source control until final artwork ships.
enum DesignTexture: String, CaseIterable, Identifiable {
    case wood
    case parchment

    var id: String { rawValue }

    /// Asset catalog name that designers can replace with production artwork.
    var assetName: String {
        switch self {
        case .wood:
            return "WoodTexturePlaceholder"
        case .parchment:
            return "ParchmentTexturePlaceholder"
        }
    }

    /// Attempt to load an image from the asset catalog.
    func image(bundle: Bundle? = nil) -> Image? {
        #if canImport(UIKit)
        if let uiImage = UIImage(named: assetName, in: bundle ?? .main, with: nil) {
            return Image(uiImage: uiImage)
        }
        #endif
        return nil
    }

    /// A reusable SwiftUI view that renders either the asset texture
    /// or a procedurally generated placeholder.
    @ViewBuilder
    var preview: some View {
        if let asset = image() {
            asset
                .resizable()
                .renderingMode(.original)
                .accessibilityLabel(Text(accessibilityLabel))
        } else {
            TextureFallback(style: self)
                .accessibilityLabel(Text(accessibilityLabel))
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .wood:
            return "Wood grain texture placeholder"
        case .parchment:
            return "Aged parchment texture placeholder"
        }
    }
}

private struct TextureFallback: View {
    let style: DesignTexture

    var body: some View {
        switch style {
        case .wood:
            wood
        case .parchment:
            parchment
        }
    }

    private var wood: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.20, green: 0.12, blue: 0.07),
                    Color(red: 0.26, green: 0.16, blue: 0.10),
                    Color(red: 0.18, green: 0.10, blue: 0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black.opacity(0.35), location: 0.0),
                        .init(color: Color.clear, location: 0.45),
                        .init(color: Color.black.opacity(0.25), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            GrainOverlay()
        }
    }

    private var parchment: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.90, blue: 0.76),
                    Color(red: 0.90, green: 0.84, blue: 0.70),
                    Color(red: 0.97, green: 0.94, blue: 0.83)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            SpeckleOverlay()
        }
    }
}

private struct GrainOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let stripeWidth = max(geometry.size.width / 32, 2)
            let stripeCount = max(Int(ceil(geometry.size.width / stripeWidth)), 1)
            HStack(spacing: 0) {
                ForEach(0..<stripeCount, id: \.self) { index in
                    Color.white.opacity(index.isMultiple(of: 2) ? 0.08 : 0.02)
                        .frame(width: stripeWidth)
                }
            }
        }
        .blendMode(.overlay)
        .opacity(0.35)
    }
}

private struct SpeckleOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let columns = Int(ceil(geometry.size.width / 16))
            let rows = Int(ceil(geometry.size.height / 16))
            ZStack {
                ForEach(0..<rows * columns, id: \.self) { index in
                    let column = index % columns
                    let row = index / columns
                    Circle()
                        .fill(Color.black.opacity(opacity(for: index)))
                        .frame(width: 3, height: 3)
                        .offset(
                            x: CGFloat(column) * 16 + xOffset(for: index),
                            y: CGFloat(row) * 16 + yOffset(for: index)
                        )
                }
            }
        }
        .blendMode(.multiply)
        .opacity(0.45)
    }

    private func opacity(for index: Int) -> Double {
        0.02 + 0.04 * pseudoRandom(for: index, seed: 11)
    }

    private func xOffset(for index: Int) -> CGFloat {
        CGFloat(pseudoRandom(for: index, seed: 23) * 8.0 - 4.0)
    }

    private func yOffset(for index: Int) -> CGFloat {
        CGFloat(pseudoRandom(for: index, seed: 47) * 8.0 - 4.0)
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
