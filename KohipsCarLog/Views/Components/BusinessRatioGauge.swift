import SwiftUI

struct BusinessRatioGauge: View {
    let ratio: Double
    let title: String

    var body: some View {
        KohipsCard(padding: 20) {
            HStack(spacing: 20) {
                // Circular gauge
                ZStack {
                    Circle()
                        .stroke(KohipsTheme.surfaceLight, lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: ratio)
                        .stroke(KohipsTheme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: ratio)

                    Text(String(format: "%.0f%%", ratio * 100))
                        .font(.kohipsHeadline)
                        .foregroundStyle(KohipsTheme.textPrimary)
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)

                    Text("업무용 비율")
                        .font(.kohipsHeadline)
                        .foregroundStyle(KohipsTheme.textPrimary)

                    Text(ratioDescription)
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textTertiary)
                }

                Spacer()
            }
        }
    }

    private var ratioDescription: String {
        if ratio >= 0.8 { return "높은 업무 사용률" }
        else if ratio >= 0.5 { return "적절한 업무 사용률" }
        else if ratio > 0 { return "업무용 비율이 낮습니다" }
        else { return "운행 기록이 없습니다" }
    }
}
