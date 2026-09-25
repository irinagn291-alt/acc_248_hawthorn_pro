import SwiftUI

/// One type scale, one spacing unit, and the two radii from the tin contract.
enum StudioMeasure {
    static let fade: Double = 0.18

    static let unit: CGFloat = 8
    static let chip: CGFloat = 4
    static let card: CGFloat = 8
    static let shadowBlur: CGFloat = 8
    static let shadowY: CGFloat = 2

    static let display = Font.custom("Menlo-Bold", size: 34, relativeTo: .largeTitle)
    static let title = Font.custom("Menlo-Bold", size: 28, relativeTo: .title)
    static let headline = Font.custom("Menlo-Bold", size: 22, relativeTo: .headline)
    static let body = Font.custom("Menlo", size: 17, relativeTo: .body)
    static let caption = Font.custom("Menlo", size: 14, relativeTo: .caption)
    static let micro = Font.custom("Menlo", size: 12, relativeTo: .caption2)

    static func count(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// YYYYMMDD day keys stay ungrouped. Counts keep locale grouping.
    static func dayKey(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func shadow<V: View>(_ view: V) -> some View {
        view.shadow(color: DesignTokens.ink.opacity(0.12), radius: shadowBlur, x: 0, y: shadowY)
    }
}
