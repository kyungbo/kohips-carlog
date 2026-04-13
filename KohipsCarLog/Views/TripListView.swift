import SwiftUI

struct TripListView: View {

    @ObservedObject var viewModel: TripViewModel
    @State private var selectedTrip: Trip?
    @State private var showingManualStartAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Live recording banner
                if viewModel.isRecording {
                    RecordingBannerView(trip: viewModel.currentTrip) {
                        viewModel.endManualTrip()
                    }
                    .listRowBackground(Color.red.opacity(0.1))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                ForEach(viewModel.allTrips) { trip in
                    TripRowView(trip: trip)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTrip = trip }
                }
                .onDelete { offsets in
                    viewModel.delete(at: offsets, from: viewModel.allTrips)
                }
            }
            .navigationTitle("코힙스 차계부")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isRecording {
                        Button("주행 종료", role: .destructive) {
                            viewModel.endManualTrip()
                        }
                    } else {
                        Button {
                            showingManualStartAlert = true
                        } label: {
                            Image(systemName: "record.circle")
                        }
                    }
                }
            }
            .alert("수동 주행 기록 시작", isPresented: $showingManualStartAlert) {
                Button("시작") { viewModel.startManualTrip() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("현재 위치에서 주행 기록을 시작합니다.")
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailMapView(trip: trip, viewModel: viewModel)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openTripDetail)) { notification in
                guard let tripId = notification.userInfo?["tripId"] as? UUID else { return }
                selectedTrip = viewModel.allTrips.first { $0.id == tripId }
            }
            .refreshable {
                viewModel.fetchTrips()
            }
        }
    }
}

// MARK: - Trip Row

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                purposeBadge
                Spacer()
                Text(trip.startTime, style: .date)
                    .font(.kohipsCaption)
                    .foregroundStyle(KohipsTheme.textSecondary)
            }
            Text("\(trip.startAddress.isEmpty ? "출발지" : trip.startAddress) → \(trip.endAddress.isEmpty ? "도착지" : trip.endAddress)")
                .font(.kohipsBody)
                .lineLimit(1)
            HStack {
                Label(String(format: "%.1f km", trip.distanceKm), systemImage: "road.lanes")
                Spacer()
                Label(trip.durationFormatted, systemImage: "clock")
            }
            .font(.kohipsCaption)
            .foregroundStyle(KohipsTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    var purposeBadge: some View {
        Text(trip.purpose.label)
            .font(.kohipsSmall)
            .fontWeight(.medium)
            .padding(.horizontal, KohipsSpacing.badgeHorizontal)
            .padding(.vertical, KohipsSpacing.badgeVertical)
            .background(purposeColor(trip.purpose).opacity(0.15))
            .foregroundStyle(purposeColor(trip.purpose))
            .clipShape(Capsule())
    }
}

// MARK: - Recording Banner

struct RecordingBannerView: View {
    let trip: Trip?
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "record.circle.fill")
                .foregroundStyle(.red)
                .symbolEffect(.pulse)
            VStack(alignment: .leading, spacing: 2) {
                Text("주행 기록 중")
                    .font(.kohipsHeadline)
                if let trip {
                    Text(trip.startAddress.isEmpty ? "위치 확인 중…" : trip.startAddress)
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("종료", action: onStop)
                .buttonStyle(.bordered)
                .tint(.red)
        }
    }
}

// MARK: - Trip Detail

struct TripDetailView: View {
    @Bindable var trip: Trip
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("주행 정보") {
                    LabeledContent("거리") { Text(String(format: "%.2f km", trip.distanceKm)) }
                    LabeledContent("시간") { Text(trip.durationFormatted) }
                    LabeledContent("출발") { Text(trip.startTime, style: .time) }
                    if let end = trip.endTime {
                        LabeledContent("도착") { Text(end, style: .time) }
                    }
                }

                Section("주소") {
                    if !trip.startAddress.isEmpty {
                        LabeledContent("출발지") { Text(trip.startAddress) }
                    }
                    if !trip.endAddress.isEmpty {
                        LabeledContent("도착지") { Text(trip.endAddress) }
                    }
                }

                Section("분류") {
                    Picker("목적", selection: $trip.purpose) {
                        ForEach(TripPurpose.allCases, id: \.self) { purpose in
                            Text(purpose.label).tag(purpose)
                        }
                    }
                    .onChange(of: trip.purpose) { _, _ in
                        trip.status = .classified
                        try? viewModel.modelContext.save()
                        viewModel.fetchTrips()
                    }
                }

                Section("메모") {
                    TextField("메모 입력", text: $trip.memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("주행 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
