// RestTimerView.swift — rest countdown with beeps at 3·2·1 only
//
// Beep rule (per spec): a beep at remaining 3s, 2s, and 1s — 3 beeps total.
// (The design reference also beeped at 10s; that was intentionally removed.)

import SwiftUI

struct RestTimerView: View {
    let total: Int
    var onClose: () -> Void

    @State private var endDate: Date
    @State private var remaining: Double
    @State private var initialTotal: Double
    @State private var beeped: Set<Int> = []
    @State private var finished = false

    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(total: Int, onClose: @escaping () -> Void) {
        self.total = total
        self.onClose = onClose
        _endDate = State(initialValue: Date().addingTimeInterval(Double(total)))
        _remaining = State(initialValue: Double(total))
        _initialTotal = State(initialValue: Double(total))
    }

    private var shown: Int { max(0, Int(ceil(remaining - 0.0001))) }
    private var progress: Double { initialTotal > 0 ? max(0, min(1, remaining / initialTotal)) : 0 }

    var body: some View {
        SheetContainer {
            VStack(spacing: 0) {
                HStack {
                    Text("휴식").font(.system(size: 15, weight: .bold)).foregroundStyle(T.text3)
                    Spacer()
                    Button("건너뛰기") { onClose() }.font(.system(size: 16, weight: .bold)).foregroundStyle(T.accent)
                }
                .padding(.top, 2).padding(.bottom, 6)

                ZStack {
                    Circle().stroke(T.surface2, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(T.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(shown <= 3 ? nil : .linear(duration: 0.2), value: progress)
                    VStack(spacing: 8) {
                        Text(fmtClock(shown))
                            .font(.system(size: 56, weight: .heavy))
                            .foregroundStyle(shown <= 3 ? T.accent : T.text).tnum()
                        Text("다음 세트까지").font(.system(size: 13)).foregroundStyle(T.text4)
                    }
                }
                .frame(width: 220, height: 220)
                .padding(.top, 6).padding(.bottom, 4)

                HStack(spacing: 10) {
                    adjustButton("−15초", -15)
                    adjustButton("+15초", 15)
                }
                .padding(.top, 14)
            }
            .padding(.bottom, 30)
        }
        .onReceive(tick) { _ in update() }
    }

    private func adjustButton(_ title: String, _ delta: Int) -> some View {
        Button { adjust(delta) } label: {
            Text(title).font(.system(size: 16, weight: .bold)).foregroundStyle(T.text)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(T.surface2).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func update() {
        let remMs = endDate.timeIntervalSinceNow
        remaining = max(0, remMs)
        let whole = Int(ceil(remaining - 0.0001))
        // beep at 3, 2, 1 only — each fires once
        if (whole == 3 || whole == 2 || whole == 1) && !beeped.contains(whole) {
            beeped.insert(whole)
            Beeper.shared.beep(frequency: 880, duration: 0.13)
            Haptic.tap()
        }
        if remMs <= 0 && !finished {
            finished = true
            Haptic.success()
            onClose()
        }
    }

    private func adjust(_ delta: Int) {
        Haptic.tap()
        let newEnd = max(Date().addingTimeInterval(1), endDate.addingTimeInterval(Double(delta)))
        let newRemWhole = Int(ceil(newEnd.timeIntervalSinceNow))
        // allow beeps to re-fire if the timer was extended past them
        beeped = beeped.filter { $0 < newRemWhole }
        initialTotal = max(initialTotal, Double(newRemWhole))
        endDate = newEnd
    }
}

// ── Rest duration picker ───────────────────────────────────────
struct RestPickerView: View {
    let value: Int
    var onPick: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let opts = [30, 45, 60, 75, 90, 120, 150, 180]

    var body: some View {
        SheetContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("휴식 시간").font(.system(size: 16, weight: .bold)).foregroundStyle(T.text)
                    Spacer()
                    Button("완료") { dismiss() }.font(.system(size: 16, weight: .bold)).foregroundStyle(T.accent)
                }
                .padding(.top, 2).padding(.bottom, 14)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(opts, id: \.self) { o in
                        let on = o == value
                        Button { Haptic.tap(); onPick(o) } label: {
                            VStack(spacing: 1) {
                                Text("\(o)").font(.system(size: 19, weight: .heavy)).tnum()
                                Text("초").font(.system(size: 11)).opacity(0.7)
                            }
                            .foregroundStyle(on ? .white : T.text)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(on ? T.accent : T.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("세트를 완료하면 자동으로 휴식 타이머가 시작돼요. 남은 3·2·1초에 알림음이 울립니다.")
                    .font(.system(size: 12.5)).foregroundStyle(T.text4).lineSpacing(3)
                    .padding(.top, 14).padding(.horizontal, 4)
            }
            .padding(.bottom, 28)
        }
    }
}
