import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var recipes: [RecipePreview] = []
    @State private var isLoading = false
    @State private var loadError: String?

    private var filteredRecipes: [RecipePreview] {
        guard !searchText.isEmpty else { return recipes }
        let needle = searchText.lowercased()
        return recipes.filter {
            $0.title.lowercased().contains(needle) ||
            ($0.cuisine?.lowercased().contains(needle) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    SearchBar(text: $searchText)

                    VStack(alignment: .leading, spacing: 18) {
                        Text("Popular Recipes")
                            .font(Theme.Typography.title)
                            .tracking(0.25)
                            .foregroundColor(Theme.Palette.darkBrown)

                        recipesSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 12)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .background(Theme.Palette.background)
            .scrollIndicators(.hidden)
            .navigationDestination(for: RecipePreview.self) { preview in
                RecipeDetailView(preview: preview)
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    @ViewBuilder
    private var recipesSection: some View {
        if isLoading && recipes.isEmpty {
            HStack {
                Spacer()
                ProgressView().tint(Theme.Palette.lightBrown)
                Spacer()
            }
            .padding(.top, 40)
        } else if let loadError, recipes.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Couldn't load recipes")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text(loadError)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Palette.lightBrown.opacity(0.8))
            }
        } else if recipes.isEmpty {
            Text("No recipes yet — be the first to create one.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
        } else {
            VStack(spacing: 24) {
                ForEach(filteredRecipes) { preview in
                    NavigationLink(value: preview) {
                        RecipeCard(preview: preview)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            recipes = try await RecipeService.shared.fetchFeed()
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    DiscoverView()
}
