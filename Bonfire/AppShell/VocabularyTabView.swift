import SwiftUI

struct VocabularyTabView: View {
    var body: some View {
        NavigationStack {
            TabPlaceholderView(
                iconSystemName: "text.book.closed",
                titleKey: LocalizedStringKey("vocab.placeholder.title")
            )
            .navigationTitle(LocalizedStringKey("vocab.title"))
        }
    }
}

struct VocabularyTabView_Previews: PreviewProvider {
    static var previews: some View {
        VocabularyTabView()
    }
}
