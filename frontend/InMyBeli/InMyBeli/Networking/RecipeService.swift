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

private struct ReviewsResponse: Decodable {
    let recipeId: Int
    let reviews: [Review]

    enum CodingKeys: String, CodingKey {
        case reviews
        case recipeId = "recipe_id"
    }
}

private struct UserReviewsResponse: Decodable {
    let userId: Int
    let reviews: [Review]

    enum CodingKeys: String, CodingKey {
        case reviews
        case userId = "user_id"
    }
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

    func createRecipe(
        title: String,
        timeMinutes: Int?,
        servings: Int?,
        cuisine: String?,
        ingredients: [[String: String]],
        instructions: [String],
        imageData: Data?
    ) async throws -> Recipe {
        var fields: [String: String] = ["title": title]
        if let timeMinutes { fields["time_minutes"] = "\(timeMinutes)" }
        if let servings { fields["servings"] = "\(servings)" }
        if let cuisine, !cuisine.isEmpty { fields["cuisine"] = cuisine }

        if !ingredients.isEmpty,
           let jsonData = try? JSONSerialization.data(withJSONObject: ingredients),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            fields["ingredients"] = jsonStr
        }

        if !instructions.isEmpty,
           let jsonData = try? JSONSerialization.data(withJSONObject: instructions),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            fields["instructions"] = jsonStr
        }

        return try await client.postMultipart(
            "recipes/",
            fields: fields,
            imageData: imageData,
            as: Recipe.self
        )
    }

    func fetchReviews(recipeId: Int) async throws -> [Review] {
        let response = try await client.get(
            "recipes/\(recipeId)/reviews/",
            as: ReviewsResponse.self
        )
        return response.reviews
    }

    func fetchUserReviews(userId: Int) async throws -> [Review] {
        let response = try await client.get(
            "users/\(userId)/reviews/",
            as: UserReviewsResponse.self
        )
        return response.reviews
    }

    func submitReview(recipeId: Int, rating: Int, text: String?) async throws -> Review {
        struct Body: Encodable { let rating: Int; let text: String? }
        return try await client.post(
            "recipes/\(recipeId)/reviews/",
            body: Body(rating: rating, text: text),
            as: Review.self
        )
    }
}
