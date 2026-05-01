import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    let name: String
    let amount: String?

    var id: String { "\(name)|\(amount ?? "")" }

    init(name: String, amount: String? = nil) {
        self.name = name
        self.amount = amount
    }
}

struct Recipe: Codable, Identifiable, Hashable {
    let id: Int
    let creatorId: Int
    let title: String
    let description: String?
    let imageUrl: String?
    let timeMinutes: Int?
    let cuisine: String?
    let servings: Int?
    let ingredients: [Ingredient]
    let instructions: [String]

    enum CodingKeys: String, CodingKey {
        case id, title, description, cuisine, servings, ingredients, instructions
        case creatorId = "creator_id"
        case imageUrl = "image_url"
        case timeMinutes = "time_minutes"
    }

    var timeLabel: String? {
        guard let timeMinutes else { return nil }
        return "\(timeMinutes) min"
    }
}

struct RecipePreview: Codable, Identifiable, Hashable {
    let id: Int
    let creatorId: Int
    let title: String
    let imageUrl: String?
    let timeMinutes: Int?
    let cuisine: String?
    let totalSavesCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, cuisine
        case creatorId = "creator_id"
        case imageUrl = "image_url"
        case timeMinutes = "time_minutes"
        case totalSavesCount = "total_saves_count"
    }

    var timeLabel: String? {
        guard let timeMinutes else { return nil }
        return "\(timeMinutes) min"
    }
}
