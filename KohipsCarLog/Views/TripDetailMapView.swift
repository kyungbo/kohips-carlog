import SwiftUI
import MapKit

struct TripDetailMapView: View {
    @Bindable var trip: Trip
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editingStartAddress = false
    @State private var editingEndAddress = false
    @State private var startAddressText = ""
    @State private var endAddressText = ""
    @State private var odometerBeforeText = ""
    @State private var odometerAfterText = ""
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Map Section
                    mapSection
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                    VStack(spacing: 16) {
                        // Route Summary Card
                        routeSummaryCard

                        // Trip Info Card
                        tripInfoCard

                        // Classification Card
                        classificationCard

                        // Odometer Card (NTS)
                        odometerCard

                        // Memo Card
                        memoCard

                        // Delete Button
                        deleteButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(KohipsTheme.background)
            .navigationTitle("운행 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.kohipsCallout)
                    .foregroundStyle(KohipsTheme.primary)
                }
            }
            .onAppear {
                startAddressText = trip.startAddress
                endAddressText = trip.endAddress
                if let b = trip.odometerBefore { odometerBeforeText = String(format: "%.1f", b) }
                if let a = trip.odometerAfter { odometerAfterText = String(format: "%.1f", a) }

                // M10: 경로 좌표 기반 카메라 초기화
                let coords = trip.coordinates
                if coords.count >= 2 {
                    let lats = coords.map(\.latitude)
                    let lngs = coords.map(\.longitude)
                    let center = CLLocationCoordinate2D(
                        latitude: (lats.min()! + lats.max()!) / 2,
                        longitude: (lngs.min()! + lngs.max()!) / 2
                    )
                    let span = MKCoordinateSpan(
                        latitudeDelta: (lats.max()! - lats.min()!) * 1.4 + 0.005,
                        longitudeDelta: (lngs.max()! - lngs.min()!) * 1.4 + 0.005
                    )
                    mapCameraPosition = .region(MKCoordinateRegion(center: center, span: span))
                }
            }
            .onDisappear {
                guard !trip.isDeleted else { return }
                saveChanges()
            }
        }
    }

    // MARK: - Map Section

    @ViewBuilder
    private var mapSection: some View {
        let coords = trip.coordinates
        if coords.count >= 2 {
            Map(position: $mapCameraPosition) {
                // Route polyline
                MapPolyline(coordinates: coords)
                    .stroke(KohipsTheme.primary, lineWidth: 4)

                // Start marker
                if let first = coords.first {
                    Annotation("출발", coordinate: first) {
                        Circle()
                            .fill(KohipsTheme.primary)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle().stroke(.white, lineWidth: 2)
                            )
                    }
                }

                // End marker
                if let last = coords.last {
                    Annotation("도착", coordinate: last) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(KohipsTheme.destructive)
                            .clipShape(Circle())
                    }
                }
            }
            .mapStyle(.standard)
        } else {
            // 좌표 데이터 없음
            ZStack {
                Rectangle()
                    .fill(KohipsTheme.surface)

                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundStyle(KohipsTheme.textTertiary)
                    Text("경로 데이터 없음")
                        .font(.kohipsBody)
                        .foregroundStyle(KohipsTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - Route Summary

    private var routeSummaryCard: some View {
        KohipsCard(padding: 20) {
            VStack(spacing: 16) {
                // Start → End with editable addresses
                HStack(alignment: .top, spacing: 12) {
                    // Route dots
                    VStack(spacing: 4) {
                        Circle()
                            .fill(KohipsTheme.primary)
                            .frame(width: 10, height: 10)
                        Rectangle()
                            .fill(KohipsTheme.textTertiary)
                            .frame(width: 2, height: 30)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(KohipsTheme.destructive)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 16) {
                        // Start address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("출발지")
                                .font(.kohipsSmall)
                                .foregroundStyle(KohipsTheme.textTertiary)
                            if editingStartAddress {
                                TextField("출발지 주소", text: $startAddressText)
                                    .font(.kohipsCallout)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit { editingStartAddress = false }
                            } else {
                                Text(startAddressText.isEmpty ? "주소 없음" : startAddressText)
                                    .font(.kohipsCallout)
                                    .foregroundStyle(KohipsTheme.textPrimary)
                                    .onTapGesture { editingStartAddress = true }
                            }
                        }

                        // End address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("도착지")
                                .font(.kohipsSmall)
                                .foregroundStyle(KohipsTheme.textTertiary)
                            if editingEndAddress {
                                TextField("도착지 주소", text: $endAddressText)
                                    .font(.kohipsCallout)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit { editingEndAddress = false }
                            } else {
                                Text(endAddressText.isEmpty ? "주소 없음" : endAddressText)
                                    .font(.kohipsCallout)
                                    .foregroundStyle(KohipsTheme.textPrimary)
                                    .onTapGesture { editingEndAddress = true }
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Trip Info

    private var tripInfoCard: some View {
        KohipsCard(padding: 20) {
            VStack(spacing: 14) {
                HStack {
                    infoItem(icon: "road.lanes", label: "주행거리",
                             value: String(format: "%.1f km", trip.distanceKm),
                             color: KohipsTheme.primary)
                    Spacer()
                    infoItem(icon: "clock", label: "소요시간",
                             value: trip.durationFormatted,
                             color: KohipsTheme.textSecondary)
                }

                KohipsTheme.separator.frame(height: 1)

                HStack {
                    infoItem(icon: "calendar", label: "운행일자",
                             value: trip.startTime.formatted(.dateTime.year().month().day()),
                             color: KohipsTheme.textSecondary)
                    Spacer()
                    infoItem(icon: "clock.arrow.2.circlepath", label: "시간",
                             value: formatTimeRange(),
                             color: KohipsTheme.textSecondary)
                }
            }
        }
    }

    private func infoItem(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.kohipsIcon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.kohipsSmall)
                    .foregroundStyle(KohipsTheme.textTertiary)
                Text(value)
                    .font(.kohipsCallout)
                    .foregroundStyle(KohipsTheme.textPrimary)
            }
        }
    }

    private func formatTimeRange() -> String {
        let start = trip.startTime.formatted(.dateTime.hour().minute())
        if let end = trip.endTime {
            return "\(start) ~ \(end.formatted(.dateTime.hour().minute()))"
        }
        return start
    }

    // MARK: - Classification

    private var classificationCard: some View {
        KohipsCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("운행 분류")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                // Purpose buttons
                HStack(spacing: 10) {
                    ForEach(TripPurpose.allCases, id: \.self) { purpose in
                        if purpose != .unclassified {
                            purposeButton(purpose)
                        }
                    }
                }

                // Purpose detail (for business)
                if trip.purpose.isBusiness {
                    TextField("업무 목적 상세 (예: 거래처 미팅)", text: Binding(
                        get: { trip.purposeDetail ?? "" },
                        set: { trip.purposeDetail = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.kohipsBody)
                    .padding(12)
                    .background(KohipsTheme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func purposeButton(_ purpose: TripPurpose) -> some View {
        let isSelected = trip.purpose == purpose
        return Button {
            HapticManager.medium()
            viewModel.classify(trip: trip, purpose: purpose)
        } label: {
            Text(purpose.label)
                .font(.kohipsCallout)
                .foregroundStyle(isSelected ? .white : purposeColor(purpose))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? purposeColor(purpose) : purposeColor(purpose).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Odometer

    private var odometerCard: some View {
        KohipsCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("계기판 (국세청 양식)")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("주행 전 (km)")
                            .font(.kohipsSmall)
                            .foregroundStyle(KohipsTheme.textTertiary)
                        TextField("0.0", text: $odometerBeforeText)
                            .keyboardType(.decimalPad)
                            .font(.kohipsBody)
                            .padding(12)
                            .background(KohipsTheme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("주행 후 (km)")
                            .font(.kohipsSmall)
                            .foregroundStyle(KohipsTheme.textTertiary)
                        TextField("0.0", text: $odometerAfterText)
                            .keyboardType(.decimalPad)
                            .font(.kohipsBody)
                            .padding(12)
                            .background(KohipsTheme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Memo

    private var memoCard: some View {
        KohipsCard(padding: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("비고")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                TextField("메모를 입력하세요", text: Binding(
                    get: { trip.memo },
                    set: { trip.memo = $0 }
                ), axis: .vertical)
                .font(.kohipsBody)
                .lineLimit(3...6)
                .padding(12)
                .background(KohipsTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button {
            let tripToDelete = trip
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.delete(trip: tripToDelete)
            }
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("이 운행 기록 삭제")
            }
            .font(.kohipsCallout)
            .foregroundStyle(KohipsTheme.destructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KohipsTheme.destructive.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Save

    private func saveChanges() {
        trip.startAddress = startAddressText
        trip.endAddress = endAddressText
        if let before = Double(odometerBeforeText) { trip.odometerBefore = before }
        if let after = Double(odometerAfterText) { trip.odometerAfter = after }
        try? viewModel.modelContext.save()
    }
}
