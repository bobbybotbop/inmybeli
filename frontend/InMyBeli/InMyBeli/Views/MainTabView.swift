import SwiftUI

enum Tab {
    case discover, create, cookbooks, profile
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .discover

    var body: some View {
        VStack(spacing: 0) {
            selectedTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBar(selectedTab: $selectedTab)
        }
        .background(Theme.Palette.background)
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .discover:
            DiscoverView()
        case .create:
            CreateView()
        case .cookbooks:
            CookbooksView()
        case .profile:
            ProfileView()
        }
    }

    private func placeholder(_ label: String) -> some View {
        Text(label)
            .font(Theme.Typography.title)
            .foregroundColor(Theme.Palette.darkBrown)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.background)
    }
}

struct TabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 25) {
            TabBarItem(
                icon: "magnifyingglass",
                isSelected: selectedTab == .discover
            ) { selectedTab = .discover }

            TabBarItem(
                icon: "square.and.pencil",
                isSelected: selectedTab == .create
            ) { selectedTab = .create }

            TabBarItem(
                icon: "book.closed",
                isSelected: selectedTab == .cookbooks
            ) { selectedTab = .cookbooks }

            TabBarItem(
                icon: "person.crop.circle",
                isSelected: selectedTab == .profile
            ) { selectedTab = .profile }
        }
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.tabBar)
    }
}

struct TabBarItem: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Theme.Palette.cream : Theme.Palette.darkBrown)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isSelected ? Theme.Palette.lightBrown : .clear)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
