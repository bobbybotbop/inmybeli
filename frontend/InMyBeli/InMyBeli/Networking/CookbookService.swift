import Foundation

private struct CookbooksListResponse: Decodable {
    let cookbooks: [Cookbook]
}

private struct CookbookResponse: Decodable {
    let cookbook: CookbookDetail
}

private struct CreateCookbookResponse: Decodable {
    let cookbook: CookbookDetail
}

final class CookbookService {
    static let shared = CookbookService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchAll() async throws -> [Cookbook] {
        let response = try await client.get("cookbooks/", as: CookbooksListResponse.self)
        return response.cookbooks
    }

    func fetchDetail(id: Int) async throws -> CookbookDetail {
        let response = try await client.get("cookbooks/\(id)/", as: CookbookResponse.self)
        return response.cookbook
    }

    func create(name: String, description: String?) async throws -> CookbookDetail {
        struct Body: Encodable {
            let name: String
            let description: String?
        }
        let response = try await client.post(
            "cookbooks/",
            body: Body(name: name, description: description),
            as: CreateCookbookResponse.self
        )
        return response.cookbook
    }
}
