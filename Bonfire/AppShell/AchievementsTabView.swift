import SwiftUI

struct AchievementsTabView: View {
    @StateObject private var viewModel: AchievementsViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 240), spacing: DesignSpacing.xl)
    ]

    init(viewModel: AchievementsViewModel = AchievementsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: DesignSpacing.xl) {
                    ForEach(viewModel.progress) { progress in
                        AchievementPatchView(progress: progress)
                    }
                }
                .padding(.horizontal, DesignSpacing.xl)
                .padding(.vertical, DesignSpacing.xl)
            }
            .background(DesignColor.agedParchment.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("achievements.title"))
        }
    }
}

struct AchievementsTabView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsTabView(viewModel: .preview)
    }
}
