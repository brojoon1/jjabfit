// Catalog.swift — exercise catalog + seed history/routines (mirrors data.jsx)

import Foundation

enum Catalog {
    static let parts  = ["가슴", "등", "어깨", "하체", "팔", "복근", "엉덩이"]
    static let equips = ["바벨", "덤벨", "머신", "케이블", "맨몸"]

    static let all: [CatalogItem] = [
        // 가슴
        .init(id: "c1", name: "바벨 벤치프레스", part: "가슴", equip: "바벨"),
        .init(id: "c2", name: "인클라인 바벨 프레스", part: "가슴", equip: "바벨"),
        .init(id: "c3", name: "덤벨 벤치프레스", part: "가슴", equip: "덤벨"),
        .init(id: "c4", name: "인클라인 덤벨 프레스", part: "가슴", equip: "덤벨"),
        .init(id: "c5", name: "덤벨 플라이", part: "가슴", equip: "덤벨"),
        .init(id: "c6", name: "체스트 프레스 머신", part: "가슴", equip: "머신"),
        .init(id: "c7", name: "펙덱 플라이", part: "가슴", equip: "머신"),
        .init(id: "c8", name: "케이블 크로스오버", part: "가슴", equip: "케이블"),
        .init(id: "c9", name: "푸시업", part: "가슴", equip: "맨몸"),
        .init(id: "c10", name: "딥스", part: "가슴", equip: "맨몸"),
        // 등
        .init(id: "b1", name: "데드리프트", part: "등", equip: "바벨"),
        .init(id: "b2", name: "바벨 로우", part: "등", equip: "바벨"),
        .init(id: "b3", name: "펜들레이 로우", part: "등", equip: "바벨"),
        .init(id: "b4", name: "덤벨 로우", part: "등", equip: "덤벨"),
        .init(id: "b5", name: "풀업", part: "등", equip: "맨몸"),
        .init(id: "b6", name: "랫풀다운", part: "등", equip: "케이블"),
        .init(id: "b7", name: "시티드 케이블 로우", part: "등", equip: "케이블"),
        .init(id: "b8", name: "티바 로우 머신", part: "등", equip: "머신"),
        // 어깨
        .init(id: "s1", name: "오버헤드 프레스", part: "어깨", equip: "바벨"),
        .init(id: "s2", name: "덤벨 숄더프레스", part: "어깨", equip: "덤벨"),
        .init(id: "s3", name: "사이드 레터럴 레이즈", part: "어깨", equip: "덤벨"),
        .init(id: "s4", name: "아놀드 프레스", part: "어깨", equip: "덤벨"),
        .init(id: "s5", name: "페이스 풀", part: "어깨", equip: "케이블"),
        .init(id: "s6", name: "리어 델트 플라이", part: "어깨", equip: "머신"),
        // 하체
        .init(id: "l1", name: "바벨 스쿼트", part: "하체", equip: "바벨"),
        .init(id: "l2", name: "루마니안 데드리프트", part: "하체", equip: "바벨"),
        .init(id: "l3", name: "레그 프레스", part: "하체", equip: "머신"),
        .init(id: "l4", name: "레그 익스텐션", part: "하체", equip: "머신"),
        .init(id: "l5", name: "레그 컬", part: "하체", equip: "머신"),
        .init(id: "l6", name: "핵 스쿼트", part: "하체", equip: "머신"),
        .init(id: "l7", name: "덤벨 런지", part: "하체", equip: "덤벨"),
        .init(id: "l8", name: "카프 레이즈", part: "하체", equip: "머신"),
        // 팔
        .init(id: "a1", name: "바벨 컬", part: "팔", equip: "바벨"),
        .init(id: "a2", name: "덤벨 컬", part: "팔", equip: "덤벨"),
        .init(id: "a3", name: "해머 컬", part: "팔", equip: "덤벨"),
        .init(id: "a4", name: "컨센트레이션 컬", part: "팔", equip: "덤벨"),
        .init(id: "a5", name: "케이블 푸시다운", part: "팔", equip: "케이블"),
        .init(id: "a6", name: "라잉 트라이셉스 익스텐션", part: "팔", equip: "바벨"),
        .init(id: "a7", name: "딥스(삼두)", part: "팔", equip: "맨몸"),
        // 복근
        .init(id: "ab1", name: "크런치", part: "복근", equip: "맨몸"),
        .init(id: "ab2", name: "행잉 레그 레이즈", part: "복근", equip: "맨몸"),
        .init(id: "ab3", name: "플랭크", part: "복근", equip: "맨몸"),
        .init(id: "ab4", name: "케이블 크런치", part: "복근", equip: "케이블"),
        // 엉덩이
        .init(id: "g1", name: "바벨 힙 쓰러스트", part: "엉덩이", equip: "바벨"),
        .init(id: "g2", name: "케이블 킥백", part: "엉덩이", equip: "케이블"),
        .init(id: "g3", name: "글루트 브릿지", part: "엉덩이", equip: "맨몸"),
    ]

    static func item(_ id: String) -> CatalogItem? { all.first { $0.id == id } }

    // ── Seed history (relative to today) ───────────────────────
    static func seedHistory() -> [WorkoutRecord] {
        func ex(_ id: String, _ kg: Double, _ reps: Int, _ n: Int) -> SessionExercise {
            let c = item(id)!
            return SessionExercise(exId: c.id, name: c.name, part: c.part, equip: c.equip,
                                   sets: (0..<n).map { _ in WorkoutSet(kg: kg, reps: reps, done: true) })
        }
        // (daysBack, durationSec, exercises)
        let plans: [(Int, Int, [SessionExercise])] = [
            (1, 3925, [ex("c1", 60, 10, 4), ex("c4", 22, 12, 3), ex("c7", 45, 15, 3), ex("a5", 25, 15, 3), ex("a7", 0, 11, 3)]),
            (3, 4510, [ex("b1", 100, 5, 4), ex("b6", 55, 12, 3), ex("b7", 50, 12, 3), ex("a2", 14, 12, 3), ex("a3", 16, 12, 3)]),
            (5, 3380, [ex("l1", 80, 8, 5), ex("l3", 140, 12, 4), ex("l4", 45, 15, 3), ex("l8", 60, 20, 3)]),
            (8, 2980, [ex("s1", 40, 8, 4), ex("s2", 18, 12, 3), ex("s3", 8, 15, 4), ex("s5", 20, 15, 3)]),
            (10, 3640, [ex("c2", 50, 8, 4), ex("c3", 28, 10, 3), ex("c8", 20, 15, 3), ex("c10", 0, 10, 3)]),
            (13, 4120, [ex("b1", 95, 5, 4), ex("b4", 26, 12, 3), ex("l1", 75, 8, 4), ex("l5", 40, 15, 3)]),
            (17, 3010, [ex("s2", 16, 12, 4), ex("s3", 8, 15, 3), ex("a1", 30, 10, 3), ex("a6", 25, 12, 3)]),
            (22, 3550, [ex("l1", 70, 8, 4), ex("g1", 80, 12, 4), ex("l4", 40, 15, 3), ex("l5", 35, 15, 3)]),
        ]
        let cal = Calendar(identifier: .gregorian)
        return plans.enumerated().map { (i, p) in
            let day = cal.date(byAdding: .day, value: -p.0, to: Date())!
            var comp = cal.dateComponents([.year, .month, .day], from: day)
            comp.hour = 19; comp.minute = 10
            let start = cal.date(from: comp) ?? day
            return WorkoutRecord(id: "seed_\(i)", date: DateKey.ymd(day),
                                 startTs: start.timeIntervalSince1970, durationSec: p.1, exercises: p.2)
        }
    }

    // ── Seed routines ──────────────────────────────────────────
    static func seedRoutines() -> [Routine] {
        func ex(_ id: String, _ kg: Double, _ reps: Int, _ n: Int) -> SessionExercise {
            let c = item(id)!
            return SessionExercise(exId: c.id, name: c.name, part: c.part, equip: c.equip,
                                   sets: (0..<n).map { _ in WorkoutSet(kg: kg, reps: reps, done: false) })
        }
        return [
            Routine(id: "r_seed_chest", name: "가슴·삼두 루틴",
                    exercises: [ex("c1", 60, 10, 4), ex("c4", 22, 12, 3), ex("c7", 45, 15, 3), ex("a5", 25, 15, 3)]),
            Routine(id: "r_seed_back", name: "등·이두 루틴",
                    exercises: [ex("b1", 100, 5, 4), ex("b6", 55, 12, 3), ex("b7", 50, 12, 3), ex("a2", 14, 12, 3)]),
            Routine(id: "r_seed_leg", name: "하체 루틴",
                    exercises: [ex("l1", 80, 8, 5), ex("l3", 140, 12, 4), ex("l4", 45, 15, 3), ex("l8", 60, 20, 3)]),
        ]
    }

    // ── Stats aggregation ──────────────────────────────────────
    static func partVolumeStats(_ history: [WorkoutRecord], days: Int) -> [(part: String, vol: Double)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Calendar.current.startOfDay(for: Date()))!
        var totals: [String: Double] = [:]
        for r in history where DateKey.date(r.date) >= cutoff {
            for e in r.exercises where e.equip != "맨몸" {
                let v = e.sets.reduce(0.0) { $0 + $1.kg * Double($1.reps) }
                totals[e.part, default: 0] += v
            }
        }
        return parts.map { (part: $0, vol: totals[$0] ?? 0) }.filter { $0.vol > 0 }.sorted { $0.vol > $1.vol }
    }

    static func weeklyVolume(_ history: [WorkoutRecord], weeks: Int) -> [(label: String, vol: Double)] {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 1
        let now = Date()
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        var out: [(String, Double)] = []
        for i in stride(from: weeks - 1, through: 0, by: -1) {
            let start = cal.date(byAdding: .day, value: -i * 7, to: weekStart)!
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            var vol = 0.0
            for r in history {
                let d = DateKey.date(r.date)
                if d >= start && d < end { vol += recordVolume(r.exercises) }
            }
            let c = cal.dateComponents([.month, .day], from: start)
            out.append(("\(c.month!)/\(c.day!)", vol))
        }
        return out
    }
}
