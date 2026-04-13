# Kohips CarLog v2.0 — PRD (Product Requirements Document)

## 1. 제품 비전

**한 줄 요약**: 법인/개인사업자를 위한 국세청 운행기록부 자동화 플랫폼

차량 이동을 자동 감지하고, 법적 효력이 있는 운행일지를 생성하며,
법인 내 다수 차량을 예약·공유·관리할 수 있는 B2B SaaS.

---

## 2. 문제 정의

| 문제 | 현재 상태 |
|------|-----------|
| 운행기록부 미작성 시 연 1,500만원 초과 차량비용 전액 부인 | 대부분 수기 엑셀 작성, 누락 빈번 |
| 법인 차량 다수 운용 시 누가 어떤 차를 쓰는지 파악 어려움 | 카톡/구두 예약, 이중 예약 발생 |
| 주행 후 기록 잊음 | 사후 기록은 세무조사 시 신뢰성 문제 |

---

## 3. 타겟 사용자

| 페르소나 | 설명 |
|----------|------|
| **관리자 (Admin)** | 법인 대표/총무. 전체 차량·직원 관리, 운행기록 취합, 세무 제출 |
| **직원 (Member)** | 법인 소속. 차량 예약, 본인 운행 기록, 분류 |
| **개인사업자** | 1인 사업자. 본인 차량 운행기록 자동화 |

---

## 4. 국세청 운행기록부 법적 요건

### 4.1 근거법령
- 법인세법 시행규칙 **별지 제84호의2 서식** (업무용승용차 운행기록부)
- 법인세법 시행규칙 **별지 제84호의3 서식** (업무용승용차 관련 비용 명세서)

### 4.2 필수 기재 항목

| # | 필드명 | 설명 | 데이터 소스 |
|---|--------|------|-------------|
| 1 | **운행일자** | 운행 날짜 | 자동 (GPS 시작 시각) |
| 2 | **운행목적** | 업무 내용 기술 | 사용자 입력 / 분류 |
| 3 | **출발지** | 출발 주소 | 자동 (역지오코딩) |
| 4 | **도착지** | 도착 주소 | 자동 (역지오코딩) |
| 5 | **주행 전 계기판 거리(km)** | 출발 시 누적 주행거리 | 블루투스 OBD / 수동 입력 |
| 6 | **주행 후 계기판 거리(km)** | 도착 시 누적 주행거리 | 블루투스 OBD / 수동 입력 |
| 7 | **주행거리(km)** | 구간 주행거리 | 자동 계산 (GPS / OBD 차이) |
| 8 | **업무용 사용거리** | 업무 목적 주행 km | 분류에 따라 자동 배분 |
| 9 | **사적 사용거리** | 개인 목적 주행 km | 분류에 따라 자동 배분 |
| 10 | **비고** | 메모 | 사용자 입력 |

### 4.3 연간 집계 항목
- 차량번호, 차종
- 총 주행거리, 업무용 사용비율 (%)
- 차량 관련 비용 합계 (별지 제84호의3)

### 4.4 보관 요건
- **5년 보관** (신고기한 다음 날부터)
- 디지털 기록 허용, 단 **출력 가능** 해야 함
- 세무조사 시 원본 데이터 제출 가능해야 함

---

## 5. 정보 구조 (IA) & 탭 네비게이션

```
[홈] — [운행이력] — [차량예약] — [마이페이지] — [검색]
```

### 5.1 홈 (Home)
- 현재 운행 상태 카드 (녹화 중이면 라이브 맵 + 거리)
- 오늘 운행 요약 (건수, 총 km, 업무용 비율)
- 미분류 운행 알림 배너 → 탭하면 빠른 분류
- 이번 달 업무용 비율 게이지
- 연결된 차량 상태 (블루투스 연결 여부)

### 5.2 운행이력 (Trip History)
- 월별 캘린더 뷰 + 리스트 뷰 토글
- 필터: 기간, 차량, 목적(업무/개인/출퇴근), 상태(미분류/분류완료)
- 각 기록 탭 → 상세 편집 (목적, 메모, 출발지/도착지 수정)
- 일괄 분류 기능

### 5.3 차량예약 (Vehicle Reservation)
- 법인 차량 목록 (차량번호, 차종, 현재 상태)
- 캘린더 기반 예약 UI (시간 슬롯)
- 예약 충돌 감지 → 대안 시간 제안
- 예약 승인/거절 (관리자)
- 현재 사용 중인 차량 표시

### 5.4 마이페이지 (My Page)
- 프로필 (이름, 소속 법인, 역할)
- 내 차량 목록 (주로 운용하는 차량 관리)
- 내보내기 (국세청 서식 CSV/PDF)
  - 기간 선택 → 별지 제84호의2 양식으로 출력
  - 별지 제84호의3 비용 명세서 생성
- 블루투스 기기 관리
- 알림 설정
- 로그아웃

### 5.5 검색 (Search)
- 운행 기록 전문 검색 (주소, 메모, 날짜)
- 차량번호로 검색
- 직원 이름으로 검색 (관리자)

---

## 6. 핵심 기능 상세

### 6.1 자동 운행 감지 & 푸시 제안

**현재 문제**: 운행 완료 후 알림이 와도, 사용자가 적극적으로 기록을 확인하지 않음.

**개선 플로우**:
```
[차량 이동 감지] → [자동 GPS 기록 시작]
       ↓
[이동 종료 감지] → [운행 데이터 임시 저장]
       ↓
[Rich Push Notification]
  "강남역 → 판교역, 32.5km 주행 완료"
  [업무용으로 기록] [개인용] [나중에 분류]
       ↓
[탭 → 상세 편집 화면] or [버튼 → 즉시 분류]
```

**변경점**:
- 알림에 출발지→도착지, 거리 정보를 포함 (Rich Notification)
- "기록으로 저장" 개념 → 모든 감지된 이동은 자동 저장, 분류만 제안
- 미분류 기록 24시간 경과 시 리마인더 재발송
- 홈 화면에 미분류 배너 상시 노출

### 6.2 계정 체계

```
Enterprise (법인)
├── Admin (관리자) — 1명 이상
│   └── 차량 등록/삭제, 직원 초대, 전체 기록 조회, 내보내기
├── Member (직원) — N명
│   └── 본인 기록만 조회, 할당된 차량 예약, 분류
└── Vehicles (차량) — M대
    └── 차량번호, 차종, 연식, OBD 연결 정보
```

**개인사업자 모드**: Enterprise 생성 없이 단독 사용 가능. 본인 = Admin + Member.

### 6.3 차량 관리

| 필드 | 설명 |
|------|------|
| 차량번호 | 예: 12가 3456 |
| 차종 | 브랜드 + 모델 (예: 현대 아반떼) |
| 연식 | 최초등록일 |
| 취득가액 | 감가상각 계산용 |
| 보험 정보 | 임직원 전용 보험 여부 (세무 요건) |
| OBD 기기 ID | 블루투스 페어링 정보 |
| 누적 주행거리 | OBD 또는 수동 입력 |

**차량-운행 매칭**:
1. 블루투스 OBD 연결 시 → 자동으로 해당 차량에 기록
2. 미연결 시 → 운행 종료 후 "어떤 차량으로 이동했나요?" 선택 제안
3. 최근 사용 차량 우선 표시

### 6.4 블루투스 OBD 연결

**목적**:
- 실제 계기판 km 수 연동 (국세청 요건: 주행 전/후 계기판 거리)
- 차량 자동 식별
- 엔진 ON/OFF 기반 정확한 운행 시작/종료 감지

**지원 프로토콜**: ELM327 호환 OBD-II 어댑터 (BLE)

**연결 플로우**:
```
[마이페이지 > 블루투스 기기 관리]
  → 스캔 → 기기 선택 → 차량 매핑
  → 이후 자동 연결 시도
```

**데이터 수집**:
- PID 01 0C: RPM (엔진 가동 감지)
- PID 01 0D: Vehicle Speed
- PID 01 A6: Odometer (지원 차량)
- 미지원 차량: GPS 거리 + 수동 계기판 입력 폴백

### 6.5 차량 예약 시스템

**예약 생성**:
- 날짜, 시작/종료 시간, 목적(간단 메모)
- 캘린더에서 빈 시간 확인 후 탭
- 충돌 시 "이 시간에 [홍길동]님이 예약 중" 표시

**예약 상태**: 대기중 → 승인됨 → 사용중 → 반납완료

**관리자 기능**:
- 예약 승인/거절
- 강제 회수 (긴급 시)
- 차량별 사용 통계

### 6.6 인증 (Authentication)

| 방식 | 구현 |
|------|------|
| 카카오 로그인 | Kakao SDK |
| 네이버 로그인 | Naver Login SDK |
| 휴대폰 번호 | Firebase Auth (SMS OTP) |

**온보딩 플로우**:
```
[로그인/회원가입]
  → [법인 참여 or 개인사업자 모드 선택]
  → 법인: 초대코드 입력 or 새 법인 생성
  → [내 차량 등록 (선택)]
  → [블루투스 OBD 연결 (선택)]
  → [홈]
```

### 6.7 내보내기 (국세청 양식)

**별지 제84호의2 — 운행기록부**:
- 기간 선택 (월별/분기별/연간)
- 차량 선택
- 서식에 맞는 테이블 자동 생성
- PDF / CSV / Excel 다운로드
- 이메일 전송

**별지 제84호의3 — 비용 명세서**:
- 연간 차량별 비용 입력 (보험료, 유류비, 수리비, 감가상각비 등)
- 업무사용비율 자동 계산
- 공제 가능 금액 자동 산출

---

## 7. 디자인 시스템

### 7.1 참고 레퍼런스
- **Uber**: 카드 기반 UI, 맵 중심 홈, 깔끔한 bottom sheet
- **Spotify**: 대담한 타이포그래피, 다크 모드, 부드러운 전환 애니메이션

### 7.2 디자인 원칙

| 원칙 | 적용 |
|------|------|
| **정보 밀도 최소화** | 한 화면에 하나의 핵심 액션 |
| **카드 기반 레이아웃** | 운행 기록, 차량 정보 모두 카드로 표현 |
| **다크 모드 우선** | 운전 중 눈부심 방지, 라이트 모드도 지원 |
| **대담한 타이포** | SF Pro Display (iOS) / Pretendard (공통) |
| **컬러 시스템** | Primary: #1DB954 (활성), Neutral: #191414 (배경), Accent: #FF6B35 (주의) |
| **마이크로 인터랙션** | 분류 버튼 탭 시 햅틱 + 체크 애니메이션 |

### 7.3 탭바 아이콘

| 탭 | 아이콘 | 라벨 |
|----|--------|------|
| 홈 | house.fill | 홈 |
| 운행이력 | clock.arrow.circlepath | 운행이력 |
| 차량예약 | calendar.badge.plus | 차량예약 |
| 마이페이지 | person.crop.circle | 마이페이지 |
| 검색 | magnifyingglass | 검색 |

---

## 8. 데이터 모델 (v2.0)

### 8.1 User
```
id: UUID
name: String
phone: String
email: String?
authProvider: kakao | naver | phone
enterpriseId: UUID?        // null = 개인사업자
role: admin | member
createdAt: DateTime
```

### 8.2 Enterprise
```
id: UUID
name: String               // 법인명
businessNumber: String      // 사업자등록번호
inviteCode: String          // 6자리 초대코드
createdAt: DateTime
```

### 8.3 Vehicle
```
id: UUID
enterpriseId: UUID?         // null = 개인 차량
licensePlate: String        // 차량번호 (12가 3456)
model: String               // 차종
year: Int                   // 연식
acquisitionCost: Int?       // 취득가액
insuranceType: String?      // 보험 유형
obdDeviceId: String?        // BLE 기기 ID
currentOdometer: Double     // 현재 누적 km
createdAt: DateTime
```

### 8.4 Trip
```
id: UUID
userId: UUID
vehicleId: UUID?
enterpriseId: UUID?
date: Date                  // 운행일자
purpose: business | commute | personal | unclassified
purposeDetail: String?      // 운행목적 상세 (예: "거래처 미팅")
startAddress: String        // 출발지
endAddress: String          // 도착지
odometerBefore: Double?     // 주행 전 계기판 (km)
odometerAfter: Double?      // 주행 후 계기판 (km)
distanceKm: Double          // 주행거리
startTime: DateTime
endTime: DateTime?
coordinatesData: Data       // GPS 경로
memo: String?               // 비고
status: recording | pending | classified
createdAt: DateTime
```

### 8.5 Reservation
```
id: UUID
vehicleId: UUID
userId: UUID
enterpriseId: UUID
startTime: DateTime
endTime: DateTime
purpose: String?
status: pending | approved | in_use | returned | rejected
approvedBy: UUID?
createdAt: DateTime
```

---

## 9. 기술 스택

### 9.1 모바일 (v2.0)

| 항목 | iOS | Android |
|------|-----|---------|
| UI | SwiftUI | Jetpack Compose |
| 로컬 DB | SwiftData | Room |
| DI | Swift native | Hilt |
| 네트워크 | URLSession + async/await | Retrofit + Coroutines |
| 인증 | Kakao SDK, Naver SDK, Firebase Auth | 동일 |
| 블루투스 | CoreBluetooth | Android BLE API |
| 위치 | CoreLocation | Fused Location Provider |
| 모션 | CoreMotion | Activity Recognition API |
| 푸시 | APNs + Firebase Cloud Messaging | FCM |

### 9.2 백엔드 (신규)

| 항목 | 선택 |
|------|------|
| API | FastAPI (Python) |
| DB | PostgreSQL |
| Auth | Firebase Auth (토큰 검증) |
| Storage | Firebase Storage (영수증 이미지 등) |
| 푸시 | Firebase Cloud Messaging |
| 배포 | Google Cloud Run |
| 실시간 | WebSocket (차량 예약 상태) |

---

## 10. 개발 우선순위 (Phase)

### Phase 1 — MVP (현재 앱 개선)
> 목표: 기존 앱을 국세청 양식 완전 준수 + UX 개선

1. Trip 모델에 국세청 필수 필드 추가 (odometerBefore/After, purposeDetail)
2. 새 탭바 구조 적용 (5탭)
3. 홈 화면 신규 (운행 상태 카드, 미분류 배너, 월간 요약)
4. Rich Push Notification (출발지→도착지, 거리 포함)
5. 미분류 24시간 리마인더
6. 국세청 별지 제84호의2 PDF 내보내기
7. 디자인 시스템 적용 (다크 모드, 카드 UI)

### Phase 2 — 계정 & 차량
> 목표: 멀티유저, 멀티차량 지원

1. 백엔드 API 구축 (FastAPI)
2. 인증 (카카오/네이버/전화번호)
3. Enterprise/User/Vehicle 모델
4. 차량 등록 및 관리
5. 차량-운행 매칭 (수동 선택)
6. 데이터 클라우드 동기화

### Phase 3 — 차량 예약 & 블루투스
> 목표: B2B 핵심 기능 완성

1. 차량 예약 캘린더 UI
2. 예약 승인/거절 워크플로우
3. 블루투스 OBD 연결
4. 계기판 자동 연동
5. 엔진 ON/OFF 기반 운행 감지
6. 검색 기능

### Phase 4 — 고도화
1. 별지 제84호의3 비용 명세서
2. 차량별 비용 관리 (유류비, 보험료 등)
3. 관리자 대시보드 (웹)
4. 업무사용비율 자동 계산 및 절세 리포트
5. 다중 법인 지원

---

## 11. 성공 지표

| 지표 | 목표 |
|------|------|
| 운행 자동 감지율 | > 95% |
| 운행 완료 후 24시간 내 분류율 | > 80% |
| 국세청 서식 정합성 | 100% (별지 84-2 필수항목 전수 충족) |
| 차량 예약 충돌율 | < 5% |

---

## 12. 제약사항 & 리스크

| 리스크 | 대응 |
|--------|------|
| iOS 백그라운드 제한 (Core Motion 15분 제한) | BGTaskScheduler + Significant Location Change 병행 |
| OBD-II 차량 호환성 | ELM327 표준만 지원, 미지원 차량은 GPS + 수동 입력 폴백 |
| 세법 변경 | 서식 필드를 설정 기반으로 관리, 업데이트 용이하게 설계 |
| 위치 정보 개인정보보호법 | 수집 동의, 최소 수집, 암호화 저장, 보관 기간 명시 |
