import SwiftUI

struct ReviewsListView: View {
    let recipeId: Int
    let recipeTitle: String?

    @Environment(\.dismiss) private var dismiss
    @State private var reviews: [Review] = []
    @State private var isLoading = false
    @State private var loadError: String?

    init(recipeId: Int, recipeTitle: String? = nil) {
        self.recipeId = recipeId
        self.recipeTitle = recipeTitle
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header

                contentBody
                    .padding(.horizontal, 22)
                    .padding(.bottom, 30)
            }
            .padding(.top, 12)
        }
        .background(Theme.Palette.background)
        .scrollIndicators(.hidden)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(recipeTitle ?? "Reviews")
                .font(.system(size: 25, weight: .medium))
                .tracking(0.25)
                .foregroundColor(Theme.Palette.darkBrown)

            Text(countLabel)
                .font(.system(size: 15, weight: .regular))
                .tracking(0.15)
                .foregroundColor(Theme.Palette.lightBrown)
        }
    }

    private var countLabel: String {
        let count = reviews.count
        return count == 1 ? "1 review" : "\(count) reviews"
    }

    @ViewBuilder
    private var contentBody: some View {
        if isLoading && reviews.isEmpty {
            ProgressView()
                .tint(Theme.Palette.lightBrown)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if let loadError, reviews.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Couldn't load reviews")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text(loadError)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Palette.lightBrown.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if reviews.isEmpty {
            Text("No reviews yet.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
        } else {
            VStack(spacing: 14) {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            reviews = try await RecipeService.shared.fetchReviews(recipeId: recipeId)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StarRow(rating: review.rating)

            if let text = review.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .tracking(0.15)
                    .foregroundColor(Theme.Palette.darkBrown)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let dateLabel = formattedDate(review.updatedAt ?? review.createdAt) {
                Text(dateLabel)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(0.13)
                    .foregroundColor(Theme.Palette.lightBrown)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.cream)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Palette.lightBrown.opacity(0.2), lineWidth: 1)
        )
    }

    private func formattedDate(_ iso: String?) -> String? {
        guard let iso else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

private struct StarRow: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.Palette.orangeBrown)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReviewsListView(recipeId: 1, recipeTitle: "Tteokbokki")
    }
}
