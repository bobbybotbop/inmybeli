import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var sessionToken: String?

    var isAuthenticated: Bool { currentUser != nil }

    func signIn(user: AppUser, token: String) {
        currentUser = user
        sessionToken = token
        APIClient.shared.sessionToken = token
    }

    func signOut() {
        currentUser = nil
        sessionToken = nil
        APIClient.shared.sessionToken = nil
    }
}
