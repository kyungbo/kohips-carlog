import Foundation
import SwiftData
import Combine

@MainActor
final class TripViewModel: ObservableObject {

    @Published var pendingTrips: [Trip] = []
    @Published var allTrips: [Trip] = []
    @Published var isRecording: Bool = false
    @Published var currentTrip: Trip?
    @Published var sensorStatus = TripDetector.SensorStatus()

    // Vehicle
    @Published var vehicles: [Vehicle] = []

    // Search & Filter
    @Published var searchResults: [Trip] = []
    @Published var selectedPurposeFilter: TripPurpose?
    @Published var selectedStatusFilter: TripStatus?
    @Published var filterStartDate: Date?
    @Published var filterEndDate: Date?

    var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Inject context into TripDetector
        TripDetector.shared.modelContext = modelContext

        // Observe TripDetector state
        TripDetector.shared.$isRecording
            .assign(to: &$isRecording)

        TripDetector.shared.$currentTrip
            .assign(to: &$currentTrip)

        TripDetector.shared.$sensorStatus
            .assign(to: &$sensorStatus)

        fetchTrips()
        fetchVehicles()

        // Refresh trip list when quick-classify notifications arrive
        NotificationCenter.default.publisher(for: .quickClassifyBusiness)
            .merge(with: NotificationCenter.default.publisher(for: .quickClassifyPersonal))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let tripId = notification.userInfo?["tripId"] as? UUID else { return }
                self.quickClassify(tripId: tripId, asBusiness: notification.name == .quickClassifyBusiness)
            }
            .store(in: &cancellables)
    }

    // MARK: - Fetch

    func fetchTrips() {
        let descriptor = FetchDescriptor<Trip>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        allTrips = (try? modelContext.fetch(descriptor)) ?? []
        pendingTrips = allTrips.filter { $0.status == .pending }
    }

    func fetchVehicles() {
        let descriptor = FetchDescriptor<Vehicle>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        vehicles = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Classification

    func classify(trip: Trip, purpose: TripPurpose, purposeDetail: String? = nil) {
        trip.purpose = purpose
        trip.status = .classified
        if let detail = purposeDetail {
            trip.purposeDetail = detail
        }
        NotificationManager.shared.cancelReminder(for: trip.id)
        try? modelContext.save()
        fetchTrips()
    }

    func quickClassify(tripId: UUID, asBusiness: Bool) {
        guard let trip = allTrips.first(where: { $0.id == tripId }) else { return }
        classify(trip: trip, purpose: asBusiness ? .businessGeneral : .personal)
    }

    func batchClassify(trips: [Trip], purpose: TripPurpose) {
        for trip in trips {
            trip.purpose = purpose
            trip.status = .classified
            NotificationManager.shared.cancelReminder(for: trip.id)
        }
        try? modelContext.save()
        fetchTrips()
    }

    // MARK: - Delete

    func delete(trip: Trip) {
        modelContext.delete(trip)
        try? modelContext.save()
        fetchTrips()
    }

    func delete(at offsets: IndexSet, from trips: [Trip]) {
        offsets.map { trips[$0] }.forEach { delete(trip: $0) }
    }

    // MARK: - Vehicle Management

    func addVehicle(licensePlate: String, model: String, year: Int, odometer: Double = 0) {
        let vehicle = Vehicle(licensePlate: licensePlate, model: model, year: year, currentOdometer: odometer)
        modelContext.insert(vehicle)
        try? modelContext.save()
        fetchVehicles()
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        modelContext.delete(vehicle)
        try? modelContext.save()
        fetchVehicles()
    }

    // MARK: - Manual Trip

    func startManualTrip() {
        TripDetector.shared.startTripManually()
    }

    func endManualTrip() {
        TripDetector.shared.endTripManually()
        fetchTrips()
    }

    // MARK: - Search

    func searchTrips(query: String) {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { searchResults = []; return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        searchResults = allTrips.filter { trip in
            trip.startAddress.lowercased().contains(q) ||
            trip.endAddress.lowercased().contains(q) ||
            trip.memo.lowercased().contains(q) ||
            (trip.purposeDetail?.lowercased().contains(q) ?? false) ||
            formatter.string(from: trip.startTime).contains(q)
        }
    }

    // MARK: - Filters

    func filteredTrips() -> [Trip] {
        var result = allTrips

        if let purpose = selectedPurposeFilter {
            result = result.filter { $0.purpose == purpose }
        }
        if let status = selectedStatusFilter {
            result = result.filter { $0.status == status }
        }
        if let start = filterStartDate {
            result = result.filter { $0.startTime >= start }
        }
        if let end = filterEndDate {
            result = result.filter { $0.startTime <= end }
        }
        return result
    }

    func clearFilters() {
        selectedPurposeFilter = nil
        selectedStatusFilter = nil
        filterStartDate = nil
        filterEndDate = nil
    }

    // MARK: - Summary

    func todaySummary() -> (count: Int, totalKm: Double, businessRatio: Double) {
        let calendar = Calendar.current
        let today = allTrips.filter { calendar.isDateInToday($0.startTime) }
        let totalKm = today.reduce(0) { $0 + $1.distanceKm }
        let businessKm = today.reduce(0) { $0 + $1.businessDistanceKm }
        let ratio = totalKm > 0 ? businessKm / totalKm : 0
        return (today.count, totalKm, ratio)
    }

    func monthlyBusinessRatio(year: Int, month: Int) -> Double {
        let calendar = Calendar.current
        let monthTrips = allTrips.filter {
            let comps = calendar.dateComponents([.year, .month], from: $0.startTime)
            return comps.year == year && comps.month == month
        }
        let totalKm = monthTrips.reduce(0) { $0 + $1.distanceKm }
        let businessKm = monthTrips.reduce(0) { $0 + $1.businessDistanceKm }
        return totalKm > 0 ? businessKm / totalKm : 0
    }

    // MARK: - Export Helper

    var businessTrips: [Trip] {
        allTrips.filter { $0.purpose.isBusiness && $0.status == .classified }
    }

    func totalBusinessKm(for month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        return businessTrips
            .filter {
                let comps = calendar.dateComponents([.year, .month], from: $0.startTime)
                return comps.year == year && comps.month == month
            }
            .reduce(0) { $0 + $1.distanceKm }
    }

    func tripsForExport(year: Int, month: Int, vehicleId: UUID? = nil) -> [Trip] {
        let calendar = Calendar.current
        return allTrips.filter { trip in
            let comps = calendar.dateComponents([.year, .month], from: trip.startTime)
            let matchesDate = comps.year == year && comps.month == month
            let matchesVehicle = vehicleId == nil || trip.vehicleId == vehicleId
            return matchesDate && matchesVehicle && trip.status == .classified
        }
        .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Odometer

    func updateTripOdometer(trip: Trip, before: Double?, after: Double?) {
        trip.odometerBefore = before
        trip.odometerAfter = after
        try? modelContext.save()
    }
}
