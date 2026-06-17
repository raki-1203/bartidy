import XCTest

// NotchDetector.swift는 BartidyTests 타깃에 직접 컴파일된다(standalone 테스트 번들).
// 기존 LaunchAtLoginServiceTests와 동일하게 @testable import를 쓰지 않는다.

final class NotchDetectorTests: XCTestCase {

    func test_divider_왼쪽_메뉴바에_있으면_포함() {
        // Tailscale 실측값: x=796, y=4.5, divider x=1060
        XCTAssertTrue(NotchDetector.isLeftOfDivider(itemX: 796, itemY: 4.5, dividerX: 1060))
    }

    func test_divider_오른쪽이면_제외() {
        // CodexBar 실측값: x=1114
        XCTAssertFalse(NotchDetector.isLeftOfDivider(itemX: 1114, itemY: 4.5, dividerX: 1060))
    }

    func test_divider와_같은_x면_제외() {
        XCTAssertFalse(NotchDetector.isLeftOfDivider(itemX: 1060, itemY: 4.5, dividerX: 1060))
    }

    func test_divider_1px_왼쪽이면_포함() {
        XCTAssertTrue(NotchDetector.isLeftOfDivider(itemX: 1059, itemY: 4.5, dividerX: 1060))
    }

    func test_화면밖_아래로_숨겨진것은_제외() {
        // 제어 센터 실측값: x=0, y=1117
        XCTAssertFalse(NotchDetector.isLeftOfDivider(itemX: 0, itemY: 1117, dividerX: 1060))
    }

    func test_음수_x는_제외() {
        XCTAssertFalse(NotchDetector.isLeftOfDivider(itemX: -5, itemY: 4.5, dividerX: 1060))
    }
}
