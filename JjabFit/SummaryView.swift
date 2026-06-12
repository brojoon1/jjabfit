// SummaryView.swift — completion summary after "완료"

import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var model: AppModel
    let record: WorkoutRecord

    private var vol: Double { recordVolume(record.exercises) }
    private var sets: Int { recordSetCount(record.exercises) }
    private var parts: [String] { uniqueParts(record.exercises) }

    var body: some View {
        ZStack(alignment: .bottom) {
            T.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // celebratory header
                    VStack(spacing: 0) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(T.accent.opacity(0.18)).frame(width: 84, height: 84)
                            Image(systemName: "trophy.fill").font(.system(size: 38)).foregroundStyle(T.accent)
                        }
                        .padding(.bottom, 18)
                        Text("운동 완료!").font(.system(size: 26, weight: .heavy)).foregroundStyle(T.text)
                        Text("\(DateKey.label(record.date)) · 수고하셨어요")
                            .font(.system(size: 15)).foregroundStyle(T.text3).padding(.top, 6)
                        HStack(spacing: 6) {
                            ForEach(parts, id: \.self) { PartChip(part: $0) }
                        }
                        .padding(.top, 14)
                    }
                    .padding(.top, 32).padding(.bottom, 24)

                    // big stats 2x2
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
                    LazyVGrid(columns: cols, spacing: 12) {
                        BigStat(icon: "clock", value: fmtDuration(record.durationSec), label: "운동 시간")
                        BigStat(icon: "scalemass", value: fmtVolume(vol), unit: "kg", label: "총 볼륨")
                        BigStat(icon: "square.stack.3d.up", value: "\(sets)", label: "총 세트")
                        BigStat(icon: "dumbbell", value: "\(record.exercises.count)", label: "운동 수")
                    }
                    .padding(.bottom, 14)

                    // per-exercise breakdown
                    VStack(spacing: 0) {
                        ForEach(Array(record.exercises.enumerated()), id: \.element.id) { i, ex in
                            HStack(spacing: 12) {
                                Circle().fill(PartColor.of(ex.part)).frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(ex.name).font(.system(size: 15.5, weight: .semibold)).foregroundStyle(T.text).lineLimit(1)
                                    Text("\(ex.sets.count)세트 · \(fmtVolume(recordVolume([ex])))kg")
                                        .font(.system(size: 12.5)).foregroundStyle(T.text4)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 13)
                            if i < record.exercises.count - 1 {
                                Rectangle().fill(T.hairline).frame(height: 0.5)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(T.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 10) {
                EFButton(title: "루틴 저장", systemIcon: "star.fill", variant: .outline, full: true) {
                    model.routineDraft = exercisesToRoutine(record.exercises)
                }
                EFButton(title: "확인", full: true) {
                    model.summary = nil
                    model.tab = .home
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 30).padding(.top, 12)
            .background(LinearGradient(colors: [.clear, T.bg], startPoint: .top, endPoint: .bottom))
        }
    }
}

struct BigStat: View {
    var icon: String
    var value: String
    var unit: String? = nil
    var label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon).font(.system(size: 21)).foregroundStyle(T.text4).padding(.bottom, 10)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.system(size: 28, weight: .heavy)).foregroundStyle(T.text).tnum()
                if let unit { Text(unit).font(.system(size: 14, weight: .semibold)).foregroundStyle(T.text3) }
            }
            Text(label).font(.system(size: 13, weight: .medium)).foregroundStyle(T.text4).padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(T.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
