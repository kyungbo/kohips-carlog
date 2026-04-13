import SwiftUI

struct UnclassifiedBanner: View {
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(KohipsTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.kohipsIconLarge)
                        .foregroundStyle(KohipsTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("미분류 주행 \(count)건")
                        .font(.kohipsHeadline)
                        .foregroundStyle(KohipsTheme.textPrimary)
                    Text("탭하여 분류하세요")
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.kohipsIconSmall)
                    .foregroundStyle(KohipsTheme.textTertiary)
            }
            .padding(20)
            .background(KohipsTheme.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(KohipsTheme.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
