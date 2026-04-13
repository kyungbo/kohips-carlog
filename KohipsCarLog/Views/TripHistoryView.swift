import SwiftUI

struct TripHistoryView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var viewMode: ViewMode = .list
    @State private var periodMode: PeriodMode = .daily
    @State private var selectedTrip: Trip?
    @State private var isMultiSelectMode = false
    @State private var selectedTrips: Set<UUID> = []
    @State private var selectedDate: Date?
    @State private var currentPeriodOffset: Int = 0 // 0 = 현재, -1 = 이전...

    enum ViewMode: String, CaseIterable {
        case calendar = "캘린더"
        case list = "리스트"
    }

    enum PeriodMode: String, CaseIterable {
        case daily = "일간"
        case weekly = "주간"
        case monthly = "월간"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter + View Toggle
                VStack(spacing: 10) {
                    filterBar

                    Picker("보기 모드", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // Period selector (일간/주간/월간) — list mode only
                    if viewMode == .list {
                        VStack(spacing: 8) {
                            Picker("기간", selection: $periodMode) {
                                ForEach(PeriodMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 20)

                            periodNavigator
                        }
                    }
                }
                .padding(.bottom, 8)

                // Content
                switch viewMode {
                case .calendar:
                    calendarView
                case .list:
                    groupedListView
                }
            }
            .background(KohipsTheme.background)
            .navigationTitle("운행이력")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isMultiSelectMode ? "완료" : "선택") {
                        isMultiSelectMode.toggle()
                        if !isMultiSelectMode { selectedTrips.removeAll() }
                    }
                    .font(.kohipsCallout)
                    .foregroundStyle(KohipsTheme.primary)
                }
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailMapView(trip: trip, viewModel: viewModel)
            }
            .onChange(of: periodMode) { _, _ in currentPeriodOffset = 0 }
        }
        .overlay(alignment: .bottom) {
            if isMultiSelectMode && !selectedTrips.isEmpty {
                batchClassifyBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: selectedTrips.isEmpty)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("전체", isActive: viewModel.selectedPurposeFilter == nil && viewModel.selectedStatusFilter == nil) {
                    viewModel.clearFilters()
                }
                filterChip("미분류", isActive: viewModel.selectedStatusFilter == .pending, color: KohipsTheme.accent) {
                    viewModel.selectedStatusFilter = .pending
                    viewModel.selectedPurposeFilter = nil
                }
                filterChip("업무", isActive: viewModel.selectedPurposeFilter == .businessGeneral, color: KohipsTheme.business) {
                    viewModel.selectedPurposeFilter = .businessGeneral
                    viewModel.selectedStatusFilter = nil
                }
                filterChip("출퇴근", isActive: viewModel.selectedPurposeFilter == .commute, color: KohipsTheme.commute) {
                    viewModel.selectedPurposeFilter = .commute
                    viewModel.selectedStatusFilter = nil
                }
                filterChip("개인", isActive: viewModel.selectedPurposeFilter == .personal, color: KohipsTheme.personal) {
                    viewModel.selectedPurposeFilter = .personal
                    viewModel.selectedStatusFilter = nil
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(_ title: String, isActive: Bool, color: Color = KohipsTheme.primary, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(.kohipsCallout)
                .foregroundStyle(isActive ? .white : KohipsTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? color : KohipsTheme.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isActive ? Color.clear : KohipsTheme.separator, lineWidth: 1)
                )
        }
    }

    // MARK: - Calendar View

    private var calendarView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                calendarGrid
                tripListForSelectedDate
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: selectedDate ?? now)
        let year = calendar.component(.year, from: selectedDate ?? now)

        return KohipsCard(padding: 16) {
            VStack(spacing: 12) {
                Text("\(String(year))년 \(month)월")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                    ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                        Text(day)
                            .font(.kohipsSmall)
                            .foregroundStyle(KohipsTheme.textTertiary)
                            .frame(height: 24)
                    }

                    let days = daysInMonth(year: year, month: month)
                    ForEach(days, id: \.self) { day in
                        if day > 0 {
                            let dayTrips = tripsForDay(year: year, month: month, day: day)
                            let hasTrips = !dayTrips.isEmpty
                            let hasPending = dayTrips.contains { $0.status == .pending }
                            let isSelected = isSelectedDay(day, month: month, year: year)

                            Button {
                                var comps = DateComponents()
                                comps.year = year; comps.month = month; comps.day = day
                                selectedDate = calendar.date(from: comps)
                            } label: {
                                VStack(spacing: 3) {
                                    Text("\(day)")
                                        .font(.kohipsCallout)
                                        .foregroundStyle(isSelected ? .white : KohipsTheme.textPrimary)

                                    Circle()
                                        .fill(hasPending ? KohipsTheme.accent : KohipsTheme.primary)
                                        .frame(width: 5, height: 5)
                                        .opacity(hasTrips ? 1 : 0)
                                }
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .background(isSelected ? KohipsTheme.primary : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
            }
        }
    }

    private func isSelectedDay(_ day: Int, month: Int, year: Int) -> Bool {
        guard let sel = selectedDate else { return false }
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: sel)
        return comps.year == year && comps.month == month && comps.day == day
    }

    private func daysInMonth(year: Int, month: Int) -> [Int] {
        let calendar = Calendar.current
        var comps = DateComponents(); comps.year = year; comps.month = month; comps.day = 1
        guard let firstDay = calendar.date(from: comps) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDay) - 1
        let range = calendar.range(of: .day, in: .month, for: firstDay) ?? 1..<31
        return Array(repeating: 0, count: weekday) + Array(range)
    }

    private func tripsForDay(year: Int, month: Int, day: Int) -> [Trip] {
        viewModel.allTrips.filter {
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: $0.startTime)
            return comps.year == year && comps.month == month && comps.day == day
        }
    }

    private var tripListForSelectedDate: some View {
        Group {
            if let date = selectedDate {
                let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
                let trips = tripsForDay(year: comps.year ?? 0, month: comps.month ?? 0, day: comps.day ?? 0)

                if trips.isEmpty {
                    Text("운행 기록 없음")
                        .font(.kohipsBody)
                        .foregroundStyle(KohipsTheme.textTertiary)
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(trips, id: \.id) { trip in
                        tripRow(trip)
                    }
                }
            }
        }
    }

    // MARK: - Period Navigator

    private var periodNavigator: some View {
        HStack {
            Button {
                currentPeriodOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.kohipsIcon)
                    .foregroundStyle(KohipsTheme.primary)
                    .padding(8)
            }

            Spacer()

            Text(periodLabel)
                .font(.kohipsHeadline)
                .foregroundStyle(KohipsTheme.textPrimary)

            Spacer()

            Button {
                if currentPeriodOffset < 0 {
                    currentPeriodOffset += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.kohipsIcon)
                    .foregroundStyle(currentPeriodOffset < 0 ? KohipsTheme.primary : KohipsTheme.textTertiary)
                    .padding(8)
            }
            .disabled(currentPeriodOffset >= 0)
        }
        .padding(.horizontal, 20)
    }

    private var periodLabel: String {
        let (start, end) = periodDateRange
        let formatter = DateFormatter()

        switch periodMode {
        case .daily:
            formatter.dateFormat = "yyyy년 M월 d일 (E)"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: start)
        case .weekly:
            formatter.dateFormat = "M/d"
            let startStr = formatter.string(from: start)
            // end is exclusive (next week start), so subtract 1 day for display
            let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
            let endStr = formatter.string(from: lastDay)
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "yyyy년"
            return "\(yearFormatter.string(from: start)) \(startStr) ~ \(endStr)"
        case .monthly:
            formatter.dateFormat = "yyyy년 M월"
            return formatter.string(from: start)
        }
    }

    private var periodDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch periodMode {
        case .daily:
            let day = calendar.date(byAdding: .day, value: currentPeriodOffset, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            return (day, nextDay)
        case .weekly:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            let adjustedStart = calendar.date(byAdding: .weekOfYear, value: currentPeriodOffset, to: weekStart)!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: adjustedStart)!
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: adjustedStart)!
            return (adjustedStart, nextWeek)
        case .monthly:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            let adjustedStart = calendar.date(byAdding: .month, value: currentPeriodOffset, to: monthStart)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: adjustedStart)!
            return (adjustedStart, nextMonth)
        }
    }

    private var periodTrips: [Trip] {
        let (start, end) = periodDateRange
        return viewModel.filteredTrips().filter { trip in
            trip.startTime >= start && trip.startTime < end
        }
    }

    // MARK: - Grouped List View

    private var groupedListView: some View {
        let trips = periodTrips

        return VStack(spacing: 0) {
            // Period summary
            periodSummaryCard(trips: trips)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)

            if trips.isEmpty {
                ContentUnavailableView(
                    "운행 기록 없음",
                    systemImage: "car.fill",
                    description: Text("해당 기간의 운행 기록이 없습니다")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        // Group by day within the period
                        let grouped = groupTripsByDay(trips)
                        ForEach(grouped, id: \.date) { group in
                            if periodMode != .daily {
                                dayHeader(date: group.date, count: group.trips.count, km: group.totalKm)
                            }
                            ForEach(group.trips, id: \.id) { trip in
                                tripRow(trip)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private func periodSummaryCard(trips: [Trip]) -> some View {
        let totalKm = trips.reduce(0) { $0 + $1.distanceKm }
        let businessKm = trips.reduce(0) { $0 + $1.businessDistanceKm }
        let ratio = totalKm > 0 ? businessKm / totalKm : 0
        let classifiedCount = trips.filter { $0.status == .classified }.count
        let pendingCount = trips.filter { $0.status == .pending }.count

        return KohipsCard(padding: 16) {
            HStack(spacing: 0) {
                summaryItem(value: "\(trips.count)", label: "총 운행", color: KohipsTheme.textPrimary)
                Spacer()
                summaryItem(value: String(format: "%.1f km", totalKm), label: "총 거리", color: KohipsTheme.primary)
                Spacer()
                summaryItem(value: String(format: "%.0f%%", ratio * 100), label: "업무용", color: KohipsTheme.business)
                Spacer()
                summaryItem(value: "\(pendingCount)", label: "미분류", color: pendingCount > 0 ? KohipsTheme.accent : KohipsTheme.textTertiary)
            }
        }
    }

    private func summaryItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.kohipsHeadline)
                .foregroundStyle(color)
            Text(label)
                .font(.kohipsSmall)
                .foregroundStyle(KohipsTheme.textTertiary)
        }
    }

    struct DayGroup {
        let date: Date
        let trips: [Trip]
        var totalKm: Double { trips.reduce(0) { $0 + $1.distanceKm } }
    }

    private func groupTripsByDay(_ trips: [Trip]) -> [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: trips) { trip in
            calendar.startOfDay(for: trip.startTime)
        }
        return grouped.map { DayGroup(date: $0.key, trips: $0.value.sorted { $0.startTime > $1.startTime }) }
            .sorted { $0.date > $1.date }
    }

    private func dayHeader(date: Date, count: Int, km: Double) -> some View {
        HStack {
            Text(date, format: .dateTime.month(.abbreviated).day().weekday(.abbreviated))
                .font(.kohipsCallout)
                .foregroundStyle(KohipsTheme.textSecondary)
            Spacer()
            Text("\(count)건 · \(String(format: "%.1f km", km))")
                .font(.kohipsSmall)
                .foregroundStyle(KohipsTheme.textTertiary)
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Trip Row

    private func tripRow(_ trip: Trip) -> some View {
        Button {
            if isMultiSelectMode {
                if selectedTrips.contains(trip.id) {
                    selectedTrips.remove(trip.id)
                } else {
                    selectedTrips.insert(trip.id)
                }
            } else {
                selectedTrip = trip
            }
        } label: {
            HStack(spacing: 14) {
                if isMultiSelectMode {
                    Image(systemName: selectedTrips.contains(trip.id) ? "checkmark.circle.fill" : "circle")
                        .font(.kohipsIconLarge)
                        .foregroundStyle(selectedTrips.contains(trip.id) ? KohipsTheme.primary : KohipsTheme.textTertiary)
                }

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(purposeColor(trip.purpose))
                    .frame(width: 4, height: 40)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(trip.startAddress) → \(trip.endAddress)")
                        .font(.kohipsCallout)
                        .foregroundStyle(KohipsTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        Text(trip.startTime, format: .dateTime.month(.abbreviated).day().hour().minute())
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
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(KohipsTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Batch Classify Bar

    private var batchClassifyBar: some View {
        VStack(spacing: 0) {
            KohipsTheme.separator.frame(height: 1)

            HStack(spacing: 14) {
                Text("\(selectedTrips.count)건 선택")
                    .font(.kohipsHeadline)
                    .foregroundStyle(KohipsTheme.textPrimary)

                Spacer()

                classifyButton("업무", purpose: .businessGeneral, color: KohipsTheme.business)
                classifyButton("출퇴근", purpose: .commute, color: KohipsTheme.commute)
                classifyButton("개인", purpose: .personal, color: KohipsTheme.personal)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }

    private func classifyButton(_ title: String, purpose: TripPurpose, color: Color) -> some View {
        Button {
            HapticManager.medium()
            let trips = viewModel.allTrips.filter { selectedTrips.contains($0.id) }
            viewModel.batchClassify(trips: trips, purpose: purpose)
            selectedTrips.removeAll()
            isMultiSelectMode = false
        } label: {
            Text(title)
                .font(.kohipsCallout)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color)
                .clipShape(Capsule())
        }
    }
}

// TripDetailSheet replaced by TripDetailMapView
