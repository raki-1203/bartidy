# Decisions - Bartidy MVP

## 2026-01-26 Session

### 아키텍처 결정

1. **싱글톤 패턴 사용**
   - MenuBarService.shared
   - IconVisibilityManager.shared
   - SettingsStore.shared

2. **Result 타입 사용**
   - `fetchMenuBarIcons() -> Result<[MenuBarIcon], MenuBarServiceError>`

3. **3단계 visibility 상태**
   - alwaysShow / collapsed / alwaysHidden

### 라이선스 결정
- 100% 직접 개발 (Apple 공식 API만 사용)
- 나중에 유료화 가능하도록 비공개 코드 유지

### MVP 범위 제외
- 키보드 단축키, 프로필, 스마트 트리거, 드래그앤드롭
