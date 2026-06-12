// HistoryViews.swift — load list, workout detail (read-only & load modes)

import SwiftUI

// ── Load previous workouts (newest first) ──────────────────────
struct LoadListView: View {
    @EnvironmentObject var model: AppModel
    @State private var detailRecord: WorkoutRecord?

    private var sorted: [WorkoutRecord] { model.history.sorted { $0.date > $1.date } }

    var body: some View {
        NavigationStack {
            ZStack {
                T.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    NavBar(title: "운동 불러오기", onBack: { model.loadOpen = false })
                    Text("예전에 했던 운동을 그대로 오늘로 불러올 수 있어요. 최신 순으로 정렬됩니다.")
                        .font(.system(size: 14)).foregroundStyle(T.text4).lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20).padding(.bottom, 10)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if sorted.isEmpty {
                                EmptyStateView(systemIcon: "clock.arrow.circlepath", title: "기록이 없어요",
                                               desc: "첫 운동을 완료하면 여기에 쌓여요.")
                            }
                            ForEach(sorted) { rec in
                                HistoryRow(rec: rec) { detailRecord = rec }
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 40)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            // iOS 16 호환: navigationDestination(item:)는 iOS 17+ 라 isPresented 방식 사용
            .navigationDestination(isPresented: Binding(
                get: { detailRecord != nil },
                set: { if !$0 { detailRecord = nil } }
            )) {
                if let rec = detailRecord {
                    WorkoutDetailBody(record: rec, mode: .load, onBack: { detailRecord = nil })
                        .navigationBarHidden(true)
                }
            }
        }
    }
}

// ── Detail screen (read-only, presented from Home/Calendar) ────
struct DetailScreen: View {
    @EnvironmentObject var model: AppModel
    let record: WorkoutRecord
    let mode: AppModel.DetailRoute.Mode
    var body: some View {
        WorkoutDetailBody(record: record, mode: mode, onBack: { model.detail = nil })
    }
}

// ── Shared detail body ─────────────────────────────────────────
struct WorkoutDetailBody: View {
    @EnvironmentObject var model: AppModel
    let record: WorkoutRecord
    let mode: AppModel.DetailRoute.Mode
    var onBack: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            T.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                NavBar(title: DateKey.label(record.date), onBack: onBack)
                ScrollView {
                    VStack(spacing: 0) {
                        FlowChips(parts: uniqueParts(record.exercises)).padding(.bottom, 16)
                        statStrip
                        ForEach(record.exercises) { ex in exerciseBlock(ex) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, mode == .load ? 120 : 40)
                }
                .scrollIndicators(.hidden)
            }

            if mode == .load {
                EFButton(title: "오늘 운동으로 불러오기", systemIcon: "clock.arrow.circlepath", full: true) {
                    model.loadRecord(record)
                }
                .padding(.horizontal, 16).padding(.bottom, 30).padding(.top, 12)
                .background(LinearGradient(colors: [.clear, T.bg], startPoint: .top, endPoint: .bottom))
            }
        }
    }

    private var statStrip: some View {
        HStack {
            StatView(value: fmtDuration(record.durationSec), label: "시간", valueSize: 22)
            Spacer()
            StatView(value: fmtVolume(recordVolume(record.exercises)), unit: "kg", label: "볼륨", valueSize: 22)
            Spacer()
            StatView(value: "\(recordSetCount(record.exercises))", label: "세트", valueSize: 22)
            Spacer()
            StatView(value: "\(record.exercises.count)", label: "운동", valueSize: 22)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.bottom, 16)
    }

    private func exerciseBlock(_ ex: SessionExercise) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(PartColor.of(ex.part).opacity(0.20)).frame(width: 30, height: 30)
                    Image(systemName: "dumbbell.fill").font(.system(size: 14)).foregroundStyle(PartColor.of(ex.part))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(ex.name).font(.system(size: 15.5, weight: .bold)).foregroundStyle(T.text)
                    Text("\(ex.part) · \(ex.equip)").font(.system(size: 12)).foregroundStyle(T.text4)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            ForEach(Array(ex.sets.enumerated()), id: \.element.id) { si, s in
                HStack(spacing: 10) {
                    Text("\(si + 1)").font(.system(size: 13, weight: .bold)).foregroundStyle(T.text5).frame(width: 22)
                    Text(fmtKg(s.kg)).font(.system(size: 14.5, weight: .bold)).foregroundStyle(T.text).tnum()
                    Text("kg").font(.system(size: 12)).foregroundStyle(T.text4)
                    Text("×").font(.system(size: 14.5)).foregroundStyle(T.text5)
                    Text("\(s.reps)").font(.system(size: 14.5, weight: .bold)).foregroundStyle(T.text).tnum()
                    Text("회").font(.system(size: 12)).foregroundStyle(T.text4)
                    Spacer()
                }
                .padding(.vertical, 5).padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 13)
        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.bottom, 12)
    }
}
