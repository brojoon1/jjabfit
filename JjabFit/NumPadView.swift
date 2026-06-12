// NumPadView.swift — numeric keypad sheet for weight (kg) / reps

import SwiftUI

struct NumPadView: View {
    enum Field { case kg, reps }
    let field: Field
    let initial: Double
    var onChange: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var str: String

    private var isKg: Bool { field == .kg }

    init(field: Field, initial: Double, onChange: @escaping (Double) -> Void) {
        self.field = field
        self.initial = initial
        self.onChange = onChange
        let v = field == .kg ? fmtKg(initial) : String(Int(initial))
        _str = State(initialValue: v)
    }

    private var keypad: [String] {
        ["1","2","3","4","5","6","7","8","9", isKg ? "." : "", "0", "del"]
    }

    var body: some View {
        SheetContainer {
            VStack(spacing: 0) {
                HStack {
                    Text(isKg ? "무게 (kg)" : "횟수 (회)").font(.system(size: 15, weight: .semibold)).foregroundStyle(T.text3)
                    Spacer()
                    Button("완료") { dismiss() }.font(.system(size: 16, weight: .bold)).foregroundStyle(T.accent)
                }
                .padding(.top, 4).padding(.bottom, 14)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(str).font(.system(size: 44, weight: .heavy)).foregroundStyle(T.text).tnum()
                    Text(isKg ? "kg" : "회").font(.system(size: 20)).foregroundStyle(T.text4)
                }
                .padding(.bottom, 12)

                HStack(spacing: 8) {
                    ForEach(isKg ? [-5.0, -2.5, 2.5, 5.0] : [-1.0, 1.0, 5.0], id: \.self) { d in
                        Button { quick(d) } label: {
                            Text(d > 0 ? "+\(fmtKg(d))" : "\(fmtKg(d))")
                                .font(.system(size: 15, weight: .bold)).foregroundStyle(T.text2)
                                .frame(maxWidth: .infinity).frame(height: 38)
                                .background(T.surface2).clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 12)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(Array(keypad.enumerated()), id: \.offset) { _, k in
                        if k.isEmpty {
                            Color.clear.frame(height: 56)
                        } else {
                            Button { press(k) } label: {
                                Group {
                                    if k == "del" { Image(systemName: "delete.left").font(.system(size: 22)) }
                                    else { Text(k).font(.system(size: 24, weight: .semibold)) }
                                }
                                .foregroundStyle(T.text).frame(maxWidth: .infinity).frame(height: 56)
                                .background(k == "del" ? Color.clear : T.surface2)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.bottom, 28)
        }
    }

    private func commit(_ v: String) {
        str = v
        onChange(Double(v) ?? 0)
    }
    private func press(_ k: String) {
        Haptic.tap()
        if k == "del" { commit(str.count <= 1 ? "0" : String(str.dropLast())); return }
        if k == "." { if !isKg || str.contains(".") { return }; commit(str + "."); return }
        var next = (str == "0" && k != ".") ? k : str + k
        if next.replacingOccurrences(of: ".", with: "").count > 5 { return }
        if !isKg, let n = Int(next) { next = String(n) }   // strip leading zero for reps
        commit(next)
    }
    private func quick(_ d: Double) {
        let v = max(0, (Double(str) ?? 0) + d)
        commit(isKg ? fmtKg(v) : String(Int(v.rounded())))
    }
}
