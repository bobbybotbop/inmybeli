import SwiftUI

struct CookbookDetailView: View {
    let cookbook: Cookbook

    @Environment(\.dismiss) private var dismiss
    @State private var detail: CookbookDetail?
    @State private var isLoading = false
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 35) {
                titleBlock

                recipesList
            }
            .padding(.top, 28)
            .padding(.horizontal, 27)
            .padding(.bottom, 24)
        }
        .background(Theme.Palette.background)
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottomTrailing) {
            addRecipeButton
                .padding(.trailing, 19)
                .padding(.bottom, 26)
        }
        .toolbar {
            ToolbarItem(placement: .principal) { EmptyView() }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private var titleBlock: some View {
        VStack(spacing: 5) {
            Text(detail?.name ?? cookbook.name)
                .font(.system(size: 25, weight: .medium))
                .tracking(0.25)
                .foregroundColor(Theme.Palette.darkBrown)
                .multilineTextAlignment(.center)

            Text(recipeCountLabel)
                .font(.system(size: 15, weight: .regular))
                .tracking(0.15)
                .foregroundColor(Theme.Palette.lightBrown)
        }
        .frame(maxWidth: .infinity)
    }

    private var recipeCountLabel: String {
        let count = detail?.recipes.count ?? 0
        return count == 1 ? "1 recipe saved" : "\(count) recipes saved"
    }

    @ViewBuilder
    private var recipesList: some View {
        if isLoading && detail == nil {
            ProgressView().tint(Theme.Palette.lightBrown)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if let loadError, detail == nil {
            VStack(alignment: .leading, spacing: 6) {
                Text("Couldn't load cookbook")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text(loadError)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Palette.lightBrown.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let recipes = detail?.recipes, recipes.isEmpty {
            Text("No recipes in this cookbook yet.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
        } else if let recipes = detail?.recipes {
            VStack(spacing: 26) {
                ForEach(recipes) { preview in
                    NavigationLink(value: preview) {
                        RecipeCard(preview: preview)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var addRecipeButton: some View {
        HStack(spacing: 5) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Palette.cream)
            Text("Add Recipe")
                .font(.system(size: 15, weight: .regular))
                .tracking(0.15)
                .foregroundColor(Theme.Palette.cream)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.Palette.darkBrown)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.Palette.cream, lineWidth: 1)
        )
        .shadow(color: Color.white.opacity(0.4), radius: 8, x: 2, y: 4)
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            detail = try await CookbookService.shared.fetchDetail(id: cookbook.id)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CookbookDetailView(cookbook: Cookbook(id: 1, name: "Savory Tastes", description: nil))
    }
}
