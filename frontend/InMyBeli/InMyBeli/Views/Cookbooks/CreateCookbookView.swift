import SwiftUI

struct CreateCookbookView: View {
    let onCreated: (CookbookDetail) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                title

                form

                Spacer()

                actions
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            .background(Theme.Palette.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var title: some View {
        Text("New Cookbook")
            .font(.system(size: 30, weight: .medium))
            .tracking(0.3)
            .foregroundColor(Theme.Palette.darkBrown)
    }

    private var form: some View {
        VStack(spacing: 10) {
            VStack(spacing: 20) {
                nameField
                descriptionField
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Palette.orangeBrown)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Name")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)
                .padding(.leading, 4)
            TextField(
                "",
                text: $name,
                prompt: Text("Themes of recipes?").foregroundColor(Theme.Palette.darkBrown.opacity(0.4))
            )
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)
                .tint(Theme.Palette.lightBrown)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hex: "EFEFEF"))
                )
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)
                .padding(.leading, 4)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "EFEFEF"))

                if description.isEmpty {
                    Text("Any specific details...")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.Palette.darkBrown.opacity(0.4))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.Palette.darkBrown)
                    .tint(Theme.Palette.lightBrown)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .frame(height: 96)
        }
    }

    private var actions: some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "A4A4A4"))
                    .frame(width: 88)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(hex: "EFEFEF"))
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            Spacer()

            Button {
                Task { await submit() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView().tint(Theme.Palette.cream)
                    } else {
                        Text("Next")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Theme.Palette.cream)
                    }
                }
                .frame(width: 88)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.Palette.darkBrown.opacity(canSubmit ? 1 : 0.5))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
        }
    }

    private func submit() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let cookbook = try await CookbookService.shared.create(
                name: trimmedName,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )
            onCreated(cookbook)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CreateCookbookView { _ in }
}
