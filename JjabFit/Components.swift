// Components.swift — shared UI primitives (dark, premium, blue accent)

import SwiftUI

// ── Primary / variant button ───────────────────────────────────
struct EFButton: View {
    enum Variant { case primary, dark, ghost, danger, outline }
    var title: String
    var systemIcon: String? = nil
    var variant: Variant = .primary
    var full: Bool = false
    var height: CGFloat = 54
    var action: () -> Void

    private var bg: Color {
        switch variant {
        case .primary: return T.accent
        case .dark: return T.surface2
        case .ghost, .outline: return .clear
        case .danger: return T.red.opacity(0.16)
        }
    }
    private var fg: Color {
        switch variant {
        case .primary: return .white
        case .dark, .outline: return T.text
        case .ghost: return T.accent
        case .danger: return T.red
        }
    }

    var body: some View {
        Button(action: { Haptic.tap(); action() }) {
            HStack(spacing: 8) {
                if let systemIcon { Image(systemName: systemIcon).font(.system(size: 18, weight: .bold)) }
                Text(title).font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(fg)
            .frame(maxWidth: full ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, full ? 0 : 20)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: T.rBtn, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: T.rBtn, style: .continuous)
                    .stroke(T.hairline2, lineWidth: variant == .outline ? 1.5 : 0)
            )
        }
        .buttonStyle(PressScale())
    }
}

/// :active { transform: scale(.96) } equivalent
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// ── Body-part chip ─────────────────────────────────────────────
struct PartChip: View {
    let part: String
    var small: Bool = false
    var body: some View {
        let c = PartColor.of(part)
        HStack(spacing: 5) {
            Circle().fill(c).frame(width: 6, height: 6)
            Text(part).font(.system(size: small ? 12 : 13, weight: .semibold))
        }
        .foregroundStyle(c)
        .padding(.horizontal, small ? 8 : 10)
        .padding(.vertical, small ? 2 : 3)
        .background(c.opacity(0.15))
        .clipShape(Capsule())
    }
}

// ── Inline stat (value + unit + label) ─────────────────────────
struct StatView: View {
    var value: String
    var unit: String? = nil
    var label: String
    var color: Color = T.text
    var valueSize: CGFloat = 26
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.system(size: valueSize, weight: .heavy)).foregroundStyle(color).tnum()
                if let unit { Text(unit).font(.system(size: 13, weight: .semibold)).foregroundStyle(T.text3) }
            }
            Text(label).font(.system(size: 12.5, weight: .medium)).foregroundStyle(T.text4)
        }
    }
}

/// Boxed stat card (surface background).
struct WeekStat: View {
    var value: String
    var unit: String? = nil
    var label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 24, weight: .heavy)).foregroundStyle(T.text).tnum()
                if let unit { Text(unit).font(.system(size: 12, weight: .semibold)).foregroundStyle(T.text4) }
            }
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(T.text4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(T.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// ── Large nav header (large title) ─────────────────────────────
struct LargeHeader<Right: View>: View {
    var title: String
    var subtitle: String?
    var accentTitle: Bool
    var right: Right

    init(title: String, subtitle: String? = nil, accentTitle: Bool = false, @ViewBuilder right: () -> Right) {
        self.title = title; self.subtitle = subtitle; self.accentTitle = accentTitle; self.right = right()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Spacer(minLength: 0)
                right
            }
            .frame(minHeight: 30)
            Text(title)
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(accentTitle ? T.accent : T.text)
            if let subtitle {
                Text(subtitle).font(.system(size: 15)).foregroundStyle(T.text3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }
}

extension LargeHeader where Right == EmptyView {
    init(title: String, subtitle: String? = nil, accentTitle: Bool = false) {
        self.init(title: title, subtitle: subtitle, accentTitle: accentTitle) { EmptyView() }
    }
}

/// Compact centered nav bar with optional back + right accessory.
struct NavBar<Right: View>: View {
    var title: String
    var onBack: (() -> Void)?
    var right: Right

    init(title: String, onBack: (() -> Void)? = nil, @ViewBuilder right: () -> Right) {
        self.title = title; self.onBack = onBack; self.right = right()
    }

    var body: some View {
        ZStack {
            Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(T.text)
            HStack {
                if let onBack {
                    Button(action: { Haptic.tap(); onBack() }) {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(T.text).frame(width: 40, height: 40)
                    }
                }
                Spacer()
                right
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }
}

extension NavBar where Right == EmptyView {
    init(title: String, onBack: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack) { EmptyView() }
    }
}

// ── Empty state ────────────────────────────────────────────────
struct EmptyStateView: View {
    var systemIcon: String
    var title: String
    var desc: String? = nil
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(T.surface)
                    .frame(width: 64, height: 64)
                Image(systemName: systemIcon).font(.system(size: 28, weight: .regular)).foregroundStyle(T.text4)
            }
            Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(T.text2)
            if let desc {
                Text(desc).font(.system(size: 14)).foregroundStyle(T.text4)
                    .multilineTextAlignment(.center).frame(maxWidth: 240)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 32)
    }
}

// ── Bottom sheet container (drag handle + surface) ─────────────
struct SheetContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(T.hairline2).frame(width: 38, height: 5).padding(.top, 8).padding(.bottom, 6)
            content
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(T.surface.ignoresSafeArea())
    }
}

extension View {
    /// Fill background with app bg color, ignoring safe area.
    func appBackground() -> some View {
        self.background(T.bg.ignoresSafeArea())
    }
}
