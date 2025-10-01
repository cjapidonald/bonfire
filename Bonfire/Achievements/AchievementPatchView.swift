import SwiftUI

struct AchievementPatchView: View {
    let progress: AchievementProgress

    var body: some View {
        VStack(spacing: DesignSpacing.lg) {
            emblem
            VStack(spacing: DesignSpacing.sm) {
                Text(progress.achievement.title)
                    .font(DesignTypography.Title.font)
                    .multilineTextAlignment(.center)
                    .foregroundColor(DesignColor.ink)
                Text(progress.achievement.detail)
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            progressSection
        }
        .padding(DesignSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(patchBackground)
        .overlay(embroideryBorder)
        .overlay(stitchBorder)
        .saturation(progress.isUnlocked ? 1 : 0)
        .opacity(progress.isUnlocked ? 1 : 0.7)
        .animation(.easeInOut(duration: 0.25), value: progress.isUnlocked)
    }

    private var emblem: some View {
        ZStack {
            Circle()
                .fill(progress.achievement.gradient)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 4)
                )
                .overlay(
                    Circle()
                        .stroke(progress.achievement.accentColor.opacity(0.5), lineWidth: 8)
                        .blur(radius: 6)
                        .opacity(0.7)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
            Image(systemName: progress.achievement.iconSystemName)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
        }
        .frame(width: 96, height: 96)
    }

    private var progressSection: some View {
        VStack(spacing: DesignSpacing.sm) {
            ProgressView(value: progress.completionFraction)
                .progressViewStyle(.linear)
                .tint(progress.achievement.accentColor)
            Text(progress.progressDescription)
                .font(DesignTypography.Caption.font.monospacedDigit())
                .foregroundColor(DesignColor.ink.opacity(0.7))
        }
    }

    private var patchBackground: some View {
        RoundedRectangle(cornerRadius: DesignCornerRadius.card, style: .continuous)
            .fill(Color.white.opacity(0.95))
            .overlay(
                DesignTexture.parchment.preview
                    .opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.card, style: .continuous))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 6)
    }

    private var embroideryBorder: some View {
        RoundedRectangle(cornerRadius: DesignCornerRadius.card, style: .continuous)
            .inset(by: 6)
            .stroke(progress.achievement.accentColor.opacity(0.45), lineWidth: 6)
    }

    private var stitchBorder: some View {
        RoundedRectangle(cornerRadius: DesignCornerRadius.card, style: .continuous)
            .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
    }
}

struct AchievementPatchView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementPatchView(progress: AchievementsViewModel.preview.progress.first!)
            .padding()
            .background(DesignColor.agedParchment)
    }
}
