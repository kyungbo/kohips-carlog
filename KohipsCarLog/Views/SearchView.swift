import SwiftUI

/// Full-screen search overlay (글로벌 검색)
struct SearchOverlay: View {
    @ObservedObject var viewModel: TripViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedTrip: Trip?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.kohipsIcon)
                        .foregroundStyle(KohipsTheme.textTertiary)

                    TextField("주소, 메모, 날짜로 검색", text: $searchText)
                        .font(.kohipsBody)
                        .foregroundStyle(KohipsTheme.textPrimary)
                        .autocorrectionDisabled()
                        .focused($isSearchFocused)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.kohipsIcon)
                                .foregroundStyle(KohipsTheme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(KohipsTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("취소") {
                    isPresented = false
                }
                .font(.kohipsCallout)
                .foregroundStyle(KohipsTheme.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Divider
            KohipsTheme.separator.frame(height: 1)

            // Content
            if searchText.isEmpty {
                recentHintsView
            } else if viewModel.searchResults.isEmpty {
                noResultsView
            } else {
                resultsView
            }
        }
        .background(KohipsTheme.background)
        .onAppear { isSearchFocused = true }
        .task(id: searchText) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            viewModel.searchTrips(query: searchText)
        }
        .sheet(item: $selectedTrip) { trip in
            TripDetailMapView(trip: trip, viewModel: viewModel)
        }
    }

    // MARK: - Hints

    private var recentHintsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.allTrips.isEmpty {
                    Text("최근 검색한 장소")
                        .font(.kohipsCaption)
                        .foregroundStyle(KohipsTheme.textSecondary)
                        .padding(.horizontal, 4)

                    // Show recent unique addresses as search suggestions
                    let recentAddresses = Array(Set(
                        viewModel.allTrips.prefix(10).flatMap { [$0.startAddress, $0.endAddress] }
                            .filter { !$0.isEmpty && $0 != "위치 불명" && $0 != "주소 불명" }
                    )).prefix(8)

                    ForEach(Array(recentAddresses), id: \.self) { address in
                        Button {
                            searchText = address
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.kohipsIconSmall)
                                    .foregroundStyle(KohipsTheme.textTertiary)

                                Text(address)
                                    .font(.kohipsBody)
                                    .foregroundStyle(KohipsTheme.textPrimary)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Spacer(minLength: 60)
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.kohipsIconHero)
                            .foregroundStyle(KohipsTheme.textTertiary)
                        Text("주소, 메모, 날짜로 검색하세요")
                            .font(.kohipsBody)
                            .foregroundStyle(KohipsTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)
            Image(systemName: "doc.text.magnifyingglass")
                .font(.kohipsIconHero)
                .foregroundStyle(KohipsTheme.textTertiary)
            Text("'\(searchText)'에 대한 결과가 없습니다")
                .font(.kohipsBody)
                .foregroundStyle(KohipsTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                Text("\(viewModel.searchResults.count)건의 결과")
                    .font(.kohipsCaption)
                    .foregroundStyle(KohipsTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                ForEach(viewModel.searchResults, id: \.id) { trip in
                    Button {
                        selectedTrip = trip
                    } label: {
                        resultRow(trip)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private func resultRow(_ trip: Trip) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(purposeColor(trip.purpose))
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(trip.startAddress) → \(trip.endAddress)")
                    .font(.kohipsCallout)
                    .foregroundStyle(KohipsTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text(trip.startTime, format: .dateTime.year().month().day())
                        .font(.kohipsSmall)
                    Text(String(format: "%.1f km", trip.distanceKm))
                        .font(.kohipsSmall)
                    if let detail = trip.purposeDetail {
                        Text(detail).font(.kohipsSmall).lineLimit(1)
                    }
                }
                .foregroundStyle(KohipsTheme.textSecondary)
            }

            Spacer()

            Text(trip.purpose.label)
                .font(.kohipsSmall)
                .foregroundStyle(purposeColor(trip.purpose))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(KohipsTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// Keep SearchView as alias for compatibility
struct SearchView: View {
    @ObservedObject var viewModel: TripViewModel
    var body: some View { EmptyView() }
}
