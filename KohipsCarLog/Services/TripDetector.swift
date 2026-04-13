import Foundation
import CoreMotion
import CoreLocation
import SwiftData
import BackgroundTasks

/// 핵심 주행 감지 서비스 — 모션 + GPS + 가속도계로 차량 이동을 자동 감지
@MainActor
final class TripDetector: NSObject, ObservableObject {

    static let shared = TripDetector()

    // ── State ──────────────────────────────────────────────────
    @Published var isRecording = false
    @Published var currentTrip: Trip?
    @Published var sensorStatus = SensorStatus()

    struct SensorStatus {
        var isMotionActivityAvailable = false
        var isAccelerometerAvailable = false
        var locationAuthStatus: CLAuthorizationStatus = .notDetermined
        var isMotionPermissionDenied = false

        var hasAnySensor: Bool {
            isMotionActivityAvailable || isAccelerometerAvailable
        }
        var isLocationAuthorized: Bool {
            locationAuthStatus == .authorizedAlways || locationAuthStatus == .authorizedWhenInUse
        }
    }

    // ── Private ────────────────────────────────────────────────
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private var collectedCoords: [CLLocationCoordinate2D] = []
    private var totalDistance: Double = 0
    private var lastLocation: CLLocation?
    private var automotiveStartTime: Date?
    private let automotiveThreshold: TimeInterval = 60
    private var isManualTrip = false
    private var pendingStartGeocode = false

    // Vehicle motion cue detection via accelerometer + GPS speed
    private var recentSpeeds: [Double] = []
    private var speedDetectionStart: Date?
    private let drivingSpeedThreshold: Double = 8.0   // m/s (~29 km/h)
    private let drivingSpeedDuration: TimeInterval = 30 // 30초 이상 고속 유지 → 주행
    private var stationaryStart: Date?
    private let stationaryDuration: TimeInterval = 120  // 2분 이상 정지 → 주행 종료
    private var isSpeedBasedMonitoring = false

    // SwiftData context (lazy — set after app init)
    var modelContext: ModelContext?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.activityType = .automotiveNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        checkSensorAvailability()
    }

    // MARK: - Sensor Availability

    func checkSensorAvailability() {
        sensorStatus.isMotionActivityAvailable = CMMotionActivityManager.isActivityAvailable()
        sensorStatus.isAccelerometerAvailable = motionManager.isAccelerometerAvailable
        sensorStatus.locationAuthStatus = locationManager.authorizationStatus
    }

    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Public API

    func startMonitoring() {
        checkSensorAvailability()

        // 위치 권한 요청
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }

        // Strategy 1: CMMotionActivityManager (best when available)
        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let self, let activity else { return }
                Task { @MainActor in
                    self.handleActivityUpdate(activity)
                }
            }
        }

        // Strategy 2: GPS speed-based detection (fallback or supplementary)
        startSpeedBasedMonitoring()
    }

    func stopMonitoring() {
        activityManager.stopActivityUpdates()
        stopSpeedBasedMonitoring()
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    // Background refresh handler
    func handleBackgroundRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        scheduleNextBackgroundRefresh()
        task.setTaskCompleted(success: true)
    }

    // MARK: - Manual trip controls

    func startTripManually(startAddress: String = "") {
        guard !isRecording else { return }
        isManualTrip = true
        beginTrip(at: Date(), address: startAddress)
    }

    func endTripManually() {
        guard isRecording, let trip = currentTrip else { return }
        finalizeTrip(trip)
    }

    // MARK: - Speed-based Vehicle Motion Detection

    private func startSpeedBasedMonitoring() {
        guard !isSpeedBasedMonitoring else { return }
        isSpeedBasedMonitoring = true
        // Use significant location changes for battery efficiency when not recording
        locationManager.startMonitoringSignificantLocationChanges()
    }

    private func stopSpeedBasedMonitoring() {
        isSpeedBasedMonitoring = false
        recentSpeeds.removeAll()
        speedDetectionStart = nil
        stationaryStart = nil
    }

    private func handleSpeedUpdate(_ speed: Double) {
        // 수동 주행 중에는 속도 기반 감지 무시
        if isManualTrip { return }

        if speed >= drivingSpeedThreshold {
            // 고속 이동 중
            stationaryStart = nil
            if speedDetectionStart == nil {
                speedDetectionStart = Date()
            }

            let elapsed = Date().timeIntervalSince(speedDetectionStart ?? Date())
            if elapsed >= drivingSpeedDuration && !isRecording {
                // 일정 시간 이상 주행 속도 유지 → 주행 시작
                beginTrip(at: speedDetectionStart ?? Date())
            }
        } else if speed < 2.0 {
            // 거의 정지 상태
            speedDetectionStart = nil
            if isRecording && !isManualTrip {
                if stationaryStart == nil {
                    stationaryStart = Date()
                }
                let stoppedFor = Date().timeIntervalSince(stationaryStart ?? Date())
                if stoppedFor >= stationaryDuration {
                    // 2분 이상 정지 → 주행 종료
                    if let trip = currentTrip {
                        finalizeTrip(trip)
                    }
                    stationaryStart = nil
                }
            }
        } else {
            // 중간 속도 — 타이머 리셋하지 않음
            stationaryStart = nil
        }
    }

    // MARK: - CMMotionActivity Handling

    private func handleActivityUpdate(_ activity: CMMotionActivity) {
        if isManualTrip { return }

        if activity.automotive && activity.confidence != .low {
            if automotiveStartTime == nil {
                automotiveStartTime = activity.startDate
            }
            let elapsed = Date().timeIntervalSince(automotiveStartTime ?? Date())
            if elapsed >= automotiveThreshold && !isRecording {
                beginTrip(at: automotiveStartTime ?? Date())
            }
        } else if activity.stationary || activity.walking {
            automotiveStartTime = nil
            if isRecording && !isManualTrip, let trip = currentTrip {
                finalizeTrip(trip)
            }
        }
    }

    // MARK: - Trip Lifecycle

    private func beginTrip(at time: Date, address: String = "") {
        guard !isRecording else { return }

        isRecording = true
        collectedCoords = []
        totalDistance = 0
        lastLocation = nil
        pendingStartGeocode = true

        let trip = Trip(startTime: time, startAddress: address)
        modelContext?.insert(trip)
        currentTrip = trip

        // 정밀 GPS 업데이트 시작
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()

        // 현재 위치가 이미 있으면 바로 역지오코딩
        if let currentLoc = locationManager.location,
           currentLoc.timestamp.timeIntervalSinceNow > -10 {
            pendingStartGeocode = false
            reverseGeocode(for: currentLoc) { [weak self] addr in
                self?.currentTrip?.startAddress = addr
                try? self?.modelContext?.save()
            }
        }
        // 없으면 didUpdateLocations에서 첫 위치 수신 시 처리
    }

    private func finalizeTrip(_ trip: Trip) {
        let wasManual = isManualTrip

        isRecording = false
        isManualTrip = false
        pendingStartGeocode = false

        trip.endTime = Date()
        trip.distanceKm = totalDistance / 1000
        trip.status = .pending

        // 좌표 데이터 저장
        let coords = collectedCoords.map { CoordCodable(lat: $0.latitude, lng: $0.longitude) }
        trip.coordinatesData = (try? JSONEncoder().encode(coords)) ?? Data()

        // 자동 감지 시 최소 거리 체크
        if !wasManual && trip.distanceKm < 0.5 {
            currentTrip = nil
            collectedCoords = []
            modelContext?.delete(trip)
            try? modelContext?.save()
            resumeSignificantLocationMonitoring()
            return
        }

        let tripRef = trip
        let lastLoc = lastLocation

        currentTrip = nil
        collectedCoords = []
        totalDistance = 0

        try? modelContext?.save()

        // 알림 발송
        NotificationManager.shared.sendTripEndedNotification(
            tripId: tripRef.id,
            startAddress: tripRef.startAddress,
            endAddress: tripRef.endAddress,
            distanceKm: tripRef.distanceKm
        )
        NotificationManager.shared.scheduleUnclassifiedReminder(
            tripId: tripRef.id,
            startAddress: tripRef.startAddress,
            endAddress: tripRef.endAddress
        )

        // 도착지 역지오코딩
        reverseGeocode(for: lastLoc) { [weak self] addr in
            Task { @MainActor in
                tripRef.endAddress = addr
                try? self?.modelContext?.save()

                // 알림 주소 업데이트
                NotificationManager.shared.sendTripEndedNotification(
                    tripId: tripRef.id,
                    startAddress: tripRef.startAddress,
                    endAddress: addr,
                    distanceKm: tripRef.distanceKm
                )
            }
        }

        resumeSignificantLocationMonitoring()
    }

    private func resumeSignificantLocationMonitoring() {
        locationManager.stopUpdatingLocation()
        if isSpeedBasedMonitoring {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    // MARK: - Geocoding

    private func reverseGeocode(for location: CLLocation?, completion: @escaping (String) -> Void) {
        guard let loc = location else { completion("위치 확인 중…"); return }
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
            guard let p = placemarks?.first else {
                completion("주소 불명")
                return
            }
            // 한국 주소 형식: 시/도 → 시/군/구 → 동/읍/면 → 도로명
            let components = [
                p.locality ?? p.administrativeArea,  // 서울특별시 / 성남시
                p.subLocality,                        // 역삼동 / 분당구
                p.thoroughfare                        // 테헤란로
            ].compactMap { $0 }

            let addr = components.joined(separator: " ")
            completion(addr.isEmpty ? "주소 불명" : addr)
        }
    }

    // MARK: - Background Scheduling

    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.kohipstech.carlog.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}

// MARK: - Codable helper for coordinates (internal access for Trip model)
struct CoordCodable: Codable {
    let lat: Double
    let lng: Double
}

// MARK: - CLLocationManagerDelegate
extension TripDetector: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }

        Task { @MainActor in
            // 속도 기반 주행 감지 (speed < 0 means invalid)
            let speed = max(location.speed, 0)
            self.handleSpeedUpdate(speed)

            guard self.isRecording else { return }

            // 첫 위치 수신 시 출발지 역지오코딩 (beginTrip에서 위치 없었던 경우)
            if self.pendingStartGeocode {
                self.pendingStartGeocode = false
                self.reverseGeocode(for: location) { [weak self] addr in
                    Task { @MainActor in
                        if let trip = self?.currentTrip, trip.startAddress.isEmpty {
                            trip.startAddress = addr
                            try? self?.modelContext?.save()
                        }
                    }
                }
            }

            // 거리 누적
            if let last = self.lastLocation {
                let dist = location.distance(from: last)
                // 비정상적으로 큰 점프 필터 (GPS 튐 방지)
                if dist < 1000 {
                    self.totalDistance += dist
                }
            }
            self.lastLocation = location
            self.collectedCoords.append(location.coordinate)

            // 현재 trip 거리 실시간 업데이트
            self.currentTrip?.distanceKm = self.totalDistance / 1000
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 위치 업데이트 실패 시 무시 (일시적 GPS 손실)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.sensorStatus.locationAuthStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedAlways:
                break
            case .authorizedWhenInUse:
                manager.requestAlwaysAuthorization()
            case .denied, .restricted:
                break
            default:
                break
            }
        }
    }
}
