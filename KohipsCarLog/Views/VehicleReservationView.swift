import SwiftUI

struct VehicleReservationView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 56))
                    .foregroundStyle(KohipsTheme.textSecondary)

                Text("차량예약")
                    .font(.kohipsTitle)
                    .foregroundStyle(KohipsTheme.textPrimary)

                Text("법인 차량 예약 기능이 곧 출시됩니다")
                    .font(.kohipsBody)
                    .foregroundStyle(KohipsTheme.textSecondary)

                Text("Phase 2에서 법인 계정 연동과 함께\n차량 예약 기능이 추가됩니다")
                    .font(.kohipsCaption)
                    .foregroundStyle(KohipsTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(KohipsTheme.background)
            .navigationTitle("차량예약")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
