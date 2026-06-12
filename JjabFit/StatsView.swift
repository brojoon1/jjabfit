// StatsView.swift — stats tab, 1RM calculator, save-routine sheet

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var model: AppModel
    @State private var period = 4   // weeks: 4 | 12

    private var days: Int { period * 7 }

    private var summary: (count: Int, sets: Int, vol: Double) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Calendar.current.startOfDay(for: Date()))!
        let recs = model.history.filter { DateKey.date($0.date) >= cutoff }
        return (recs.count,
                recs.reduce(0) { $0 + recordSetCount($1.exercises) },
                recs.reduce(0) { $0 + recordVolume($1.exercises) })
    }

    var body: some View {
        ScrollView {
            LargeHeader(title: "통계")
            VStack(spacing: 0) {
                // period toggle
                HStack(spacing: 0) {
                    ForEach([4, 12], id: \.self) { w in
                        Button { period = w } label: {
                            Text("최근 \(w)주").font(.system(size: 14.5, weight: .bold))
                                .foregroundStyle(period == w ? T.text : T.text4)
                                .frame(maxWidth: .infinity).frame(height: 36)
                                .background(period == w ? T.surface3 : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3).background(T.surface).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.bottom, 16)

                HStack(spacing: 10) {
                    WeekStat(value: "\(summary.count)", label: "운동 횟수")
                    WeekStat(value: "\(summary.sets)", label: "총 세트")
                    WeekStat(value: fmtVolume(summary.vol), unit: "kg", label: "총 볼륨")
                }
                .padding(.bottom, 24)

                weeklyVolumeSection
                partVolumeSection
                oneRMRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var weeklyVolumeSection: some View {
        let data = Catalog.weeklyVolume(model.history, weeks: period == 4 ? 6 : 12)
        let maxVol = max(1, data.map { $0.vol }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("주간 볼륨 추이").font(.system(size: 17, weight: .heavy)).foregroundStyle(T.text)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, d in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(i == data.count - 1 ? T.accent : T.surface3)
                            .frame(height: max(4, CGFloat(d.vol / maxVol) * 120))
                        Text(d.label).font(.system(size: 10, weight: .medium)).foregroundStyle(T.text5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.bottom, 16)
    }

    private var partVolumeSection: some View {
        let data = Catalog.partVolumeStats(model.history, days: days)
        let total = max(1, data.reduce(0) { $0 + $1.vol })
        let maxVol = max(1, data.map { $0.vol }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 14) {
            Text("부위별 볼륨").font(.system(size: 17, weight: .heavy)).foregroundStyle(T.text)
            if data.isEmpty {
                Text("기록이 없어요").font(.system(size: 14)).foregroundStyle(T.text4)
            } else {
                ForEach(Array(data.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 6) {
                        HStack {
                            Text(d.part).font(.system(size: 14, weight: .semibold)).foregroundStyle(T.text2)
                            Spacer()
                            Text("\(fmtVolume(d.vol))kg").font(.system(size: 13, weight: .bold)).foregroundStyle(T.text).tnum()
                            Text("\(Int((d.vol / total * 100).rounded()))%").font(.system(size: 12)).foregroundStyle(T.text4).tnum()
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(T.surface2)
                                Capsule().fill(PartColor.of(d.part))
                                    .frame(width: geo.size.width * CGFloat(d.vol / maxVol))
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.bottom, 16)
    }

    private var oneRMRow: some View {
        Button { model.oneRMOpen = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(T.surface2).frame(width: 42, height: 42)
                    Image(systemName: "bolt.fill").font(.system(size: 19)).foregroundStyle(T.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("1RM 계산기").font(.system(size: 16, weight: .bold)).foregroundStyle(T.text)
                    Text("무게·횟수로 예상 1RM 계산").font(.system(size: 13)).foregroundStyle(T.text4)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundStyle(T.text5)
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressScale())
    }
}

// ── 1RM calculator ─────────────────────────────────────────────
struct OneRMView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var kg = 60.0
    @State private var reps = 5
    @State private var editKg = false
    @State private var editReps = false

    private var oneRM: Double { epley1RM(kg, reps) }
    private let repTable = [1, 2, 3, 5, 8, 10, 12, 15]

    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("1RM 계산기").font(.system(size: 17, weight: .bold)).foregroundStyle(T.text)
                    Spacer()
                    Button("완료") { dismiss() }.font(.system(size: 16, weight: .bold)).foregroundStyle(T.accent)
                }
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 10) {
                            inputCell(title: "무게", value: "\(fmtKg(kg))kg") { editKg = true }
                            inputCell(title: "횟수", value: "\(reps)회") { editReps = true }
                        }
                        VStack(spacing: 4) {
                            Text("예상 1RM").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.text4)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(fmtKg(round1(oneRM))).font(.system(size: 44, weight: .heavy)).foregroundStyle(T.accent).tnum()
                                Text("kg").font(.system(size: 18, weight: .semibold)).foregroundStyle(T.text3)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        VStack(spacing: 0) {
                            ForEach(Array(repTable.enumerated()), id: \.offset) { i, r in
                                HStack {
                                    Text("\(r)회").font(.system(size: 14.5, weight: .semibold)).foregroundStyle(T.text2).frame(width: 50, alignment: .leading)
                                    Spacer()
                                    Text("\(fmtKg(round1(weightForReps(oneRM, r))))kg").font(.system(size: 15, weight: .bold)).foregroundStyle(T.text).tnum()
                                    Spacer()
                                    Text("\(Int((Double(100) / (1 + Double(r) / 30)).rounded()))%").font(.system(size: 13)).foregroundStyle(T.text4).tnum().frame(width: 50, alignment: .trailing)
                                }
                                .padding(.vertical, 11)
                                if i < repTable.count - 1 { Rectangle().fill(T.hairline).frame(height: 0.5) }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .padding(.horizontal, 16).padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(isPresented: $editKg) {
            NumPadView(field: .kg, initial: kg) { kg = $0 }.presentationDetents([.height(420)])
        }
        .sheet(isPresented: $editReps) {
            NumPadView(field: .reps, initial: Double(reps)) { reps = max(1, Int($0)) }.presentationDetents([.height(420)])
        }
    }

    private func inputCell(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptic.tap(); action() }) {
            VStack(spacing: 4) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(T.text4)
                Text(value).font(.system(size: 22, weight: .heavy)).foregroundStyle(T.text).tnum()
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// ── Save routine sheet ─────────────────────────────────────────
struct SaveRoutineSheet: View {
    @EnvironmentObject var model: AppModel
    let exercises: [SessionExercise]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        SheetContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("루틴으로 저장").font(.system(size: 16, weight: .bold)).foregroundStyle(T.text)
                    Spacer()
                    Button("취소") { dismiss() }.font(.system(size: 16, weight: .semibold)).foregroundStyle(T.text3)
                }
                .padding(.top, 2).padding(.bottom, 14)

                TextField("", text: $name, prompt: Text("루틴 이름").foregroundColor(T.text4))
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(T.text).tint(T.accent)
                    .padding(.horizontal, 14).frame(height: 50)
                    .background(T.surface2).clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .padding(.bottom, 14)

                EFButton(title: "저장", full: true) {
                    let final = name.trimmingCharacters(in: .whitespaces)
                    model.routineDraft = exercises
                    model.saveRoutine(name: final.isEmpty ? suggestRoutineName(exercises) : final)
                    dismiss()
                }
            }
            .padding(.bottom, 24)
        }
        .onAppear { if name.isEmpty { name = suggestRoutineName(exercises) } }
    }
}
