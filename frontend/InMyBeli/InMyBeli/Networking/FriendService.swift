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

    static var useMockData = true

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func searchUsers(currentUserId: Int, query: String) async throws -> [FriendCandidate] {
        if FriendService.useMockData {
            let q = query.lowercased()
            return MockFriends.everyone
                .filter { $0.id != currentUserId }
                .filter { q.isEmpty || $0.username.lowercased().contains(q) || ($0.name?.lowercased().contains(q) ?? false) }
        }
        guard !query.isEmpty else { return [] }
        let path = "users/\(currentUserId)/friends/search/\(query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query)"
        let response = try await client.get(path, as: SearchResultsResponse.self)
        return response.results.filter { $0.id != currentUserId }
    }

    func sendFriendRequest(currentUserId: Int, friendId: Int) async throws {
        if FriendService.useMockData { return }
        struct Body: Encodable { let friend_id: Int }
        struct Empty: Decodable {}
        _ = try await client.post(
            "users/\(currentUserId)/friends/request/",
            body: Body(friend_id: friendId),
            as: Empty.self
        )
    }
}

private enum MockFriends {
    static let everyone: [FriendCandidate] = [
        FriendCandidate(id: 101, username: "minji.k", name: "Minji Kim"),
        FriendCandidate(id: 102, username: "leoparra", name: "Leo Parra"),
        FriendCandidate(id: 103, username: "sasha.m", name: "Sasha Müller"),
        FriendCandidate(id: 104, username: "ravioli_rio", name: "Rio Tanaka"),
        FriendCandidate(id: 105, username: "amaraokafor", name: "Amara Okafor"),
        FriendCandidate(id: 106, username: "thomas.h", name: "Thomas Huang"),
        FriendCandidate(id: 107, username: "priya_d", name: "Priya Desai"),
        FriendCandidate(id: 108, username: "noah.b", name: "Noah Bennett"),
    ]
}
