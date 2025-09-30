import SwiftUI

struct AchievementsTabView: View {
    var body: some View {
        NavigationStack {
            TabPlaceholderView(
                iconSystemName: "trophy",
                titleKey: LocalizedStringKey("achievements.placeholder.title")
            )
            .navigationTitle(LocalizedStringKey("achievements.title"))
        }
    }
}

struct AchievementsTabView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsTabView()
    }
}
