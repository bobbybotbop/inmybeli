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
            placeholder("Cookbooks")
        case .profile:
            ProfileView()
        }
    }

    private func placeholder(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 25, weight: .medium))
            .foregroundColor(Theme.Palette.darkBrown)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.background)
    }
}

struct TabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 18) {
            TabBarItem(
                icon: "magnifyingglass",
                label: "Discover",
                isSelected: selectedTab == .discover
            ) { selectedTab = .discover }

            TabBarItem(
                icon: "square.and.pencil",
                label: "Create",
                isSelected: selectedTab == .create
            ) { selectedTab = .create }

            TabBarItem(
                icon: "book",
                label: "Cookbooks",
                isSelected: selectedTab == .cookbooks
            ) { selectedTab = .cookbooks }

            TabBarItem(
                icon: "person.crop.circle",
                label: "Profile",
                isSelected: selectedTab == .profile
            ) { selectedTab = .profile }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.tabBar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Palette.lightBrown.opacity(0.12))
                .frame(height: 1)
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .frame(height: 24)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .tracking(0.1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(isSelected ? Theme.Palette.cream : Theme.Palette.darkBrown)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tabItem)
                    .fill(isSelected ? Theme.Palette.lightBrown : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
