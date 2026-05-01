import Foundation

private struct SearchResultsResponse: Decodable {
    let results: [FriendCandidate]
}

struct FriendCandidate: Codable, Identifiable, Hashable {
    let id: Int
    let username: String
    let name: String?
}

final class FriendService {
    static let shared = FriendService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func searchUsers(currentUserId: Int, query: String) async throws -> [FriendCandidate] {
        guard !query.isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        let response = try await client.get("friends/search/\(encoded)", as: SearchResultsResponse.self)
        return response.results.filter { $0.id != currentUserId }
    }

    func sendFriendRequest(friendId: Int) async throws {
        struct Body: Encodable { let friend_id: Int }
        struct Empty: Decodable {}
        _ = try await client.post(
            "friends/request/",
            body: Body(friend_id: friendId),
            as: Empty.self
        )
    }
}
