import SwiftUI

struct CreateAccountView: View {
    let onComplete: (AuthSession) -> Void

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?

    private enum Field {
        case name, username, password, confirm
    }

    // One-off Figma colors not promoted to Theme.
    private let fieldFill = Color(hex: "EFEFEF")
    private let placeholderGray = Color(hex: "888888")
    private let photoPlaceholder = Color(hex: "D9D9D9")
    private let disabledFill = Color(hex: "F6F6F6")
    private let disabledStroke = Color(hex: "A4A4A4")

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var trimmedUsername: String { username.trimmingCharacters(in: .whitespaces) }

    private var validationError: String? {
        if trimmedName.isEmpty { return nil }
        if trimmedUsername.count < 3 { return "Username must be at least 3 characters." }
        if password.count < 8 { return "Password must be at least 8 characters." }
        if password != confirmPassword { return "Passwords don't match." }
        return nil
    }

    private var canSubmit: Bool {
        !trimmedName.isEmpty &&
        trimmedUsername.count >= 3 &&
        password.count >= 8 &&
        password == confirmPassword &&
        !isSubmitting
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 10) {
                    stepLabel
                    progressBar
                }
                .frame(width: 320)
                .frame(maxWidth: .infinity)
                .padding(.top, 30)

                VStack(spacing: 75) {
                    VStack(spacing: 60) {
                        photoBlock
                        inputsBlock
                    }
                    .frame(width: 329)

                    continueSection
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.background)
    }

    // MARK: - Progress

    private var stepLabel: some View {
        (Text("Step 1").font(.system(size: 15, weight: .bold))
         + Text(" of 3").font(.system(size: 15, weight: .light)))
            .tracking(0.15)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressBar: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.Palette.lightBrown)
                .frame(width: 100, height: 12)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(fieldFill)
                .frame(width: 110, height: 12)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(fieldFill)
                .frame(width: 100, height: 12)
        }
        .frame(width: 320, height: 12)
    }

    // MARK: - Photo

    private var photoBlock: some View {
        VStack(spacing: 20) {
            Button {
                // Profile picture upload not wired up in this UX pass.
            } label: {
                Circle()
                    .fill(photoPlaceholder)
                    .frame(width: 115, height: 115)
            }
            .buttonStyle(.plain)

            Text("Add Photo")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.black)
        }
    }

    // MARK: - Inputs

    private var inputsBlock: some View {
        VStack(spacing: 30) {
            inputField(label: "Your Name") {
                TextField("", text: $name, prompt: placeholder("First Name, Last Name"))
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .username }
            }

            inputField(label: "Username") {
                TextField("", text: $username, prompt: placeholder("Begin typing..."))
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            inputField(label: "Password") {
                SecureField("", text: $password, prompt: placeholder("Begin typing..."))
                    .textContentType(.newPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .confirm }
            }

            inputField(label: "Confirm Password") {
                SecureField("", text: $confirmPassword, prompt: placeholder("Re-enter password"))
                    .textContentType(.newPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .confirm)
                    .submitLabel(.done)
                    .onSubmit { submit() }
            }
        }
    }

    private func placeholder(_ text: String) -> Text {
        Text(text)
            .font(.system(size: 15, weight: .light))
            .foregroundColor(placeholderGray)
    }

    private func inputField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .padding(.leading, 10)

            content()
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .tint(Theme.Palette.lightBrown)
                .textFieldStyle(.plain)
                .padding(.leading, 20)
                .padding(.trailing, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(fieldFill)
                )
        }
    }

    // MARK: - Continue

    private var continueSection: some View {
        VStack(spacing: 12) {
            if let message = errorMessage ?? validationError, !message.isEmpty {
                Text(message)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Palette.orangeBrown)
                    .frame(width: 329, alignment: .leading)
            }

            continueButton
        }
    }

    private var continueButton: some View {
        Button(action: submit) {
            ZStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(canSubmit ? Theme.Palette.cream : disabledStroke)
                } else {
                    Text("Continue")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(canSubmit ? Theme.Palette.cream : disabledStroke)
                }
            }
            .frame(width: 230, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(canSubmit ? Theme.Palette.darkBrown : disabledFill)
            )
            .overlay(
                Group {
                    if !canSubmit {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(disabledStroke, lineWidth: 1)
                    }
                }
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
                let session = try await AuthService.shared.createAccount(
                    name: trimmedName,
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
        CreateAccountView { _ in }
    }
}
