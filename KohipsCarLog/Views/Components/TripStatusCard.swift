import SwiftUI

struct TripStatusCard: View {
    let isRecording: Bool
    let currentTrip: Trip?
    let sensorStatus: TripDetector.SensorStatus
    let onStop: () -> Void
    let onStart: () -> Void

    @State private var showSensorAlert = false

    var body: some View {
        VStack(spacing: 12) {
            // 센서/권한 경고 배너
            if !sensorStatus.isLocationAuthorized {
                sensorWarningBanner(
                    icon: "location.slash.fill",
                    message: "위치 권한이 필요합니다. 설정에서 '항상 허용'으로 변경해주세요.",
                    color: KohipsTheme.destructive
                )
            } else if !sensorStatus.hasAnySensor {
                sensorWarningBanner(
                    icon: "sensor.fill",
                    message: "모션 센서를 사용할 수 없습니다. 수동 기록만 가능합니다.",
                    color: KohipsTheme.accent
                )
            } else if sensorStatus.isMotionPermissionDenied {
                sensorWarningBanner(
                    icon: "figure.walk",
                    message: "모션 권한이 거부되었습니다. 설정에서 '모션 및 피트니스'를 허용해주세요.",
                    color: KohipsTheme.accent
                )
            }

            KohipsCard(padding: 20) {
                if isRecording, let trip = currentTrip {
                    recordingContent(trip)
                } else {
                    idleContent
                }
            }
        }
    }

    private func sensorWarningBanner(icon: String, message: String, color: Color) -> some View {
        Button {
            openAppSettings()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.kohipsIcon)
                    .foregroundStyle(color)

                Text(message)
                    .font(.kohipsSmall)
                    .foregroundStyle(KohipsTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "arrow.up.forward.app")
                    .font(.kohipsSmall)
                    .foregroundStyle(KohipsTheme.textTertiary)
            }
            .padding(14)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func recordingContent(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .modifier(PulsingModifier())

                Text("주행 기록 중")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                Spacer()

                Button {
                    HapticManager.medium()
                    onStop()
                } label: {
                    Text("종료")
                        .font(.kohipsCallout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(KohipsTheme.destructive)
                        .clipShape(Capsule())
                }
            }

            if !trip.startAddress.isEmpty {
                Label(trip.startAddress, systemImage: "location.fill")
                    .font(.kohipsBody)
                    .foregroundStyle(KohipsTheme.textSecondary)
            } else {
                Label("위치 확인 중…", systemImage: "location.fill")
                    .font(.kohipsBody)
                    .foregroundStyle(KohipsTheme.textSecondary)
            }

            HStack(spacing: 20) {
                Label(String(format: "%.1f km", trip.distanceKm), systemImage: "road.lanes")
                    .font(.kohipsCallout)
                    .foregroundStyle(KohipsTheme.primary)

                Label(trip.durationFormatted, systemImage: "clock")
                    .font(.kohipsCallout)
                    .foregroundStyle(KohipsTheme.textSecondary)
            }
        }
    }

    private var idleContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("주행 대기 중")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                if sensorStatus.hasAnySensor && sensorStatus.isLocationAuthorized {
                    Text("차량 이동 감지 시 자동 기록")
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)
                } else {
                    Text("수동 기록 버튼을 눌러 시작하세요")
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.accent)
                }
            }

            Spacer()

            Button {
                HapticManager.light()
                onStart()
            } label: {
                Image(systemName: "record.circle")
                    .font(.kohipsIconHero)
                    .foregroundStyle(KohipsTheme.primary)
            }
        }
    }
}

private struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
