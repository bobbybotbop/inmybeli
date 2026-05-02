import SwiftUI

private enum RecipeDetailTab {
    case ingredients, steps
}

struct RecipeDetailView: View {
    let recipeId: Int
    let initialTitle: String?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: RecipeDetailTab = .ingredients
    @State private var recipe: Recipe?
    @State private var loadError: String?
    @State private var isLoading = false
    @State private var isWriteReviewPresented = false
    @State private var isSaveSheetPresented = false

    init(recipeId: Int, initialTitle: String? = nil) {
        self.recipeId = recipeId
        self.initialTitle = initialTitle
    }

    init(preview: RecipePreview) {
        self.recipeId = preview.id
        self.initialTitle = preview.title
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header

                heroImage

                actionButtons

                Rectangle()
                    .fill(Theme.Palette.divider)
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                tabToggle

                tabContent
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
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
        .task { await loadRecipe() }
        .sheet(isPresented: $isWriteReviewPresented) {
            WriteReviewView(recipeId: recipeId)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $isSaveSheetPresented) {
            SaveToCookbookSheet(recipeId: recipeId, onSaved: {})
                .presentationDetents([.height(464), .large])
                .presentationDragIndicator(.hidden)
        }
    }

    private func loadRecipe() async {
        guard recipe == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            recipe = try await RecipeService.shared.fetchRecipe(id: recipeId)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private var displayTitle: String {
        recipe?.title ?? initialTitle ?? ""
    }

    private var displayTime: String? {
        if let mins = recipe?.timeMinutes { return "\(mins) minutes" }
        return nil
    }

    private var displayCuisine: String? {
        recipe?.cuisine
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(displayTitle)
                .font(Theme.Typography.title)
                .tracking(0.25)
                .foregroundColor(Theme.Palette.darkBrown)

            let parts = [displayTime, displayCuisine].compactMap { $0 }.filter { !$0.isEmpty }
            if !parts.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(parts.enumerated()), id: \.offset) { index, value in
                        if index > 0 {
                            Circle()
                                .fill(Theme.Palette.lightBrown)
                                .frame(width: 2, height: 2)
                        }
                        Text(value)
                            .font(.system(size: 15, weight: .regular))
                            .tracking(0.15)
                            .foregroundColor(Theme.Palette.lightBrown)
                    }
                }
            }
        }
    }

    private var heroImage: some View {
        Group {
            if let imageUrl = recipe?.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Theme.Palette.placeholder
                    }
                }
            } else {
                Theme.Palette.placeholder
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Theme.Palette.lightBrown.opacity(0.6))
                    )
            }
        }
        .frame(height: 264)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 24)
    }

    private var actionButtons: some View {
        HStack(spacing: 48) {
            Button {
                isSaveSheetPresented = true
            } label: {
                ActionIconButton(icon: "bookmark", label: "Save", bordered: false)
            }
            .buttonStyle(.plain)
            Button {
                isWriteReviewPresented = true
            } label: {
                ActionIconButton(icon: "square.and.pencil", label: "Rate", bordered: false)
            }
            .buttonStyle(.plain)
            NavigationLink {
                ReviewsListView(recipeId: recipeId, recipeTitle: displayTitle)
            } label: {
                ActionIconButton(icon: "person.2", label: "Reviews", bordered: true)
            }
            .buttonStyle(.plain)
        }
    }

    private var tabToggle: some View {
        HStack(spacing: 0) {
            tabButton(title: "Ingredients", tab: .ingredients, leading: true)
            tabButton(title: "Steps", tab: .steps, leading: false)
        }
        .frame(width: 280)
    }

    private func tabButton(title: String, tab: RecipeDetailTab, leading: Bool) -> some View {
        let isSelected = selectedTab == tab
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: leading ? Theme.Radius.pill : 0,
            bottomLeadingRadius: leading ? Theme.Radius.pill : 0,
            bottomTrailingRadius: leading ? 0 : Theme.Radius.pill,
            topTrailingRadius: leading ? 0 : Theme.Radius.pill
        )
        return Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .tracking(0.15)
                .foregroundColor(isSelected ? .white : Theme.Palette.lightBrown)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    shape.fill(isSelected ? Theme.Palette.lightBrown : Theme.Palette.cream)
                )
                .overlay(
                    shape.stroke(Theme.Palette.lightBrown, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .ingredients:
            ingredientList
        case .steps:
            stepList
        }
    }

    private var ingredientList: some View {
        let ingredients = recipe?.ingredients ?? []
        return VStack(spacing: 18) {
            if isLoading && ingredients.isEmpty {
                ProgressView().tint(Theme.Palette.lightBrown)
            } else if let error = loadError, ingredients.isEmpty {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Palette.lightBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else if ingredients.isEmpty {
                Text("No ingredients listed.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Palette.lightBrown.opacity(0.6))
            } else {
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline) {
                        Text(ingredient.name)
                            .font(.system(size: 15, weight: .regular))
                            .tracking(0.15)
                            .foregroundColor(Theme.Palette.darkBrown)
                        Spacer()
                        if let amount = ingredient.amount, !amount.isEmpty {
                            Text(amount)
                                .font(.system(size: 15, weight: .semibold))
                                .tracking(0.15)
                                .foregroundColor(Theme.Palette.orangeBrown)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var stepList: some View {
        let steps = recipe?.instructions ?? []
        return VStack(alignment: .leading, spacing: 14) {
            if isLoading && steps.isEmpty {
                ProgressView().tint(Theme.Palette.lightBrown)
                    .frame(maxWidth: .infinity)
            } else if steps.isEmpty {
                Text("No steps listed.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Palette.lightBrown.opacity(0.6))
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Step \(index + 1)")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(0.13)
                            .foregroundColor(Theme.Palette.lightBrown)
                        Text(step)
                            .font(.system(size: 15, weight: .regular))
                            .tracking(0.15)
                            .foregroundColor(Theme.Palette.darkBrown)
                            .lineSpacing(4)
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
            }
        }
    }
}

private struct ActionIconButton: View {
    let icon: String
    let label: String
    let bordered: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if bordered {
                    Circle()
                        .stroke(Theme.Palette.darkBrown, lineWidth: 1)
                        .frame(width: 40, height: 40)
                }
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Theme.Palette.darkBrown)
                    .frame(width: 40, height: 40)
            }
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .tracking(0.14)
                .foregroundColor(Theme.Palette.darkBrown)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipeId: 1, initialTitle: "Tteokbokki")
    }
}
