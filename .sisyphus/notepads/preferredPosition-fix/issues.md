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

## 2026-01-27 Automation Limitation: cliclick Accessibility

**Attempted**: Used cliclick to click on chevron at coordinates (2685, 15)
**Result**: Click did not register - cliclick lacks Accessibility permissions
**Error**: "WARNING: Accessibility privileges not enabled"

**To enable cliclick** (if desired for future automation):
1. System Preferences → Security & Privacy → Privacy → Accessibility
2. Add Terminal.app (or the app running cliclick)

**Current workaround**: User must manually click the chevron in the menubar

## FINAL STATUS: All Automatable Work Complete

**Date**: 2026-01-27

### What Was Completed Automatically:
1. ✅ Code change: autosaveName + preferredPosition in ControlItem.swift
2. ✅ Notch Mac fix: position values 999/1000 → 200/210
3. ✅ Build verification: xcodebuild BUILD SUCCEEDED
4. ✅ Chevron visibility: verified via screenshot (position x≈2685)
5. ✅ Commits: `3f941a1`, `57c7e18`
6. ✅ UserDefaults: Bartidy_Chevron=210, Bartidy_Divider=200

### What Cannot Be Automated:
1. 🔒 Clicking menubar items (requires Accessibility permissions for cliclick)
2. 🔒 Observing visual changes in menubar
3. 🔒 Verifying third-party icons hide/show
4. 🔒 Testing persistence after app restart

### Resolution:
User must perform manual verification:
1. Click chevron (<) in menubar
2. Verify third-party icons hide
3. Click again to verify they reappear
4. Restart app to verify position persists

