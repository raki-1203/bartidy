//
//  LaunchAtLoginService.swift
//  Bartidy
//

import Foundation
import ServiceManagement
import OSLog

// MARK: - Protocol

protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get }
    @discardableResult func setEnabled(_ enabled: Bool) -> Bool
}

// MARK: - Implementation

/// macOS 13.0+의 SMAppService를 사용하여 로그인 시 자동 실행을 관리합니다.
final class LaunchAtLoginService: LaunchAtLoginManaging {
    // MARK: - Singleton

    static let shared = LaunchAtLoginService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Bartidy", category: "LaunchAtLogin")

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Interface

    /// 현재 로그인 항목 등록 여부를 반환합니다.
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// 로그인 시 자동 실행을 활성화하거나 비활성화합니다.
    /// - Returns: 성공 여부 (실패 시 UI를 원래 상태로 롤백하는 데 사용)
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        if enabled {
            return register()
        } else {
            return unregister()
        }
    }

    // MARK: - Private Methods

    private func register() -> Bool {
        do {
            try SMAppService.mainApp.register()
            logger.info("Launch at login 등록 완료")
            return true
        } catch {
            logger.error("Launch at login 등록 실패: \(error.localizedDescription)")
            return false
        }
    }

    private func unregister() -> Bool {
        do {
            try SMAppService.mainApp.unregister()
            logger.info("Launch at login 등록 해제 완료")
            return true
        } catch {
            logger.error("Launch at login 등록 해제 실패: \(error.localizedDescription)")
            return false
        }
    }
}
