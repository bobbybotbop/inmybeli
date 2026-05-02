import Foundation

struct AppUser: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let username: String
    let profileURL: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, username
        case profileURL = "profile_url"
        case createdAt = "created_at"
    }
}
