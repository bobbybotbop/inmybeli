import SwiftUI

private enum ProfileSection: String, CaseIterable {
    case recipes = "Recipes"
    case ratings = "Ratings"
    case requests = "Friend Requests"
}

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @State private var selectedSection: ProfileSection = .recipes
    @State private var recipes: [RecipePreview] = []
    @State private var friendRequests: [FriendRequest] = []
    @State private var friendCount = 0
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.horizontal, 22)
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                    Rectangle()
                        .fill(Theme.Palette.divider)
                        .frame(height: 1)

                    sectionPicker

                    sectionContent
                        .padding(.horizontal, 22)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                }
            }
            .background(Theme.Palette.background)
            .scrollIndicators(.hidden)
            .navigationDestination(for: RecipePreview.self) { preview in
                RecipeDetailView(preview: preview)
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(alignment: .center, spacing: 20) {
            Circle()
                .fill(Theme.Palette.placeholder)
                .frame(width: 101, height: 101)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Theme.Palette.lightBrown)
                )

            VStack(alignment: .leading, spacing: 4) {
                if let user = session.currentUser {
                    Text(user.name)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                    Text("@\(user.username)")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 24) {
                    statView(count: recipes.count, label: "Recipes")
                    statView(count: friendCount, label: "Friends")
                }
                .padding(.top, 6)
            }

            Spacer()
        }
    }

    private func statView(count: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.black)
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(ProfileSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(section.rawValue)
                            .font(.system(
                                size: 13,
                                weight: selectedSection == section ? .semibold : .regular
                            ))
                            .foregroundColor(
                                selectedSection == section
                                    ? .black
                                    : Color.black.opacity(0.4)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Rectangle()
                            .fill(selectedSection == section ? Theme.Palette.darkBrown : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.Palette.divider)
                .frame(height: 1)
        }
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .recipes:
            recipesContent
        case .ratings:
            ratingsContent
        case .requests:
            requestsContent
        }
    }

    @ViewBuilder
    private var recipesContent: some View {
        if isLoading && recipes.isEmpty {
            loadingView
        } else if recipes.isEmpty {
            emptyState(icon: "fork.knife", message: "No recipes yet.\nCreate your first recipe!")
        } else {
            VStack(spacing: 20) {
                ForEach(recipes) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeCard(preview: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ratingsContent: some View {
        emptyState(icon: "star", message: "No ratings yet.\nRate recipes you've tried!")
    }

    @ViewBuilder
    private var requestsContent: some View {
        if isLoading && friendRequests.isEmpty {
            loadingView
        } else if friendRequests.isEmpty {
            emptyState(icon: "person.2", message: "No pending friend requests.")
        } else {
            VStack(spacing: 12) {
                ForEach(friendRequests) { request in
                    FriendRequestRow(request: request) {
                        await handleAccept(request)
                    } onDecline: {
                        await handleDecline(request)
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        ProgressView()
            .tint(Theme.Palette.lightBrown)
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Theme.Palette.lightBrown.opacity(0.45))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color.black.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Actions

    private func load() async {
        guard let userId = session.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }

        async let recipesTask: [RecipePreview] = RecipeService.shared.fetchRecipes(forUserId: userId)
        async let requestsTask: [FriendRequest] = FriendService.shared.fetchFriendRequests()
        async let friendsTask: [FriendCandidate] = FriendService.shared.fetchFriends(userId: userId)

        do { recipes = try await recipesTask } catch {}
        do { friendRequests = try await requestsTask } catch {}
        do { friendCount = (try await friendsTask).count } catch {}
    }

    private func handleAccept(_ request: FriendRequest) async {
        do {
            try await FriendService.shared.acceptFriendRequest(requestId: request.id)
            friendRequests.removeAll { $0.id == request.id }
            friendCount += 1
        } catch {
            print("[ProfileView] Accept failed: \(error)")
        }
    }

    private func handleDecline(_ request: FriendRequest) async {
        do {
            try await FriendService.shared.declineFriendRequest(requestId: request.id)
            friendRequests.removeAll { $0.id == request.id }
        } catch {
            print("[ProfileView] Decline failed: \(error)")
        }
    }
}

// MARK: - FriendRequestRow

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () async -> Void
    let onDecline: () async -> Void

    @State private var isProcessing = false

    private var initial: String {
        let s = request.sender.name ?? request.sender.username
        return String(s.prefix(1)).uppercased()
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.Palette.cream)
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(Theme.Palette.lightBrown.opacity(0.2), lineWidth: 1))
                .overlay(
                    Text(initial)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.Palette.lightBrown)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(request.sender.name ?? request.sender.username)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                Text("@\(request.sender.username)")
                    .font(.system(size: 12))
                    .foregroundColor(Color.black.opacity(0.5))
            }

            Spacer()

            if isProcessing {
                ProgressView()
                    .tint(Theme.Palette.lightBrown)
                    .frame(width: 20, height: 20)
            } else {
                HStack(spacing: 8) {
                    Button {
                        isProcessing = true
                        Task {
                            await onDecline()
                            isProcessing = false
                        }
                    } label: {
                        Text("Decline")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Palette.lightBrown.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        isProcessing = true
                        Task {
                            await onAccept()
                            isProcessing = false
                        }
                    } label: {
                        Text("Accept")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.Palette.cream)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.Palette.darkBrown)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Palette.darkBrown.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Theme.Palette.darkBrown.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
