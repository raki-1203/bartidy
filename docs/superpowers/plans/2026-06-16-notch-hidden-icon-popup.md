# 노치에 가려진 메뉴바 아이콘 팝업 접근 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bartidy를 펼친 상태에서 divider(`│`)를 클릭하면 노치에 가려진 메뉴바 앱 목록이 팝업으로 뜨고, 선택하면 AXPress로 그 앱 메뉴를 연다.

**Architecture:** chevron 숨김/펼침 동작은 그대로 둔다. divider 버튼에 클릭 핸들러를 추가하고, `AXExtrasMenuBar`로 타 앱 status item을 열거해 노치 오른쪽 경계(`auxiliaryTopRightArea.minX`)보다 왼쪽에 있는 것을 "가려짐"으로 판정한다. SwiftUI 팝업에서 항목을 선택하면 해당 `AXUIElement`에 `AXPress`를 보낸다. CGWindowList 기반 미사용 코드는 제거한다.

**Tech Stack:** Swift, AppKit, SwiftUI, Accessibility(AX) API, XCTest. Xcode 프로젝트(`Bartidy.xcodeproj`, scheme `Bartidy`).

---

## 사전 참고 (구현자 필독)

- **빌드 검증 명령** (네트워크로 Sparkle SPM을 받아야 함 — 이미 캐시돼 있어야 빠름):
  ```bash
  xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' build 2>&1 | tail -20
  ```
  Xcode GUI에서 `Cmd+B`로 빌드해도 된다.
- **테스트 실행 명령**:
  ```bash
  xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' test 2>&1 | tail -30
  ```
  Xcode GUI에서 `Cmd+U`로 실행해도 된다.
- **새 파일을 만들면 반드시 Xcode 프로젝트에 등록한다.** 이 프로젝트는 파일 시스템 동기화 그룹을 쓰지 않으므로, 디스크에 `.swift`를 만들기만 하면 빌드에 포함되지 않는다. 방법 둘 중 하나:
  - **(권장)** Xcode 프로젝트 네비게이터에서 해당 그룹을 우클릭 → "Add Files to Bartidy…" → 파일 선택 → 앱 코드는 **Bartidy** 타깃에, 테스트 코드는 **BartidyTests** 타깃에 체크.
  - (CLI) `Bartidy.xcodeproj/project.pbxproj`에 직접 등록: 각 파일마다 `PBXFileReference` 1개, `PBXBuildFile` 1개를 추가하고, 해당 그룹의 `children`과 타깃의 `Sources` 빌드 페이즈 `files`에 등록한다. 기존 항목(예: `ControlItem.swift`)의 4곳 등록 패턴을 그대로 따른다. ID는 기존과 충돌하지 않는 24자리 16진수를 새로 부여한다.
- **권한**: AXPress와 status item 열거에는 "손쉬운 사용(Accessibility)" 권한이 필요하다. 통합 검증 시 빌드한 Bartidy.app(또는 Xcode가 실행하는 앱)을 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에 추가해야 한다.

---

## File Structure

**생성:**
- `Bartidy/Services/NotchDetector.swift` — 순수 판정 로직(좌표 → 노치 가려짐 여부). 단위 테스트 대상.
- `Bartidy/Models/HiddenMenuItem.swift` — 팝업에 표시할 항목 모델(이름, 아이콘, AXUIElement).
- `Bartidy/Services/HiddenItemScanner.swift` — AX로 가려진 status item 열거 + 권한 확인 + AXPress 실행.
- `Bartidy/Views/HiddenItemsPopover.swift` — 가려진 앱 리스트 SwiftUI 팝업.
- `BartidyTests/NotchDetectorTests.swift` — NotchDetector 단위 테스트.

**수정:**
- `Bartidy/MenuBar/ControlItem.swift` — divider 클릭 핸들러, 팝업 표시, 권한 안내 추가.

**삭제 (미사용 죽은 코드):**
- `Bartidy/Services/MenuBarService.swift`
- `Bartidy/Views/MenuBarPopoverView.swift`
- `Bartidy/ViewModels/MenuBarViewModel.swift`
- `Bartidy/Views/Components/MenuBarIconRow.swift`
- `Bartidy/Models/MenuBarIcon.swift`

---

## Task 1: 미사용 죽은 코드 제거

이 5개 파일은 서로만 참조하고 `ControlItem`/`MenuBarManager`/`AppDelegate`와 연결되어 있지 않다. 통째로 제거해도 빌드가 깨지지 않는다. 먼저 정리해 깨끗한 상태에서 시작한다.

**Files:**
- Delete: `Bartidy/Services/MenuBarService.swift`
- Delete: `Bartidy/Views/MenuBarPopoverView.swift`
- Delete: `Bartidy/ViewModels/MenuBarViewModel.swift`
- Delete: `Bartidy/Views/Components/MenuBarIconRow.swift`
- Delete: `Bartidy/Models/MenuBarIcon.swift`

- [ ] **Step 1: 참조 없음을 재확인**

Run:
```bash
grep -rn "MenuBarService\|MenuBarPopoverView\|MenuBarViewModel\|MenuBarIconRow\|MenuBarIcon\b\|IconVisibility" Bartidy --include="*.swift" | grep -vE "Bartidy/Services/MenuBarService.swift|Bartidy/Views/MenuBarPopoverView.swift|Bartidy/ViewModels/MenuBarViewModel.swift|Bartidy/Views/Components/MenuBarIconRow.swift|Bartidy/Models/MenuBarIcon.swift"
```
Expected: 출력 없음(이 5개 파일 외에 참조가 없음). 출력이 있으면 그 참조를 먼저 확인하고, 본 계획 범위를 벗어나면 멈추고 보고한다.

- [ ] **Step 2: 파일 삭제 + Xcode 프로젝트에서 등록 해제**

디스크에서 5개 파일을 삭제하고, `Bartidy.xcodeproj/project.pbxproj`에서 각 파일의 `PBXFileReference`/`PBXBuildFile`/그룹 children/Sources 등록을 제거한다. (Xcode GUI: 네비게이터에서 5개 파일 선택 → Delete → "Move to Trash".)

Run (디스크 삭제):
```bash
rm Bartidy/Services/MenuBarService.swift Bartidy/Views/MenuBarPopoverView.swift Bartidy/ViewModels/MenuBarViewModel.swift Bartidy/Views/Components/MenuBarIconRow.swift Bartidy/Models/MenuBarIcon.swift
```

- [ ] **Step 3: 빌드해서 깨지지 않음 확인**

Run:
```bash
xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "refactor: 미사용 CGWindowList 기반 메뉴바 코드 제거"
```

---

## Task 2: 노치 가려짐 판정 로직 (TDD)

좌표만으로 판정하는 순수 로직. 테스트가 자연스럽다.

**Files:**
- Create: `Bartidy/Services/NotchDetector.swift`
- Test: `BartidyTests/NotchDetectorTests.swift`

- [ ] **Step 1: 실패하는 테스트 작성**

`BartidyTests/NotchDetectorTests.swift`:
```swift
import XCTest
@testable import Bartidy

final class NotchDetectorTests: XCTestCase {

    func test_노치왼쪽_메뉴바에_있으면_가려짐() {
        // Tailscale 실측값: x=790, y=4, 노치 오른쪽 경계=956
        XCTAssertTrue(NotchDetector.isHiddenBehindNotch(itemX: 790, itemY: 4, notchRightEdgeX: 956))
    }

    func test_노치오른쪽이면_보임() {
        // Shottr 실측값: x=987
        XCTAssertFalse(NotchDetector.isHiddenBehindNotch(itemX: 987, itemY: 4, notchRightEdgeX: 956))
    }

    func test_노치오른쪽경계와_같으면_보임() {
        XCTAssertFalse(NotchDetector.isHiddenBehindNotch(itemX: 956, itemY: 4, notchRightEdgeX: 956))
    }

    func test_경계_1px_왼쪽이면_가려짐() {
        XCTAssertTrue(NotchDetector.isHiddenBehindNotch(itemX: 955, itemY: 4, notchRightEdgeX: 956))
    }

    func test_화면밖_아래로_숨겨진것은_제외() {
        // chevron으로 화면 밖에 숨긴 항목 실측값: x=0, y=1117
        XCTAssertFalse(NotchDetector.isHiddenBehindNotch(itemX: 0, itemY: 1117, notchRightEdgeX: 956))
    }

    func test_음수_x는_제외() {
        XCTAssertFalse(NotchDetector.isHiddenBehindNotch(itemX: -5, itemY: 4, notchRightEdgeX: 956))
    }
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run:
```bash
xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' test 2>&1 | tail -30
```
Expected: 컴파일 실패 — `cannot find 'NotchDetector' in scope`.

> 참고: `@testable import Bartidy`가 실패하면(앱 타깃 testability 미설정) 멈추고 보고한다. Debug 빌드는 기본적으로 `ENABLE_TESTABILITY=YES`라 대개 동작한다.

- [ ] **Step 3: 최소 구현 작성**

`Bartidy/Services/NotchDetector.swift`:
```swift
//
//  NotchDetector.swift
//  Bartidy
//
//  status item의 화면 좌표로 "노치에 가려져 클릭할 수 없는지"를 판정한다.
//  좌표는 Accessibility API의 kAXPositionAttribute(화면 상단이 원점) 기준이다.
//

import CoreGraphics

enum NotchDetector {
    /// 메뉴바로 인정하는 최대 y. 이보다 크면 화면 밖(아래)으로 숨겨진 항목으로 본다.
    /// 메뉴바 높이는 약 24pt이며, chevron으로 숨긴 항목은 y가 1000 이상으로 찍힌다.
    static let menuBarMaxY: CGFloat = 24

    /// 아이콘이 노치에 가려져 마우스로 클릭할 수 없는 상태인지 판정한다.
    /// - Parameters:
    ///   - itemX: status item의 x좌표 (kAXPositionAttribute)
    ///   - itemY: status item의 y좌표 (kAXPositionAttribute)
    ///   - notchRightEdgeX: 노치 오른쪽 경계 = NSScreen.auxiliaryTopRightArea.minX
    /// - Returns: 노치에 가려졌으면 true
    static func isHiddenBehindNotch(
        itemX: CGFloat,
        itemY: CGFloat,
        notchRightEdgeX: CGFloat
    ) -> Bool {
        guard itemX >= 0 else { return false }          // 화면 왼쪽 밖
        guard itemY <= menuBarMaxY else { return false } // 화면 아래로 숨겨진 항목
        return itemX < notchRightEdgeX                   // 노치 오른쪽 경계보다 왼쪽 = 가려짐
    }
}
```

새 파일이므로 **Bartidy 타깃**과 **NotchDetectorTests.swift는 BartidyTests 타깃**에 등록한다(사전 참고 참조).

- [ ] **Step 4: 테스트 통과 확인**

Run:
```bash
xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' test 2>&1 | tail -30
```
Expected: `Test Suite 'NotchDetectorTests' passed`, 6개 테스트 통과.

- [ ] **Step 5: 커밋**

```bash
git add -A
git commit -m "feat: 노치 가려짐 판정 로직 추가"
```

---

## Task 3: 가려진 status item 열거 서비스

AX로 타 앱 status item을 순회하고 Task 2의 판정으로 필터링한다.

**Files:**
- Create: `Bartidy/Models/HiddenMenuItem.swift`
- Create: `Bartidy/Services/HiddenItemScanner.swift`

- [ ] **Step 1: 모델 작성**

`Bartidy/Models/HiddenMenuItem.swift`:
```swift
//
//  HiddenMenuItem.swift
//  Bartidy
//
//  노치에 가려진 메뉴바 status item 하나를 나타낸다.
//

import AppKit
import ApplicationServices

struct HiddenMenuItem: Identifiable {
    let id: String           // "\(pid)_\(index)"
    let appName: String
    let icon: NSImage?
    let axElement: AXUIElement
}
```

- [ ] **Step 2: 스캐너 작성**

`Bartidy/Services/HiddenItemScanner.swift`:
```swift
//
//  HiddenItemScanner.swift
//  Bartidy
//
//  Accessibility(AX)로 실행 중인 모든 앱의 메뉴바 status item을 열거하고,
//  노치에 가려진 항목만 골라낸다. 선택된 항목에 AXPress를 보낸다.
//

import AppKit
import ApplicationServices

final class HiddenItemScanner {
    static let shared = HiddenItemScanner()
    private init() {}

    // MARK: - 권한

    func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    func requestAccessibility() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - 열거

    /// 노치에 가려진 메뉴바 status item을 수집한다. 권한이 없거나 노치가 없으면 빈 배열.
    func scanHiddenItems() -> [HiddenMenuItem] {
        guard isAccessibilityTrusted() else { return [] }
        guard let screen = NSScreen.main,
              let notchRightEdgeX = screen.auxiliaryTopRightArea?.minX else {
            return []
        }

        var result: [HiddenMenuItem] = []

        for app in NSWorkspace.shared.runningApplications {
            guard let name = app.localizedName else { continue }
            if shouldSkip(app) { continue }

            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            guard let extrasRef = copyAttribute(axApp, "AXExtrasMenuBar") else { continue }
            let extras = extrasRef as! AXUIElement
            guard let childrenRef = copyAttribute(extras, kAXChildrenAttribute as String),
                  let children = childrenRef as? [AXUIElement] else { continue }

            for (index, item) in children.enumerated() {
                guard let point = copyPosition(item) else { continue }
                guard NotchDetector.isHiddenBehindNotch(
                    itemX: point.x,
                    itemY: point.y,
                    notchRightEdgeX: notchRightEdgeX
                ) else { continue }

                result.append(HiddenMenuItem(
                    id: "\(app.processIdentifier)_\(index)",
                    appName: name,
                    icon: app.icon,
                    axElement: item
                ))
            }
        }

        return result
    }

    // MARK: - 실행

    /// 해당 status item에 AXPress를 보내 메뉴를 연다.
    /// 메뉴가 열리며 -25204(kAXErrorCannotComplete)를 반환해도 정상 동작이므로 결과는 무시한다.
    func press(_ item: HiddenMenuItem) {
        _ = AXUIElementPerformAction(item.axElement, kAXPressAction as CFString)
    }

    // MARK: - Private

    private func shouldSkip(_ app: NSRunningApplication) -> Bool {
        let skipBundleIds: Set<String> = [
            "com.apple.controlcenter",
            "com.apple.Spotlight",
            "com.apple.notificationcenterui",
            Bundle.main.bundleIdentifier ?? "",   // Bartidy 자신
        ]
        return skipBundleIds.contains(app.bundleIdentifier ?? "")
    }

    private func copyAttribute(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return err == .success ? value : nil
    }

    private func copyPosition(_ element: AXUIElement) -> CGPoint? {
        guard let value = copyAttribute(element, kAXPositionAttribute as String) else { return nil }
        var point = CGPoint.zero
        if AXValueGetValue(value as! AXValue, .cgPoint, &point) { return point }
        return nil
    }
}
```

두 파일을 **Bartidy 타깃**에 등록한다.

- [ ] **Step 3: 빌드 확인**

Run:
```bash
xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "feat: 노치 가려진 status item 열거/AXPress 스캐너 추가"
```

---

## Task 4: 팝업 UI

가려진 앱 리스트를 보여주는 SwiftUI 뷰. 항목 클릭 시 콜백을 호출한다.

**Files:**
- Create: `Bartidy/Views/HiddenItemsPopover.swift`

- [ ] **Step 1: 뷰 작성**

`Bartidy/Views/HiddenItemsPopover.swift`:
```swift
//
//  HiddenItemsPopover.swift
//  Bartidy
//
//  노치에 가려진 메뉴바 앱 목록 팝업. 행을 클릭하면 onSelect 콜백을 호출한다.
//

import SwiftUI

struct HiddenItemsPopover: View {
    let items: [HiddenMenuItem]
    let onSelect: (HiddenMenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("노치에 가려진 아이콘")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

            if items.isEmpty {
                Text("노치에 가려진 아이콘이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        HStack(spacing: 8) {
                            if let icon = item.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            Text(item.appName)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 240)
        .padding(.bottom, 6)
    }
}
```

**Bartidy 타깃**에 등록한다.

- [ ] **Step 2: 빌드 확인**

Run:
```bash
xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add -A
git commit -m "feat: 노치 가려진 아이콘 팝업 뷰 추가"
```

---

## Task 5: divider 클릭 핸들러 연결

divider 버튼에 클릭 액션을 붙이고, 펼친 상태에서만 팝업을 띄운다. 권한이 없으면 안내한다.

**Files:**
- Modify: `Bartidy/MenuBar/ControlItem.swift`

- [ ] **Step 1: divider 버튼에 클릭 액션 추가**

`Bartidy/MenuBar/ControlItem.swift`의 `setupDivider()`를 아래로 교체한다:
```swift
    private func setupDivider() {
        guard let button = dividerItem.button else { return }
        button.title = "│"
        button.appearsDisabled = true   // 외형만 흐리게, 클릭 동작은 유지됨
        button.target = self
        button.action = #selector(dividerClicked)
    }
```

- [ ] **Step 2: 팝업 프로퍼티와 핸들러 추가**

`ControlItem` 클래스의 프로퍼티 영역(예: `private var settingsWindow: NSWindow?` 아래)에 추가:
```swift
    private var hiddenItemsPopover: NSPopover?
```

`ControlItem` 클래스 안(예: `showMenu()` 아래)에 메서드 추가:
```swift
    @objc private func dividerClicked() {
        // 펼친 상태에서만 동작. 접힌 상태에선 아이콘이 화면 밖이라 팝업이 무의미하다.
        guard state == .showItems else { return }

        guard HiddenItemScanner.shared.isAccessibilityTrusted() else {
            showAccessibilityAlert()
            return
        }

        let items = HiddenItemScanner.shared.scanHiddenItems()
        showHiddenItemsPopover(items: items)
    }

    private func showHiddenItemsPopover(items: [HiddenMenuItem]) {
        guard let button = dividerItem.button else { return }

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: HiddenItemsPopover(items: items) { [weak self] item in
                self?.hiddenItemsPopover?.performClose(nil)
                HiddenItemScanner.shared.press(item)
            }
        )
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        hiddenItemsPopover = popover
    }

    private func showAccessibilityAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "손쉬운 사용 권한이 필요합니다"
        alert.informativeText = "노치에 가려진 메뉴바 아이콘에 접근하려면 시스템 설정에서 Bartidy에 손쉬운 사용 권한을 허용해주세요."
        alert.addButton(withTitle: "권한 요청")
        alert.addButton(withTitle: "취소")
        if alert.runModal() == .alertFirstButtonReturn {
            HiddenItemScanner.shared.requestAccessibility()
        }
    }
```

> 참고: `ControlItem.swift`는 이미 `import AppKit`과 `import SwiftUI`(→ `NSHostingController`)를 갖고 있어 추가 import는 필요 없다.

- [ ] **Step 3: 빌드 확인**

Run:
```bash
xcodebuild -project Bartidy.xcodeproj -scheme Bartidy -destination 'platform=macOS' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "feat: divider 클릭으로 노치 가려진 아이콘 팝업 표시"
```

---

## Task 6: 수동 통합 검증

실 환경(권한 + 노치 맥북)에서만 검증 가능한 부분. 빌드한 앱으로 직접 확인한다.

**Files:** 없음 (검증만)

- [ ] **Step 1: 앱 실행 및 권한 부여**

Xcode에서 `Cmd+R`로 실행하거나 빌드된 `Bartidy.app`을 실행한다. 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서 Bartidy를 켠다.

- [ ] **Step 2: 검증 체크리스트** (각 항목 육안 확인)

1. 메뉴바 아이콘이 노치를 넘길 만큼 충분히 있는 상태에서, Bartidy를 **펼친 상태**로 둔다.
2. divider(`│`)를 클릭 → 팝업이 뜨고, **노치에 가려진 앱들만** 아이콘+이름으로 나열된다(노치 오른쪽에 보이는 앱은 목록에 없어야 함).
3. 팝업에서 앱 하나 선택 → 그 앱의 메뉴가 (노치 아래쯤) 실제로 열린다.
4. Bartidy를 **접힌 상태**로 두고 divider를 클릭 → 아무 일도 일어나지 않는다.
5. (선택) 권한을 끈 상태로 divider 클릭 → 권한 안내 알림이 뜬다.

- [ ] **Step 3: 결과 기록**

체크리스트 결과를 PR 본문 또는 커밋 메시지에 기록한다. 실패 항목이 있으면 해당 Task로 돌아가 수정한다.

---

## Self-Review (계획 작성자 기록)

- **스펙 커버리지**: 설계의 7개 컴포넌트(변경 없음 / divider 핸들러 / AX 열거 / 판정 / 팝업 / 권한 / 정리) → Task 1(정리), 2(판정), 3(열거+권한+AXPress), 4(팝업), 5(divider 핸들러+권한 안내), 6(검증)으로 모두 매핑됨. 단위 테스트는 Task 2, 수동 검증은 Task 6.
- **타입 일관성**: `NotchDetector.isHiddenBehindNotch(itemX:itemY:notchRightEdgeX:)`, `HiddenMenuItem(id:appName:icon:axElement:)`, `HiddenItemScanner.shared.{isAccessibilityTrusted, requestAccessibility, scanHiddenItems, press}`, `HiddenItemsPopover(items:onSelect:)` — Task 간 시그니처/이름 일치 확인.
- **플레이스홀더 없음**: 모든 코드 스텝에 실제 코드 포함.
- **알려진 환경 의존**: 빌드/테스트가 Sparkle SPM(네트워크)과 Accessibility 권한에 의존. 사전 참고에 명시.
