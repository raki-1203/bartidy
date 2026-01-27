# Learnings - Bartidy MVP

## 2026-01-26 Session

### Accessibility API
- `AXIsProcessTrusted()` - 권한 확인
- `AXIsProcessTrustedWithOptions()` - 권한 요청 다이얼로그
- `AXUIElementCreateApplication(pid)` - 앱 요소 생성
- `kAXExtrasMenuBarAttribute` - 메뉴바 상태 아이템 접근
- `kAXChildrenAttribute` - 자식 요소 접근
- `kAXPositionAttribute`, `kAXSizeAttribute` - 위치/크기 속성
- `AXValueGetValue()` - CGPoint, CGSize 추출
- `AXUIElementSetAttributeValue()` - 속성 변경 (위치 이동)

### 아이콘 숨기기 방식
- 실제로 아이콘을 "제거"하는 것이 아님
- 화면 밖으로 이동 (x = -10000)
- 원래 위치 저장 후 복원 가능

### SwiftUI + AppKit 통합
- `@NSApplicationDelegateAdaptor` - AppDelegate 연결
- `NSStatusItem` - 메뉴바 아이콘 생성
- `NSPopover` - 팝오버 UI
- `NSHostingController` - SwiftUI 뷰를 AppKit에서 사용

### UserDefaults 패턴
- `[String: String]` 딕셔너리로 저장
- bundleId를 키로, visibility.rawValue를 값으로
- 앱 시작 시 로드, 변경 시 즉시 저장
