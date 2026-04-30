import Foundation

private struct CreateAccountBody: Encodable {
    let name: String
    let username: String
    let password: String
}

private struct CreateAccountResponse: Decodable {
    let user: AppUser
    let sessionToken: String

    enum CodingKeys: String, CodingKey {
        case user
        case sessionToken = "session_token"
    }
}

struct AuthSession {
    let user: AppUser
    let token: String
}

final class AuthService {
    static let shared = AuthService()

    /// Set to false once a real backend is available
    static var useMockData = true

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    @discardableResult
    func createAccount(name: String, username: String, password: String) async throws -> AuthSession {
        if AuthService.useMockData {
            let user = AppUser(
                id: Int.random(in: 1000...9999),
                name: name,
                username: username,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            let token = "mock-token-\(user.id)"
            APIClient.shared.sessionToken = token
            return AuthSession(user: user, token: token)
        }

        let body = CreateAccountBody(name: name, username: username, password: password)
        let response = try await client.post(
            "users/create/",
            body: body,
            as: CreateAccountResponse.self
        )
        APIClient.shared.sessionToken = response.sessionToken
        return AuthSession(user: response.user, token: response.sessionToken)
    }
}
