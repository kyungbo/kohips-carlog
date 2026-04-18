# Kohips CarLog — Cross-Platform Specification v1.0

> iOS 코드베이스(`~/kohips-carlog`)를 기준으로 안드로이드 등 다른 플랫폼에서 동일한 앱을 구현하기 위한 상세 스펙.
> 2026-04-18 기준.

---

## 1. 제품 개요

| 항목 | 내용 |
|---|---|
| 앱 이름 | 코힙스 차계부 (Kohips CarLog) |
| 목적 | 차량 주행 자동 감지 → 업무/개인 분류 → 국세청 운행기록부(별지 84-2) 내보내기 |
| 대상 사용자 | 개인사업자, 법인 차량 사용자 |
| 언어 | 한국어 (ko) |
| 다크모드 | 기본값 dark, light/system 전환 가능 |

---

## 2. 디자인 시스템

### 2.1 색상 (Hex)

#### Core Colors (모드 무관)
| Token | Hex | 용도 |
|---|---|---|
| `primary` | `#1DB954` | 메인 브랜드, CTA 버튼, 업무용 색상 |
| `primaryDark` | `#18993F` | primary hover/pressed |
| `accent` | `#FF6B35` | 미분류 배지, 경고 배너 |
| `destructive` | `#FF453A` | 삭제, 종료 버튼, 녹화 점 |

#### Purpose Colors (모드 무관)
| Token | Hex | 용도 |
|---|---|---|
| `business` | `#1DB954` | 업무(일반) 표시 |
| `commute` | `#5B86E5` | 출퇴근 표시 |
| `personal` | `#8E8E93` | 개인 표시 |
| `unclassified` | `#FF6B35` | 미분류 표시 |

#### Dark Mode
| Token | Hex | 용도 |
|---|---|---|
| `background` | `#121212` | 앱 배경 |
| `surface` | `#1E1E1E` | 카드, 리스트 아이템 배경 |
| `surfaceElevated` | `#2A2A2A` | TextField, 선택된 요소 배경 |
| `surfaceLight` | `#3A3A3A` | 게이지 트랙, 구분선 배경 |
| `textPrimary` | `#FFFFFF` | 제목, 주요 텍스트 |
| `textSecondary` | `#A0A0A0` | 부제목, 보조 정보 |
| `textTertiary` | `#6B6B6B` | 비활성 텍스트, 힌트 |
| `separator` | `white @ 8% alpha` | 구분선 |

#### Light Mode
| Token | Hex | 용도 |
|---|---|---|
| `background` | `#F2F2F7` | 앱 배경 |
| `surface` | `#FFFFFF` | 카드, 리스트 아이템 배경 |
| `surfaceElevated` | `#F0F0F5` | TextField, 선택된 요소 배경 |
| `surfaceLight` | `#E5E5EA` | 게이지 트랙, 구분선 배경 |
| `textPrimary` | `#1C1C1E` | 제목, 주요 텍스트 |
| `textSecondary` | `#6B6B6B` | 부제목, 보조 정보 |
| `textTertiary` | `#A0A0A0` | 비활성 텍스트, 힌트 |
| `separator` | `black @ 8% alpha` | 구분선 |

### 2.2 타이포그래피

시스템 폰트 사용 (iOS: SF Pro, Android: Roboto/Google Sans).

| Token | Size | Weight | Design | 용도 |
|---|---|---|---|---|
| `largeTitle` | 26sp | Bold | Rounded | 사용 안 함 (예비) |
| `title` | 20sp | Bold | Rounded | 화면 제목, 큰 숫자 |
| `headline` | 16sp | SemiBold | Default | 섹션 제목, 카드 제목 |
| `body` | 15sp | Regular | Default | 본문 텍스트 |
| `callout` | 14sp | Medium | Default | 버튼, 리스트 아이템 제목 |
| `caption` | 13sp | Regular | Default | 보조 설명 |
| `small` | 11sp | Medium | Default | 배지, 날짜/시간 |

### 2.3 아이콘

시스템 아이콘 사용 (iOS: SF Symbols, Android: Material Icons).

| Token | Size | Weight | 용도 |
|---|---|---|---|
| `iconSmall` | 14dp | Medium | 인라인 아이콘 |
| `icon` | 16dp | Medium | 일반 아이콘 |
| `iconLarge` | 20dp | Regular | 카드 내 아이콘 |
| `iconXL` | 28dp | Regular | 프로필, 설정 아이콘 |
| `iconHero` | 40dp | Regular | 빈 상태, 검색 |

### 2.4 간격 (dp/pt)

| Token | Value | 용도 |
|---|---|---|
| `cardPadding` | 20 | KohipsCard 내부 padding |
| `sectionSpacing` | 12 | 섹션 간 간격 |
| `contentHorizontal` | 20 | 화면 좌우 margin |
| `componentInner` | 14 | 컴포넌트 내부 간격 |
| `chipVertical` | 8 | 필터 칩 세로 padding |
| `chipHorizontal` | 14 | 필터 칩 가로 padding |
| `badgeVertical` | 5 | 목적 배지 세로 padding |
| `badgeHorizontal` | 10 | 목적 배지 가로 padding |

### 2.5 공통 컴포넌트

#### KohipsCard
- padding: 기본 20dp (커스텀 가능)
- background: `surface`
- cornerRadius: 16dp (continuous/superellipse)
- 그림자 없음 (배경색 대비로 구분)

#### Purpose Badge (목적 표시)
- font: `small`
- foreground: 해당 purpose 색상
- background: 해당 purpose 색상 @ 12% alpha
- shape: Capsule (pill)
- padding: H=10, V=5

#### Purpose Color Indicator (리스트 좌측)
- 너비 4dp, 높이 40dp
- cornerRadius: 3dp
- 색상: purpose에 따라 `business`/`commute`/`personal`/`unclassified`

#### Filter Chip
- font: `callout`
- 활성: foreground=white, background=color
- 비활성: foreground=`textSecondary`, background=`surface`, border=`separator` 1dp
- shape: Capsule
- padding: H=16, V=8

---

## 3. 데이터 모델

### 3.1 Trip

| 필드 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `id` | UUID | auto | PK |
| `startTime` | DateTime | now | 주행 시작 시각 |
| `endTime` | DateTime? | null | 주행 종료 시각 |
| `startAddress` | String | "" | 출발지 주소 (역지오코딩) |
| `endAddress` | String | "" | 도착지 주소 (역지오코딩) |
| `distanceKm` | Double | 0 | 총 주행거리 (km) |
| `purposeRaw` | String | "unclassified" | TripPurpose enum rawValue |
| `statusRaw` | String | "recording" | TripStatus enum rawValue |
| `coordinatesData` | Blob/JSON | [] | `[{lat, lng}]` JSON 인코딩 |
| `memo` | String | "" | 사용자 메모 |
| `receiptImageData` | Blob? | null | (Phase 2) 영수증 이미지 |
| `createdAt` | DateTime | now | 생성일 |
| `vehicleId` | UUID? | null | 연결된 차량 ID |
| `purposeDetail` | String? | null | 운행 목적 상세 (예: "거래처 미팅") |
| `odometerBefore` | Double? | null | 주행 전 계기판 (km) |
| `odometerAfter` | Double? | null | 주행 후 계기판 (km) |

#### Computed Properties
- `purpose`: `purposeRaw` → `TripPurpose` enum 변환
- `status`: `statusRaw` → `TripStatus` enum 변환
- `coordinates`: `coordinatesData` JSON → `[{lat, lng}]` 디코딩
- `businessDistanceKm`: `purpose.isBusiness ? distanceKm : 0`
- `personalDistanceKm`: `purpose.isBusiness ? 0 : distanceKm`
- `durationFormatted`: endTime이 없으면 "기록 중…", 있으면 "X시간 Y분" (음수 방지: `max(0, seconds)`)

### 3.2 Vehicle

| 필드 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `id` | UUID | auto | PK |
| `licensePlate` | String | - | 차량번호 (예: "12가 3456") |
| `model` | String | - | 차종 (예: "현대 아반떼") |
| `year` | Int | - | 연식 |
| `currentOdometer` | Double | 0 | 현재 누적 주행거리 (km) |
| `createdAt` | DateTime | now | 등록일 |

### 3.3 Enums

#### TripPurpose
| rawValue | 라벨 | isBusiness |
|---|---|---|
| `"unclassified"` | 미분류 | false |
| `"business_general"` | 업무 (일반) | true |
| `"commute"` | 출퇴근 | **true** (법인세법 시행령 §50의2) |
| `"personal"` | 개인 | false |

#### TripStatus
| rawValue | 설명 |
|---|---|
| `"recording"` | 현재 주행 기록 중 |
| `"pending"` | 종료됨, 분류 대기 |
| `"classified"` | 분류 완료 |

---

## 4. 주행 감지 알고리즘

### 4.1 이중 전략 병행

두 전략을 **동시에** 실행하여 신뢰성 확보.

#### Strategy 1: 모션 활동 감지
- **iOS**: `CMMotionActivityManager.startActivityUpdates`
- **Android**: `ActivityRecognitionClient` (IN_VEHICLE transition)

**시작 조건:**
1. `automotive` 활동 감지 (confidence != low)
2. 1분(60초) 이상 지속
3. **GPS 속도 크로스체크**: 현재 속도 >= 2.0 m/s (정지 상태 오감지 방지)
→ 세 조건 모두 충족 시 `beginTrip()` 호출

**종료 조건:**
1. `stationary` 또는 `walking` 활동 감지
2. **2분 디바운스**: 연속 2분 이상 비차량 활동이 지속되어야 종료 (일시적 walking 오분류 방지)
→ `finalizeTrip()` 호출

**예외 처리:**
- `cycling`, `running`, `unknown` → 디바운스 타이머 리셋 (종료하지 않음)
- 수동 주행 중에는 모션 감지 무시

#### Strategy 2: GPS 속도 기반 감지
- 배터리 효율을 위해 비주행 시 `significantLocationChanges` 모드
- 주행 감지 시 정밀 GPS 모드로 전환

**시작 조건:**
1. GPS 속도 >= 8.0 m/s (~29 km/h)
2. 30초 이상 지속
→ `beginTrip()` 호출

**종료 조건:**
1. GPS 속도 < 2.0 m/s (거의 정지)
2. 2분(120초) 이상 지속
→ `finalizeTrip()` 호출

**중간 속도 (2.0~8.0 m/s):**
- 정지 타이머만 리셋, 시작 타이머는 유지하지 않음

### 4.2 Trip Lifecycle

#### `beginTrip(at: Date, address: String = "")`
1. **가드**: 이미 recording 중이면 무시, DB 컨텍스트 없으면 무시
2. Trip 객체 생성 → DB 삽입 → **즉시 저장** (크래시 대비)
3. GPS 모드 전환: `significantLocationChanges` → `startUpdatingLocation`
4. 현재 위치가 있으면 바로 역지오코딩 → `startAddress` 저장
5. 없으면 `pendingStartGeocode = true` → 첫 위치 수신 시 역지오코딩

#### 주행 중 GPS 업데이트
- 거리 누적: `location.distance(from: lastLocation)` (1000m 이상 점프는 필터)
- 좌표 수집: `collectedCoords` 배열에 append
- `distanceKm` 실시간 업데이트

#### `finalizeTrip(trip: Trip)`
1. **타이머 리셋**: `automotiveStartTime`, `speedDetectionStart`, `nonAutomotiveStart` 모두 nil
2. `endTime = now`, `distanceKm = totalDistance / 1000`, `status = .pending`
3. 좌표 데이터 JSON 인코딩 → `coordinatesData` 저장
4. **자동 감지 + 0.5km 미만**: Trip 삭제 (수동은 유지)
5. DB 저장
6. 알림 발송 (주행 완료 + 24시간 미분류 리마인더)
7. 도착지 역지오코딩 (비동기, 삭제된 trip 체크 필수)
8. GPS 모드 전환: `stopUpdatingLocation` → `significantLocationChanges` 복원

### 4.3 역지오코딩 (주소 변환)

- **공유 인스턴스** 사용 (매번 새 객체 생성 금지 — 요청 제한 방지)
- 한국 주소 형식: `locality(시/도) + subLocality(구/동) + thoroughfare(도로명)`
- 실패 시: `"주소 불명"`
- 위치 없음: `"위치 확인 중…"`

### 4.4 GPS 설정

| 설정 | 값 | 이유 |
|---|---|---|
| accuracy | Best | 주행 경로 정확도 |
| distanceFilter | 10m | 불필요한 업데이트 감소 |
| activityType | automotiveNavigation | iOS 최적화 |
| allowsBackgroundUpdates | true | 백그라운드 주행 |
| pausesAutomatically | false | 시스템 임의 중단 방지 |

---

## 5. 화면 구조

### 5.1 탭 구조

3개 탭 + 글로벌 검색 오버레이

| 탭 | 아이콘 | 라벨 | 뱃지 |
|---|---|---|---|
| 홈 | `house.fill` / `home` | 홈 | - |
| 운행이력 | `clock.arrow.circlepath` / `history` | 운행이력 | 미분류 건수 |
| 마이페이지 | `person.crop.circle` / `account_circle` | 마이페이지 | - |

TabBar tint: `primary`

---

### 5.2 홈 (HomeView)

**Navigation Title**: "Kohips" (font: `title`)

**레이아웃** (ScrollView, padding H=20):

1. **검색 바** (SearchBar)
   - 탭 시 글로벌 검색 오버레이 열림
   - placeholder: "주소, 메모, 날짜 검색"
   - background: `surface`, cornerRadius: 12
   - 아이콘: `magnifyingglass`, 색상: `textTertiary`

2. **주행 상태 카드** (TripStatusCard)
   - 센서/권한 경고 배너 (조건부):
     - 위치 권한 없음: icon `location.slash.fill`, 색상 `destructive`, "위치 권한이 필요합니다…"
     - 모션 센서 없음: icon `sensor.fill`, 색상 `accent`, "모션 센서를 사용할 수 없습니다…"
     - 모션 권한 거부: icon `figure.walk`, 색상 `accent`, "모션 권한이 거부되었습니다…"
     - 탭 시 앱 설정 열기
   - **주행 중 상태** (isRecording):
     - 빨간 점 (pulsing animation: opacity 0.3↔1.0, 0.8초 주기)
     - "주행 기록 중" (`headline`)
     - 종료 버튼: "종료", background `destructive`, white text, Capsule
     - 출발지 주소 (또는 "위치 확인 중…")
     - 현재 거리 + 소요시간
   - **대기 상태**:
     - "주행 대기 중" (`headline`)
     - 센서 OK: "차량 이동 감지 시 자동 기록" / 센서 없음: "수동 기록 버튼을 눌러 시작하세요"
     - 수동 기록 버튼: `record.circle` 아이콘 (40dp), 색상 `primary`

3. **미분류 배너** (UnclassifiedBanner) — `pendingTrips` > 0 일 때만
   - 좌측: 원형 아이콘 (`exclamationmark.circle.fill`, `accent`)
   - "미분류 주행 N건" + "탭하여 분류하세요"
   - background: `accent @ 8%`, border: `accent @ 20%`
   - 탭 → 운행이력 탭으로 전환

4. **오늘 운행 요약** (TripSummaryCard)
   - title: "오늘 운행" (`caption`)
   - 3-column: 건수 / 총 km / 업무용 % (font: `title`)
   - KohipsCard 래핑

5. **이번 달 업무용 비율 게이지** (BusinessRatioGauge)
   - 원형 게이지: 지름 68dp, 트랙 `surfaceLight` 8dp, fill `primary` 8dp, round cap
   - 중앙: "XX%" (`headline`)
   - 우측: title, "업무용 비율", 설명 텍스트
   - 설명 로직: >=80% "높은 업무 사용률", >=50% "적절한", >0% "낮습니다", 0% "기록 없음"

6. **빈 상태** (allTrips 비어있을 때) — recentTrips 대신 표시
   - car.fill 아이콘 (44dp), `textTertiary`
   - "아직 운행 기록이 없습니다" (`headline`)
   - "주행이 자동으로 감지되거나,\n수동 기록 버튼으로 시작할 수 있습니다" (`body`, center)

7. **최근 운행** (recentTripsSection) — allTrips가 있을 때
   - 헤더: "최근 운행" + "전체보기" (→ 운행이력 탭)
   - 최대 5건 표시
   - 각 row:
     - 좌측: Purpose Color Indicator (4x40dp)
     - 출발지 → 도착지 (lineLimit 1)
     - 날짜 | 거리 | 소요시간 (`small`, `textSecondary`)
     - 우측: Purpose Badge
     - background: `surface`, cornerRadius: 14, padding V=12 H=16
     - 탭 → TripDetailMapView (sheet)

---

### 5.3 운행이력 (TripHistoryView)

**Navigation Title**: "운행이력"

**레이아웃:**

1. **필터 바** (가로 스크롤)
   - Chips: 전체 | 미분류(accent) | 업무(business) | 출퇴근(commute) | 개인(personal)
   - 활성 칩: 흰 텍스트 + 컬러 배경
   - 비활성 칩: `textSecondary` 텍스트 + `surface` 배경 + `separator` 보더
   - Haptic: light

2. **보기 모드** (Segmented Picker)
   - "캘린더" | "리스트"

3. **기간 선택** (리스트 모드에서만)
   - Segmented Picker: "일간" | "주간" | "월간"
   - Period Navigator: ← 이전 / 현재 기간 표시 / 다음 →
     - 현재(offset=0)이면 → 버튼 비활성 (`textTertiary`)
     - 일간: "2026년 4월 18일 (금)"
     - 주간: "2026년 4/14 ~ 4/20"
     - 월간: "2026년 4월"
   - `periodMode` 변경 시 offset 0으로 리셋

4. **캘린더 뷰** (calendar 모드)
   - KohipsCard 래핑, "2026년 4월" 제목
   - 7-column grid (일~토)
   - 날짜 셀:
     - 하단: 운행 있으면 dot (미분류→accent, 그 외→primary)
     - 선택됨: background `primary`, 흰 텍스트, cornerRadius 10
   - 하단: 선택 날짜의 trip 리스트 (없으면 "운행 기록 없음")

5. **그룹 리스트 뷰** (list 모드)
   - **Period Summary Card**: 총 운행 건수 | 총 거리 | 업무용 % | 미분류 건수
   - 빈 상태: ContentUnavailableView "운행 기록 없음"
   - Day Group (주간/월간에서만 헤더 표시):
     - "4월 18일 (금)" + "3건 · 15.2 km"
   - Trip Row: 홈의 최근 운행 row와 동일한 디자인
     - 다중 선택 모드: 좌측에 체크박스
     - 탭 → TripDetailMapView (sheet)

6. **일괄 분류 바** (다중 선택 시 하단 표시)
   - "N건 선택" + 업무/출퇴근/개인 버튼 (Capsule, 각 purpose 색상)
   - background: `.ultraThinMaterial`
   - animation: spring(0.3), move(bottom)+opacity

7. **선택 모드 토글**: 우상단 "선택"/"완료" 버튼

---

### 5.4 운행 상세 (TripDetailMapView) — Sheet/BottomSheet

**Navigation Title**: "운행 상세" (inline)
**완료 버튼**: 우상단, 탭 시 `saveChanges()` + dismiss

**레이아웃** (ScrollView):

1. **지도 섹션** (height: 300dp)
   - 좌표 2개 이상: MapView + 경로 폴리라인 (primary, 4dp) + 출발 마커 (원형) + 도착 마커 (깃발)
   - 좌표 없음: "경로 데이터 없음" placeholder
   - **카메라 초기화**: 좌표 bounds 계산, 1.4배 확대 + 0.005 padding

2. **경로 요약 카드** (routeSummaryCard)
   - 좌측: 출발 dot → 점선 → 도착 깃발 (수직 배치)
   - 출발지/도착지: 탭하면 편집 모드 (TextField)
   - 빈 주소: "주소 없음" 표시

3. **운행 정보 카드** (tripInfoCard)
   - Row 1: 주행거리 (road.lanes, primary) | 소요시간 (clock)
   - 구분선
   - Row 2: 운행일자 (calendar) | 시간 "HH:mm ~ HH:mm"

4. **운행 분류 카드** (classificationCard)
   - 제목: "운행 분류"
   - 3개 버튼: 업무(일반) / 출퇴근 / 개인
     - 선택됨: 흰 텍스트 + purpose 색상 배경
     - 미선택: purpose 색상 텍스트 + 12% 배경
     - maxWidth, cornerRadius 10
   - 업무용 선택 시: "업무 목적 상세" TextField (예: "거래처 미팅")

5. **계기판 카드** (odometerCard)
   - 제목: "계기판 (국세청 양식)"
   - 2-column: "주행 전 (km)" / "주행 후 (km)"
   - decimalPad 키보드

6. **비고** (memoCard)
   - TextField, axis: vertical, lineLimit 3~6
   - placeholder: "메모를 입력하세요"

7. **삭제 버튼**
   - "이 운행 기록 삭제" (trash 아이콘)
   - foreground: `destructive`, background: `destructive @ 10%`
   - **동작**: dismiss 먼저 → 0.5초 후 삭제 (크래시 방지)

**자동 저장**: `onDisappear` 시 `saveChanges()` 호출 (삭제된 trip이면 무시)

---

### 5.5 마이페이지 (MyPageView)

**Navigation Title**: "마이페이지"

**레이아웃** (ScrollView, padding H=20):

1. **프로필 카드**
   - 아바타: 원형 56dp, `primary @ 15%` 배경, `person.fill` 아이콘
   - "개인사업자 모드" + "로그인하여 법인 기능을 사용하세요"
   - 우측 chevron

2. **내 차량 섹션**
   - 차량 없음: "등록된 차량이 없습니다" + car.fill 아이콘
   - 차량 row:
     - 좌측: car.fill 아이콘 (44dp box)
     - 차량번호 (`headline`) + "차종 (연식)" (`caption`)
     - 우측: 주행거리 "XXX km"
     - **삭제**: 길게 누르기(context menu) → "삭제"
   - "차량 추가" 버튼: plus.circle.fill + "차량 추가", primary 색상, dashed-style border

3. **차량 추가 시트** (AddVehicleSheet)
   - Form: 차량번호 / 차종 / 연식(Picker) / 현재 주행거리
   - 취소 / 추가 버튼 (번호+차종 비어있으면 비활성)

4. **차량예약 (Phase 2 placeholder)**
   - calendar.badge.clock 아이콘, `commute` 색상
   - "법인 차량 예약" + "Phase 2에서 법인 계정 연동과 함께 추가됩니다"

5. **국세청 내보내기 섹션**
   - 기간 선택: 년(2024~2030 Picker) + 월(1~12 Picker)
   - 차량 선택: "전체" 또는 특정 차량 (vehicles 있을 때만)
   - 대상 건수 표시: "N건"
   - 버튼 2개: "CSV" (doc.text) / "PDF (별지 84-2)" (doc.richtext)
   - trips 비어있으면 버튼 비활성

6. **설정 섹션**
   - 화면 모드: 다크/라이트/시스템 Picker
   - OBD-II 블루투스: "Phase 3" (비활성)
   - 앱 버전: "2.0.0"

---

### 5.6 글로벌 검색 (SearchOverlay)

화면 전체를 덮는 오버레이 (transition: 위에서 내려옴 + opacity).

1. **검색 헤더**
   - TextField + x 버튼 + "취소" 버튼
   - 300ms debounce 후 검색 실행
   - autoFocus on appear

2. **검색 전**: 최근 주소 목록 (최대 8개, 중복 제거)
3. **결과 없음**: "'{query}'에 대한 결과가 없습니다"
4. **결과 있음**: "N건의 결과" + Trip Row 리스트
   - 탭 → TripDetailMapView (sheet)

**검색 대상**: startAddress, endAddress, memo, purposeDetail, 날짜(yyyy-MM-dd)

---

## 6. 알림

### 6.1 주행 완료 알림

| 항목 | 값 |
|---|---|
| 타이밍 | `finalizeTrip()` 직후 (1초 delay) |
| 제목 | "주행 완료 🚗" |
| 본문 | "{출발지} → {도착지}, {X.X}km 주행 완료" (주소 없으면 "X.Xkm 주행을 업무용으로 등록할까요?") |
| 카테고리 | `TRIP_ENDED` |
| 액션 버튼 | "✅ 업무용" / "❌ 개인용" / "⏰ 나중에 분류" |

### 6.2 미분류 리마인더

| 항목 | 값 |
|---|---|
| 타이밍 | `finalizeTrip()` 후 24시간 |
| 제목 | "미분류 주행이 있어요" |
| 본문 | "{출발지} → {도착지} 주행을 아직 분류하지 않았어요." |
| 카테고리 | `TRIP_ENDED` (동일 액션) |

### 6.3 액션 처리

| 액션 | 동작 |
|---|---|
| 업무용 버튼 | `quickClassify(tripId, asBusiness: true)` → purpose = businessGeneral, status = classified, 리마인더 취소 |
| 개인용 버튼 | `quickClassify(tripId, asBusiness: false)` → purpose = personal, status = classified, 리마인더 취소 |
| 나중에 분류 | 무시 (24시간 리마인더 유지) |
| 알림 본문 탭 | 앱 열기 → trip 상세 (openTripDetail 이벤트) |

---

## 7. 국세청 내보내기 (NTS Export)

### 7.1 대상 데이터
- `status == .classified` 인 trip만 포함
- 년/월/차량 필터
- 시간순 정렬 (오름차순)

### 7.2 CSV (10-Column)

```
운행일자,운행목적,출발지,도착지,주행전계기판(km),주행후계기판(km),주행거리(km),업무용거리(km),사적거리(km),비고
# 차량번호: 12가3456, 차종: 현대 아반떼
2026-04-18,"거래처 미팅","서울특별시 역삼동 테헤란로","성남시 분당구 판교로",12345.0,12367.5,22.5,22.5,0.0,메모
합계,,,,,,100.0,80.0,20.0,업무사용비율: 80.0%
```

**CSV 필드 이스케이프 (RFC 4180)**:
- 쉼표, 큰따옴표, 줄바꿈이 포함된 필드 → `"필드"` 로 감싸기
- 내부 큰따옴표 → `""` 로 이스케이프
- **절대로 쉼표를 공백으로 치환하지 말 것** (주소 데이터 파괴)

### 7.3 PDF (별지 제84호의2)

- 페이지: A4 횡방향 (841.89 x 595.28 pt)
- 마진: 40pt
- 제목: "업무용승용차 운행기록부 [별지 제84호의2]" (bold 14pt)
- 부제: "기간: YYYY년 M월", "차량번호: XX, 차종: XX"
- 테이블: 10 컬럼 (운행일자 9%, 운행목적 14%, 출발지 13%, 도착지 13%, ...)
- 헤더: bold 8pt, `systemGray5` 배경
- 데이터: regular 8pt, 줄무늬 (white / 97% white)
- 합계행: bold, `systemGray5` 배경, 업무비율 표시
- 푸터: "※ 본 운행기록부는 법인세법 시행규칙 별지 제84호의2 서식에 준하여 작성되었습니다. | 코힙스 차계부 v2.0"
- **셀 텍스트**: 가운데 정렬, 줄바꿈 허용 (byWordWrapping)
- 페이지네이션: 페이지당 최대 행 수 자동 계산

### 7.4 파일 공유
- CSV: `YYYYMM_운행기록부.csv` → 시스템 공유 시트
- PDF: `YYYYMM_운행기록부.pdf` → 시스템 공유 시트

---

## 8. 비즈니스 규칙

| 규칙 | 설명 |
|---|---|
| 최소 거리 | 자동 감지 주행 0.5km 미만 → 자동 삭제 (수동은 유지) |
| 출퇴근 = 업무용 | 법인세법 시행령 §50의2 근거, `isBusiness = true` |
| GPS 점프 필터 | 연속 좌표 간 1000m 이상 차이 → 거리 누적 무시 |
| 역지오코딩 실패 | "주소 불명" 저장 |
| 역지오코딩 대기 | "위치 확인 중…" (위치 수신 전) |
| 분류 시 리마인더 취소 | 업무용/개인용 분류 → 24시간 리마인더 제거 |
| 내보내기 대상 | `classified` 상태만 (recording, pending 제외) |
| 다크모드 기본 | AppStorage "appColorScheme" = "dark" |

---

## 9. 권한

| 권한 | 용도 | 필수 |
|---|---|---|
| 위치 (항상) | 백그라운드 주행 자동 감지 + 역지오코딩 | Yes |
| 위치 (사용 중) | 포그라운드 GPS | Yes |
| 모션/활동 인식 | 차량 이동 감지 (CMMotionActivity / ActivityRecognition) | No (없으면 GPS only) |
| 알림 | 주행 완료, 미분류 리마인더 | Recommended |
| 백그라운드 실행 | 위치 업데이트, 주기적 새로고침 | Yes |

---

## 10. Haptic Feedback

| 상황 | 강도 |
|---|---|
| 필터 칩 탭 | Light |
| 수동 기록 시작 버튼 | Light |
| 주행 종료 버튼 | Medium |
| 분류 버튼 탭 | Medium |
| 일괄 분류 | Medium |

---

## 11. Phase 로드맵 (참고)

| Phase | 기능 |
|---|---|
| **Phase 1 (현재)** | 자동/수동 주행 감지, 업무/개인 분류, CSV/PDF 내보내기, 차량 관리 |
| Phase 2 | 법인 계정 연동, 차량 예약, 영수증 OCR |
| Phase 3 | OBD-II 블루투스 연동, 연비/DTC 분석 |
