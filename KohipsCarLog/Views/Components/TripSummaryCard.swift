import SwiftUI

struct TripSummaryCard: View {
    let title: String
    let count: Int
    let totalKm: Double
    let businessRatio: Double

    var body: some View {
        KohipsCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.kohipsCaption)
                    .foregroundStyle(KohipsTheme.textSecondary)

                HStack(spacing: 0) {
                    statItem(value: "\(count)", label: "건")
                    Spacer()
                    statItem(value: String(format: "%.1f", totalKm), label: "km")
                    Spacer()
                    statItem(
                        value: String(format: "%.0f%%", businessRatio * 100),
                        label: "업무용",
                        color: KohipsTheme.primary
                    )
                }
            }
        }
    }

    private func statItem(value: String, label: String, color: Color = KohipsTheme.textPrimary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.kohipsTitle)
                .foregroundStyle(color)
            Text(label)
                .font(.kohipsSmall)
                .foregroundStyle(KohipsTheme.textSecondary)
        }
        .frame(minWidth: 60)
    }
}
