import SwiftUI

struct MyPageView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var showAddVehicle = false
    @State private var shareItem: URL?
    @AppStorage("appColorScheme") private var appColorScheme: String = "dark"

    // Export
    @State private var exportYear = Calendar.current.component(.year, from: Date())
    @State private var exportMonth = Calendar.current.component(.month, from: Date())
    @State private var exportVehicleId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Profile Card
                    profileCard

                    // Vehicle Section
                    vehicleSection

                    // Vehicle Reservation (placeholder)
                    reservationPlaceholder

                    // Export Section
                    exportSection

                    // Settings
                    settingsSection

                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(KohipsTheme.background)
            .navigationTitle("마이페이지")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleSheet(viewModel: viewModel)
            }
            .sheet(isPresented: Binding(
                get: { shareItem != nil },
                set: { if !$0 { shareItem = nil } }
            )) {
                if let url = shareItem {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        KohipsCard(padding: 20) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(KohipsTheme.primary.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "person.fill")
                        .font(.kohipsIconXL)
                        .foregroundStyle(KohipsTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("개인사업자 모드")
                        .font(.kohipsHeadline)
                        .foregroundStyle(KohipsTheme.textPrimary)
                    Text("로그인하여 법인 기능을 사용하세요")
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.kohipsIconSmall)
                    .foregroundStyle(KohipsTheme.textTertiary)
            }
        }
    }

    // MARK: - Vehicle Section

    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("내 차량")

            if viewModel.vehicles.isEmpty {
                KohipsCard(padding: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "car.fill")
                            .font(.kohipsIconXL)
                            .foregroundStyle(KohipsTheme.textTertiary)
                        Text("등록된 차량이 없습니다")
                            .font(.kohipsBody)
                            .foregroundStyle(KohipsTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                ForEach(viewModel.vehicles, id: \.id) { vehicle in
                    vehicleRow(vehicle)
                }
            }

            Button {
                showAddVehicle = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.kohipsIconLarge)
                    Text("차량 추가")
                        .font(.kohipsCallout)
                }
                .foregroundStyle(KohipsTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(KohipsTheme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(KohipsTheme.primary.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(KohipsTheme.surfaceElevated)
                    .frame(width: 44, height: 44)

                Image(systemName: "car.fill")
                    .font(.kohipsIcon)
                    .foregroundStyle(KohipsTheme.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(vehicle.licensePlate)
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)
                Text("\(vehicle.model) (\(vehicle.year))")
                    .font(.kohipsCaption)
                    .foregroundStyle(KohipsTheme.textSecondary)
            }

            Spacer()

            Text(String(format: "%.0f km", vehicle.currentOdometer))
                .font(.kohipsCaption)
                .foregroundStyle(KohipsTheme.textTertiary)
        }
        .padding(14)
        .background(KohipsTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteVehicle(vehicle)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - Reservation Placeholder

    private var reservationPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("차량예약")

            KohipsCard(padding: 20) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(KohipsTheme.commute.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "calendar.badge.clock")
                            .font(.kohipsIconLarge)
                            .foregroundStyle(KohipsTheme.commute)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("법인 차량 예약")
                            .font(.kohipsHeadline)
                            .foregroundStyle(KohipsTheme.textPrimary)
                        Text("Phase 2에서 법인 계정 연동과 함께 추가됩니다")
                            .font(.kohipsCaption)
                            .foregroundStyle(KohipsTheme.textSecondary)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("국세청 내보내기")

            KohipsCard(padding: 20) {
                VStack(spacing: 16) {
                    HStack {
                        Text("기간")
                            .font(.kohipsBody)
                            .foregroundStyle(KohipsTheme.textSecondary)
                        Spacer()
                        Picker("", selection: $exportYear) {
                            ForEach(2024...2030, id: \.self) { Text("\($0)년").tag($0) }
                        }
                        .labelsHidden()
                        .tint(KohipsTheme.textPrimary)

                        Picker("", selection: $exportMonth) {
                            ForEach(1...12, id: \.self) { Text("\($0)월").tag($0) }
                        }
                        .labelsHidden()
                        .tint(KohipsTheme.textPrimary)
                    }

                    if !viewModel.vehicles.isEmpty {
                        KohipsTheme.separator.frame(height: 1)

                        HStack {
                            Text("차량")
                                .font(.kohipsBody)
                                .foregroundStyle(KohipsTheme.textSecondary)
                            Spacer()
                            Picker("", selection: $exportVehicleId) {
                                Text("전체").tag(nil as UUID?)
                                ForEach(viewModel.vehicles, id: \.id) { v in
                                    Text(v.licensePlate).tag(v.id as UUID?)
                                }
                            }
                            .labelsHidden()
                            .tint(KohipsTheme.textPrimary)
                        }
                    }

                    KohipsTheme.separator.frame(height: 1)

                    let trips = viewModel.tripsForExport(year: exportYear, month: exportMonth, vehicleId: exportVehicleId)

                    HStack {
                        Text("대상 건수")
                            .font(.kohipsBody)
                            .foregroundStyle(KohipsTheme.textSecondary)
                        Spacer()
                        Text("\(trips.count)건")
                            .font(.kohipsHeadline)
                            .foregroundStyle(KohipsTheme.textPrimary)
                    }

                    // Export buttons
                    HStack(spacing: 12) {
                        exportButton(
                            title: "CSV",
                            icon: "doc.text",
                            disabled: trips.isEmpty
                        ) { exportCSV(trips: trips) }

                        exportButton(
                            title: "PDF (별지 84-2)",
                            icon: "doc.richtext",
                            disabled: trips.isEmpty
                        ) { exportPDF(trips: trips) }
                    }
                }
            }
        }
    }

    private func exportButton(title: String, icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.kohipsIconSmall)
                Text(title)
                    .font(.kohipsCallout)
            }
            .foregroundStyle(disabled ? KohipsTheme.textTertiary : KohipsTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(disabled ? KohipsTheme.surfaceElevated : KohipsTheme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .disabled(disabled)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("설정")

            KohipsCard(padding: 0) {
                VStack(spacing: 0) {
                    // Appearance mode
                    HStack(spacing: 14) {
                        Image(systemName: "moon.circle")
                            .font(.kohipsIcon)
                            .foregroundStyle(KohipsTheme.textSecondary)
                            .frame(width: 24)

                        Text("화면 모드")
                            .font(.kohipsBody)
                            .foregroundStyle(KohipsTheme.textPrimary)

                        Spacer()

                        Picker("", selection: $appColorScheme) {
                            Text("다크").tag("dark")
                            Text("라이트").tag("light")
                            Text("시스템").tag("system")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .tint(KohipsTheme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    KohipsTheme.separator.frame(height: 1).padding(.leading, 52)
                    settingsRow(icon: "antenna.radiowaves.left.and.right", title: "OBD-II 블루투스", trailing: "Phase 3")
                    KohipsTheme.separator.frame(height: 1).padding(.leading, 52)
                    settingsRow(icon: "info.circle", title: "앱 버전", trailing: "2.0.0")
                }
            }
        }
    }

    private func settingsRow(icon: String, title: String, trailing: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.kohipsIcon)
                .foregroundStyle(KohipsTheme.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(.kohipsBody)
                .foregroundStyle(KohipsTheme.textPrimary)

            Spacer()

            Text(trailing)
                .font(.kohipsCaption)
                .foregroundStyle(KohipsTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.kohipsHeadline)
            .foregroundStyle(KohipsTheme.textPrimary)
            .padding(.leading, 4)
    }

    private func exportCSV(trips: [Trip]) {
        let vehicle = exportVehicleId.flatMap { id in viewModel.vehicles.first { $0.id == id } }
        let csv = NTSExportService.generateCSV(trips: trips, vehicle: vehicle, year: exportYear, month: exportMonth)
        let fileName = String(format: "%04d%02d_운행기록부.csv", exportYear, exportMonth)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareItem = url
    }

    private func exportPDF(trips: [Trip]) {
        let vehicle = exportVehicleId.flatMap { id in viewModel.vehicles.first { $0.id == id } }
        let data = NTSExportService.generatePDF(trips: trips, vehicle: vehicle, year: exportYear, month: exportMonth)
        let fileName = String(format: "%04d%02d_운행기록부.pdf", exportYear, exportMonth)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
        shareItem = url
    }
}

// MARK: - Add Vehicle Sheet

struct AddVehicleSheet: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var licensePlate = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var odometerText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("차량 정보") {
                    TextField("차량번호 (예: 12가 3456)", text: $licensePlate)
                    TextField("차종 (예: 현대 아반떼)", text: $model)
                    Picker("연식", selection: $year) {
                        ForEach(2000...2030, id: \.self) { Text("\($0)년").tag($0) }
                    }
                    TextField("현재 주행거리 (km)", text: $odometerText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("차량 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        viewModel.addVehicle(
                            licensePlate: licensePlate,
                            model: model,
                            year: year,
                            odometer: Double(odometerText) ?? 0
                        )
                        dismiss()
                    }
                    .disabled(licensePlate.isEmpty || model.isEmpty)
                }
            }
        }
    }
}

// ShareSheet is defined in ExportView.swift
