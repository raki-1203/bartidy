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

    /// 앱별 AX 메시징 응답을 기다리는 최대 시간(초). 응답이 느린 앱이 스캔 전체를 막지 않도록
    /// 기본 타임아웃(수 초) 대신 짧게 제한한다.
    private static let messagingTimeout: Float = 0.2

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
