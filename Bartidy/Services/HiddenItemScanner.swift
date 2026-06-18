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

    /// 앱별 AX 메시징 응답을 기다리는 최대 시간(초) = 응답 안 하는 앱을 기다리는 상한.
    /// 데워진 앱은 수~수십 ms로 답하므로 정상이면 상한을 다 안 기다린다. 콜드 누락은 실행 시
    /// warmUp()으로 막으므로 상한을 0.15s까지 낮춰 느린 앱이 있을 때의 대기를 줄인다.
    private static let messagingTimeout: Float = 0.15

    /// divider(│) 왼쪽에 있는 메뉴바 status item을 수집한다. 권한이 없으면 빈 배열.
    ///
    /// 메뉴바 아이콘은 UI 앱(`.regular`/`.accessory`)만 만들 수 있으므로 백그라운드 데몬
    /// (`.prohibited`)은 후보에서 제외한다. 남은 앱은 동시 큐에 한꺼번에 던져(웨이브 없이)
    /// AX 조회를 겹쳐서 수행한다. AX 조회는 앱마다 IPC 왕복이라 순차로 돌면 느리다.
    /// **블로킹 호출이므로 백그라운드에서 부른다.**
    /// - Parameter dividerX: divider status item의 왼쪽 x좌표. 이보다 왼쪽 항목만 수집한다.
    func scanHiddenItems(dividerX: CGFloat) -> [HiddenMenuItem] {
        guard isAccessibilityTrusted() else { return [] }

        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy != .prohibited && $0.localizedName != nil && !shouldSkip($0)
        }

        // 모든 앱 조회를 동시에 띄워 IPC 대기를 겹친다(코어 수에 묶이는 concurrentPerform과 달리
        // 느린 앱이 웨이브로 누적되지 않음). 결과는 고유 인덱스에 써서 락으로 보호한다.
        var perApp = [[HiddenMenuItem]](repeating: [], count: apps.count)
        let lock = NSLock()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.bartidy.hiddenitemscanner.scan", attributes: .concurrent)

        for index in apps.indices {
            queue.async(group: group) {
                let items = self.hiddenItems(in: apps[index], dividerX: dividerX)
                lock.lock()
                perApp[index] = items
                lock.unlock()
            }
        }
        group.wait()

        return perApp.flatMap { $0 }
    }

    /// 앱 실행 직후 각 앱과의 AX 연결을 미리 맺어둔다. AX IPC 연결은 대상 pid 단위로 캐시되므로,
    /// 여기서 한 번 조회해두면 첫 클릭 스캔이 콜드 상태가 아니라 빠르게 전부 응답한다.
    /// 결과는 버린다. 권한이 없으면 아무것도 하지 않는다. **블로킹이므로 백그라운드에서 부른다.**
    func warmUp() {
        guard isAccessibilityTrusted() else { return }

        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy != .prohibited && $0.localizedName != nil && !shouldSkip($0)
        }

        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.bartidy.hiddenitemscanner.warmup", attributes: .concurrent)
        for app in apps {
            queue.async(group: group) {
                let axApp = AXUIElementCreateApplication(app.processIdentifier)
                // 워밍업은 사용자 비가시라 연결이 확실히 맺히도록 넉넉한 타임아웃을 준다.
                AXUIElementSetMessagingTimeout(axApp, 2.0)
                _ = self.copyAttribute(axApp, "AXExtrasMenuBar")
            }
        }
        group.wait()
    }

    private func hiddenItems(in app: NSRunningApplication, dividerX: CGFloat) -> [HiddenMenuItem] {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(axApp, Self.messagingTimeout)

        guard let extrasRef = copyAttribute(axApp, "AXExtrasMenuBar") else { return [] }
        let extras = extrasRef as! AXUIElement
        guard let childrenRef = copyAttribute(extras, kAXChildrenAttribute as String),
              let children = childrenRef as? [AXUIElement] else { return [] }

        var items: [HiddenMenuItem] = []
        for (index, item) in children.enumerated() {
            guard let point = copyPosition(item) else { continue }
            guard NotchDetector.isLeftOfDivider(
                itemX: point.x,
                itemY: point.y,
                dividerX: dividerX
            ) else { continue }

            items.append(HiddenMenuItem(
                id: "\(app.processIdentifier)_\(index)",
                appName: app.localizedName ?? "",
                icon: app.icon,
                axElement: item
            ))
        }
        return items
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
