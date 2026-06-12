// Models.swift — data model + session math + date/format helpers

import Foundation

// ── Core records ───────────────────────────────────────────────
struct CatalogItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let part: String
    let equip: String
}

struct WorkoutSet: Identifiable, Codable, Hashable {
    var id = UUID()
    var kg: Double
    var reps: Int
    var done: Bool = false
}

struct SessionExercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var exId: String
    var name: String
    var part: String
    var equip: String
    var sets: [WorkoutSet]
}

/// A finished, saved workout (one per day in history).
struct WorkoutRecord: Identifiable, Codable, Hashable {
    var id: String
    var date: String          // "yyyy-MM-dd"
    var startTs: Double        // epoch seconds
    var durationSec: Int
    var exercises: [SessionExercise]
}

/// An in-progress workout (not yet saved).
struct ActiveSession: Codable {
    var startTs: Double        // epoch seconds — when first exercise/session started
    var exercises: [SessionExercise]
}

/// A saved routine (favorite template).
struct Routine: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var exercises: [SessionExercise]   // sets carry kg/reps; `done` ignored
}

// ── Session math ───────────────────────────────────────────────
// NOTE: 맨몸(bodyweight) exercises are excluded from volume per spec.
func sessionVolume(_ ex: [SessionExercise]) -> Double {
    var v = 0.0
    for e in ex where e.equip != "맨몸" {
        for s in e.sets where s.done { v += s.kg * Double(s.reps) }
    }
    return v
}

/// Volume counting all sets regardless of `done` (used for saved records where every set is done).
func recordVolume(_ ex: [SessionExercise]) -> Double {
    var v = 0.0
    for e in ex where e.equip != "맨몸" {
        for s in e.sets { v += s.kg * Double(s.reps) }
    }
    return v
}

func sessionSetCount(_ ex: [SessionExercise]) -> Int {
    ex.reduce(0) { $0 + $1.sets.filter { $0.done }.count }
}

func recordSetCount(_ ex: [SessionExercise]) -> Int {
    ex.reduce(0) { $0 + $1.sets.count }
}

func uniqueParts(_ ex: [SessionExercise]) -> [String] {
    var seen: [String] = []
    for e in ex where !seen.contains(e.part) { seen.append(e.part) }
    return seen
}

// ── Builders / cloning ─────────────────────────────────────────
func defaultKg(_ cat: CatalogItem) -> Double {
    if cat.equip == "맨몸" { return 0 }
    let map: [String: Double] = ["가슴": 40, "등": 50, "어깨": 20, "하체": 60, "팔": 15, "복근": 0, "엉덩이": 50]
    return map[cat.part] ?? 20
}

func makeExercise(_ cat: CatalogItem) -> SessionExercise {
    SessionExercise(exId: cat.id, name: cat.name, part: cat.part, equip: cat.equip,
                    sets: [WorkoutSet(kg: defaultKg(cat), reps: 10, done: false)])
}

/// Deep-clone a past session's exercises into a fresh (not-done) today list.
func cloneExercisesForToday(_ exs: [SessionExercise]) -> [SessionExercise] {
    exs.map { e in
        SessionExercise(exId: e.exId, name: e.name, part: e.part, equip: e.equip,
                        sets: e.sets.map { WorkoutSet(kg: $0.kg, reps: $0.reps, done: false) })
    }
}

func exercisesToRoutine(_ exs: [SessionExercise]) -> [SessionExercise] {
    exs.map { e in
        let done = e.sets.filter { $0.done }
        let base = done.isEmpty ? e.sets : done
        return SessionExercise(exId: e.exId, name: e.name, part: e.part, equip: e.equip,
                               sets: base.map { WorkoutSet(kg: $0.kg, reps: $0.reps, done: false) })
    }
}

func routineToToday(_ r: Routine) -> [SessionExercise] {
    cloneExercisesForToday(r.exercises)
}

func suggestRoutineName(_ exs: [SessionExercise]) -> String {
    uniqueParts(exs).prefix(2).joined(separator: "·") + " 루틴"
}

// ── 1RM (Epley) ────────────────────────────────────────────────
func epley1RM(_ kg: Double, _ reps: Int) -> Double {
    if kg <= 0 || reps <= 0 { return 0 }
    if reps == 1 { return kg }
    return kg * (1 + Double(reps) / 30)
}
func weightForReps(_ oneRM: Double, _ reps: Int) -> Double { oneRM / (1 + Double(reps) / 30) }
func round1(_ n: Double) -> Double { (n * 10).rounded() / 10 }

func exerciseBest1RM(_ ex: SessionExercise, doneOnly: Bool = true) -> Double {
    var best = 0.0
    for s in ex.sets where (!doneOnly || s.done) { best = max(best, epley1RM(s.kg, s.reps)) }
    return best
}

/// Most recent record for an exercise across history (for "지난 기록" comparison).
func lastRecordFor(exId: String, history: [WorkoutRecord], excludeDate: String) -> (date: String, sets: [WorkoutSet])? {
    let sorted = history.filter { $0.date != excludeDate }.sorted { $0.date > $1.date }
    for rec in sorted {
        if let e = rec.exercises.first(where: { $0.exId == exId }) {
            return (rec.date, e.sets)
        }
    }
    return nil
}

// ── Date / number helpers (local, no tz drift) ─────────────────
enum DateKey {
    static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    private static var cal: Calendar {
        var c = Calendar(identifier: .gregorian); c.firstWeekday = 1; return c
    }

    static func pad2(_ n: Int) -> String { String(format: "%02d", n) }

    static func ymd(_ d: Date) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return "\(c.year!)-\(pad2(c.month!))-\(pad2(c.day!))"
    }
    static func today() -> String { ymd(Date()) }

    static func date(_ key: String) -> Date {
        let p = key.split(separator: "-").compactMap { Int($0) }
        var c = DateComponents(); c.year = p[0]; c.month = p[1]; c.day = p[2]
        return cal.date(from: c) ?? Date()
    }

    static func label(_ key: String) -> String {
        let d = date(key)
        let c = cal.dateComponents([.month, .day, .weekday], from: d)
        return "\(c.month!)월 \(c.day!)일 (\(weekdays[c.weekday! - 1]))"
    }

    static func relative(_ key: String) -> String {
        let a = date(key), b = date(today())
        let diff = cal.dateComponents([.day], from: a, to: b).day ?? 0
        if diff == 0 { return "오늘" }
        if diff == 1 { return "어제" }
        if diff < 7 { return "\(diff)일 전" }
        if diff < 14 { return "지난주" }
        return "\(diff / 7)주 전"
    }
}

func fmtDuration(_ sec: Int) -> String {
    let s = max(0, sec)
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? "\(h):\(DateKey.pad2(m)):\(DateKey.pad2(sec))" : "\(m):\(DateKey.pad2(sec))"
}
func fmtClock(_ sec: Int) -> String {
    let s = max(0, sec); return "\(DateKey.pad2(s / 60)):\(DateKey.pad2(s % 60))"
}
func fmtVolume(_ kg: Double) -> String {
    let n = Int(kg.rounded())
    let f = NumberFormatter(); f.numberStyle = .decimal; f.locale = Locale(identifier: "ko_KR")
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}
/// kg renders without trailing ".0"; reps are ints.
func fmtKg(_ kg: Double) -> String {
    kg == kg.rounded() ? String(Int(kg)) : String(round1(kg))
}
