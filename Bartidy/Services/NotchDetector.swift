//
//  NotchDetector.swift
//  Bartidy
//
//  status item의 화면 좌표로 divider(│) 왼쪽에 있는지 판정한다.
//  좌표는 Accessibility API의 kAXPositionAttribute(화면 상단이 원점) 기준이다.
//  (노치 경계 기준은 경계에 걸친 아이콘에서 보였다 안 보였다 해서 divider 기준으로 바꿈)
//

import CoreGraphics

enum NotchDetector {
    /// 메뉴바로 인정하는 최대 y. 이보다 크면 화면 밖(아래)으로 숨겨진 항목으로 본다.
    /// 메뉴바 높이는 약 24pt이며, chevron으로 숨긴 항목은 y가 1000 이상으로 찍힌다.
    static let menuBarMaxY: CGFloat = 24

    /// 아이콘이 divider(│)보다 왼쪽에 있는 메뉴바 항목인지 판정한다.
    /// - Parameters:
    ///   - itemX: status item의 x좌표 (kAXPositionAttribute)
    ///   - itemY: status item의 y좌표 (kAXPositionAttribute)
    ///   - dividerX: divider status item의 왼쪽 x좌표
    /// - Returns: divider 왼쪽 메뉴바 항목이면 true
    static func isLeftOfDivider(
        itemX: CGFloat,
        itemY: CGFloat,
        dividerX: CGFloat
    ) -> Bool {
        guard itemX >= 0 else { return false }          // 화면 왼쪽 밖
        guard itemY <= menuBarMaxY else { return false } // 화면 아래로 숨겨진 항목
        return itemX < dividerX                          // divider보다 왼쪽
    }
}
