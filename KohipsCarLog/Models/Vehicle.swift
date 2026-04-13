import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID
    var licensePlate: String    // 예: "12가 3456"
    var model: String           // 예: "현대 아반떼"
    var year: Int
    var currentOdometer: Double // 현재 누적 km
    var createdAt: Date

    init(
        licensePlate: String,
        model: String,
        year: Int,
        currentOdometer: Double = 0
    ) {
        self.id = UUID()
        self.licensePlate = licensePlate
        self.model = model
        self.year = year
        self.currentOdometer = currentOdometer
        self.createdAt = Date()
    }
}
