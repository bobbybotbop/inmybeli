import Foundation
import Combine
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var sessionToken: String?

    var isAuthenticated: Bool { currentUser != nil }

    func attachToken(_ token: String?) {
        sessionToken = token
        APIClient.shared.sessionToken = token
    }

    func signIn(user: AppUser, token: String) {
        currentUser = user
        attachToken(token)
    }

    func signOut() {
        currentUser = nil
        attachToken(nil)
    }
}
