import SwiftUI

private enum OnboardingStep {
    case createAccount
    case findFriends
}

struct OnboardingFlow: View {
    @EnvironmentObject private var session: SessionStore

    @State private var step: OnboardingStep = .createAccount
    @State private var pendingSession: AuthSession?

    var body: some View {
        NavigationStack {
            content
                .background(Theme.Palette.background.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .createAccount:
            CreateAccountView { authSession in
                pendingSession = authSession
                APIClient.shared.sessionToken = authSession.token
                withAnimation { step = .findFriends }
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
