import SwiftUI

struct CreateAccountView: View {
    let onComplete: (AuthSession) -> Void

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?

    private enum Field {
        case name, username, password, confirm
    }

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
            VStack(alignment: .leading, spacing: 28) {
                heading

                VStack(spacing: 14) {
                    field(label: "Name", systemImage: "person") {
                        TextField("Your full name", text: $name)
                            .textContentType(.name)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .username }
                    }

                    field(label: "Username", systemImage: "at") {
                        TextField("at least 3 characters", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }

                    field(label: "Password", systemImage: "lock") {
                        passwordField($password, placeholder: "at least 8 characters", focus: .password) {
                            focusedField = .confirm
                        }
                    }

                    field(label: "Confirm Password", systemImage: "lock.rotation") {
                        passwordField($confirmPassword, placeholder: "re-enter password", focus: .confirm) {
                            submit()
                        }
                    }
                }

                if let message = errorMessage ?? validationError, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.Palette.orangeBrown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                primaryButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.background)
        .navigationBarBackButtonHidden(true)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create your account")
                .font(.system(size: 28, weight: .semibold))
                .tracking(0.28)
                .foregroundColor(Theme.Palette.darkBrown)
            Text("A few quick details to get cooking.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Theme.Palette.lightBrown)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field<Content: View>(
        label: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .tracking(0.13)
                .foregroundColor(Theme.Palette.darkBrown.opacity(0.7))

            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.Palette.lightBrown)
                    .frame(width: 18)

                content()
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Theme.Palette.darkBrown)
                    .tint(Theme.Palette.lightBrown)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.Palette.darkBrown.opacity(0.10), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func passwordField(
        _ binding: Binding<String>,
        placeholder: String,
        focus: Field,
        onSubmit: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Group {
                if showPassword {
                    TextField(placeholder, text: binding)
                } else {
                    SecureField(placeholder, text: binding)
                }
            }
            .textContentType(focus == .password ? .newPassword : .newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: focus)
            .submitLabel(focus == .password ? .next : .done)
            .onSubmit(onSubmit)

            if focus == .password {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: submit) {
            ZStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(0.16)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(canSubmit ? Theme.Palette.lightBrown : Theme.Palette.lightBrown.opacity(0.4))
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
