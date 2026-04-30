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

    var body: some View {
        VStack(spacing: 0) {
            heading
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 18)

            SearchBar(text: $query, placeholder: "Search by username or name")
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

            list

            footer
        }
        .background(Theme.Palette.background)
        .navigationBarBackButtonHidden(true)
        .onChange(of: query) { _, newValue in
            scheduleSearch(for: newValue)
        }
        .task { await runSearch(query: "") }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add your friends")
                .font(.system(size: 28, weight: .semibold))
                .tracking(0.28)
                .foregroundColor(Theme.Palette.darkBrown)
            Text("See what your friends are cooking. You can always add more later.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Theme.Palette.lightBrown)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var list: some View {
        if isLoading && results.isEmpty {
            VStack {
                Spacer()
                ProgressView().tint(Theme.Palette.lightBrown)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError, results.isEmpty {
            stateMessage(title: "Couldn't load people", body: loadError)
        } else if results.isEmpty {
            stateMessage(
                title: query.isEmpty ? "Search for friends" : "No matches",
                body: query.isEmpty
                    ? "Type a username or name to find people on InMyBeli."
                    : "Try a different name or username."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(results) { candidate in
                        FriendRow(
                            candidate: candidate,
                            requested: requestedIds.contains(candidate.id),
                            onAdd: { add(candidate) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
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
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(action: onFinish) {
                Text(requestedIds.isEmpty ? "Skip for now" : "Done (\(requestedIds.count))")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(0.16)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.Palette.lightBrown)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Theme.Palette.background
                .shadow(color: Theme.Palette.darkBrown.opacity(0.04), radius: 8, x: 0, y: -2)
        )
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
                try await FriendService.shared.sendFriendRequest(
                    currentUserId: currentUser.id,
                    friendId: candidate.id
                )
            } catch {
                requestedIds.remove(candidate.id)
                loadError = error.localizedDescription
            }
        }
    }
}

private struct FriendRow: View {
    let candidate: FriendCandidate
    let requested: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.name ?? candidate.username)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Palette.darkBrown)
                    .lineLimit(1)
                Text("@\(candidate.username)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Palette.lightBrown)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onAdd) {
                Text(requested ? "Added" : "Add")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(requested ? Theme.Palette.lightBrown : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(requested ? Theme.Palette.cream : Theme.Palette.lightBrown)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Theme.Palette.lightBrown, lineWidth: requested ? 1 : 0)
                    )
            }
            .buttonStyle(.plain)
            .disabled(requested)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.Palette.darkBrown.opacity(0.08), lineWidth: 1)
        )
    }

    private var avatar: some View {
        let initial = (candidate.name?.first ?? candidate.username.first).map { String($0).uppercased() } ?? "?"
        return ZStack {
            Circle()
                .fill(Theme.Palette.cream)
            Text(initial)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Palette.lightBrown)
        }
        .frame(width: 40, height: 40)
        .overlay(
            Circle().stroke(Theme.Palette.lightBrown.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    FindFriendsView(
        currentUser: AppUser(id: 1, name: "Ronald", username: "ronald", createdAt: nil),
        onFinish: {}
    )
}
