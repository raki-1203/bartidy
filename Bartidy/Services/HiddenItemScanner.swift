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
