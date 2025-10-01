import AuthenticationServices
import SwiftUI

struct OnboardingSignInView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var userProfileStore: UserProfileStore

    @State private var isProcessing = false
    @State private var errorMessageKey: LocalizedStringKey?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Text(LocalizedStringKey("onboarding.title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStringKey("onboarding.subtitle"))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                if let errorMessageKey {
                    Text(errorMessageKey)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if isProcessing {
                    ProgressView()
                }

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                    isProcessing = true
                    errorMessageKey = nil
                } onCompletion: { result in
                    handleAuthorizationResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal)
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.6 : 1.0)

                Text(LocalizedStringKey("onboarding.disclaimer"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical, 32)
            .navigationTitle(LocalizedStringKey("onboarding.navigationTitle"))
        }
        .environment(\.locale, languageManager.locale)
    }

    private func handleAuthorizationResult(_ result: Result<ASAuthorization, Error>) {
        isProcessing = false

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessageKey = LocalizedStringKey("onboarding.error.generic")
                return
            }

            let displayName = resolvedDisplayName(from: credential)
            userProfileStore.saveProfile(
                id: credential.user,
                displayName: displayName,
                avatarIdentifier: "default-parent",
                language: languageManager.currentLanguage
            )
            errorMessageKey = nil

        case .failure:
            errorMessageKey = LocalizedStringKey("onboarding.error.generic")
        }
    }

    private func resolvedDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String {
        if let fullName = credential.fullName {
            let components = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            if !components.isEmpty {
                return components.joined(separator: " ")
            }
        }

        if let email = credential.email, !email.isEmpty {
            return email
        }

        return String(localized: "onboarding.defaultDisplayName")
    }
}

struct OnboardingSignInView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingSignInView()
            .environmentObject(LanguageManager())
            .environmentObject(UserProfileStore.preview)
    }
}
