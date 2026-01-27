import AppKit

enum IconVisibility: String, CaseIterable {
    case alwaysShow
    case collapsed
    case alwaysHidden
    
    var displayName: String {
        switch self {
        case .alwaysShow:
            return "항상 표시"
        case .collapsed:
            return "접기"
        case .alwaysHidden:
            return "완전 숨김"
        }
    }
    
    var systemImage: String {
        switch self {
        case .alwaysShow:
            return "eye"
        case .collapsed:
            return "eye.trianglebadge.exclamationmark"
        case .alwaysHidden:
            return "eye.slash"
        }
    }
}

struct MenuBarIcon: Identifiable, Equatable {
    let id: String
    let bundleIdentifier: String
    let appName: String
    var visibility: IconVisibility
    var position: CGPoint
    var size: CGSize
    let ownerPID: pid_t
    let windowID: UInt32
    var image: NSImage?
    
    init(
        bundleIdentifier: String,
        appName: String,
        visibility: IconVisibility = .alwaysShow,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        ownerPID: pid_t = 0,
        windowID: UInt32 = 0,
        image: NSImage? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.visibility = visibility
        self.position = position
        self.size = size
        self.ownerPID = ownerPID
        self.windowID = windowID
        self.image = image
        self.id = "\(bundleIdentifier)_\(ownerPID)"
    }
}
