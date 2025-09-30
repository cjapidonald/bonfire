import SwiftUI

struct TabPlaceholderView: View {
    let iconSystemName: String
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey

    init(
        iconSystemName: String,
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey = LocalizedStringKey("placeholder.comingSoon")
    ) {
        self.iconSystemName = iconSystemName
        self.titleKey = titleKey
        self.messageKey = messageKey
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconSystemName)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(titleKey)
                .font(.title2.weight(.semibold))

            Text(messageKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
