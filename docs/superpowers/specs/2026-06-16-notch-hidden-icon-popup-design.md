# 노치에 가려진 메뉴바 아이콘 팝업 접근 — 설계

- 작성일: 2026-06-16
- 상태: 승인 대기

## 배경 / 문제

Bartidy는 chevron(`<`)과 divider(`│`) 두 개의 status item으로 메뉴바 아이콘을 화면 밖으로 밀어내 숨기는 앱이다(Hidden Bar 패턴).

노치가 있는 맥북에서는 별도의 문제가 있다: status 아이콘이 많으면 일부가 **노치 뒤로 가려져 마우스로 클릭할 수 없다.** chevron으로 펼쳐도(아이콘을 화면에 복귀시켜도) 노치 뒤에 들어간 아이콘은 여전히 클릭 불가다.

사용자가 원하는 흐름:
1. 평소엔 chevron으로 접어둔다(기존 동작).
2. 가끔 잘 안 쓰는 메뉴바 앱을 써야 할 때 chevron으로 펼친다(기존 동작).
3. 펼친 상태에서 divider(`│`)를 클릭하면 **노치에 가려진 앱 목록**이 팝업으로 뜨고, 항목을 선택하면 그 앱의 메뉴가 열린다(신규).

## 검증 결과 (스파이크)

`/tmp/axpress_spike.swift`로 핵심 가정을 실측했다(throwaway).

| 항목 | 결과 |
|---|---|
| `AXExtrasMenuBar`로 타 앱 status item 열거 | ✅ 거의 모든 앱 잡힘 |
| 각 item의 `AXPress` 액션 지원 | ✅ 전부 지원 |
| 보이는 상태에서 AXPress → 메뉴 열림 | ✅ |
| **노치 뒤(화면 안) 아이콘 → AXPress → 메뉴 노치 아래 표시** | ✅ 핵심 해결 확인 |
| 완전히 화면 밖(y≈1117)으로 숨긴 아이콘 → AXPress | ❌ 메뉴 화면 밖에 떠서 안 보임 |

핵심 사실:
- **AXPress는 좌표와 무관하게 동작한다.** 노치 뒤라 마우스로 못 누르는 아이콘도 AXPress로 누를 수 있다.
- **메뉴는 아이콘의 실제 화면 위치에 뜬다.** 따라서 아이콘이 화면 안(노치 뒤 포함)에 있어야 메뉴가 보인다. 완전히 화면 밖이면 안 보인다.
- 따라서 팝업은 **펼친 상태(아이콘이 화면 안)에서만** 의미가 있다.
- AXPress가 `-25204`(kAXErrorCannotComplete)를 반환해도 실제로는 메뉴가 열린다(메뉴 모달 트래킹으로 완료 보고를 못 함). **반환 코드는 무시한다.**

실측 환경 좌표 예시(화면 width=1728, 노치 구간 x=771~956, status 정상영역 x=956~1728):
- 노치 뒤(가려짐): Tailscale 790, Docker 822, Teams 867, Defender 903, Claude 941
- 정상(보임): Shottr 987, RunCat 1086, 카카오톡 1311 등

## 설계

### 사용자 워크플로우

```
평소:   [chevron 접음] → 아이콘 화면 밖, 메뉴바 깔끔        (기존)
사용 시: [chevron 펼침] → 아이콘 복귀(일부 노치 뒤로 가려짐)  (기존)
        [divider 클릭] → 노치에 가려진 앱 팝업 → 선택 → AXPress → 메뉴 열림  (신규)
```

자동 펼침/재숨김은 하지 않는다. 펼침/접음은 사용자가 chevron으로 직접 제어한다.

### 컴포넌트

**1. 변경 없음**
- chevron toggle, divider Cmd-드래그, 우클릭 메뉴(Settings/Update/Quit) 유지.

**2. divider 클릭 핸들러** (`ControlItem.swift`)
- divider 버튼에 target/action 추가. 현재 `appearsDisabled = true`인 시각 구분자를 클릭 가능하게 한다(시각적으로는 여전히 옅게 보이도록 유지).
- `state == .showItems`(펼친 상태)일 때만 팝업을 연다. `.hideItems`(접힌 상태)에서는 클릭을 무시한다 — 접힌 상태에선 divider가 `expanded`(10000px)라 클릭 영역이 비정상적으로 크고, 아이콘이 화면 밖이라 팝업 자체가 무의미하다.
- 좌클릭만 처리(우클릭은 기존 chevron 메뉴와 혼동 방지를 위해 동작 없음 또는 chevron 메뉴 재사용 — 후자는 후순위).

**3. 노치 가려짐 열거 서비스** (신규 파일, 예: `Services/HiddenItemScanner.swift`)
- `AXIsProcessTrusted()`로 권한 확인.
- `NSWorkspace.shared.runningApplications` 순회 → 각 앱의 `AXUIElementCreateApplication(pid)` → `AXExtrasMenuBar` → children(status item).
- 각 item의 `kAXPositionAttribute`(x좌표)를 읽어 **노치에 가려졌는지** 판정(아래).
- 가려진 항목을 `(앱 이름, 앱 아이콘 NSImage, AXUIElement)`로 수집. 순회 중 `NSRunningApplication`을 알고 있으므로 이름·아이콘은 거기서 얻는다.
- Bartidy 자신의 chevron/divider, Spotlight/제어센터 등은 제외(기존 `shouldSkipApplication` 로직 참고).

**4. 노치 가려짐 판정**
- 노치 오른쪽 경계 = `NSScreen.main.auxiliaryTopRightArea?.minX` (macOS 12+).
- status item의 x좌표가 이 경계보다 **작고**(노치에 걸침/뒤), 화면 안(y가 메뉴바 높이 범위, x ≥ 0)이면 "가려짐"으로 본다.
- `auxiliaryTopRightArea`가 nil(노치 없는 외장 모니터 등)이면 가려진 항목 없음 → 팝업은 빈 상태 안내를 보여준다.
- 완전 화면 밖(y가 메뉴바 밖, 예: y≈1117)인 항목은 제외(AXPress해도 메뉴 안 보임).

**5. 팝업 UI** (신규 SwiftUI 뷰, 예: `Views/HiddenItemsPopover.swift`)
- divider 버튼에 앵커된 `NSPopover`. divider가 노치 오른쪽(보이는 영역)에 있으므로 팝업도 보이는 위치에 뜬다.
- 가려진 앱들을 아이콘 + 이름 행 리스트로 표시.
- 행 클릭 → 해당 `AXUIElement`에 `AXUIElementPerformAction(item, kAXPressAction)`. 반환 코드 무시. 팝업은 닫는다.
- 빈 상태: "노치에 가려진 아이콘이 없습니다" 안내.

**6. 권한 처리**
- divider 클릭 시 `AXIsProcessTrusted()`가 false면, 팝업 대신 권한 안내(시스템 설정 열기 버튼 `AXIsProcessTrustedWithOptions` prompt)를 보여준다.

### 미사용 코드 정리

새 AX 기반 설계로 대체되므로 다음을 제거한다(현재 `ControlItem`과 연결되지 않은 죽은 코드):
- `Services/MenuBarService.swift` (CGWindowList 방식) — 권한 체크 로직(`AXIsProcessTrusted`/`AXIsProcessTrustedWithOptions`)만 신규 서비스로 이전
- `Views/MenuBarPopoverView.swift`
- `ViewModels/MenuBarViewModel.swift`
- `Views/Components/MenuBarIconRow.swift`
- `Models/MenuBarIcon.swift`

> 이 정리는 본 기능 구현에 직접 관련된다(같은 책임을 새 코드가 대체). 무관한 리팩토링은 하지 않는다.

### 엣지 케이스 / 에러 처리

- 권한 없음 → 권한 안내.
- 노치 없는 디스플레이 → 빈 상태 안내.
- 가려진 항목 0개 → 빈 상태 안내.
- AXPress 실패 코드 → 무시(정상 동작 케이스 포함).
- 접힌 상태에서 divider 클릭 → 무시.

### 테스트

- **단위 테스트**: 노치 판정 로직 — 좌표(x, y) + 노치 경계 입력 → 가려짐 여부 출력. 경계값(노치 경계 정확히, 화면 밖 y) 포함.
- **수동 통합 검증 체크리스트**(실 환경 필요):
  1. 펼친 상태에서 divider 클릭 → 팝업에 노치 뒤 앱들이 뜬다.
  2. 항목 선택 → 해당 앱 메뉴가 노치 아래에 열린다.
  3. 접힌 상태에서 divider 클릭 → 아무 일도 없다.
  4. 권한 없는 상태 → 권한 안내가 뜬다.

## 리스크 / 미해결

- `auxiliaryTopRightArea` 기반 노치 경계는 macOS 12+ 한정. 앱 최소 타깃이 macOS 13+이므로 문제 없음(README 기준).
- status item 폭(width)을 AX로 정확히 얻기 어려우면 x좌표만으로 판정한다. 경계에 걸친 아이콘(예: 일부만 가려짐)은 포함 쪽으로 처리한다(빠뜨리는 것보다 낫다).
- 일부 앱의 status item이 `AXExtrasMenuBar`에 안 잡힐 가능성(스파이크에선 거의 다 잡혔으나 100%는 아님). 안 잡히면 팝업에 안 나타난다 — 알려진 한계로 둔다.
