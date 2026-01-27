# Issues - preferredPosition-fix

## Problems & Gotchas

## 2026-01-27 Task 2 & 3: Manual Verification Required

**BLOCKER TYPE**: Requires physical GUI interaction - cannot be automated

**Tasks 2 and 3 require**:
- Running the app in Xcode (⌘R)
- Clicking the chevron in the menubar
- Observing if third-party icons are hidden
- Restarting the app and verifying persistence

**All automatable work COMPLETED**:
- ✅ Code change implemented (ControlItem.swift)
- ✅ Commit created: `3f941a1 fix(menubar): add preferredPosition...`
- ✅ Cleared existing UserDefaults position data
- ✅ Built the app successfully (`xcodebuild BUILD SUCCEEDED`)
- ✅ LSP diagnostics clean
- ✅ Documented learnings in notepad

**User must manually verify**:
1. `open Bartidy.xcodeproj` then ⌘R to run
2. Confirm chevron appears on RIGHT side of menubar (near clock)
3. Click chevron → third-party icons should hide
4. Click again → icons should reappear
5. Quit and restart → position should persist

**Resolution**: User performs manual verification, then marks Tasks 2 & 3 complete

