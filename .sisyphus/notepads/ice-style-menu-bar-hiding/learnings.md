# Learnings - Ice-Style Menu Bar Hiding

## 2026-01-27 Implementation Complete

### Key Technical Insight: CGS APIs Don't Work for Other Apps' Windows

**Problem**: CGSMoveWindow and CGSSetWindowAlpha return error code 1000 (kCGErrorCannotComplete) when trying to manipulate windows owned by other processes.

**Solution**: Use the "Divider Strategy" from Ice (jordanbaird/Ice):
- Create an NSStatusItem that acts as a divider
- When hiding: expand the divider to 10,000px width
- This pushes all icons to the LEFT of the divider off-screen
- When showing: collapse back to standard width

### Implementation Pattern

```swift
// ControlItem.swift
enum Lengths {
    static let standard: CGFloat = NSStatusItem.variableLength
    static let expanded: CGFloat = 10_000
}

func hide() {
    statusItem.length = Lengths.expanded  // Pushes icons off-screen
}

func show() {
    statusItem.length = Lengths.standard  // Shows chevron icon
}
```

### Architecture Decisions

1. **Singleton MenuBarManager**: Manages the ControlItem, provides simple API (toggle/show/hide/isHidden)
2. **Lazy initialization**: `_ = MenuBarManager.shared` in AppDelegate triggers creation
3. **SwiftUI integration**: ViewModel wraps MenuBarManager with `objectWillChange.send()` for reactivity

### Files Created/Modified

| File | Purpose |
|------|---------|
| `Bartidy/MenuBar/ControlItem.swift` | NSStatusItem wrapper with expand/collapse |
| `Bartidy/MenuBar/MenuBarManager.swift` | Singleton manager |
| `Bartidy/App/AppDelegate.swift` | Initialize manager on launch |
| `Bartidy/Views/MenuBarPopoverView.swift` | Toggle button UI |
| `Bartidy/ViewModels/MenuBarViewModel.swift` | ViewModel integration |

### Removed

- `Bartidy/Services/IconVisibilityManager.swift` - Broken CGS-based approach

### Future Improvements

1. **Keyboard shortcut**: Add global hotkey to toggle hiding
2. **Multiple sections**: Ice supports "always visible" / "hidden" / "always hidden" sections
3. **Drag to reorder**: Allow users to drag icons between sections
4. **Persistence**: Remember hidden state across app restarts
