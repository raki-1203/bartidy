# Learnings - preferredPosition-fix

## Conventions & Patterns


## Jan 27, 2026 - preferredPosition Implementation Complete

### Task Completed
✅ Added `autosaveName` and `preferredPosition` configuration to ControlItem

### Implementation Details
- **File Modified**: `Bartidy/MenuBar/ControlItem.swift`
- **Method**: `init()` (lines 24-47)
- **Key Pattern**: UserDefaults position values set BEFORE autosaveName assignment

### Critical Execution Order
```swift
// WRONG ORDER (won't work):
dividerItem.autosaveName = "Bartidy_Divider"  // System reads defaults NOW
UserDefaults.standard.set(999, forKey: dividerKey)  // Too late!

// CORRECT ORDER (works):
UserDefaults.standard.set(999, forKey: dividerKey)  // Set first
dividerItem.autosaveName = "Bartidy_Divider"  // System reads defaults NOW
```

### Position Values
- **dividerItem**: 999 (right side, second from Control Center)
- **chevronItem**: 1000 (rightmost, closest to Control Center)
- **Rationale**: Higher values = closer to Control Center. Divider positioned right of third-party icons to push them left when expanded.

### Verification
- ✅ Code compiles: `xcodebuild -scheme Bartidy -configuration Debug build`
- ✅ No LSP diagnostics (errors)
- ✅ Commit created: `3f941a1 fix(menubar): add preferredPosition to place divider right of third-party icons`

### Inherited Wisdom Applied
- Followed Ice (jordanbaird/Ice) pattern for menubar positioning
- Documented non-obvious macOS API behavior with necessary comments
- Preserved other methods (setupButton, updateAppearance) unchanged

## 2026-01-27 CRITICAL FIX: Notch Mac Position Values

### Problem Discovered
Position values 999/1000 push status items INTO THE NOTCH on MacBook Pro with notch display, making them invisible!

### Solution
Changed position values from 999/1000 to 200/210:
- Divider: 200
- Chevron: 210

### Evidence
- Display: MacBook Pro with Liquid Retina XDR Display (has notch)
- Old values (999/1000): Chevron invisible
- New values (200/210): Chevron visible between Battery and Date/Time

### Key Learning
On notch Macs, position values around 600-800 are typical for visible status items. Values approaching 1000 push items under the notch where they become invisible.

### UserDefaults Behavior
The code uses `if UserDefaults.standard.object(forKey:) == nil` to only set defaults on first run. If old values exist, they must be manually cleared:
```bash
defaults delete com.bartidy.app "NSStatusItem Preferred Position Bartidy_Divider"
defaults delete com.bartidy.app "NSStatusItem Preferred Position Bartidy_Chevron"
```

