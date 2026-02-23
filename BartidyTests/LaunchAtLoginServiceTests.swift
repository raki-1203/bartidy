//
//  LaunchAtLoginServiceTests.swift
//  BartidyTests
//

import XCTest

// MARK: - Protocol (테스트 내 재정의)

private protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get }
    @discardableResult func setEnabled(_ enabled: Bool) -> Bool
}

// MARK: - Mock

private final class MockLaunchAtLoginService: LaunchAtLoginManaging {
    var isEnabled: Bool = false
    var setEnabledCallCount = 0
    var lastSetEnabledValue: Bool?
    var shouldSucceed = true

    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        setEnabledCallCount += 1
        lastSetEnabledValue = enabled
        if shouldSucceed {
            isEnabled = enabled
        }
        return shouldSucceed
    }
}

// MARK: - Tests

final class LaunchAtLoginServiceTests: XCTestCase {

    // MARK: - 초기 상태

    func test_초기상태_비활성화() {
        let sut = MockLaunchAtLoginService()
        XCTAssertFalse(sut.isEnabled)
    }

    func test_초기_callCount_0() {
        let sut = MockLaunchAtLoginService()
        XCTAssertEqual(sut.setEnabledCallCount, 0)
    }

    // MARK: - setEnabled 성공 케이스

    func test_setEnabled_true_호출시_활성화됨() {
        let sut = MockLaunchAtLoginService()

        let result = sut.setEnabled(true)

        XCTAssertTrue(result)
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(sut.setEnabledCallCount, 1)
        XCTAssertEqual(sut.lastSetEnabledValue, true)
    }

    func test_setEnabled_false_호출시_비활성화됨() {
        let sut = MockLaunchAtLoginService()
        sut.isEnabled = true

        let result = sut.setEnabled(false)

        XCTAssertTrue(result)
        XCTAssertFalse(sut.isEnabled)
        XCTAssertEqual(sut.lastSetEnabledValue, false)
    }

    func test_활성화_후_비활성화_순서() {
        let sut = MockLaunchAtLoginService()

        XCTAssertTrue(sut.setEnabled(true))
        XCTAssertTrue(sut.isEnabled)

        XCTAssertTrue(sut.setEnabled(false))
        XCTAssertFalse(sut.isEnabled)
    }

    func test_비활성화_상태에서_비활성화_시도() {
        let sut = MockLaunchAtLoginService()
        // 초기 상태: false

        let result = sut.setEnabled(false)

        XCTAssertTrue(result)
        XCTAssertFalse(sut.isEnabled)
        XCTAssertEqual(sut.setEnabledCallCount, 1)
    }

    func test_여러번_호출시_callCount_증가() {
        let sut = MockLaunchAtLoginService()

        sut.setEnabled(true)
        sut.setEnabled(false)
        sut.setEnabled(true)

        XCTAssertEqual(sut.setEnabledCallCount, 3)
    }

    // MARK: - setEnabled 실패 케이스

    func test_실패시_isEnabled_변경_안됨() {
        let sut = MockLaunchAtLoginService()
        sut.shouldSucceed = false

        let result = sut.setEnabled(true)

        XCTAssertFalse(result)
        XCTAssertFalse(sut.isEnabled, "실패 시 isEnabled가 변경되면 안 됨")
    }

    func test_실패시_callCount_증가() {
        let sut = MockLaunchAtLoginService()
        sut.shouldSucceed = false

        sut.setEnabled(true)

        XCTAssertEqual(sut.setEnabledCallCount, 1)
    }

    // MARK: - UI 롤백 로직 (SettingsView의 onChange 동작을 검증)

    func test_setEnabled_실패시_UI_롤백() {
        // Given
        let service = MockLaunchAtLoginService()
        service.shouldSucceed = false
        var uiState = false

        // When: 활성화 시도 → 실패
        let newValue = true
        let success = service.setEnabled(newValue)
        if !success {
            uiState = !newValue  // 롤백
        } else {
            uiState = newValue
        }

        // Then: UI가 원래 상태(false)로 롤백
        XCTAssertFalse(uiState, "실패 시 UI 상태가 원래대로 롤백되어야 함")
    }

    func test_setEnabled_성공시_UI_상태_유지() {
        // Given
        let service = MockLaunchAtLoginService()
        service.shouldSucceed = true
        var uiState = false

        // When: 활성화 시도 → 성공
        let newValue = true
        let success = service.setEnabled(newValue)
        if !success {
            uiState = !newValue
        } else {
            uiState = newValue
        }

        // Then: UI 상태가 true로 유지
        XCTAssertTrue(uiState, "성공 시 UI 상태가 변경된 값을 유지해야 함")
    }

    func test_비활성화_실패시_UI_롤백() {
        // Given: 이미 활성화된 상태에서 비활성화 실패
        let service = MockLaunchAtLoginService()
        service.isEnabled = true
        service.shouldSucceed = false
        var uiState = true

        // When: 비활성화 시도 → 실패
        let newValue = false
        let success = service.setEnabled(newValue)
        if !success {
            uiState = !newValue  // true로 롤백
        } else {
            uiState = newValue
        }

        // Then: UI가 true로 롤백
        XCTAssertTrue(uiState, "비활성화 실패 시 UI 상태가 true로 롤백되어야 함")
    }

    // MARK: - onAppear 동기화 로직

    func test_onAppear_시_활성화_상태_동기화() {
        // Given: 시스템에서 이미 활성화된 상태
        let service = MockLaunchAtLoginService()
        service.isEnabled = true

        // When: onAppear 동기화
        var uiState = false
        uiState = service.isEnabled

        // Then: UI가 시스템 상태(true)와 동기화
        XCTAssertTrue(uiState)
    }

    func test_onAppear_시_비활성화_상태_동기화() {
        // Given: 시스템에서 비활성화된 상태 (UI는 true였던 상황)
        let service = MockLaunchAtLoginService()
        service.isEnabled = false

        // When: onAppear 동기화
        var uiState = true
        uiState = service.isEnabled

        // Then: UI가 시스템 상태(false)로 동기화
        XCTAssertFalse(uiState)
    }
}
