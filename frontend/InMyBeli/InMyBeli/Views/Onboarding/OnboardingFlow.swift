import SwiftUI

private enum OnboardingRoute: Hashable {
    case createAccount
    case login
    case cuisinePreferences
    case findFriends
}

struct OnboardingFlow: View {
    @EnvironmentObject private var session: SessionStore

    @State private var path: [OnboardingRoute] = []
    @State private var pendingSession: AuthSession?
    @State private var selectedCuisines: Set<String> = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onCreateAccount: { path.append(.createAccount) },
                onLogin: { path.append(.login) }
            )
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationDestination(for: OnboardingRoute.self) { route in
                destination(for: route)
                    .background(Theme.Palette.background.ignoresSafeArea())
            }
        }
    }

    @ViewBuilder
    private func destination(for route: OnboardingRoute) -> some View {
        switch route {
        case .createAccount:
            CreateAccountView { authSession in
                pendingSession = authSession
                APIClient.shared.sessionToken = authSession.token
                path.append(.cuisinePreferences)
            }
        case .login:
            LoginView { authSession in
                APIClient.shared.sessionToken = authSession.token
                session.signIn(user: authSession.user, token: authSession.token)
            }
        case .cuisinePreferences:
            CuisinePreferencesView { cuisines in
                selectedCuisines = cuisines
                path.append(.findFriends)
            }
        case .findFriends:
            FindFriendsView(
                currentUser: pendingSession?.user
                    ?? AppUser(id: 0, name: "", username: "", createdAt: nil),
                onFinish: {
                    if let pending = pendingSession {
                        session.signIn(user: pending.user, token: pending.token)
                    }
                }
            )
        }
    }
}

#Preview {
    OnboardingFlow().environmentObject(SessionStore())
}
