import Foundation

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

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    @discardableResult
    func createAccount(name: String, username: String, password: String) async throws -> AuthSession {
        let response = try await client.postForm(
            "users/create",
            fields: ["name": name, "username": username, "password": password],
            as: CreateAccountResponse.self
        )
        APIClient.shared.sessionToken = response.sessionToken
        return AuthSession(user: response.user, token: response.sessionToken)
    }

    @discardableResult
    func login(username: String, password: String) async throws -> AuthSession {
        struct Body: Encodable { let username: String; let password: String }
        struct Response: Decodable {
            let user: AppUser
            let token: String
        }
        let response = try await client.post(
            "users/login/",
            body: Body(username: username, password: password),
            as: Response.self
        )
        APIClient.shared.sessionToken = response.token
        return AuthSession(user: response.user, token: response.token)
    }
}
