import SwiftUI

struct FindFriendsView: View {
    let currentUser: AppUser
    let onFinish: () -> Void

    @State private var query: String = ""
    @State private var results: [FriendCandidate] = []
    @State private var requestedIds: Set<Int> = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var searchTask: Task<Void, Never>?

    private let searchFill = Color(hex: "EFEFEF")
    private let placeholderGray = Color(hex: "888888")

    var body: some View {
        VStack(spacing: 0) {
            StepProgressBar(currentStep: 3)
                .padding(.top, 30)

            content
                .padding(.top, 32)

            Spacer(minLength: 16)

            PrimaryActionButton(action: onFinish)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.background)
        .onChange(of: query) { _, newValue in
            scheduleSearch(for: newValue)
        }
        .task { await runSearch(query: "") }
    }

    private var content: some View {
        VStack(spacing: 25) {
            heading
            searchField
            list
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    private var heading: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 36, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)
                .frame(height: 40)

            Text("Add your friends.")
                .font(.system(size: 30, weight: .medium))
                .tracking(0.3)
                .foregroundColor(Theme.Palette.darkBrown)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(placeholderGray)

            TextField(
                "",
                text: $query,
                prompt: Text("Begin typing usernames...")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(placeholderGray)
            )
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(Theme.Palette.darkBrown)
            .tint(Theme.Palette.lightBrown)
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .padding(.leading, 20)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(searchFill)
        )
    }

    @ViewBuilder
    private var list: some View {
        if isLoading && results.isEmpty {
            ProgressView()
                .tint(Theme.Palette.lightBrown)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else if let loadError, results.isEmpty {
            stateMessage(title: "Couldn't load people", body: loadError)
        } else if results.isEmpty {
            stateMessage(
                title: query.isEmpty ? "Search for friends" : "No matches",
                body: query.isEmpty
                    ? "Type a username or name to find people."
                    : "Try a different name or username."
            )
        } else {
            ScrollView {
                WrappedHStack(spacing: 15, runSpacing: 32) {
                    ForEach(results) { candidate in
                        FriendCard(
                            candidate: candidate,
                            requested: requestedIds.contains(candidate.id),
                            onAdd: { add(candidate) }
                        )
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 360)
        }
    }

    private func stateMessage(title: String, body: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Palette.darkBrown)
            Text(body)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.Palette.lightBrown.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private func scheduleSearch(for value: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            await runSearch(query: value)
        }
    }

    private func runSearch(query: String) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            results = try await FriendService.shared.searchUsers(
                currentUserId: currentUser.id,
                query: query.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func add(_ candidate: FriendCandidate) {
        guard !requestedIds.contains(candidate.id) else { return }
        requestedIds.insert(candidate.id)
        Task {
            do {
                try await FriendService.shared.sendFriendRequest(friendId: candidate.id)
            } catch {
                requestedIds.remove(candidate.id)
                loadError = error.localizedDescription
            }
        }
    }
}

private struct FriendCard: View {
    let candidate: FriendCandidate
    let requested: Bool
    let onAdd: () -> Void

    private let avatarFill = Color(hex: "F6F6F6")
    private let avatarStroke = Color(hex: "BEBEBE")
    private let cream = Color(hex: "FAF6EE")

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                avatar

                Text(candidate.name ?? candidate.username)
                    .font(.system(size: 15, weight: .medium))
                    .tracking(0.15)
                    .foregroundColor(Theme.Palette.darkBrown)
                    .lineLimit(1)

                Text("@\(candidate.username)")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "888888"))
                    .lineLimit(1)
            }

            Button(action: { if !requested { onAdd() } }) {
                Text(requested ? "Added" : "Add")
                    .font(.system(size: 15, weight: requested ? .medium : .light))
                    .foregroundColor(requested ? cream : Theme.Palette.lightBrown)
                    .frame(width: 80)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(requested ? Theme.Palette.lightBrown : cream)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.Palette.lightBrown, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(requested)
        }
        .frame(width: 90)
    }

    private var avatar: some View {
        let initial = (candidate.name?.first ?? candidate.username.first).map { String($0).uppercased() } ?? "?"
        return ZStack {
            Circle()
                .fill(avatarFill)
            Text(initial)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.Palette.lightBrown)
        }
        .frame(width: 70, height: 70)
        .overlay(
            Circle().stroke(avatarStroke, lineWidth: 1.5)
        )
    }
}

#Preview {
    NavigationStack {
        FindFriendsView(
            currentUser: AppUser(id: 1, name: "Ronald", username: "ronald", profileURL: nil, createdAt: nil),
            onFinish: {}
        )
    }
}
