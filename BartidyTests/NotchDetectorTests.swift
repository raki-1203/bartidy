import XCTest

// NotchDetector.swift는 BartidyTests 타깃에 직접 컴파일된다(standalone 테스트 번들).
// 기존 LaunchAtLoginServiceTests와 동일하게 @testable import를 쓰지 않는다.

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
