import SwiftUI

private let cuisineOptions: [String] = [
    "Japanese", "Italian", "Greek", "Chinese", "Mexican",
    "French", "Thai", "American", "Indian", "Spanish"
]

struct CuisinePreferencesView: View {
    let onContinue: (Set<String>) -> Void

    @State private var selected: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            StepProgressBar(currentStep: 2)
                .padding(.top, 30)

            VStack(spacing: 20) {
                heading
                cuisineChips
            }
            .padding(.horizontal, 38)
            .padding(.top, 75)

            Spacer(minLength: 30)

            PrimaryActionButton(action: { onContinue(selected) })
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.background)
    }

    private var heading: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 44, weight: .regular))
                .foregroundColor(Theme.Palette.darkBrown)
                .frame(height: 53)

            Text("What do you like to cook?")
                .font(.system(size: 30, weight: .medium))
                .tracking(0.3)
                .foregroundColor(Theme.Palette.darkBrown)
                .multilineTextAlignment(.center)
                .frame(width: 247)

            Text("Select some cuisines.")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color(hex: "888888"))
        }
        .frame(maxWidth: .infinity)
    }

    private var cuisineChips: some View {
        WrappedHStack(spacing: 15, runSpacing: 15) {
            ForEach(cuisineOptions, id: \.self) { name in
                CuisineChip(
                    name: name,
                    isSelected: selected.contains(name)
                ) {
                    toggle(name)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func toggle(_ name: String) {
        if selected.contains(name) {
            selected.remove(name)
        } else {
            selected.insert(name)
        }
    }
}

private struct CuisineChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    private let cream = Color(hex: "FAF6EE")
    private let creamYellow = Color(hex: "FDEED3")

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 15, weight: isSelected ? .medium : .light))
                .tracking(0.15)
                .foregroundColor(isSelected ? creamYellow : Theme.Palette.lightBrown)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(isSelected ? Theme.Palette.lightBrown : cream)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            isSelected ? creamYellow : Theme.Palette.lightBrown,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct WrappedHStack<Content: View>: View {
    let spacing: CGFloat
    let runSpacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        _WrappedHStackLayout(spacing: spacing, runSpacing: runSpacing) {
            content()
        }
    }
}

private struct _WrappedHStackLayout: Layout {
    var spacing: CGFloat
    var runSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                width = max(width, rowWidth - spacing)
                height += rowHeight + runSpacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        width = max(width, rowWidth - spacing)
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var rows: [[(LayoutSubview, CGSize)]] = [[]]
        var currentRowWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth, !(rows.last?.isEmpty ?? true) {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append((sub, size))
            currentRowWidth += size.width + spacing
        }

        var y = bounds.minY
        for row in rows {
            let totalRowWidth = row.reduce(0) { $0 + $1.1.width } + spacing * CGFloat(max(row.count - 1, 0))
            var x = bounds.minX + (maxWidth - totalRowWidth) / 2
            let rowHeight = row.map(\.1.height).max() ?? 0
            for (sub, size) in row {
                sub.place(
                    at: CGPoint(x: x, y: y + (rowHeight - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += rowHeight + runSpacing
        }
    }
}

#Preview {
    NavigationStack {
        CuisinePreferencesView { _ in }
    }
}
