import Foundation

struct APIError: Error, LocalizedError {
    var errorDescription: String? { "Something went wrong. Please try again." }
}

final class APIClient {
    static let shared = APIClient()

    var baseURL: URL = URL(string: "https://5571-128-84-126-121.ngrok-free.app/api/")!
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

    func postMultipart<T: Decodable>(
        _ path: String,
        fields: [String: String],
        imageData: Data?,
        imageFieldName: String = "image",
        imageFileName: String = "recipe.jpg",
        as type: T.Type
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        func append(_ string: String) {
            if let data = string.data(using: .utf8) { body.append(data) }
        }

        for (key, value) in fields {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            append("\(value)\r\n")
        }

        if let imageData {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(imageFieldName)\"; filename=\"\(imageFileName)\"\r\n")
            append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            append("\r\n")
        }

        append("--\(boundary)--\r\n")

        return try await request(
            path: path,
            method: "POST",
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            as: type
        )
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
