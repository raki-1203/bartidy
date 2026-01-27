# Ice-Style Menu Bar Hiding Implementation

## Context

### Original Request
Implement menu bar icon hiding functionality for Bartidy (Bartender 5 clone). The current CGSMoveWindow approach fails with error 1000 because CGS APIs cannot manipulate windows owned by other processes.

### Interview Summary
**Key Discussions**:
- Current implementation uses CGSMoveWindow which returns kCGErrorCannotComplete (1000)
- User wants to hide/show menu bar icons similar to Bartender
- Accessibility permissions are properly granted

**Research Findings**:
- Ice (jordanbaird/Ice) uses the "divider strategy" - creates NSStatusItems that expand to push icons off-screen
- CGSMoveWindow/CGSSetWindowAlpha only work for windows owned by the same process
- The proven approach is to create a "control item" (NSStatusItem) that expands from standard width to 10,000px

---

## Work Objectives

### Core Objective
Implement Ice-style menu bar hiding using expandable NSStatusItem dividers instead of attempting to manipulate other apps' windows.

### Concrete Deliverables
- `Bartidy/MenuBar/ControlItem.swift` - NSStatusItem wrapper that can expand/collapse
- `Bartidy/MenuBar/MenuBarManager.swift` - Manager for control items and sections
- Updated `AppDelegate.swift` - Initialize and manage control items
- Updated `MenuBarPopoverView.swift` - Toggle button functionality
- Remove broken `IconVisibilityManager.swift`

### Definition of Done
- [x] ControlItem can toggle between standard width and 10,000px expanded width
- [x] Clicking the control item (chevron icon) toggles hide/show state
- [x] When expanded, icons to the LEFT of the control item are pushed off-screen
- [x] When collapsed, icons return to visible area
- [x] Build succeeds with `xcodebuild -scheme Bartidy build`
- [x] App runs and hiding functionality works

### Must Have
- Single control item that acts as a divider
- Click-to-toggle functionality
- Visual indicator (chevron icon when visible)
- Proper cleanup in deinit

### Must NOT Have (Guardrails)
- NO CGSMoveWindow or CGSSetWindowAlpha calls for other apps' windows
- NO complex multi-section architecture (keep it simple like Dozer)
- NO simulated Command-Drag events (advanced Ice feature - not needed for MVP)
- NO changes to existing MenuBarService icon fetching logic

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: NO (no test files currently)
- **User wants tests**: Manual-only
- **Framework**: none

### Manual QA Verification

Each TODO includes detailed verification procedures using direct app interaction.

---

## Task Flow

```
Task 1 (ControlItem) → Task 2 (MenuBarManager) → Task 3 (AppDelegate) → Task 4 (UI) → Task 5 (Cleanup) → Task 6 (Test)
```

## Parallelization

| Task | Depends On | Reason |
|------|------------|--------|
| 1 | None | Core component |
| 2 | 1 | Uses ControlItem |
| 3 | 2 | Uses MenuBarManager |
| 4 | 3 | Needs manager initialized |
| 5 | 4 | Cleanup after integration |
| 6 | 5 | Final verification |

---

## TODOs

- [x] 1. Create ControlItem class

  **What to do**:
  - Create new directory: `Bartidy/MenuBar/`
  - Create `Bartidy/MenuBar/ControlItem.swift`
  - Implement NSStatusItem wrapper with:
    - `HidingState` enum (hideItems, showItems)
    - `Lengths` enum with standard and expanded (10_000) values
    - `toggle()`, `show()`, `hide()` methods
    - Click handler that toggles state
    - `updateAppearance()` that sets length and icon based on state
  - Add file to Xcode project (project.pbxproj)

  **Must NOT do**:
  - Do not use CGS APIs
  - Do not make it overly complex

  **Parallelizable**: NO (first task)

  **References**:
  - Ice's ControlItem: https://github.com/jordanbaird/Ice/blob/main/Ice/MenuBar/ControlItem/ControlItem.swift
  - Key pattern: `statusItem.length = Lengths.expanded` to push icons off-screen

  **Acceptance Criteria**:
  - [x] File created at `Bartidy/MenuBar/ControlItem.swift`
  - [x] File added to project.pbxproj
  - [x] Build succeeds

  **Commit**: YES
  - Message: `feat(menubar): add ControlItem class for expandable divider`
  - Files: `Bartidy/MenuBar/ControlItem.swift`, `Bartidy.xcodeproj/project.pbxproj`

---

- [x] 2. Create MenuBarManager class

  **What to do**:
  - Create `Bartidy/MenuBar/MenuBarManager.swift`
  - Singleton pattern
  - Hold reference to ControlItem
  - Provide `toggle()`, `isHidden` accessors
  - Add file to Xcode project

  **Must NOT do**:
  - Do not implement complex section management
  - Keep it minimal

  **Parallelizable**: NO (depends on 1)

  **References**:
  - Existing singleton pattern in `MenuBarService.swift`

  **Acceptance Criteria**:
  - [x] File created at `Bartidy/MenuBar/MenuBarManager.swift`
  - [x] Singleton with `shared` instance
  - [x] `toggle()` and `isHidden` work correctly
  - [x] Build succeeds

  **Commit**: YES
  - Message: `feat(menubar): add MenuBarManager for control item management`
  - Files: `Bartidy/MenuBar/MenuBarManager.swift`, `Bartidy.xcodeproj/project.pbxproj`

---

- [x] 3. Update AppDelegate to initialize MenuBarManager

  **What to do**:
  - In `AppDelegate.applicationDidFinishLaunching`:
    - Initialize MenuBarManager.shared to create the control item
  - Ensure control item appears in menu bar on launch

  **Must NOT do**:
  - Do not remove existing status item setup
  - Bartidy's own icon should remain separate from the control item

  **Parallelizable**: NO (depends on 2)

  **References**:
  - `Bartidy/App/AppDelegate.swift:20-24` - existing launch code

  **Acceptance Criteria**:
  - [x] MenuBarManager initialized on app launch
  - [x] Control item appears in menu bar (chevron icon)
  - [x] Build succeeds

  **Commit**: YES
  - Message: `feat(app): initialize MenuBarManager on launch`
  - Files: `Bartidy/App/AppDelegate.swift`

---

- [x] 4. Update UI toggle button functionality

  **What to do**:
  - In `MenuBarPopoverView.swift`:
    - Update the eye.slash button to call `MenuBarManager.shared.toggle()`
    - Update icon to reflect current state
  - In `MenuBarViewModel.swift`:
    - Add `var isHidden: Bool { MenuBarManager.shared.isHidden }` 
    - Add `func toggleHidden() { MenuBarManager.shared.toggle() }`

  **Must NOT do**:
  - Do not change the overall UI structure
  - Keep existing icon visibility picker (can be used later)

  **Parallelizable**: NO (depends on 3)

  **References**:
  - `Bartidy/Views/MenuBarPopoverView.swift:44-46` - existing toggle button

  **Acceptance Criteria**:
  - [x] Clicking toggle button in popover hides/shows icons
  - [x] Button icon updates based on state
  - [x] Build succeeds

  **Commit**: YES
  - Message: `feat(ui): connect toggle button to MenuBarManager`
  - Files: `Bartidy/Views/MenuBarPopoverView.swift`, `Bartidy/ViewModels/MenuBarViewModel.swift`

---

- [x] 5. Remove broken IconVisibilityManager

  **What to do**:
  - Delete `Bartidy/Services/IconVisibilityManager.swift`
  - Remove file from project.pbxproj
  - Remove all references in `MenuBarViewModel.swift`:
    - Remove `IconVisibilityManager.shared.applyVisibility(icons:)` calls
    - Remove `IconVisibilityManager.shared.toggleCollapsed()` call
    - Remove `isCollapsedExpanded` property
  - Remove CGSPrivate.h (no longer needed) or keep for future use

  **Must NOT do**:
  - Do not break compilation - ensure all references are removed

  **Parallelizable**: NO (depends on 4)

  **References**:
  - `Bartidy/Services/IconVisibilityManager.swift` - file to delete
  - `Bartidy/ViewModels/MenuBarViewModel.swift:31,51,55-56,60` - references to remove

  **Acceptance Criteria**:
  - [x] IconVisibilityManager.swift deleted
  - [x] No compilation errors
  - [x] Build succeeds

  **Commit**: YES
  - Message: `refactor: remove broken IconVisibilityManager`
  - Files: `Bartidy/Services/IconVisibilityManager.swift` (deleted), `Bartidy/ViewModels/MenuBarViewModel.swift`, `Bartidy.xcodeproj/project.pbxproj`

---

- [x] 6. Build and Test

  **What to do**:
  - Run `xcodebuild -scheme Bartidy -configuration Debug build`
  - Launch the built app
  - Verify functionality:
    1. Bartidy icon appears in menu bar
    2. Control item (chevron) appears in menu bar
    3. Clicking chevron expands it and hides icons to its left
    4. Clicking expanded area collapses and shows icons again
    5. Toggle button in popover works

  **Must NOT do**:
  - Do not skip verification steps

  **Parallelizable**: NO (final task)

  **References**:
  - Build command: `xcodebuild -scheme Bartidy -configuration Debug build`
  - App location: `~/Library/Developer/Xcode/DerivedData/Bartidy-*/Build/Products/Debug/Bartidy.app`

  **Acceptance Criteria**:
  - [x] Build succeeds with exit code 0
  - [x] App launches without crash
  - [x] Chevron control item visible in menu bar
  - [x] Clicking chevron hides icons to its left
  - [x] Clicking expanded area shows icons again
  - [x] Popover toggle button works

  **Commit**: NO (verification only)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `feat(menubar): add ControlItem class for expandable divider` | ControlItem.swift, project.pbxproj | xcodebuild |
| 2 | `feat(menubar): add MenuBarManager for control item management` | MenuBarManager.swift, project.pbxproj | xcodebuild |
| 3 | `feat(app): initialize MenuBarManager on launch` | AppDelegate.swift | xcodebuild |
| 4 | `feat(ui): connect toggle button to MenuBarManager` | MenuBarPopoverView.swift, MenuBarViewModel.swift | xcodebuild |
| 5 | `refactor: remove broken IconVisibilityManager` | IconVisibilityManager.swift, MenuBarViewModel.swift, project.pbxproj | xcodebuild |

---

## Success Criteria

### Verification Commands
```bash
# Build
xcodebuild -scheme Bartidy -configuration Debug build

# Run app
open ~/Library/Developer/Xcode/DerivedData/Bartidy-*/Build/Products/Debug/Bartidy.app
```

### Final Checklist
- [x] ControlItem creates expandable NSStatusItem divider
- [x] Clicking control item toggles hide/show state
- [x] Hidden state expands to 10,000px pushing icons off-screen
- [x] Visible state shows chevron icon at standard width
- [x] Popover toggle button works
- [x] No CGS API errors in console
- [x] Build succeeds without errors
