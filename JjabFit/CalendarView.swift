// CalendarView.swift — monthly calendar marking completed days

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var model: AppModel
    @State private var cursor: Date = {
        var c = Calendar(identifier: .gregorian)
        let comps = c.dateComponents([.year, .month], from: Date())
        return c.date(from: comps) ?? Date()
    }()

    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.firstWeekday = 1; return c }

    private var byDate: [String: WorkoutRecord] {
        Dictionary(model.history.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        let comps = cal.dateComponents([.year, .month], from: cursor)
        let year = comps.year!, month = comps.month!
        let first = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let startPad = cal.component(.weekday, from: first) - 1
        let daysIn = cal.range(of: .day, in: .month, for: first)!.count
        let cells: [Int?] = Array(repeating: nil, count: startPad) + (1...daysIn).map { $0 }
        let monthRecords = byDate.values.filter {
            let d = DateKey.date($0.date)
            let c = cal.dateComponents([.year, .month], from: d)
            return c.year == year && c.month == month
        }

        return ScrollView {
            LargeHeader(title: "캘린더")
            VStack(spacing: 0) {
                // month nav
                HStack {
                    navButton("chevron.left") { cursor = cal.date(byAdding: .month, value: -1, to: cursor)! }
                    Spacer()
                    Text("\(String(year))년 \(month)월").font(.system(size: 19, weight: .heavy)).foregroundStyle(T.text)
                    Spacer()
                    navButton("chevron.right") { cursor = cal.date(byAdding: .month, value: 1, to: cursor)! }
                }
                .padding(.horizontal, 4).padding(.bottom, 14)

                // weekday header
                HStack(spacing: 0) {
                    ForEach(Array(DateKey.weekdays.enumerated()), id: \.offset) { i, w in
                        Text(w).font(.system(size: 12, weight: .bold))
                            .foregroundStyle(i == 0 ? T.red : i == 6 ? T.accent : T.text5)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 6)

                // grid
                let gcols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
                LazyVGrid(columns: gcols, spacing: 2) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, d in
                        if let d {
                            dayCell(year: year, month: month, day: d)
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
                .padding(.bottom, 24)

                HStack(spacing: 10) {
                    WeekStat(value: "\(monthRecords.count)", label: "운동한 날")
                    WeekStat(value: "\(monthRecords.reduce(0) { $0 + recordSetCount($1.exercises) })", label: "총 세트")
                    WeekStat(value: fmtVolume(monthRecords.reduce(0) { $0 + recordVolume($1.exercises) }), unit: "kg", label: "총 볼륨")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func navButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptic.tap(); action() }) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(T.text2)
                .frame(width: 40, height: 40).background(T.surface).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func dayCell(year: Int, month: Int, day: Int) -> some View {
        let key = DateKey.ymd(cal.date(from: DateComponents(year: year, month: month, day: day))!)
        let rec = byDate[key]
        let isToday = key == DateKey.today()
        let parts = rec != nil ? uniqueParts(rec!.exercises) : []
        return Button {
            if let rec { Haptic.tap(); model.detail = .init(record: rec, mode: .view) }
        } label: {
            VStack(spacing: 4) {
                Text("\(day)").font(.system(size: 14.5, weight: isToday ? .heavy : .semibold))
                    .foregroundStyle(isToday ? T.accent : (rec != nil ? T.text : T.text5))
                HStack(spacing: 2.5) {
                    ForEach(Array(parts.prefix(3).enumerated()), id: \.offset) { _, p in
                        Circle().fill(PartColor.of(p)).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(rec != nil ? T.accent.opacity(0.15) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(rec == nil)
    }
}
