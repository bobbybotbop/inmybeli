import SwiftUI

struct CreateView: View {
    @EnvironmentObject var session: SessionStore
    @State private var recipes: [RecipePreview] = []
    @State private var isLoading = true
    @State private var showCreateFlow = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                header
                if isLoading {
                    Spacer()
                    ProgressView().frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    recipeList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.Palette.background)

            createButton
        }
        .task { await loadRecipes() }
        .fullScreenCover(isPresented: $showCreateFlow, onDismiss: {
            Task { await loadRecipes() }
        }) {
            CreateRecipeView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text("My Recipes")
                    .font(Theme.Typography.title)
                    .tracking(0.25)
                    .foregroundColor(Theme.Palette.darkBrown)
            }
            .padding(.leading, 24)
            .padding(.top, 20)

            Text("\(recipes.count) recipe\(recipes.count == 1 ? "" : "s")")
                .font(.system(size: 15))
                .tracking(0.15)
                .foregroundColor(Theme.Palette.lightBrown)
                .padding(.leading, 32)
                .padding(.bottom, 8)
        }
    }

    private var recipeList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(recipes) { recipe in
                    RecipeCard(preview: recipe)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 88)
        }
    }

    private var createButton: some View {
        Button { showCreateFlow = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("Create a Recipe")
                    .font(.system(size: 15))
                    .tracking(0.15)
            }
            .foregroundColor(Theme.Palette.cream)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.Palette.darkBrown)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.Palette.cream.opacity(0.3), lineWidth: 1))
            .shadow(color: .white.opacity(0.5), radius: 5, x: 2, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }

    private func loadRecipes() async {
        guard let userId = session.currentUser?.id else { return }
        isLoading = true
        do {
            recipes = try await RecipeService.shared.fetchRecipes(forUserId: userId)
        } catch {
            print("[CreateView] Failed to load recipes: \(error)")
        }
        isLoading = false
    }
}
