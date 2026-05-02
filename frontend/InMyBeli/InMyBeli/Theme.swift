import SwiftUI

enum Theme {
    enum Palette {
        static let background = Color(hex: "FCFCFC")
        static let tabBar = Color(hex: "FBFBFB")
        static let cream = Color(hex: "FAF6EE")
        static let lightBrown = Color(hex: "955430")
        static let darkBrown = Color(hex: "501F1F")
        static let orangeBrown = Color(hex: "CD512F")
        static let placeholder = Color(hex: "EDE6DA")
        static let divider = Color(hex: "955430").opacity(0.4)
    }

    enum Radius {
        static let card: CGFloat = 18
        static let pill: CGFloat = 22
        static let tabItem: CGFloat = 14
        static let search: CGFloat = 12
    }

    enum Typography {
        static let title = Font.system(size: 25, weight: .medium)
    }
}
