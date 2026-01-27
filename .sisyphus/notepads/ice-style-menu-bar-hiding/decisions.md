# Decisions - Ice-Style Menu Bar Hiding

## 2026-01-27 Architecture Decisions

### Decision 1: Use Divider Strategy Instead of CGS APIs

**Context**: Original implementation used CGSMoveWindow to move other apps' menubar icons off-screen.

**Problem**: CGS APIs only work for windows owned by the same process. Error 1000 (kCGErrorCannotComplete) returned for other apps' windows.

**Decision**: Adopt Ice's "Divider Strategy" - expand our own NSStatusItem to push icons off-screen.

**Rationale**:
- Proven approach used by Ice (popular open-source Bartender alternative)
- No private API hacks needed
- Works reliably across macOS versions
- Simple to implement and maintain

### Decision 2: Single Control Item (MVP)

**Context**: Ice supports multiple sections (always visible, hidden, always hidden).

**Decision**: Start with a single control item for MVP.

**Rationale**:
- Simpler implementation
- Covers the primary use case (hide/show toggle)
- Can add multiple sections later if needed

### Decision 3: Singleton MenuBarManager

**Context**: Need to manage the control item lifecycle and provide access from multiple places (AppDelegate, ViewModel).

**Decision**: Use singleton pattern with `MenuBarManager.shared`.

**Rationale**:
- Consistent with existing `MenuBarService.shared` pattern
- Simple initialization via lazy loading
- Easy access from anywhere in the app

### Decision 4: Keep MenuBarService for Icon Fetching

**Context**: MenuBarService uses Accessibility APIs to fetch menubar icon information.

**Decision**: Keep MenuBarService separate from MenuBarManager.

**Rationale**:
- Separation of concerns: fetching vs hiding
- Icon fetching still useful for displaying icon list in popover
- May be useful for future features (per-icon visibility settings)
