import SwiftUI

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    private let inactiveFill = Color(hex: "EFEFEF")
    private let segmentWidth: CGFloat = 100
    private let spacing: CGFloat = 5

    init(currentStep: Int, totalSteps: Int = 3) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
    }

    var body: some View {
        VStack(spacing: 10) {
            stepLabel
            progressBar
        }
        .frame(width: totalWidth)
    }

    private var totalWidth: CGFloat {
        segmentWidth * CGFloat(totalSteps) + spacing * CGFloat(max(totalSteps - 1, 0))
    }

    private var stepLabel: some View {
        HStack(spacing: 0) {
            Text("Step \(currentStep)")
                .font(.system(size: 15, weight: .bold))
                .tracking(0.15)
            Text(" of \(totalSteps)")
                .font(.system(size: 15, weight: .light))
                .tracking(0.15)
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressBar: some View {
        HStack(spacing: spacing) {
            ForEach(1...totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(currentStep >= index ? Theme.Palette.lightBrown : inactiveFill)
                    .frame(width: segmentWidth, height: 12)
            }
        }
        .frame(width: totalWidth, height: 12)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    private let disabledFill = Color(hex: "F6F6F6")
    private let disabledStroke = Color(hex: "A4A4A4")

    init(
        title: String = "Continue",
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(isEnabled ? Theme.Palette.cream : disabledStroke)
                } else {
                    Text(title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isEnabled ? Theme.Palette.cream : disabledStroke)
                }
            }
            .frame(width: 230, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(isEnabled ? Theme.Palette.darkBrown : disabledFill)
            )
            .overlay(
                Group {
                    if !isEnabled {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(disabledStroke, lineWidth: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}
