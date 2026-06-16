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
