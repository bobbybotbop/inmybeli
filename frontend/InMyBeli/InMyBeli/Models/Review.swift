import Foundation

struct Review: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let recipeId: Int
    let rating: Int
    let text: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, rating, text
        case userId = "user_id"
        case recipeId = "recipe_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
