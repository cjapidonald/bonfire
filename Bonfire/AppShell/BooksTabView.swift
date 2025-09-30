import SwiftUI

struct BooksTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(LocalizedStringKey("books.section.library")) {
                    NavigationLink {
                        ReaderView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey("books.sample.title"))
                                .font(.headline)

                            Text(LocalizedStringKey("books.sample.subtitle"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(LocalizedStringKey("books.title"))
        }
    }
}

struct BooksTabView_Previews: PreviewProvider {
    static var previews: some View {
        BooksTabView()
    }
}
