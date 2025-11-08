# Changelog

## 2024-11-08 - Widget System Implementation

### Fixed
- ✓ Dashboard cycling - Ctrl-j/k now properly cycles through widget pages and back to dashboard
- ✓ Invalid buffer errors when navigating pages
- ✓ "Dashboard" command not found - now uses `Snacks.dashboard.open()`
- ✓ Cleaned up duplicate/redundant documentation files

### Added
- ✓ Custom widget system with full buffer control
- ✓ Two widget pages: System and Dev
- ✓ Page navigation with Ctrl-j (next) and Ctrl-k (prev)
- ✓ Proper cycling back to dashboard from widget pages
- ✓ Widget types: text, command, tui (foundation ready)

### Structure
```
Widget Pages:
  1. System - Calendar, system info, disk usage
  2. Dev - Git status, recent commits
  
Navigation:
  - From dashboard: Press 'w' or Ctrl-j to open widgets
  - Between pages: Ctrl-j (next), Ctrl-k (prev)
  - Return to dashboard: 'q' or navigate past last page
  - Refresh page: 'r'
```

### Next Steps
- [ ] Add borders to widgets
- [ ] Implement live/interactive TUI widgets (htop example)
- [ ] Add widget auto-refresh capability
- [ ] Implement widget highlighting/selection
- [ ] Add more widget types (API data, weather, etc.)
