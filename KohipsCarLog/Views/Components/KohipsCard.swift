import SwiftUI

struct KohipsCard<Content: View>: View {
    var padding: CGFloat = 20
    let content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(KohipsTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
