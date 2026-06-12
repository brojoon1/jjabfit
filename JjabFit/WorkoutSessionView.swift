// WorkoutSessionView.swift — live workout: timer, exercise cards, set rows

import SwiftUI

struct WorkoutSessionView: View {
    @EnvironmentObject var model: AppModel

    @State private var edit: EditTarget?
    @State private var restPickerOpen = false

    struct EditTarget: Identifiable {
        let id = UUID()
        let exIdx: Int
        let setIdx: Int
        let field: NumPadView.Field
    }

    private var exercises: [SessionExercise] { model.session?.exercises ?? [] }
    private var vol: Double { sessionVolume(exercises) }
    private var doneSets: Int { sessionSetCount(exercises) }
    private var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }

    var body: some View {
        ZStack(alignment: .bottom) {
            T.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if exercises.isEmpty {
                            EmptyStateView(systemIcon: "dumbbell", title: "운동을 추가해 주세요",
                                           desc: "아래 버튼으로 오늘 할 운동을 골라보세요.")
                        }
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { idx, ex in
                            ExerciseCard(
                                ex: ex, exIdx: idx,
                                prev: lastRecordFor(exId: ex.exId, history: model.history, excludeDate: DateKey.today()),
                                onEdit: { setIdx, field in edit = EditTarget(exIdx: idx, setIdx: setIdx, field: field) },
                                onToggle: { setIdx in model.toggleSet(idx, setIdx) },
                                onAddSet: { model.addSet(idx) },
                                onRemoveLast: { if ex.sets.count > 1 { model.removeSet(idx, ex.sets.count - 1) } },
                                onRemoveEx: { model.removeExercise(idx) }
                            )
                        }

                        Button { model.pickerOpen = true } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "plus").font(.system(size: 18, weight: .bold))
                                Text("운동 추가").font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(T.accent)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundStyle(T.hairline2))
                        }
                        .buttonStyle(PressScale())

                        if !exercises.isEmpty {
                            Button { model.routineDraft = exercisesToRoutine(exercises) } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill").font(.system(size: 15))
                                    Text("루틴으로 저장").font(.system(size: 14.5, weight: .bold))
                                }
                                .foregroundStyle(T.text3).frame(maxWidth: .infinity).frame(height: 46)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 130)
                }
                .scrollIndicators(.hidden)
            }
        }
        // Exercise picker over session
        .fullScreenCover(isPresented: $model.pickerOpen) {
            ExercisePickerView(onClose: { model.pickerOpen = false })
        }
        // Numeric keypad
        .sheet(item: $edit) { t in
            let set = model.session!.exercises[t.exIdx].sets[t.setIdx]
            NumPadView(field: t.field, initial: t.field == .kg ? set.kg : Double(set.reps)) { newVal in
                if t.field == .kg { model.editSet(t.exIdx, t.setIdx, kg: newVal) }
                else { model.editSet(t.exIdx, t.setIdx, reps: Int(newVal)) }
            }
            .presentationDetents([.height(420)])
        }
        // Rest duration picker
        .sheet(isPresented: $restPickerOpen) {
            RestPickerView(value: model.restSec) { model.restSec = $0 }
                .presentationDetents([.height(330)])
        }
        // Rest timer (over everything in session)
        .sheet(isPresented: Binding(get: { model.rest != nil }, set: { if !$0 { model.rest = nil } })) {
            if let total = model.rest {
                RestTimerView(total: total) { model.rest = nil }
                    .presentationDetents([.height(440)])
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button { model.showSession = false } label: {
                    Image(systemName: "chevron.down").font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(T.text3).frame(width: 40, height: 40)
                }
                Spacer()
                Button { restPickerOpen = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock").font(.system(size: 14, weight: .semibold))
                        Text("휴식 \(model.restSec)초").font(.system(size: 13.5, weight: .semibold))
                    }
                    .foregroundStyle(T.text2).padding(.horizontal, 12).frame(height: 34)
                    .background(T.surface).clipShape(Capsule())
                }
                EFButton(title: "완료", height: 38) { model.finishWorkout() }
                    .fixedSize()
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("운동 시간").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.text4)
                    HStack(spacing: 8) {
                        Circle().fill(T.accent).frame(width: 9, height: 9)
                        Text(fmtDuration(model.elapsed)).font(.system(size: 38, weight: .heavy)).foregroundStyle(T.text).tnum()
                    }
                }
                Spacer()
                HStack(spacing: 18) {
                    StatView(value: fmtVolume(vol), unit: "kg", label: "볼륨")
                    StatView(value: "\(doneSets)/\(totalSets)", label: "세트")
                }
                .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 12)
    }
}

// ── Exercise card ──────────────────────────────────────────────
struct ExerciseCard: View {
    let ex: SessionExercise
    let exIdx: Int
    let prev: (date: String, sets: [WorkoutSet])?
    var onEdit: (Int, NumPadView.Field) -> Void
    var onToggle: (Int) -> Void
    var onAddSet: () -> Void
    var onRemoveLast: () -> Void
    var onRemoveEx: () -> Void

    @State private var menu = false

    private var doneCount: Int { ex.sets.filter { $0.done }.count }
    private var best1RM: Double {
        ex.equip == "맨몸" ? 0 : exerciseBest1RM(ex)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(PartColor.of(ex.part).opacity(0.20)).frame(width: 36, height: 36)
                    Image(systemName: "dumbbell.fill").font(.system(size: 16)).foregroundStyle(PartColor.of(ex.part))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(ex.name).font(.system(size: 16.5, weight: .bold)).foregroundStyle(T.text).lineLimit(1)
                    Text(subtitle).font(.system(size: 12.5)).foregroundStyle(T.text4)
                }
                Spacer()
                Menu {
                    Button(role: .destructive) { onRemoveEx() } label: { Label("운동 삭제", systemImage: "trash") }
                } label: {
                    Image(systemName: "trash").font(.system(size: 17)).foregroundStyle(T.text4).padding(6)
                }
            }
            .padding(.bottom, 10)

            if let prev, !prev.sets.isEmpty {
                HStack(spacing: 7) {
                    Text("지난 \(DateKey.relative(prev.date))")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(T.text5)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(T.surface2).clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text(prev.sets.map { "\(fmtKg($0.kg))×\($0.reps)" }.joined(separator: "  ·  "))
                        .font(.system(size: 12)).foregroundStyle(T.text3).lineLimit(1).tnum()
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 9)
            }

            columnHeader
            ForEach(Array(ex.sets.enumerated()), id: \.element.id) { si, s in
                SetRow(idx: si, set: s,
                       onEditKg: { onEdit(si, .kg) },
                       onEditReps: { onEdit(si, .reps) },
                       onToggle: { onToggle(si) })
            }

            HStack(spacing: 8) {
                Button(action: { Haptic.tap(); onAddSet() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                        Text("세트 추가").font(.system(size: 14.5, weight: .bold))
                    }
                    .foregroundStyle(T.text2).frame(maxWidth: .infinity).frame(height: 40)
                    .background(T.surface2).clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                if ex.sets.count > 1 {
                    Button(action: { Haptic.tap(); onRemoveLast() }) {
                        Image(systemName: "minus").font(.system(size: 17, weight: .bold)).foregroundStyle(T.text4)
                            .frame(width: 40, height: 40).background(T.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)
        .background(T.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.bottom, 14)
    }

    private var subtitle: String {
        var s = "\(ex.part) · \(ex.equip) · \(doneCount)/\(ex.sets.count) 세트"
        if best1RM > 0 { s += " · 예상 1RM \(fmtKg(round1(best1RM)))kg" }
        return s
    }

    private var columnHeader: some View {
        HStack(spacing: 6) {
            Text("세트").frame(width: 34)
            Text("무게").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
            Text("횟수").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
            Text("완료").frame(width: 46)
        }
        .font(.system(size: 11.5, weight: .semibold)).foregroundStyle(T.text5)
        .padding(.horizontal, 4).padding(.bottom, 4)
    }
}

// ── Set row ────────────────────────────────────────────────────
struct SetRow: View {
    let idx: Int
    let set: WorkoutSet
    var onEditKg: () -> Void
    var onEditReps: () -> Void
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text("\(idx + 1)").font(.system(size: 15, weight: .bold))
                .foregroundStyle(set.done ? T.accent : T.text4).frame(width: 34)

            cell(value: fmtKg(set.kg), unit: "kg", action: onEditKg)
            cell(value: "\(set.reps)", unit: "회", action: onEditReps)

            Button(action: { Haptic.tap(); onToggle() }) {
                Image(systemName: "checkmark").font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(set.done ? .white : T.text4)
                    .frame(width: 34, height: 34)
                    .background(set.done ? T.accent : T.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .frame(width: 46)
        }
        .padding(.vertical, 7).padding(.horizontal, 4)
        .background(set.done ? T.accent.opacity(0.12) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeOut(duration: 0.2), value: set.done)
    }

    private func cell(value: String, unit: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptic.tap(); action() }) {
            HStack(spacing: 3) {
                Text(value).font(.system(size: 17, weight: .bold)).foregroundStyle(T.text).tnum()
                Text(unit).font(.system(size: 12)).foregroundStyle(T.text4)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10).frame(maxWidth: .infinity).frame(height: 40)
            .background(T.surface2).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
