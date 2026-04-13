import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MainViewWithContext(modelContext: modelContext)
    }
}

struct MainViewWithContext: View {
    @StateObject private var viewModel: TripViewModel
    @State private var selectedTab = 0
    @State private var showSearch = false
    @AppStorage("appColorScheme") private var appColorScheme: String = "dark"

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TripViewModel(modelContext: modelContext))
    }

    private var resolvedColorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(viewModel: viewModel, showSearch: $showSearch)
                    .tabItem {
                        Label("홈", systemImage: "house.fill")
                    }
                    .tag(0)

                TripHistoryView(viewModel: viewModel)
                    .tabItem {
                        Label("운행이력", systemImage: "clock.arrow.circlepath")
                    }
                    .badge(viewModel.pendingTrips.count)
                    .tag(1)

                MyPageView(viewModel: viewModel)
                    .tabItem {
                        Label("마이페이지", systemImage: "person.crop.circle")
                    }
                    .tag(2)
            }
            .tint(KohipsTheme.primary)

            // Global Search Overlay
            if showSearch {
                SearchOverlay(viewModel: viewModel, isPresented: $showSearch)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .preferredColorScheme(resolvedColorScheme)
        .animation(.spring(duration: 0.3), value: showSearch)
        .task {
            viewModel.fetchTrips()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHistoryTab)) { _ in
            selectedTab = 1
        }
    }
}
