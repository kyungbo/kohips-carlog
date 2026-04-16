import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: TripViewModel
    @Binding var showSearch: Bool
    @State private var showManualStartAlert = false
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Search Bar (글로벌 검색 진입)
                    searchBar

                    // Trip Status
                    TripStatusCard(
                        isRecording: viewModel.isRecording,
                        currentTrip: viewModel.currentTrip,
                        sensorStatus: viewModel.sensorStatus,
                        onStop: { viewModel.endManualTrip() },
                        onStart: { showManualStartAlert = true }
                    )

                    // Unclassified Banner
                    if !viewModel.pendingTrips.isEmpty {
                        UnclassifiedBanner(
                            count: viewModel.pendingTrips.count,
                            onTap: {
                                NotificationCenter.default.post(
                                    name: .switchToHistoryTab,
                                    object: nil
                                )
                            }
                        )
                    }

                    // Today + Monthly in horizontal layout
                    summarySection

                    // Recent Trips
                    if viewModel.allTrips.isEmpty {
                        emptyStateView
                    } else {
                        recentTripsSection
                    }

                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(KohipsTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Kohips")
                        .font(.kohipsTitle)
                        .foregroundStyle(KohipsTheme.textPrimary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("수동 주행 시작", isPresented: $showManualStartAlert) {
                Button("시작") { viewModel.startManualTrip() }
                Button("취소", role: .cancel) { }
            } message: {
                Text("수동으로 주행 기록을 시작할까요?")
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailMapView(trip: trip, viewModel: viewModel)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        Button {
            showSearch = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.kohipsIcon)
                    .foregroundStyle(KohipsTheme.textTertiary)

                Text("주소, 메모, 날짜 검색")
                    .font(.kohipsBody)
                    .foregroundStyle(KohipsTheme.textTertiary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(KohipsTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        let summary = viewModel.todaySummary()
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        let monthRatio = viewModel.monthlyBusinessRatio(
            year: now.year ?? 2026,
            month: now.month ?? 1
        )

        return VStack(spacing: 12) {
            // Today summary
            TripSummaryCard(
                title: "오늘 운행",
                count: summary.count,
                totalKm: summary.totalKm,
                businessRatio: summary.businessRatio
            )

            // Monthly gauge
            BusinessRatioGauge(
                ratio: monthRatio,
                title: "이번 달 업무용 비율"
            )
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        KohipsCard(padding: 24) {
            VStack(spacing: 16) {
                Image(systemName: "car.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(KohipsTheme.textTertiary)

                Text("아직 운행 기록이 없습니다")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                Text("주행이 자동으로 감지되거나,\n수동 기록 버튼으로 시작할 수 있습니다")
                    .font(.kohipsBody)
                    .foregroundStyle(KohipsTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Recent Trips

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 운행")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                Spacer()

                Button {
                    NotificationCenter.default.post(name: .switchToHistoryTab, object: nil)
                } label: {
                    Text("전체보기")
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.primary)
                }
            }

            ForEach(viewModel.allTrips.prefix(5), id: \.id) { trip in
                Button {
                    selectedTrip = trip
                } label: {
                    recentTripRow(trip)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recentTripRow(_ trip: Trip) -> some View {
        HStack(spacing: 14) {
            // Purpose indicator
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(purposeColor(trip.purpose))
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trip.startAddress.isEmpty ? "출발지" : trip.startAddress)
                        .font(.kohipsCallout)
                        .foregroundStyle(KohipsTheme.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "arrow.right")
                        .font(.kohipsSmall)
                        .foregroundStyle(KohipsTheme.textTertiary)

                    Text(trip.endAddress.isEmpty ? "도착지" : trip.endAddress)
                        .font(.kohipsCallout)
                        .foregroundStyle(KohipsTheme.textPrimary)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    Text(trip.startTime, format: .dateTime.month(.abbreviated).day())
                        .font(.kohipsSmall)
                    Text(String(format: "%.1f km", trip.distanceKm))
                        .font(.kohipsSmall)
                    Text(trip.durationFormatted)
                        .font(.kohipsSmall)
                }
                .foregroundStyle(KohipsTheme.textSecondary)
            }

            Spacer()

            Text(trip.purpose.label)
                .font(.kohipsSmall)
                .foregroundStyle(purposeColor(trip.purpose))
                .padding(.horizontal, KohipsSpacing.badgeHorizontal)
                .padding(.vertical, KohipsSpacing.badgeVertical)
                .background(purposeColor(trip.purpose).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(KohipsTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Notification for tab switching
extension Notification.Name {
    static let switchToHistoryTab = Notification.Name("switchToHistoryTab")
}
