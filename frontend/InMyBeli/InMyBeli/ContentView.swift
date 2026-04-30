import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionStore()

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
            } else {
                OnboardingFlow()
            }
        }
        .environmentObject(session)
    }
}

#Preview {
    ContentView()
}
