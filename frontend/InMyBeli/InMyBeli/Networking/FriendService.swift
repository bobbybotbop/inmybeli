import Foundation

private struct SearchResultsResponse: Decodable {
    let results: [FriendCandidate]
}

private struct PendingRequestsResponse: Decodable {
    let userId: Int
    let receivedPendingRequests: [FriendCandidate]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case receivedPendingRequests = "received_pending_requests"
    }
}

private struct FriendsListResponse: Decodable {
    let friends: [FriendCandidate]
}

struct FriendCandidate: Codable, Identifiable, Hashable {
    let id: Int
    let username: String
    let name: String?
}

struct FriendRequest: Codable, Identifiable {
    let id: Int
    let sender: FriendCandidate
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

    func fetchFriendRequests() async throws -> [FriendRequest] {
        let response = try await client.get("friends/pending/received/", as: PendingRequestsResponse.self)
        return response.receivedPendingRequests.map { candidate in
            FriendRequest(id: candidate.id, sender: candidate)
        }
    }

    func fetchFriends(userId: Int) async throws -> [FriendCandidate] {
        let response = try await client.get("friends/", as: FriendsListResponse.self)
        return response.friends
    }

    func acceptFriendRequest(requestId: Int) async throws {
        struct Body: Encodable { let friend_id: Int }
        struct EmptyResponse: Decodable {}
        _ = try await client.post(
            "friends/accept/",
            body: Body(friend_id: requestId),
            as: EmptyResponse.self
        )
    }

    func declineFriendRequest(requestId: Int) async throws {
        struct Body: Encodable { let friend_id: Int }
        struct EmptyResponse: Decodable {}
        _ = try await client.post(
            "friends/decline/",
            body: Body(friend_id: requestId),
            as: EmptyResponse.self
        )
    }
}
