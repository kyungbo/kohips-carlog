import SwiftUI

struct PendingClassifyView: View {

    @ObservedObject var viewModel: TripViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.pendingTrips.isEmpty {
                    ContentUnavailableView(
                        "분류 완료",
                        systemImage: "checkmark.circle.fill",
                        description: Text("미분류 주행이 없습니다.")
                    )
                } else {
                    List {
                        ForEach(viewModel.pendingTrips) { trip in
                            TripClassifyCard(trip: trip) { purpose in
                                viewModel.classify(trip: trip, purpose: purpose)
                            }
                        }
                        .onDelete { offsets in
                            viewModel.delete(at: offsets, from: viewModel.pendingTrips)
                        }
                    }
                }
            }
            .navigationTitle("분류하기")
            .toolbar {
                if !viewModel.pendingTrips.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("모두 업무용") {
                            viewModel.pendingTrips.forEach {
                                viewModel.classify(trip: $0, purpose: .businessGeneral)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Classify Card

struct TripClassifyCard: View {
    let trip: Trip
    let onClassify: (TripPurpose) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.startTime, style: .date)
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)
                    Text("\(trip.startAddress.isEmpty ? "출발지" : trip.startAddress) → \(trip.endAddress.isEmpty ? "도착지" : trip.endAddress)")
                        .font(.kohipsBody)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f km", trip.distanceKm))
                        .font(.kohipsHeadline)
                    Text(trip.durationFormatted)
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)
                }
            }

            HStack(spacing: 8) {
                ClassifyButton(title: "업무 (일반)", color: KohipsTheme.business) {
                    onClassify(.businessGeneral)
                }
                ClassifyButton(title: "출퇴근", color: KohipsTheme.commute) {
                    onClassify(.commute)
                }
                ClassifyButton(title: "개인", color: KohipsTheme.personal) {
                    onClassify(.personal)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ClassifyButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kohipsSmall)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(color.opacity(0.12))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
