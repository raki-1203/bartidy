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
