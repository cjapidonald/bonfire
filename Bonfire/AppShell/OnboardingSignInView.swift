import AuthenticationServices
import SwiftUI
import UIKit

struct OnboardingSignInView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var userProfileStore: UserProfileStore

    @State private var isProcessing = false
    @State private var errorMessageKey: LocalizedStringKey?
    @State private var isParentalGatePresented = false
    @State private var parentalGateChallenge = ParentalGateChallenge.random()
    @State private var signInCoordinator: SignInCoordinator?

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

                ZStack {
                    SignInWithAppleButton(.signIn) { _ in } onCompletion: { _ in }
                    .signInWithAppleButtonStyle(.black)
                    .allowsHitTesting(false)

                    Button(action: presentParentalGate) {
                        Label("Sign in with Apple", systemImage: "apple.logo")
                            .labelStyle(.titleAndIcon)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(0.01)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Sign in with Apple"))
                    .accessibilityHint(Text(String(localized: "parentalGate.hint")))
                    .disabled(isProcessing)
                }
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal)
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
        .sheet(isPresented: $isParentalGatePresented) {
            ParentalGatePrompt(
                challenge: parentalGateChallenge,
                onSuccess: completeParentalGateAndSignIn,
                onCancel: cancelParentalGate
            )
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
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

    private func presentParentalGate() {
        parentalGateChallenge = ParentalGateChallenge.random()
        isParentalGatePresented = true
    }

    private func completeParentalGateAndSignIn() {
        isParentalGatePresented = false
        parentalGateChallenge = ParentalGateChallenge.random()

        DispatchQueue.main.async {
            startSignInFlow()
        }
    }

    private func cancelParentalGate() {
        isParentalGatePresented = false
        parentalGateChallenge = ParentalGateChallenge.random()
    }

    private func startSignInFlow() {
        isProcessing = true
        errorMessageKey = nil

        let coordinator = SignInCoordinator { result in
            handleAuthorizationResult(result)
            signInCoordinator = nil
        }

        signInCoordinator = coordinator
        coordinator.start()
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

// MARK: - Parental Gate Support

private struct ParentalGateChallenge: Equatable {
    let left: Int
    let right: Int

    var prompt: String {
        String(format: String(localized: "parentalGate.question"), left, right)
    }

    var answer: Int { left + right }

    static func random() -> ParentalGateChallenge {
        ParentalGateChallenge(left: Int.random(in: 3...9), right: Int.random(in: 2...9))
    }
}

private struct ParentalGatePrompt: View {
    let challenge: ParentalGateChallenge
    var onSuccess: () -> Void
    var onCancel: () -> Void

    @State private var response: String = ""
    @State private var showError = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(String(localized: "parentalGate.description"))
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text(challenge.prompt)
                        .font(.title3.weight(.semibold))

                    TextField(String(localized: "parentalGate.field.placeholder"), text: $response)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(validateResponse)
                        .accessibilityHint(Text(String(localized: "parentalGate.hint")))
                }

                if showError {
                    Text(String(localized: "parentalGate.error"))
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                }
            }
            .navigationTitle(Text(String(localized: "parentalGate.title")))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "parentalGate.cancel")) {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "parentalGate.cta")) {
                        validateResponse()
                    }
                    .disabled(response.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFieldFocused = true
            }
        }
        .onChange(of: response) { _ in
            if showError {
                showError = false
            }
        }
    }

    private func validateResponse() {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), value == challenge.answer else {
            withAnimation {
                showError = true
            }
            return
        }

        onSuccess()
    }
}

private final class SignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    private var controller: ASAuthorizationController?

    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func start() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()

        self.controller = controller
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
