# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**코힙스 차계부 (Kohips CarLog)** — iOS 차량 주행 기록 앱.
Core Motion으로 주행을 자동 감지하고, GPS로 경로를 기록하며, 업무용/개인용으로 분류해 국세청 양식으로 내보냅니다.

## 빌드 및 실행

Xcode에서 프로젝트를 열고 실기기(iPhone)에서 실행해야 합니다.
- 시뮬레이터: Core Motion (CMMotionActivityManager) 미지원 → 실기기 필수
- Deployment Target: iOS 17.0 (SwiftData, `@Bindable` 요구)
- Bundle ID: `com.kohipstech.carlog`

## 아키텍처

```
KohipsCarLog/
├── KohipsCarLogApp.swift      # @main, AppDelegate (BGTaskScheduler), ModelContainer
├── Models/
│   ├── Trip.swift             # SwiftData @Model, TripPurpose/TripStatus enum
│   └── Vehicle.swift          # SwiftData @Model 차량 관리
├── Services/
│   ├── TripDetector.swift     # @MainActor singleton — Core Motion + GPS + 가속도 기반 감지
│   ├── NotificationManager.swift  # UNUserNotificationCenter, 알림 액션
│   └── NTSExportService.swift # 국세청 양식 CSV/PDF 내보내기
├── Theme/
│   └── KohipsTheme.swift      # 디자인 시스템 (색상, 타이포, 간격)
├── ViewModels/
│   └── TripViewModel.swift    # ObservableObject, TripDetector + 센서 상태 래핑
└── Views/
    ├── MainView.swift         # 탭 컨테이너 (MainViewWithContext)
    ├── HomeView.swift         # 홈 대시보드
    ├── TripHistoryView.swift  # 운행이력 (캘린더/리스트, 일간·주간·월간 그룹)
    ├── TripDetailMapView.swift # 지도 기반 운행 상세 (경로 + 편집)
    ├── MyPageView.swift       # 마이페이지 (차량, 내보내기, 설정)
    ├── SearchView.swift       # 전체 검색 오버레이
    ├── TripListView.swift     # 주행 목록 (legacy)
    ├── PendingClassifyView.swift  # 미분류 주행 분류 화면
    └── ExportView.swift       # CSV 내보내기 (legacy)
```

## 핵심 로직

**주행 감지 흐름** (`TripDetector.swift`):
1. Strategy 1: `CMMotionActivityManager` → `automotive` 활동 감지 (1분 임계)
2. Strategy 2: GPS 속도 기반 — 8m/s 이상 30초 유지 시 주행 시작, 2분 정지 시 종료
3. 두 전략 병행 (CMMotionActivity가 없어도 GPS 속도로 감지)
4. `beginTrip()` → 첫 위치 수신 시 역지오코딩 → 좌표 저장
5. `finalizeTrip()` → 역지오코딩 + 알림 + 좌표 Data 저장
6. 0.5km 미만 자동 감지 주행은 자동 삭제 (수동은 유지)
7. `SensorStatus` 구조체로 센서/권한 상태 실시간 제공

**알림 액션** (`NotificationManager.swift`):
- 카테고리 `TRIP_ENDED`에 "✅ 업무용" / "❌ 개인용" 액션 버튼
- 탭 → `.openTripDetail`, 버튼 → `.quickClassifyBusiness` / `.quickClassifyPersonal` NotificationCenter 포스팅

**뷰 진입점**: `KohipsCarLogApp`의 `WindowGroup`이 `MainView`를 렌더링하고, `MainView`는 Environment에서 `ModelContext`를 꺼내 `MainViewWithContext`에 주입합니다.

## 권한 (Info.plist)

| 권한 | 용도 |
|---|---|
| `NSLocationAlwaysAndWhenInUseUsageDescription` | 백그라운드 주행 자동 감지 |
| `NSMotionUsageDescription` | CMMotionActivityManager |
| `UIBackgroundModes` | `location`, `fetch`, `processing` |
| `BGTaskSchedulerPermittedIdentifiers` | `com.kohipstech.carlog.refresh` |

## 데이터 모델

`Trip` (@Model):
- `purposeRaw: String` / `statusRaw: String` — enum을 String으로 저장 (SwiftData 제약)
- `coordinatesData: Data` — `[CoordCodable]` JSON 인코딩
- `status`: recording → pending → classified 순서
