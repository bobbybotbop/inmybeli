import SwiftUI

struct SheetHandle: View {
    var color: Color = Theme.Palette.lightBrown

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: 97, height: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        SheetHandle()
        SheetHandle(color: Color(hex: "888888").opacity(0.3))
    }
    .padding()
}
