import SwiftUI

struct DesignSystemDemoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.xl) {
                paletteSection
                typographySection
                spacingSection
                cornerRadiusSection
                textureSection
                componentSection
            }
            .padding(DesignSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignColor.deepWalnut.ignoresSafeArea())
    }

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            sectionHeader("Color Palette")
            paletteRow(name: "Deep Walnut", color: DesignColor.deepWalnut, description: "Primary background and elevated wood surfaces")
            paletteRow(name: "Aged Parchment", color: DesignColor.agedParchment, description: "Content surfaces and cards")
            paletteRow(name: "Ink", color: DesignColor.ink, description: "Primary text and high contrast accents")
            paletteRow(name: "Aqua Glow", color: DesignColor.aquaGlow, description: "Magical highlights and actions")
            paletteRow(name: "Amber Glow", color: DesignColor.amberGlow, description: "Secondary highlights and warnings")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                .fill(DesignColor.agedParchment)
                .shadow(color: DesignColor.deepWalnut.opacity(0.35), radius: 12, x: 0, y: 8)
        )
    }

    private func paletteRow(name: String, color: Color, description: String) -> some View {
        HStack(alignment: .center, spacing: DesignSpacing.md) {
            RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                        .stroke(DesignColor.ink.opacity(0.1), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                Text(name)
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                Text(description)
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink.opacity(0.8))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            sectionHeader("Typography")
            VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                Text("Display – Hearth & Heroes")
                    .font(DesignTypography.Display.font)
                    .foregroundColor(DesignColor.amberGlow)
                    .shadow(color: DesignColor.deepWalnut.opacity(0.6), radius: 4, x: 0, y: 2)
                Text("Title – Tales of the Bonfire")
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                Text("Body – SF Pro keeps long-form reading comfortable and accessible across locales.")
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink)
                Text("Caption – Quick notes, tooltips, and metadata.")
                    .font(DesignTypography.Caption.font)
                    .foregroundColor(DesignColor.ink.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                    .fill(DesignColor.agedParchment)
            )
        }
    }

    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            sectionHeader("Spacing Scale")
            HStack(spacing: DesignSpacing.lg) {
                spacingSample(label: "XS", value: DesignSpacing.xs)
                spacingSample(label: "SM", value: DesignSpacing.sm)
                spacingSample(label: "MD", value: DesignSpacing.md)
                spacingSample(label: "LG", value: DesignSpacing.lg)
                spacingSample(label: "XL", value: DesignSpacing.xl)
                spacingSample(label: "XXL", value: DesignSpacing.xxl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                    .fill(DesignColor.agedParchment)
            )
        }
    }

    private func spacingSample(label: String, value: CGFloat) -> some View {
        VStack(spacing: DesignSpacing.xs) {
            Text(label)
                .font(DesignTypography.Caption.font)
                .foregroundColor(DesignColor.ink)
            RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                .fill(DesignColor.aquaGlow.opacity(0.6))
                .frame(width: max(value * 2, DesignSpacing.lg), height: DesignSpacing.sm)
            Text("\(Int(value)) pt")
                .font(DesignTypography.Caption.font)
                .foregroundColor(DesignColor.ink.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var cornerRadiusSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            sectionHeader("Corner Radius Tokens")
            HStack(spacing: DesignSpacing.lg) {
                cornerSample(name: "Sharp", radius: DesignCornerRadius.sharp)
                cornerSample(name: "Soft", radius: DesignCornerRadius.soft)
                cornerSample(name: "Card", radius: DesignCornerRadius.card)
                cornerSample(name: "Pill", radius: DesignCornerRadius.pill, isPill: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                .fill(DesignColor.agedParchment)
        )
    }

    private func cornerSample(name: String, radius: CGFloat, isPill: Bool = false) -> some View {
        VStack(spacing: DesignSpacing.sm) {
            RoundedRectangle(cornerRadius: isPill ? DesignCornerRadius.pill : radius)
                .fill(DesignColor.amberGlow.opacity(0.8))
                .frame(width: isPill ? 88 : 60, height: isPill ? 32 : 60)
                .overlay(
                    RoundedRectangle(cornerRadius: isPill ? DesignCornerRadius.pill : radius)
                        .stroke(DesignColor.ink.opacity(0.15), lineWidth: 1)
                )
            Text(name)
                .font(DesignTypography.Caption.font)
                .foregroundColor(DesignColor.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private var textureSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            sectionHeader("Texture Placeholders")
            ForEach(DesignTexture.allCases) { texture in
                VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                    Text(texture.rawValue.capitalized)
                        .font(DesignTypography.Title.font)
                        .foregroundColor(DesignColor.ink)
                    texture.preview
                        .scaledToFill()
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                                .stroke(DesignColor.ink.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                .fill(DesignColor.agedParchment)
        )
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(DesignTypography.Title.font)
            .foregroundColor(DesignColor.amberGlow)
            .padding(.bottom, DesignSpacing.sm)
    }

    private var componentSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.lg) {
            sectionHeader("Visual Shell Components")

            VStack(alignment: .leading, spacing: DesignSpacing.lg) {
                WoodCard {
                    VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                        Text("Wood Card")
                            .font(DesignTypography.Title.font)
                            .foregroundColor(DesignColor.agedParchment)
                        Text("Rich wood grain container for hero moments and featured actions.")
                            .font(DesignTypography.Body.font)
                            .foregroundColor(DesignColor.agedParchment.opacity(0.9))
                        GlowButton(title: "Equip Relic", icon: "wand.and.sparkles", style: .aqua)
                    }
                }

                ParchmentPage {
                    VStack(alignment: .leading, spacing: DesignSpacing.md) {
                        Text("Parchment Page")
                            .font(DesignTypography.Title.font)
                            .foregroundColor(DesignColor.ink)
                        Text("Use for lore entries and long-form reading surfaces.")
                            .font(DesignTypography.Body.font)
                            .foregroundColor(DesignColor.ink.opacity(0.8))
                        ProgressRing(progress: 0.72)
                            .frame(width: 120)
                            .padding(.top, DesignSpacing.md)
                    }
                }

                VStack(alignment: .leading, spacing: DesignSpacing.lg) {
                    Text("Badge Tiles")
                        .font(DesignTypography.Title.font)
                        .foregroundColor(DesignColor.amberGlow)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSpacing.lg) {
                            BadgeTile(title: "Lore Master", subtitle: "Unlocked", state: .unlocked)
                                .frame(width: 180)
                            BadgeTile(title: "Trailblazer", subtitle: "Unlock by mapping every realm", state: .locked)
                                .frame(width: 180)
                        }
                        .padding(.horizontal, DesignSpacing.sm)
                    }
                }

                VStack(alignment: .leading, spacing: DesignSpacing.md) {
                    Text("Gear Slider")
                        .font(DesignTypography.Title.font)
                        .foregroundColor(DesignColor.amberGlow)
                    GearSlider(value: 0.6)
                }

                VStack(alignment: .leading, spacing: DesignSpacing.md) {
                    Text("Difficulty Gear Slider")
                        .font(DesignTypography.Title.font)
                        .foregroundColor(DesignColor.amberGlow)
                    DifficultyGearSlider()
                }

                VStack(alignment: .leading, spacing: DesignSpacing.md) {
                    Text("Star Particles")
                        .font(DesignTypography.Title.font)
                        .foregroundColor(DesignColor.amberGlow)
                    StarParticles()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                    .fill(DesignColor.deepWalnut.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignCornerRadius.card)
                            .stroke(DesignColor.ink.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
}

struct DesignSystemDemoView_Previews: PreviewProvider {
    static var previews: some View {
        DesignSystemDemoView()
            .environment(\.colorScheme, .dark)
    }
}
