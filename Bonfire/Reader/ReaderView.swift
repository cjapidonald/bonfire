import SwiftUI

struct ReaderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("reader.placeholder.heading"))
                    .font(.title.weight(.semibold))

                Text(LocalizedStringKey("reader.placeholder.body"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(LocalizedStringKey("reader.title"))
    }
}

struct ReaderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReaderView()
        }
    }
}
