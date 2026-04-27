import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var recipes: [Recipe] = [
        Recipe(
            name: "Dish Name",
            time: "30 min",
            cuisine: "Italian",
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
        ),
        Recipe(
            name: "Dish Name",
            time: "45 min",
            cuisine: "Japanese",
            friendsSaved: 8,
            ingredients: [
                Ingredient(name: "Ingredient 1", amount: "2 cups"),
                Ingredient(name: "Ingredient 2", amount: "1 tbsp"),
            ],
            steps: [
                RecipeStep(title: "Step 1", detail: "Combine ingredients in a pan."),
                RecipeStep(title: "Step 2", detail: "Cook over medium heat for 10 minutes."),
            ]
        ),
        Recipe(
            name: "Dish Name",
            time: "20 min",
            cuisine: "Mexican",
            friendsSaved: 12,
            ingredients: [
                Ingredient(name: "Ingredient 1", amount: "4 oz"),
                Ingredient(name: "Ingredient 2", amount: "1 cup"),
            ],
            steps: [
                RecipeStep(title: "Step 1", detail: "Mix everything together."),
                RecipeStep(title: "Step 2", detail: "Serve immediately."),
            ]
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    SearchBar(text: $searchText)

                    VStack(alignment: .leading, spacing: 30) {
                        Text("Popular Recipes")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundColor(.black)

                        VStack(spacing: 24) {
                            ForEach(recipes) { recipe in
                                NavigationLink(value: recipe) {
                                    RecipeCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 16)
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .scrollIndicators(.hidden)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

#Preview {
    DiscoverView()
}
