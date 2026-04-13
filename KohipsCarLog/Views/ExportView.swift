import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {

    @ObservedObject var viewModel: TripViewModel
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var exportedFile: ExportedCSV?
    @State private var showingShareSheet = false

    private let years = Array((2024...2030))
    private let months = Array(1...12)

    var body: some View {
        NavigationStack {
            Form {
                Section("기간 선택") {
                    Picker("연도", selection: $selectedYear) {
                        ForEach(years, id: \.self) { Text("\($0)년") }
                    }
                    Picker("월", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { Text("\($0)월") }
                    }
                }

                Section("요약") {
                    let km = viewModel.totalBusinessKm(for: selectedMonth, year: selectedYear)
                    LabeledContent("업무용 주행") {
                        Text(String(format: "%.1f km", km))
                            .fontWeight(.semibold)
                    }
                    LabeledContent("업무용 건수") {
                        Text("\(tripCount) 건")
                    }
                }

                Section {
                    Button {
                        generateCSV()
                    } label: {
                        Label("CSV 내보내기 (국세청 양식)", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(tripCount == 0)
                }
            }
            .navigationTitle("내보내기")
            .sheet(isPresented: $showingShareSheet) {
                if let file = exportedFile {
                    ShareSheet(items: [file.url])
                }
            }
        }
    }

    var tripCount: Int {
        let calendar = Calendar.current
        return viewModel.businessTrips.filter {
            let comps = calendar.dateComponents([.year, .month], from: $0.startTime)
            return comps.year == selectedYear && comps.month == selectedMonth
        }.count
    }

    func generateCSV() {
        let calendar = Calendar.current
        let trips = viewModel.businessTrips.filter {
            let comps = calendar.dateComponents([.year, .month], from: $0.startTime)
            return comps.year == selectedYear && comps.month == selectedMonth
        }

        var csv = "날짜,출발지,도착지,거리(km),목적,메모\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for trip in trips {
            let date = dateFormatter.string(from: trip.startTime)
            let from = trip.startAddress.replacingOccurrences(of: ",", with: " ")
            let to = trip.endAddress.replacingOccurrences(of: ",", with: " ")
            let dist = String(format: "%.2f", trip.distanceKm)
            let purpose = trip.purpose.label
            let memo = trip.memo.replacingOccurrences(of: ",", with: " ")
            csv += "\(date),\(from),\(to),\(dist),\(purpose),\(memo)\n"
        }

        let fileName = "\(selectedYear)\(String(format: "%02d", selectedMonth))_업무주행.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? csv.data(using: .utf8)?.write(to: url)
        exportedFile = ExportedCSV(url: url)
        showingShareSheet = true
    }
}

struct ExportedCSV: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
