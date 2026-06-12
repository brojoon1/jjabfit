// HomeView.swift — home tab: start, load, routines, week summary, recent

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var model: AppModel

    private var recent: [WorkoutRecord] { model.history.sorted { $0.date > $1.date } }

    private var weekRecords: [WorkoutRecord] {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 1
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return model.history.filter { DateKey.date($0.date) >= weekStart }
    }

    var body: some View {
        ScrollView {
            LargeHeader(title: "오늘", subtitle: DateKey.label(DateKey.today()))

            VStack(spacing: 0) {
                if model.session != nil {
                    resumeBanner
                } else {
                    heroCard
                }

                loadCard

                if !model.routines.isEmpty { routinesSection }

                sectionTitle("이번 주")
                HStack(spacing: 10) {
                    WeekStat(value: "\(weekRecords.count)", label: "운동한 날")
                    WeekStat(value: "\(weekRecords.reduce(0) { $0 + recordSetCount($1.exercises) })", label: "총 세트")
                    WeekStat(value: fmtVolume(weekRecords.reduce(0) { $0 + recordVolume($1.exercises) }), unit: "kg", label: "총 볼륨")
                }
                .padding(.bottom, 24)

                HStack(alignment: .firstTextBaseline) {
                    Text("최근 기록").font(.system(size: 17, weight: .heavy)).foregroundStyle(T.text)
                    Spacer()
                    if !recent.isEmpty {
                        Button("전체보기") { model.loadOpen = true }
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(T.accent)
                    }
                }
                .padding(.bottom, 10)

                if recent.isEmpty {
                    EmptyStateView(systemIcon: "dumbbell", title: "아직 기록이 없어요", desc: "첫 운동을 시작해 보세요.")
                } else {
                    ForEach(recent.prefix(4)) { rec in
                        HistoryRow(rec: rec) { model.detail = .init(record: rec, mode: .view) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func sectionTitle(_ t: String) -> some View {
        HStack { Text(t).font(.system(size: 17, weight: .heavy)).foregroundStyle(T.text); Spacer() }
            .padding(.bottom, 10)
    }

    // MARK: pieces
    private var resumeBanner: some View {
        Button { model.showSession = true } label: {
            HStack(spacing: 12) {
                Circle().fill(T.accent).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 1) {
                    Text("운동 진행 중").font(.system(size: 15, weight: .bold)).foregroundStyle(T.text)
                    Text("\(fmtDuration(model.elapsed)) · \(model.session?.exercises.count ?? 0)개 운동")
                        .font(.system(size: 13)).foregroundStyle(T.text3).tnum()
                }
                Spacer()
                Text("이어서 하기").font(.system(size: 14.5, weight: .bold)).foregroundStyle(T.accent)
            }
            .padding(16)
            .background(T.accent.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(T.accent.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(PressScale())
        .padding(.bottom, 14)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("READY TO LIFT").font(.system(size: 13, weight: .bold)).foregroundStyle(T.accent)
                .padding(.bottom, 6)
            Text("오늘도 한 세트씩,\n기록으로 남겨요")
                .font(.system(size: 23, weight: .heavy)).foregroundStyle(T.text)
                .lineSpacing(3).padding(.bottom, 18)
            EFButton(title: "오늘 운동 시작하기", systemIcon: "play.fill", full: true, height: 56) {
                model.startWorkout()
            }
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [T.accent.opacity(0.30), T.surface],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.bottom, 14)
    }

    private var loadCard: some View {
        Button { model.loadOpen = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(T.surface2).frame(width: 42, height: 42)
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 20, weight: .semibold)).foregroundStyle(T.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("운동 불러오기").font(.system(size: 16, weight: .bold)).foregroundStyle(T.text)
                    Text("예전 운동을 그대로 가져오기").font(.system(size: 13)).foregroundStyle(T.text4)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundStyle(T.text5)
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .background(T.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressScale())
        .padding(.bottom, 22)
    }

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("내 루틴").font(.system(size: 17, weight: .heavy)).foregroundStyle(T.text)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.routines) { rt in
                        RoutineCard(routine: rt,
                                    onStart: { model.startRoutine(rt) },
                                    onDelete: { model.deleteRoutine(rt.id) })
                    }
                }
            }
        }
        .padding(.bottom, 22)
    }
}

// ── History row (reused in Home, LoadList) ─────────────────────
struct HistoryRow: View {
    let rec: WorkoutRecord
    var onTap: () -> Void
    var body: some View {
        Button(action: { Haptic.tap(); onTap() }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(DateKey.label(rec.date)).font(.system(size: 16.5, weight: .bold)).foregroundStyle(T.text)
                    Text(DateKey.relative(rec.date)).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(T.text4)
                        .padding(.horizontal, 9).padding(.vertical, 2)
                        .background(T.surface2).clipShape(Capsule())
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundStyle(T.text5)
                }
                .padding(.bottom, 10)

                FlowChips(parts: uniqueParts(rec.exercises), small: true).padding(.bottom, 12)

                HStack(spacing: 16) {
                    summaryStat("\(rec.exercises.count)", "운동")
                    summaryStat("\(recordSetCount(rec.exercises))", "세트")
                    summaryStat(fmtVolume(recordVolume(rec.exercises)), "kg")
                    Text(fmtDuration(rec.durationSec)).font(.system(size: 13, weight: .bold)).foregroundStyle(T.text2).tnum()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(T.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressScale())
        .padding(.bottom, 12)
    }

    private func summaryStat(_ v: String, _ l: String) -> some View {
        HStack(spacing: 3) {
            Text(v).font(.system(size: 13, weight: .bold)).foregroundStyle(T.text2).tnum()
            Text(l).font(.system(size: 13)).foregroundStyle(T.text3)
        }
    }
}

/// Simple wrapping chip row (parts are few, so an HStack with wrap via FlowLayout-lite).
struct FlowChips: View {
    let parts: [String]
    var small: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            ForEach(parts, id: \.self) { PartChip(part: $0, small: small) }
            Spacer(minLength: 0)
        }
    }
}

// ── Routine card (horizontal) ──────────────────────────────────
struct RoutineCard: View {
    let routine: Routine
    var onStart: () -> Void
    var onDelete: () -> Void
    var body: some View {
        let parts = uniqueParts(routine.exercises)
        let sets = routine.exercises.reduce(0) { $0 + $1.sets.count }
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name).font(.system(size: 16, weight: .bold)).foregroundStyle(T.text).lineLimit(1)
                    Text("\(routine.exercises.count)개 운동 · \(sets)세트").font(.system(size: 12.5)).foregroundStyle(T.text4)
                }
                Spacer()
                Button(action: { Haptic.tap(); onDelete() }) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(T.text5)
                        .frame(width: 24, height: 24).background(T.surface2).clipShape(Circle())
                }
            }
            .padding(.bottom, 12)
            HStack(spacing: 5) {
                ForEach(parts.prefix(3), id: \.self) { PartChip(part: $0, small: true) }
            }
            .padding(.bottom, 12)
            EFButton(title: "시작", systemIcon: "play.fill", full: true, height: 40) { onStart() }
        }
        .padding(14)
        .frame(width: 200, alignment: .leading)
        .background(T.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
