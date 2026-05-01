import SwiftUI

struct SaveToCookbookSheet: View {
    let recipeId: Int
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cookbooks: [Cookbook] = []
    @State private var cookbookCounts: [Int: Int] = [:]
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var savingCookbookId: Int?
    @State private var actionError: String?
    @State private var showCreateSheet = false

    var body: some View {
        VStack(spacing: 0) {
            handle

            VStack(alignment: .leading, spacing: 35) {
                header

                cookbooksBlock
            }
            .padding(.horizontal, 36)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Theme.Palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .task { await load() }
        .sheet(isPresented: $showCreateSheet) {
            CreateCookbookView { _ in
                showCreateSheet = false
                Task { await load() }
            }
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Theme.Palette.lightBrown)
            .frame(width: 97, height: 4)
            .padding(.top, 10)
            .padding(.bottom, 20)
    }

    private var header: some View {
        HStack(spacing: 15) {
            Image(systemName: "book.closed")
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)
            Text("Save to Cookbook")
                .font(.system(size: 30, weight: .regular))
                .tracking(0.3)
                .foregroundColor(Theme.Palette.darkBrown)
        }
    }

    @ViewBuilder
    private var cookbooksBlock: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading && cookbooks.isEmpty {
                ProgressView()
                    .tint(Theme.Palette.lightBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else if let loadError, cookbooks.isEmpty {
                Text(loadError)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Palette.orangeBrown)
            } else {
                cookbookList
            }

            if let actionError {
                Text(actionError)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Palette.orangeBrown)
            }

            createCookbookButton
        }
    }

    private var cookbookList: some View {
        VStack(spacing: 25) {
            ForEach(cookbooks) { cookbook in
                Button {
                    Task { await save(to: cookbook) }
                } label: {
                    cookbookRow(cookbook)
                }
                .buttonStyle(.plain)
                .disabled(savingCookbookId != nil)
            }
        }
    }

    private func cookbookRow(_ cookbook: Cookbook) -> some View {
        VStack(spacing: 25) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(cookbook.name)
                        .font(.system(size: 23, weight: .regular))
                        .foregroundColor(Theme.Palette.darkBrown)
                        .lineLimit(1)
                    Text(recipeCountLabel(for: cookbook))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.Palette.lightBrown)
                }
                Spacer()
                if savingCookbookId == cookbook.id {
                    ProgressView().tint(Theme.Palette.darkBrown)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Palette.darkBrown)
                }
            }

            Rectangle()
                .fill(Color(hex: "D0D0D0"))
                .frame(height: 1)
        }
    }

    private var createCookbookButton: some View {
        Button {
            showCreateSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Create Cookbook")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Theme.Palette.orangeBrown)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func recipeCountLabel(for cookbook: Cookbook) -> String {
        let count = cookbookCounts[cookbook.id] ?? 0
        return count == 1 ? "1 recipe saved" : "\(count) recipes saved"
    }

    private func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let all = try await CookbookService.shared.fetchAll()
            cookbooks = all
            await withTaskGroup(of: (Int, Int).self) { group in
                for cookbook in all {
                    group.addTask {
                        let count = (try? await CookbookService.shared.fetchDetail(id: cookbook.id).recipes.count) ?? 0
                        return (cookbook.id, count)
                    }
                }
                var counts: [Int: Int] = [:]
                for await (id, count) in group { counts[id] = count }
                cookbookCounts = counts
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func save(to cookbook: Cookbook) async {
        savingCookbookId = cookbook.id
        actionError = nil
        defer { savingCookbookId = nil }
        do {
            _ = try await CookbookService.shared.addRecipe(cookbookId: cookbook.id, recipeId: recipeId)
            onSaved()
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }
}

#Preview {
    Color.gray.sheet(isPresented: .constant(true)) {
        SaveToCookbookSheet(recipeId: 1, onSaved: {})
            .presentationDetents([.height(469)])
            .presentationDragIndicator(.hidden)
    }
}
