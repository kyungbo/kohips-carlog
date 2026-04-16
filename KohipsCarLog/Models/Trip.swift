import Foundation
import SwiftData
import CoreLocation

// MARK: - Trip (SwiftData Model)
@Model
final class Trip {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var startAddress: String
    var endAddress: String
    var distanceKm: Double
    var purposeRaw: String      // TripPurpose.rawValue
    var statusRaw: String       // TripStatus.rawValue
    var coordinatesData: Data   // [CLLocationCoordinate2D] encoded
    var memo: String
    var receiptImageData: Data?
    var createdAt: Date

    // NTS (국세청) 필수 필드
    var vehicleId: UUID?
    var purposeDetail: String?       // 운행목적 상세 (예: "거래처 미팅")
    var odometerBefore: Double?      // 주행 전 계기판 (km)
    var odometerAfter: Double?       // 주행 후 계기판 (km)

    init(
        startTime: Date = Date(),
        startAddress: String = "",
        coordinates: [CLLocationCoordinate2D] = []
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = nil
        self.startAddress = startAddress
        self.endAddress = ""
        self.distanceKm = 0
        self.purposeRaw = TripPurpose.unclassified.rawValue
        self.statusRaw = TripStatus.recording.rawValue
        self.coordinatesData = (try? JSONEncoder().encode(
            coordinates.map { CoordCodable(lat: $0.latitude, lng: $0.longitude) }
        )) ?? Data()
        self.memo = ""
        self.receiptImageData = nil
        self.createdAt = Date()
    }

    var purpose: TripPurpose {
        get { TripPurpose(rawValue: purposeRaw) ?? .unclassified }
        set { purposeRaw = newValue.rawValue }
    }

    var status: TripStatus {
        get { TripStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var coordinates: [CLLocationCoordinate2D] {
        guard let decoded = try? JSONDecoder().decode([CoordCodable].self, from: coordinatesData)
        else { return [] }
        return decoded.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
    }

    func updateCoordinates(_ coords: [CLLocationCoordinate2D]) {
        let encoded = coords.map { CoordCodable(lat: $0.latitude, lng: $0.longitude) }
        coordinatesData = (try? JSONEncoder().encode(encoded)) ?? Data()
    }

    // NTS 업무/사적 거리 분배
    var businessDistanceKm: Double {
        purpose.isBusiness ? distanceKm : 0
    }

    var personalDistanceKm: Double {
        purpose.isBusiness ? 0 : distanceKm
    }

    var durationFormatted: String {
        guard let end = endTime else { return "기록 중…" }
        let seconds = max(0, Int(end.timeIntervalSince(startTime)))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? "\(h)시간 \(m)분" : "\(m)분"
    }
}

// MARK: - Supporting Enums
enum TripPurpose: String, CaseIterable {
    case unclassified = "unclassified"
    case businessGeneral = "business_general"   // 일반 업무
    case commute = "commute"                     // 출퇴근
    case personal = "personal"                   // 개인

    var label: String {
        switch self {
        case .unclassified:     return "미분류"
        case .businessGeneral:  return "업무 (일반)"
        case .commute:          return "출퇴근"
        case .personal:         return "개인"
        }
    }

    /// 출퇴근은 세법상 업무용에 포함 (법인세법 시행령 §50의2)
    var isBusiness: Bool {
        self == .businessGeneral || self == .commute
    }
}

enum TripStatus: String {
    case recording = "recording"
    case pending = "pending"       // 종료됨, 분류 대기
    case classified = "classified"
}

// CoordCodable is defined in TripDetector.swift (shared)
