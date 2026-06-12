// Theme.swift — design tokens (dark / premium / blue accent)
// Mirrors the design-reference token set (README "Design Tokens").

import SwiftUI

extension Color {
    init(hex: String, opacity: Double = 1) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v & 0xFF0000) >> 16) / 255
        let g = Double((v & 0x00FF00) >> 8) / 255
        let b = Double(v & 0x0000FF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// Central palette + spacing/radius tokens.
enum T {
    // Surfaces
    static let bg        = Color(hex: "0B0B0E")
    static let surface   = Color(hex: "16161A")
    static let surface2  = Color(hex: "232329")
    static let surface3  = Color(hex: "2E2E36")

    // Text
    static let text  = Color(hex: "F4F4F6")
    static let text2 = Color(hex: "F4F4F6", opacity: 0.82)
    static let text3 = Color(hex: "F4F4F6", opacity: 0.60)
    static let text4 = Color(hex: "F4F4F6", opacity: 0.42)
    static let text5 = Color(hex: "F4F4F6", opacity: 0.28)

    // Lines
    static let hairline  = Color.white.opacity(0.07)
    static let hairline2 = Color.white.opacity(0.17)

    // Accent / semantic
    static let accent = Color(hex: "4F86F7")
    static let red    = Color(hex: "FF6B6B")

    // Radii
    static let rCell: CGFloat = 11
    static let rBtn: CGFloat = 16
    static let rCard: CGFloat = 20
    static let rSheet: CGFloat = 26
}

/// Body-part accent colors (sRGB approximations of the design's oklch values).
enum PartColor {
    static let map: [String: Color] = [
        "가슴":  Color(hex: "DE6F62"),
        "등":    Color(hex: "5F93DB"),
        "어깨":  Color(hex: "D6A64C"),
        "하체":  Color(hex: "3DB389"),
        "팔":    Color(hex: "BE7AD6"),
        "복근":  Color(hex: "46AEC0"),
        "엉덩이": Color(hex: "DB6FA1"),
    ]
    static func of(_ part: String) -> Color { map[part] ?? T.accent }
}

extension View {
    /// tabular figures for numeric readouts
    func tnum() -> some View { self.monospacedDigit() }
}
