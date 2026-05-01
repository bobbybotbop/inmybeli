import SwiftUI

struct LoginView: View {
    let onComplete: (AuthSession) -> Void

    @State private var usernameOrName: String = ""
    @State private var password: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?

    private enum Field {
        case username, password
    }

    private var trimmedUsername: String {
        usernameOrName.trimmingCharacters(in: .whitespaces)
    }

    private var canSubmit: Bool {
        !trimmedUsername.isEmpty && !password.isEmpty && !isSubmitting
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 120)

                VStack(spacing: 0) {
                    profilePhotoBlock

                    Spacer().frame(height: 60)

                    VStack(spacing: 30) {
                        field(label: "Username") {
                            TextField("", text: $usernameOrName, prompt: placeholderText("Begin typing..."))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }

                        field(label: "Password") {
                            SecureField("", text: $password, prompt: placeholderText("Begin typing..."))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .password)
                                .submitLabel(.done)
                                .onSubmit { submit() }
                        }
                    }

                    if let message = errorMessage, !message.isEmpty {
                        Text(message)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.Palette.orangeBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                    }

                    Spacer().frame(height: 153)

                    continueButton
                }
                .frame(width: 329)

                Spacer().frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.background)
    }

    private var profilePhotoBlock: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "EFEFEF"))
                .frame(width: 115, height: 115)
            Text("Add Photo")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(hex: "888888"))
        }
    }

    private func placeholderText(_ text: String) -> Text {
        Text(text)
            .font(.system(size: 15, weight: .light))
            .foregroundColor(Color(hex: "888888"))
    }

    private func field<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .padding(.leading, 4)

            content()
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .tint(Theme.Palette.lightBrown)
                .textFieldStyle(.plain)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.leading, 20)
                .padding(.trailing, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hex: "EFEFEF"))
                )
        }
    }

    private var continueButton: some View {
        Button(action: submit) {
            ZStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(canSubmit ? Theme.Palette.cream : Color(hex: "A4A4A4"))
                } else {
                    Text("Continue")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(canSubmit ? Theme.Palette.cream : Color(hex: "A4A4A4"))
                }
            }
            .frame(width: 230, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(canSubmit ? Theme.Palette.darkBrown : Color(hex: "F6F6F6"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(canSubmit ? Color.clear : Color(hex: "A4A4A4"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func submit() {
        guard canSubmit else { return }
        errorMessage = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let session = try await AuthService.shared.login(
                    username: trimmedUsername,
                    password: password
                )
                onComplete(session)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(onComplete: { _ in })
    }
}
