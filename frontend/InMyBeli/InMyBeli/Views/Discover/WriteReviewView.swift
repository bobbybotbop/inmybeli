import SwiftUI

struct WriteReviewView: View {
    let recipeId: Int
    var onSubmitted: ((Review) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var notesFocused: Bool

    private let starColor = Color(hex: "F5A94C")
    private let asteriskColor = Color(hex: "C51B1B")
    private let notesFill = Color(hex: "EAEAEA")
    private let notesStroke = Color(hex: "F1F1F1")
    private let placeholderGray = Color(hex: "888888")

    private var canSubmit: Bool {
        rating >= 1 && rating <= 5 && !isSubmitting
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle()
                .padding(.top, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 35) {
                    header

                    VStack(alignment: .leading, spacing: 25) {
                        reviewSection
                        notesSection
                    }

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.Palette.orangeBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    saveButton
                        .frame(maxWidth: .infinity)
                        .padding(.top, 35)
                }
                .padding(.horizontal, 36)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
            .fill(Theme.Palette.background)
        )
    }

    private var header: some View {
        HStack(spacing: 15) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)

            Text("Write a Review")
                .font(.system(size: 30, weight: .regular))
                .tracking(0.3)
                .foregroundColor(Theme.Palette.darkBrown)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                Text("Review ")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text("*")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundColor(asteriskColor)
            }

            starRating
        }
    }

    private var starRating: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    rating = index
                } label: {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.system(size: 27, weight: .regular))
                        .foregroundColor(index <= rating ? starColor : Theme.Palette.lightBrown.opacity(0.4))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Notes")
                .font(.system(size: 23, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(notesFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(notesStroke, lineWidth: 1)
                    )

                if notes.isEmpty {
                    Text("Begin typing...")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(placeholderGray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                }

                TextEditor(text: $notes)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.Palette.darkBrown)
                    .tint(Theme.Palette.lightBrown)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .focused($notesFocused)
            }
            .frame(height: 120)
        }
    }

    private var saveButton: some View {
        Button(action: submit) {
            ZStack {
                if isSubmitting {
                    ProgressView().tint(Theme.Palette.cream)
                } else {
                    Text("Save")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Palette.cream)
                }
            }
            .frame(maxWidth: 230)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(canSubmit ? Theme.Palette.darkBrown : Theme.Palette.darkBrown.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func submit() {
        guard canSubmit else { return }
        errorMessage = nil
        isSubmitting = true
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let text: String? = trimmed.isEmpty ? nil : trimmed
        Task {
            defer { isSubmitting = false }
            do {
                let review = try await RecipeService.shared.submitReview(
                    recipeId: recipeId,
                    rating: rating,
                    text: text
                )
                onSubmitted?(review)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    Color.black.opacity(0.4)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            WriteReviewView(recipeId: 1)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
}
