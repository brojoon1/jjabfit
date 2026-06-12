# JjabFit — iOS 운동 기록 앱 (SwiftUI)

번핏 스타일 다크모드 운동 기록 앱. `design/` 폴더의 React/JSX 디자인 레퍼런스를 SwiftUI 네이티브로 재현했습니다.

## 열기 / 빌드 (Mac + Xcode 필요)

1. macOS에서 `JjabFit/JjabFit.xcodeproj`를 Xcode 16 이상으로 엽니다.
2. 상단에서 시뮬레이터(예: iPhone 15)를 선택하고 ⌘R 로 실행합니다.
3. 서명: 처음 실기기에 올릴 때 Signing & Capabilities에서 본인 Team을 선택하세요.
   (시뮬레이터 실행은 서명 없이 가능합니다.)

> 프로젝트는 Xcode 16의 **file-system-synchronized group** 형식이라, `JjabFit/JjabFit/`
> 폴더에 Swift 파일을 추가하면 자동으로 타깃에 포함됩니다.
> 최소 지원: **iOS 16.0**.

## 적용된 요청사항

- **휴식 타이머 알림음: 남은 3·2·1초에 각 1회, 총 3번** (10초 알림음은 제거).
  `RestTimerView.swift` 참고.
- **맨몸(bodyweight) 운동은 볼륨 계산에서 제외.** `Models.swift`의 `sessionVolume`/`recordVolume` 참고.

## 핵심 플로우

1. 홈 → "오늘 운동 시작하기" → 운동 추가(부위/도구별 필터) → 세션 진입(첫 운동 시작 시 운동 시간 측정 시작)
2. 세트 kg·횟수 입력 → 완료 체크 → 휴식 타이머 자동 시작(3·2·1 beep)
3. "완료" → 요약(시간·볼륨·세트·운동수) → 기록 저장
4. 홈 "운동 불러오기" → 과거 운동(최신순) → 날짜 선택 → 상세 → "오늘 운동으로 불러오기"(전체 복사)
5. 캘린더에서 운동 완료일 확인 → 날짜 클릭 → 그날 상세

## 파일 구성 (`JjabFit/JjabFit/`)

| 파일 | 역할 |
|---|---|
| `JjabFitApp.swift` | 앱 진입점 |
| `Theme.swift` | 디자인 토큰(색상/반경/부위색) |
| `Models.swift` | 데이터 모델 + 세션 계산 + 날짜/포맷 헬퍼 |
| `Catalog.swift` | 운동 카탈로그(46종) + 시드 기록/루틴 + 통계 집계 |
| `Beeper.swift` | 합성 beep 톤(AVAudioEngine) + 햅틱 |
| `AppModel.swift` | 루트 상태(세션 생명주기/영속화/라우팅) |
| `Components.swift` | 공용 UI(버튼/칩/스탯/헤더/시트) |
| `RootView.swift` | 탭 셸 + 오버레이 라우팅 |
| `HomeView.swift` | 홈(시작/불러오기/루틴/주간/최근) |
| `ExercisePickerView.swift` | 운동 추가(부위·도구 필터, 검색) |
| `WorkoutSessionView.swift` | 운동 세션(타이머/운동카드/세트행) |
| `RestTimerView.swift` | 휴식 타이머(3·2·1 beep) + 휴식시간 선택 |
| `NumPadView.swift` | kg/횟수 입력 키패드 |
| `SummaryView.swift` | 운동 완료 요약 |
| `HistoryViews.swift` | 운동 불러오기 목록 + 상세(보기/불러오기) |
| `CalendarView.swift` | 월간 캘린더(완료일 표시) |
| `StatsView.swift` | 통계 + 1RM 계산기 + 루틴 저장 시트 |

## 저장소

기록/루틴은 `UserDefaults`(JSON 인코딩)에 저장됩니다. 첫 실행 시 데모용 시드 데이터가 채워집니다.
실제 출시 시 SwiftData/CoreData 등으로 교체를 권장합니다.
