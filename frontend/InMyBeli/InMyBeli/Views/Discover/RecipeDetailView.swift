import SwiftUI

private enum RecipeDetailTab {
    case ingredients, steps
}

struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: RecipeDetailTab = .ingredients

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text(recipe.name)
                    .font(.system(size: 25, weight: .regular))
                    .tracking(0.25)
                    .foregroundColor(.black)
                    .padding(.top, 20)

                heroImage

                actionButtons

                Divider()
                    .padding(.horizontal, 21)

                tabToggle

                tabContent
                    .padding(.horizontal, 37)
                    .padding(.bottom, 30)
            }
        }
        .background(Color.white)
        .scrollIndicators(.hidden)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .regular))
                        Text("Back")
                            .font(.system(size: 15, weight: .regular))
                            .tracking(0.15)
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }

    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "d9d9d9"))
                .frame(height: 268)

            HStack(spacing: 5) {
                Text(recipe.time)
                    .font(.system(size: 15, weight: .light))
                    .tracking(0.15)
                    .foregroundColor(.black)
                Circle()
                    .fill(Color.black)
                    .frame(width: 2, height: 2)
                Text(recipe.cuisine)
                    .font(.system(size: 15, weight: .light))
                    .tracking(0.15)
                    .foregroundColor(.black)
            }
            .padding(.leading, 25)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 28)
    }

    private var actionButtons: some View {
        HStack(spacing: 43) {
            ActionIconButton(icon: "bookmark", label: "Save")
            ActionIconButton(icon: "note.text.badge.plus", label: "Notes")
            ActionIconButton(icon: "person.2", label: "Reviews")
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
            topLeadingRadius: leading ? 20 : 0,
            bottomLeadingRadius: leading ? 20 : 0,
            bottomTrailingRadius: leading ? 0 : 20,
            topTrailingRadius: leading ? 0 : 20
        )
        return Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .regular))
                .tracking(0.2)
                .foregroundColor(isSelected ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "3a3a3a") : Color(hex: "dfdede"))
                .clipShape(shape)
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
        VStack(spacing: 20) {
            ForEach(recipe.ingredients) { ingredient in
                HStack {
                    Text(ingredient.name)
                        .font(.system(size: 15, weight: .regular))
                        .tracking(0.15)
                        .foregroundColor(.black)
                    Spacer()
                    Text(ingredient.amount)
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(0.15)
                        .foregroundColor(.black)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var stepList: some View {
        VStack(spacing: 15) {
            ForEach(recipe.steps) { step in
                VStack(alignment: .leading, spacing: 5) {
                    Text(step.title)
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(0.16)
                        .foregroundColor(.black)
                    Text(step.detail)
                        .font(.system(size: 15, weight: .regular))
                        .tracking(0.15)
                        .foregroundColor(.black)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "f8f8f8"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "e2e2e2"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
}

private struct ActionIconButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.black)
                .frame(width: 39, height: 39)
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .tracking(0.15)
                .foregroundColor(.black)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(
            recipe: Recipe(
                name: "Dish Name",
                time: "Time",
                cuisine: "Cuisine",
                friendsSaved: 5,
                ingredients: [
                    Ingredient(name: "Ingredient 1", amount: "12 tsp"),
                    Ingredient(name: "Ingredient 2", amount: "3 cups"),
                    Ingredient(name: "Ingredient 3", amount: "5 oz"),
                ],
                steps: [
                    RecipeStep(title: "Step 1", detail: "Place 10tsp of ingredient 1 into a bowl with 2 cups of ingredient 2"),
                    RecipeStep(title: "Step 2", detail: "Preheat oven to 350"),
                ]
            )
        )
    }
}
