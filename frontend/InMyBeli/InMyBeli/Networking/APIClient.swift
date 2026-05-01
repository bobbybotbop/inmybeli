import Foundation

struct APIError: Error, LocalizedError {
    var errorDescription: String? { "Something went wrong. Please try again." }
}

final class APIClient {
    static let shared = APIClient()

    var baseURL: URL = URL(string: "http://localhost:5000/api/")!
    var sessionToken: String?

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func get<T: Decodable>(_ path: String, as: T.Type) async throws -> T {
        try await request(path: path, method: "GET", body: nil, contentType: nil, as: T.self)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B, as: T.Type) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(path: path, method: "POST", body: data, contentType: "application/json", as: T.self)
    }

    func postForm<T: Decodable>(_ path: String, fields: [String: String], as: T.Type) async throws -> T {
        let body = fields
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        return try await request(path: path, method: "POST", body: body, contentType: "application/x-www-form-urlencoded", as: T.self)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: Data?,
        contentType: String?,
        as: T.Type
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError()
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        if let contentType {
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let token = sessionToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body

        let (data, response) = try await session.data(for: req)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[APIClient] \(method) \(url.path) failed — \(status): \(body)")
            throw APIError()
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[APIClient] Decoding failed: \(error)")
            throw APIError()
        }
    }
}
