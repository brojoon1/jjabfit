// RootView.swift — tab shell + overlay routing

import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Group {
                    switch model.tab {
                    case .home:     HomeView()
                    case .stats:    StatsView()
                    case .calendar: CalendarView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                TabBar(tab: $model.tab)
            }
        }
        // Active workout session
        .fullScreenCover(isPresented: $model.showSession) { WorkoutSessionView() }
        // Load previous workouts
        .fullScreenCover(isPresented: $model.loadOpen) { LoadListView() }
        // Read-only detail from Home / Calendar
        .fullScreenCover(item: $model.detail) { route in
            DetailScreen(record: route.record, mode: route.mode)
        }
        // Completion summary
        .fullScreenCover(item: $model.summary) { rec in SummaryView(record: rec) }
        // 1RM calculator
        .sheet(isPresented: $model.oneRMOpen) {
            OneRMView().presentationDetents([.medium, .large])
        }
        // Save routine
        .sheet(isPresented: Binding(
            get: { model.routineDraft != nil },
            set: { if !$0 { model.routineDraft = nil } })
        ) {
            if let draft = model.routineDraft {
                SaveRoutineSheet(exercises: draft).presentationDetents([.height(220)])
            }
        }
    }
}

// ── Bottom tab bar ─────────────────────────────────────────────
struct TabBar: View {
    @Binding var tab: AppModel.Tab
    private let items: [(AppModel.Tab, String, String)] = [
        (.home, "운동", "house.fill"),
        (.stats, "통계", "chart.bar.fill"),
        (.calendar, "캘린더", "calendar"),
    ]
    var body: some View {
        HStack {
            ForEach(items, id: \.0) { item in
                let active = tab == item.0
                Button {
                    Haptic.tap()
                    tab = item.0
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.1.isEmpty ? "" : item.2)
                            .font(.system(size: 22, weight: active ? .semibold : .regular))
                        Text(item.1).font(.system(size: 11, weight: active ? .bold : .semibold))
                    }
                    .foregroundStyle(active ? T.accent : T.text4)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 22)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(T.hairline).frame(height: 0.5), alignment: .top)
    }
}
