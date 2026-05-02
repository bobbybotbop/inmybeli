import SwiftUI

private let savedCookbookName = "saved"

struct CookbooksView: View {
    @State private var cookbooks: [Cookbook] = []
    @State private var savedCookbookId: Int?
    @State private var savedRecipes: [RecipePreview] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showCreateSheet = false

    private var personalCookbooks: [Cookbook] {
        cookbooks.filter { $0.name.lowercased() != savedCookbookName }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 48) {
                    header

                    contentBody
                }
                .padding(.top, 12)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Theme.Palette.background)
            .scrollIndicators(.hidden)
            .navigationDestination(for: Cookbook.self) { cookbook in
                CookbookDetailView(cookbook: cookbook)
            }
            .navigationDestination(for: RecipePreview.self) { preview in
                RecipeDetailView(preview: preview)
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCookbookView { newCookbook in
                    showCreateSheet = false
                    Task { await load() }
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)
            Text("Cookbooks")
                .font(Theme.Typography.title)
                .tracking(0.25)
                .foregroundColor(Theme.Palette.darkBrown)
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        if isLoading && cookbooks.isEmpty {
            HStack {
                Spacer()
                ProgressView().tint(Theme.Palette.lightBrown)
                Spacer()
            }
            .padding(.top, 40)
        } else if let loadError, cookbooks.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Couldn't load cookbooks")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Palette.darkBrown)
                Text(loadError)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Palette.lightBrown.opacity(0.8))
            }
        } else {
            VStack(alignment: .leading, spacing: 48) {
                myCookbooksSection
                allSavedRecipesSection
            }
        }
    }

    private var myCookbooksSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("My Cookbooks")
                        .font(.system(size: 20, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(Theme.Palette.darkBrown)
                    Spacer()
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Palette.darkBrown)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                Rectangle()
                    .fill(Theme.Palette.darkBrown)
                    .frame(height: 2)
            }

            VStack(spacing: 20) {
                if personalCookbooks.isEmpty {
                    Text("No cookbooks yet — tap + to create one.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(personalCookbooks) { cookbook in
                        NavigationLink(value: cookbook) {
                            CookbookRow(cookbook: cookbook)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var allSavedRecipesSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 10) {
                Text("All Saved Recipes")
                    .font(.system(size: 20, weight: .medium))
                    .tracking(0.2)
                    .foregroundColor(Theme.Palette.darkBrown)
                Rectangle()
                    .fill(Theme.Palette.darkBrown)
                    .frame(height: 2)
            }

            VStack(spacing: 24) {
                if savedRecipes.isEmpty {
                    Text("No saved recipes yet.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(savedRecipes) { preview in
                        NavigationLink(value: preview) {
                            RecipeCard(preview: preview)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let all = try await CookbookService.shared.fetchAll()
            cookbooks = all
            if let saved = all.first(where: { $0.name.lowercased() == savedCookbookName }) {
                savedCookbookId = saved.id
                let detail = try await CookbookService.shared.fetchDetail(id: saved.id)
                savedRecipes = detail.recipes
            } else {
                savedCookbookId = nil
                savedRecipes = []
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct CookbookRow: View {
    let cookbook: Cookbook

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(cookbook.name)
                    .font(.system(size: 20, weight: .regular))
                    .tracking(0.2)
                    .foregroundColor(Theme.Palette.darkBrown)
                    .lineLimit(1)
                if let description = cookbook.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Theme.Palette.lightBrown)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Palette.darkBrown)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Theme.Palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "EFEFEF"), lineWidth: 1)
        )
    }
}

#Preview {
    CookbooksView()
}
