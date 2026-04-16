import Foundation
import UIKit

/// 국세청 별지 제84호의2 (업무용승용차 운행기록부) 내보내기 서비스
enum NTSExportService {

    // MARK: - CSV (10-Column NTS Format)

    static func generateCSV(
        trips: [Trip],
        vehicle: Vehicle?,
        year: Int,
        month: Int
    ) -> String {
        var csv = "운행일자,운행목적,출발지,도착지,주행전계기판(km),주행후계기판(km),주행거리(km),업무용거리(km),사적거리(km),비고\n"

        if let v = vehicle {
            csv += "# 차량번호: \(v.licensePlate), 차종: \(v.model)\n"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var totalDistance = 0.0
        var totalBusiness = 0.0
        var totalPersonal = 0.0

        for trip in trips {
            let date = formatter.string(from: trip.startTime)
            let purpose = csvField(trip.purposeDetail ?? trip.purpose.label)
            let start = csvField(trip.startAddress)
            let end = csvField(trip.endAddress)
            let odoBefore = trip.odometerBefore.map { String(format: "%.1f", $0) } ?? ""
            let odoAfter = trip.odometerAfter.map { String(format: "%.1f", $0) } ?? ""
            let distance = String(format: "%.1f", trip.distanceKm)
            let bizKm = String(format: "%.1f", trip.businessDistanceKm)
            let perKm = String(format: "%.1f", trip.personalDistanceKm)
            let memo = csvField(trip.memo)

            csv += "\(date),\(purpose),\(start),\(end),\(odoBefore),\(odoAfter),\(distance),\(bizKm),\(perKm),\(memo)\n"

            totalDistance += trip.distanceKm
            totalBusiness += trip.businessDistanceKm
            totalPersonal += trip.personalDistanceKm
        }

        // Summary row
        let ratio = totalDistance > 0 ? (totalBusiness / totalDistance * 100) : 0
        csv += "합계,,,,,,\(String(format: "%.1f", totalDistance)),\(String(format: "%.1f", totalBusiness)),\(String(format: "%.1f", totalPersonal)),업무사용비율: \(String(format: "%.1f", ratio))%\n"

        return csv
    }

    /// RFC 4180: 쉼표·줄바꿈·큰따옴표가 포함된 필드는 큰따옴표로 감싸고, 내부 " → ""
    private static func csvField(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return text
    }

    // MARK: - PDF (별지 제84호의2)

    static func generatePDF(
        trips: [Trip],
        vehicle: Vehicle?,
        year: Int,
        month: Int
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 841.89, height: 595.28) // A4 landscape
        let margin: CGFloat = 40
        let contentWidth = pageRect.width - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            let headerHeight: CGFloat = 80
            let rowHeight: CGFloat = 22
            let tableHeaderHeight: CGFloat = 28
            let maxRowsPerPage = Int((pageRect.height - margin * 2 - headerHeight - tableHeaderHeight - 40) / rowHeight)

            let columnWidths: [CGFloat] = [
                contentWidth * 0.09,  // 운행일자
                contentWidth * 0.14,  // 운행목적
                contentWidth * 0.13,  // 출발지
                contentWidth * 0.13,  // 도착지
                contentWidth * 0.08,  // 주행전
                contentWidth * 0.08,  // 주행후
                contentWidth * 0.08,  // 주행거리
                contentWidth * 0.09,  // 업무용
                contentWidth * 0.09,  // 사적
                contentWidth * 0.09,  // 비고
            ]

            let headers = ["운행일자", "운행목적", "출발지", "도착지", "주행전\n계기판(km)", "주행후\n계기판(km)", "주행거리\n(km)", "업무용\n거리(km)", "사적\n거리(km)", "비고"]

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            var pageIndex = 0
            var tripIndex = 0

            while tripIndex < trips.count || pageIndex == 0 {
                context.beginPage()

                var y = margin

                // Title
                let titleFont = UIFont.boldSystemFont(ofSize: 14)
                let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont]
                let title = "업무용승용차 운행기록부 [별지 제84호의2]"
                (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttr)
                y += 24

                // Period & Vehicle info
                let infoFont = UIFont.systemFont(ofSize: 10)
                let infoAttr: [NSAttributedString.Key: Any] = [.font: infoFont]
                let periodInfo = "기간: \(year)년 \(month)월"
                (periodInfo as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttr)

                if let v = vehicle {
                    let vehicleInfo = "차량번호: \(v.licensePlate)  차종: \(v.model)"
                    (vehicleInfo as NSString).draw(at: CGPoint(x: margin + 200, y: y), withAttributes: infoAttr)
                }
                y += 20
                y += 16 // spacing before table

                // Table Header
                drawTableRow(
                    context: context.cgContext,
                    x: margin, y: y,
                    widths: columnWidths,
                    height: tableHeaderHeight,
                    texts: headers,
                    font: UIFont.boldSystemFont(ofSize: 8),
                    bgColor: UIColor.systemGray5
                )
                y += tableHeaderHeight

                // Table Rows
                var rowsOnPage = 0
                while tripIndex < trips.count && rowsOnPage < maxRowsPerPage {
                    let trip = trips[tripIndex]
                    let row = [
                        formatter.string(from: trip.startTime),
                        trip.purposeDetail ?? trip.purpose.label,
                        trip.startAddress,
                        trip.endAddress,
                        trip.odometerBefore.map { String(format: "%.0f", $0) } ?? "-",
                        trip.odometerAfter.map { String(format: "%.0f", $0) } ?? "-",
                        String(format: "%.1f", trip.distanceKm),
                        String(format: "%.1f", trip.businessDistanceKm),
                        String(format: "%.1f", trip.personalDistanceKm),
                        trip.memo
                    ]

                    let bgColor = rowsOnPage % 2 == 0 ? UIColor.white : UIColor(white: 0.97, alpha: 1)
                    drawTableRow(
                        context: context.cgContext,
                        x: margin, y: y,
                        widths: columnWidths,
                        height: rowHeight,
                        texts: row,
                        font: UIFont.systemFont(ofSize: 8),
                        bgColor: bgColor
                    )
                    y += rowHeight
                    tripIndex += 1
                    rowsOnPage += 1
                }

                // Summary row on last page
                if tripIndex >= trips.count {
                    let totalDist = trips.reduce(0) { $0 + $1.distanceKm }
                    let totalBiz = trips.reduce(0) { $0 + $1.businessDistanceKm }
                    let totalPer = trips.reduce(0) { $0 + $1.personalDistanceKm }
                    let ratio = totalDist > 0 ? totalBiz / totalDist * 100 : 0

                    let summaryRow = [
                        "합계", "", "", "", "", "",
                        String(format: "%.1f", totalDist),
                        String(format: "%.1f", totalBiz),
                        String(format: "%.1f", totalPer),
                        String(format: "업무비율: %.0f%%", ratio)
                    ]

                    drawTableRow(
                        context: context.cgContext,
                        x: margin, y: y,
                        widths: columnWidths,
                        height: rowHeight + 4,
                        texts: summaryRow,
                        font: UIFont.boldSystemFont(ofSize: 8),
                        bgColor: UIColor.systemGray5
                    )
                    y += rowHeight + 4

                    // Footer
                    y += 16
                    let footerAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray]
                    let footer = "※ 본 운행기록부는 법인세법 시행규칙 별지 제84호의2 서식에 준하여 작성되었습니다. | 코힙스 차계부 v2.0"
                    (footer as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttr)
                }

                pageIndex += 1
            }
        }
    }

    // MARK: - Drawing Helper

    private static func drawTableRow(
        context: CGContext,
        x: CGFloat, y: CGFloat,
        widths: [CGFloat],
        height: CGFloat,
        texts: [String],
        font: UIFont,
        bgColor: UIColor
    ) {
        var currentX = x

        for (i, width) in widths.enumerated() {
            let cellRect = CGRect(x: currentX, y: y, width: width, height: height)

            // Background
            context.setFillColor(bgColor.cgColor)
            context.fill(cellRect)

            // Border
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.stroke(cellRect)

            // Text
            let text = i < texts.count ? texts[i] : ""
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            let attr: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black
            ]
            let textRect = cellRect.insetBy(dx: 2, dy: 2)
            (text as NSString).draw(in: textRect, withAttributes: attr)

            currentX += width
        }
    }
}
