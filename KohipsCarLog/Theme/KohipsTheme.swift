import SwiftUI
import UIKit

// MARK: - Color System (Light / Dark Adaptive)

enum KohipsTheme {
    // Core
    static let primary = Color(hex: "1DB954")
    static let primaryDark = Color(hex: "18993F")
    static let accent = Color(hex: "FF6B35")
    static let destructive = Color(hex: "FF453A")

    // Adaptive Background
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "121212") : UIColor(hex: "F2F2F7")
    })
    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "1E1E1E") : .white
    })
    static let surfaceElevated = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "2A2A2A") : UIColor(hex: "F0F0F5")
    })
    static let surfaceLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "3A3A3A") : UIColor(hex: "E5E5EA")
    })

    // Adaptive Text
    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(hex: "1C1C1E")
    })
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "A0A0A0") : UIColor(hex: "6B6B6B")
    })
    static let textTertiary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "6B6B6B") : UIColor(hex: "A0A0A0")
    })

    // Adaptive Semantic
    static let separator = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let cardShadow = Color.black.opacity(0.08)

    // Purpose (accent colors — same in both modes)
    static let business = Color(hex: "1DB954")
    static let commute = Color(hex: "5B86E5")
    static let personal = Color(hex: "8E8E93")
    static let unclassified = Color(hex: "FF6B35")
}

// MARK: - UIColor Hex Init

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}

// MARK: - Typography

extension Font {
    static let kohipsLargeTitle = Font.system(size: 26, weight: .bold, design: .rounded)
    static let kohipsTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    static let kohipsHeadline = Font.system(size: 16, weight: .semibold)
    static let kohipsBody = Font.system(size: 15, weight: .regular)
    static let kohipsCallout = Font.system(size: 14, weight: .medium)
    static let kohipsCaption = Font.system(size: 13, weight: .regular)
    static let kohipsSmall = Font.system(size: 11, weight: .medium)

    // Icon fonts (standardized sizes for SF Symbols)
    static let kohipsIconSmall = Font.system(size: 14, weight: .medium)
    static let kohipsIcon = Font.system(size: 16, weight: .medium)
    static let kohipsIconLarge = Font.system(size: 20, weight: .regular)
    static let kohipsIconXL = Font.system(size: 28, weight: .regular)
    static let kohipsIconHero = Font.system(size: 40, weight: .regular)
}

// MARK: - Spacing Constants

enum KohipsSpacing {
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 12
    static let contentHorizontal: CGFloat = 20
    static let componentInner: CGFloat = 14
    static let chipVertical: CGFloat = 8
    static let chipHorizontal: CGFloat = 14
    static let badgeVertical: CGFloat = 5
    static let badgeHorizontal: CGFloat = 10
}

// MARK: - Card Style

struct KohipsCardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(KohipsTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func kohipsCard(padding: CGFloat = 16) -> some View {
        modifier(KohipsCardStyle(padding: padding))
    }
}

// MARK: - Haptic Manager

enum HapticManager {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Purpose Color Helper

func purposeColor(_ purpose: TripPurpose) -> Color {
    switch purpose {
    case .businessGeneral: return KohipsTheme.business
    case .commute: return KohipsTheme.commute
    case .personal: return KohipsTheme.personal
    case .unclassified: return KohipsTheme.unclassified
    }
}
