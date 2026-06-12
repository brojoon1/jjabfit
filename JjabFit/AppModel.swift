// AppModel.swift — root state: session lifecycle, persistence, routing
// Mirrors the React `App` root (app.jsx).

import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    // Persisted data
    @Published var history: [WorkoutRecord] = []
    @Published var routines: [Routine] = []

    // Live session (nil when no workout in progress)
    @Published var session: ActiveSession?

    // Settings (persisted manually so changes publish to observers)
    @Published var restSec: Int {
        didSet { UserDefaults.standard.set(restSec, forKey: restSecKey) }
    }

    // Routing flags / sheets
    @Published var tab: Tab = .home
    @Published var showSession = false
    @Published var pickerOpen = false
    @Published var loadOpen = false
    @Published var detail: DetailRoute?
    @Published var summary: WorkoutRecord?
    @Published var rest: Int?               // total rest seconds when timer active
    @Published var oneRMOpen = false
    @Published var routineDraft: [SessionExercise]?

    // Live clock
    @Published var now = Date()
    private var timer: AnyCancellable?

    enum Tab { case home, stats, calendar }
    struct DetailRoute: Identifiable {
        enum Mode { case view, load }
        let id = UUID()
        let record: WorkoutRecord
        let mode: Mode
    }

    private let historyKey = "jjabfit_history_v2"
    private let routinesKey = "jjabfit_routines_v1"
    private let restSecKey = "jjabfit_restSec"

    init() {
        restSec = (UserDefaults.standard.object(forKey: restSecKey) as? Int) ?? 90
        history = load([WorkoutRecord].self, key: historyKey) ?? {
            let seed = Catalog.seedHistory(); save(seed, key: historyKey); return seed
        }()
        routines = load([Routine].self, key: routinesKey) ?? {
            let seed = Catalog.seedRoutines(); save(seed, key: routinesKey); return seed
        }()
    }

    // ── Live elapsed ───────────────────────────────────────────
    var elapsed: Int {
        guard let s = session else { return 0 }
        return max(0, Int(now.timeIntervalSince1970 - s.startTs))
    }

    private func startClock() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] t in self?.now = t }
    }
    private func stopClock() { timer?.cancel(); timer = nil }

    // ── Persistence helpers ────────────────────────────────────
    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func persistHistory() { save(history, key: historyKey) }
    private func persistRoutines() { save(routines, key: routinesKey) }

    // ── Session lifecycle ──────────────────────────────────────
    func startWorkout() {
        Beeper.shared.prepare()
        session = ActiveSession(startTs: Date().timeIntervalSince1970, exercises: [])
        startClock()
        showSession = true
        pickerOpen = true
    }

    func addExercises(_ cats: [CatalogItem]) {
        guard session != nil else { return }
        session?.exercises.append(contentsOf: cats.map(makeExercise))
        pickerOpen = false
    }

    func editSet(_ exIdx: Int, _ setIdx: Int, kg: Double? = nil, reps: Int? = nil) {
        guard session != nil else { return }
        if let kg { session!.exercises[exIdx].sets[setIdx].kg = kg }
        if let reps { session!.exercises[exIdx].sets[setIdx].reps = reps }
    }

    func toggleSet(_ exIdx: Int, _ setIdx: Int) {
        guard session != nil else { return }
        let becameDone = !session!.exercises[exIdx].sets[setIdx].done
        session!.exercises[exIdx].sets[setIdx].done.toggle()
        if becameDone {
            Beeper.shared.beep(frequency: 660, duration: 0.1)
            Haptic.tap()
            rest = restSec            // open rest timer
        }
    }

    func addSet(_ exIdx: Int) {
        guard session != nil else { return }
        let last = session!.exercises[exIdx].sets.last ?? WorkoutSet(kg: 0, reps: 10)
        session!.exercises[exIdx].sets.append(WorkoutSet(kg: last.kg, reps: last.reps, done: false))
    }

    func removeSet(_ exIdx: Int, _ setIdx: Int) {
        guard session != nil, session!.exercises.indices.contains(exIdx) else { return }
        session!.exercises[exIdx].sets.remove(at: setIdx)
        session!.exercises.removeAll { $0.sets.isEmpty }
    }

    func removeExercise(_ exIdx: Int) {
        session?.exercises.remove(at: exIdx)
    }

    func finishWorkout() {
        guard let s = session else { return }
        let cleaned = s.exercises
            .map { e -> SessionExercise in
                var e2 = e; e2.sets = e.sets.filter { $0.done }; return e2
            }
            .filter { !$0.sets.isEmpty }
        if cleaned.isEmpty {
            // nothing completed — just discard
            endSession()
            tab = .home
            return
        }
        let date = DateKey.today()
        let record = WorkoutRecord(id: "w_\(Int(Date().timeIntervalSince1970 * 1000))",
                                   date: date, startTs: s.startTs, durationSec: elapsed, exercises: cleaned)
        history = [record] + history.filter { $0.date != date }
        persistHistory()
        endSession()
        summary = record
    }

    private func endSession() {
        rest = nil
        showSession = false
        session = nil
        stopClock()
    }

    /// Discard an in-progress session (no save).
    func discardSession() { endSession() }

    // ── Load past workout / routine ────────────────────────────
    func loadRecord(_ rec: WorkoutRecord) {
        let cloned = cloneExercisesForToday(rec.exercises)
        if session != nil {
            session!.exercises.append(contentsOf: cloned)
        } else {
            session = ActiveSession(startTs: Date().timeIntervalSince1970, exercises: cloned)
            startClock()
        }
        detail = nil
        loadOpen = false
        showSession = true
    }

    func startRoutine(_ r: Routine) {
        let cloned = routineToToday(r)
        if session != nil {
            session!.exercises.append(contentsOf: cloned)
        } else {
            session = ActiveSession(startTs: Date().timeIntervalSince1970, exercises: cloned)
            startClock()
        }
        showSession = true
    }

    // ── Routines ───────────────────────────────────────────────
    func saveRoutine(name: String) {
        guard let draft = routineDraft else { return }
        routines.insert(Routine(id: "r_\(Int(Date().timeIntervalSince1970 * 1000))", name: name, exercises: draft), at: 0)
        persistRoutines()
        routineDraft = nil
    }
    func deleteRoutine(_ id: String) {
        routines.removeAll { $0.id == id }
        persistRoutines()
    }
}
