import Foundation

struct Cookbook: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String?
}

struct CookbookDetail: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let recipes: [RecipePreview]
}
