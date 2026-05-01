import SwiftUI

private enum OnboardingRoute: Hashable {
    case createAccount
    case login
    case findFriends
}

struct OnboardingFlow: View {
    @EnvironmentObject private var session: SessionStore

    @State private var path: [OnboardingRoute] = []
    @State private var pendingSession: AuthSession?

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
                path.append(.findFriends)
            }
        case .login:
            LoginView { authSession in
                APIClient.shared.sessionToken = authSession.token
                session.signIn(user: authSession.user, token: authSession.token)
            }
        case .findFriends:
            if let pending = pendingSession {
                FindFriendsView(currentUser: pending.user, onFinish: {
                    session.signIn(user: pending.user, token: pending.token)
                })
            }
        }
    }
}

#Preview {
    OnboardingFlow().environmentObject(SessionStore())
}
