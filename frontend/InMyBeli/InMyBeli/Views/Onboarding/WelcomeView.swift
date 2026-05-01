import SwiftUI

struct WelcomeView: View {
    let onCreateAccount: () -> Void
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            Theme.Palette.background
                .ignoresSafeArea()

            VStack(spacing: 30) {
                logoAndTagline
                buttons
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 228)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var logoAndTagline: some View {
        VStack(spacing: 25) {
            logoBlock
            tagline
        }
    }

    private var logoBlock: some View {
        VStack(spacing: 5) {
            Image("MenuvoLogo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: 91, height: 95.79)

            Text("menuvo")
                .font(.system(size: 50, weight: .medium))
                .tracking(1.0) // 2% of 50pt
                .foregroundColor(Theme.Palette.darkBrown)
                .multilineTextAlignment(.center)
        }
        .frame(width: 174)
    }

    private var tagline: some View {
        Text("Cooking is better with friends. Discover new recipes to make, review, and share.")
            .font(.system(size: 24, weight: .light))
            .tracking(0.48) // 2% of 24pt
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .frame(width: 235)
    }

    private var buttons: some View {
        VStack(spacing: 20) {
            Button(action: onCreateAccount) {
                Text("Create an Account")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Palette.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(Theme.Palette.darkBrown)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onLogin) {
                Text("Login")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Palette.lightBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(Theme.Palette.cream)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(Theme.Palette.lightBrown, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(width: 230)
    }
}

#Preview {
    WelcomeView(onCreateAccount: {}, onLogin: {})
}
