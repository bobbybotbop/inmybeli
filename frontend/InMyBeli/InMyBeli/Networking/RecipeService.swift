import Foundation

private struct UserRecipesResponse: Decodable {
    let userId: Int
    let recipes: [RecipePreview]

    enum CodingKeys: String, CodingKey {
        case recipes
        case userId = "user_id"
    }
}

private struct FeedResponse: Decodable {
    let recipes: [RecipePreview]
}

final class RecipeService {
    static let shared = RecipeService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchFeed() async throws -> [RecipePreview] {
        let response = try await client.get("feed/recipes/", as: FeedResponse.self)
        return response.recipes
    }

    func fetchRecipes(forUserId userId: Int) async throws -> [RecipePreview] {
        let response = try await client.get(
            "users/\(userId)/recipes/",
            as: UserRecipesResponse.self
        )
        return response.recipes
    }

    func fetchRecipe(id: Int) async throws -> Recipe {
        try await client.get("recipes/\(id)/", as: Recipe.self)
    }
}
