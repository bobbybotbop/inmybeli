import Foundation

struct Ingredient: Identifiable, Hashable {
    let id: UUID
    let name: String
    let amount: String

    init(id: UUID = UUID(), name: String, amount: String) {
        self.id = id
        self.name = name
        self.amount = amount
    }
}

struct RecipeStep: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String

    init(id: UUID = UUID(), title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

struct Recipe: Identifiable, Hashable {
    let id: UUID
    let name: String
    let time: String
    let cuisine: String
    let friendsSaved: Int
    let ingredients: [Ingredient]
    let steps: [RecipeStep]

    init(
        id: UUID = UUID(),
        name: String,
        time: String,
        cuisine: String,
        friendsSaved: Int,
        ingredients: [Ingredient] = [],
        steps: [RecipeStep] = []
    ) {
        self.id = id
        self.name = name
        self.time = time
        self.cuisine = cuisine
        self.friendsSaved = friendsSaved
        self.ingredients = ingredients
        self.steps = steps
    }
}
