# Bartidy MVP - 메뉴바 아이콘 숨기기 기능

## Context

### Original Request
macOS 메뉴바 정리 앱 (Bartender 5 클론) MVP 개발. 서드파티 앱 아이콘(MS Defender, Shottr 등)을 숨기거나 접을 수 있는 기능 구현.

### Interview Summary
**Key Discussions**:
- 3단계 아이콘 상태: 항상 표시 / 접기 (토글) / 완전 숨김
- 접기: 평소엔 숨김, 클릭하면 보임
- 완전 숨김: 절대 안 보임
- 라이선스: 100% 직접 개발 (오픈소스 참고 없이 Apple 공식 API만 사용)
- 수익화 고려: 나중에 프리미엄 모델 가능하도록 비공개 코드 유지

**Research Findings**:
- Accessibility API (`AXUIElement`)로 메뉴바 아이콘 감지 및 위치 조작 가능
- 시스템 아이콘(Control Center, 시계)은 제어 불가, 서드파티만 가능
- 실제 "숨김"은 아이콘을 화면 밖으로 이동시키는 방식

---

## Work Objectives

### Core Objective
사용자가 메뉴바 아이콘을 3단계로 관리(항상 표시/접기/완전 숨김)할 수 있는 MVP 앱 완성

### Concrete Deliverables
- `MenuBarIcon.swift`: 아이콘 모델 (visibility 상태 포함)
- `MenuBarService.swift`: Accessibility API로 아이콘 감지 서비스
- `IconVisibilityManager.swift`: 아이콘 숨기기/보이기 로직
- `SettingsStore.swift`: UserDefaults 설정 저장
- 업데이트된 UI: 아이콘별 상태 선택 가능

### Definition of Done
- [x] 앱 실행 시 Accessibility 권한 요청
- [x] 메뉴바의 서드파티 앱 아이콘 목록 표시
- [x] 각 아이콘에 대해 "항상 표시/접기/완전 숨김" 선택 가능
- [x] Bartidy 아이콘 클릭 시 "접기" 상태 아이콘 토글
- [x] 설정이 앱 재시작 후에도 유지됨
- [x] `xcodebuild -scheme Bartidy build` 성공

### Must Have
- Accessibility API를 통한 아이콘 감지
- 3단계 visibility 상태 관리
- 클릭으로 접힌 아이콘 토글
- 설정 영속성 (UserDefaults)

### Must NOT Have (Guardrails)
- 시스템 아이콘 제어 시도 (불가능하므로 범위 제외)
- 키보드 단축키 (MVP 이후)
- 프로필 기능 (MVP 이후)
- 스마트 트리거 (MVP 이후)
- 드래그앤드롭 순서 변경 (MVP 이후)

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO (새 프로젝트)
- **User wants tests**: Manual verification for MVP
- **Framework**: 추후 XCTest 추가 가능

### Manual QA Procedures
각 TODO 완료 후 Xcode에서 빌드 및 실행하여 수동 검증

---

## Task Flow

```
Task 1 (모델) → Task 2 (서비스) → Task 3 (매니저) → Task 4 (저장소)
                                                          ↓
Task 7 (통합 테스트) ← Task 6 (ViewModel) ← Task 5 (UI)
```

---

## TODOs

- [x] 1. MenuBarIcon 모델 업데이트

  **What to do**:
  - `IconVisibility` enum 추가: `alwaysShow`, `collapsed`, `alwaysHidden`
  - `MenuBarIcon` 구조체에 `visibility`, `position`, `size`, `ownerPID` 필드 추가
  - `displayName`, `systemImage` computed property 추가

  **Must NOT do**:
  - Codable 전체 구현 (설정 저장은 별도 Task)

  **Parallelizable**: NO (기반 모델)

  **References**:
  - `Bartidy/Models/MenuBarIcon.swift` - 현재 모델 파일

  **Acceptance Criteria**:
  - [ ] `IconVisibility` enum이 3가지 case 포함
  - [ ] `MenuBarIcon`이 position, size 정보 저장 가능
  - [ ] `xcodebuild -scheme Bartidy build` 성공

  **Commit**: YES
  - Message: `feat(model): add IconVisibility enum and update MenuBarIcon`
  - Files: `Bartidy/Models/MenuBarIcon.swift`

---

- [x] 2. MenuBarService 구현 (Accessibility API)

  **What to do**:
  - `Bartidy/Services/MenuBarService.swift` 파일 생성
  - `AXIsProcessTrusted()` 권한 확인 메서드
  - `AXIsProcessTrustedWithOptions()` 권한 요청 메서드
  - `AXUIElement` API로 실행 중인 앱의 메뉴바 아이콘 감지
  - 각 아이콘의 position, size, 앱 이름, bundle ID 추출

  **Must NOT do**:
  - 아이콘 위치 조작 (Task 3에서 구현)
  - UI 관련 코드

  **Parallelizable**: NO (Task 1 완료 필요)

  **References**:
  - Apple Documentation: `AXUIElement`, `AXUIElementCreateApplication`, `kAXExtrasMenuBarAttribute`
  - `Bartidy/ViewModels/MenuBarViewModel.swift:14` - 현재 `AXIsProcessTrusted()` 사용 위치

  **Acceptance Criteria**:
  - [ ] `MenuBarService.shared.isAccessibilityEnabled()` 호출 가능
  - [ ] Accessibility 권한 허용 후 `fetchMenuBarIcons()` 호출 시 아이콘 목록 반환
  - [ ] 반환된 아이콘에 appName, bundleIdentifier, position 포함
  - [ ] 빌드 성공

  **Commit**: YES
  - Message: `feat(service): implement MenuBarService with Accessibility API`
  - Files: `Bartidy/Services/MenuBarService.swift`

---

- [x] 3. IconVisibilityManager 구현 (숨기기/보이기 로직)

  **What to do**:
  - `Bartidy/Services/IconVisibilityManager.swift` 파일 생성
  - 아이콘 상태별 처리 로직:
    - `alwaysShow`: 원래 위치 유지
    - `collapsed`: 숨김 상태면 화면 밖으로 이동, 펼침 상태면 원래 위치
    - `alwaysHidden`: 항상 화면 밖으로 이동
  - `toggleCollapsed()`: 접힌 아이콘 토글 메서드
  - `applyVisibility()`: 모든 아이콘에 현재 설정 적용

  **Must NOT do**:
  - 시스템 아이콘 조작 시도
  - 애니메이션 (MVP 이후)

  **Parallelizable**: NO (Task 2 완료 필요)

  **References**:
  - `AXUIElementSetAttributeValue` - 위치 변경 API
  - `kAXPositionAttribute` - 위치 속성

  **Acceptance Criteria**:
  - [ ] `collapsed` 상태 아이콘이 토글 시 보임/숨김 전환
  - [ ] `alwaysHidden` 상태 아이콘이 항상 안 보임
  - [ ] `alwaysShow` 상태 아이콘이 항상 보임
  - [ ] 빌드 성공

  **Commit**: YES
  - Message: `feat(service): implement IconVisibilityManager for hiding/showing icons`
  - Files: `Bartidy/Services/IconVisibilityManager.swift`

---

- [x] 4. SettingsStore 구현 (설정 저장)

  **What to do**:
  - `Bartidy/Services/SettingsStore.swift` 파일 생성
  - `UserDefaults`를 사용한 아이콘별 visibility 설정 저장
  - 앱 시작 시 저장된 설정 로드
  - 설정 변경 시 자동 저장

  **Must NOT do**:
  - iCloud 동기화 (MVP 이후)
  - 복잡한 마이그레이션 로직

  **Parallelizable**: YES (Task 2, 3과 병렬 가능)

  **References**:
  - `@AppStorage` 또는 `UserDefaults.standard`
  - JSON 인코딩으로 딕셔너리 저장: `[bundleId: IconVisibility.rawValue]`

  **Acceptance Criteria**:
  - [ ] 아이콘 visibility 변경 후 앱 종료 → 재시작해도 설정 유지
  - [ ] 새 아이콘은 기본값 `alwaysShow`로 표시
  - [ ] 빌드 성공

  **Commit**: YES
  - Message: `feat(service): implement SettingsStore for persisting icon visibility`
  - Files: `Bartidy/Services/SettingsStore.swift`

---

- [x] 5. 설정 UI 업데이트

  **What to do**:
  - `MenuBarIconRow.swift` 수정: visibility 선택 Picker 추가
  - `MenuBarPopoverView.swift` 수정: 토글 버튼 추가 (접힌 아이콘 펼치기)
  - 각 아이콘 옆에 상태 표시 아이콘 (eye, eye.slash 등)

  **Must NOT do**:
  - 복잡한 애니메이션
  - 드래그앤드롭

  **Parallelizable**: NO (Task 1 완료 필요)

  **References**:
  - `Bartidy/Views/Components/MenuBarIconRow.swift` - 현재 UI
  - `Bartidy/Views/MenuBarPopoverView.swift` - 팝오버 뷰
  - SwiftUI `Picker` 컴포넌트

  **Acceptance Criteria**:
  - [ ] 각 아이콘 행에 visibility 선택 Picker 표시
  - [ ] 선택 변경 시 즉시 반영
  - [ ] 빌드 성공

  **Commit**: YES
  - Message: `feat(ui): add visibility picker to MenuBarIconRow`
  - Files: `Bartidy/Views/Components/MenuBarIconRow.swift`, `Bartidy/Views/MenuBarPopoverView.swift`

---

- [x] 6. MenuBarViewModel 통합

  **What to do**:
  - `MenuBarService`, `IconVisibilityManager`, `SettingsStore` 통합
  - 앱 시작 시 아이콘 감지 및 저장된 설정 적용
  - visibility 변경 시 즉시 적용 및 저장
  - 토글 버튼 동작 연결

  **Must NOT do**:
  - 백그라운드 폴링 (MVP는 수동 새로고침)

  **Parallelizable**: NO (Task 2, 3, 4, 5 완료 필요)

  **References**:
  - `Bartidy/ViewModels/MenuBarViewModel.swift` - 현재 ViewModel

  **Acceptance Criteria**:
  - [ ] 앱 실행 시 메뉴바 아이콘 목록 자동 로드
  - [ ] visibility 변경 시 메뉴바에 즉시 반영
  - [ ] 토글 버튼으로 collapsed 아이콘 펼치기/접기 동작
  - [ ] 빌드 성공

  **Commit**: YES
  - Message: `feat(viewmodel): integrate services into MenuBarViewModel`
  - Files: `Bartidy/ViewModels/MenuBarViewModel.swift`

---

- [x] 7. 빌드 및 수동 테스트

  **What to do**:
  - `xcodebuild -scheme Bartidy -configuration Debug build` 실행
  - 앱 실행하여 전체 플로우 테스트:
    1. Accessibility 권한 요청 확인
    2. 아이콘 목록 표시 확인
    3. visibility 변경 동작 확인
    4. 토글 동작 확인
    5. 앱 재시작 후 설정 유지 확인

  **Must NOT do**:
  - 자동화 테스트 작성 (MVP 이후)

  **Parallelizable**: NO (모든 Task 완료 필요)

  **References**:
  - AGENTS.md - 빌드 명령어

  **Acceptance Criteria**:
  - [ ] 빌드 성공 (에러 0개)
  - [ ] MS Defender, Shottr 등 서드파티 아이콘 감지됨
  - [ ] "완전 숨김" 설정 시 해당 아이콘 메뉴바에서 사라짐
  - [ ] "접기" 설정 후 토글 버튼으로 보임/숨김 전환됨
  - [ ] 앱 재시작 후에도 설정 유지됨

  **Commit**: NO (테스트만)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `feat(model): add IconVisibility enum and update MenuBarIcon` | MenuBarIcon.swift | build |
| 2 | `feat(service): implement MenuBarService with Accessibility API` | MenuBarService.swift | build |
| 3 | `feat(service): implement IconVisibilityManager` | IconVisibilityManager.swift | build |
| 4 | `feat(service): implement SettingsStore` | SettingsStore.swift | build |
| 5 | `feat(ui): add visibility picker to MenuBarIconRow` | MenuBarIconRow.swift, MenuBarPopoverView.swift | build |
| 6 | `feat(viewmodel): integrate services into MenuBarViewModel` | MenuBarViewModel.swift | build |

---

## Success Criteria

### Verification Commands
```bash
xcodebuild -scheme Bartidy -configuration Debug build
# Expected: ** BUILD SUCCEEDED **

open ~/Library/Developer/Xcode/DerivedData/Bartidy-*/Build/Products/Debug/Bartidy.app
# Expected: 앱 실행, 메뉴바에 Bartidy 아이콘 표시
```

### Final Checklist
- [x] 서드파티 앱 아이콘 감지 및 목록 표시
- [x] 3단계 visibility 선택 가능
- [x] "완전 숨김" 아이콘이 메뉴바에서 안 보임
- [x] "접기" 아이콘이 토글로 보임/숨김 전환
- [x] 설정이 앱 재시작 후에도 유지
- [x] 빌드 성공, 크래시 없음
