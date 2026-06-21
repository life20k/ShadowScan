# Changelog

All notable changes to ShadowScan will be documented in this file.

## [1.4.0] - 2025-06-21

### Added

**Self-Learning Support Bot:**
- Interactive support menu (`-Support`)
- Direct question mode (`-Ask "question"`)
- Learning statistics (`-SupportStats`)
- Export unanswered questions (`-ExportUnanswered`)
- 55+ Q&A patterns in knowledge base
- Fuzzy matching with 5-factor scoring
- Feedback collection (y/n after answers)
- Unanswered question logging
- Typo recognition (e.g., "rever" → revert)

**Knowledge Base:**
- 15 feature explanations
- 8 error message fixes
- 18 how-to guides
- 10 FAQ entries
- 4 troubleshooting guides
- 5 typo patterns

### Changed

- Updated version to v1.4.0
- Added support bot commands to README

## [1.3.0] - 2025-06-19

### Added

**Feature Selection Menu:**
- Interactive dropdown menu to select which features to run
- Select single features, multiple features, or all
- Options: 1-17 for individual features, 'a' for all, 'd' for dry-run

**Improved Time Estimates:**
- Updated time estimates from "5-15 minutes" to "10-30 minutes"
- More realistic for DISM/SFC operations

**WinSxS Cleanup Fix:**
- Always runs cleanup (not just when DISM recommends it)
- Added debug output to show DISM progress
- Better error handling

### Changed

- Updated version to v1.3.0

## [1.2.0] - 2025-06-19

### Added

**WinSxS Component Cleanup (Feature 17):**
- Safe DISM StartComponentCleanup
- Analyzes component store before cleanup
- Shows current WinSxS size
- Admin-only feature with manual fallback

**Downloads Cleanup Improvement:**
- Shows files before deleting
- Interactive confirmation menu
- Options: Delete All, Skip All, or Select Individual
- Displays file sizes and age

**Product Model:**
- CLI edition: Free (MIT license)
- Pro edition: $19 one-time purchase (proprietary)
- Maintenance plan: $9/year (optional)

### Changed

- Updated version to v1.2.0
- Updated summary to show Downloads as "with confirmation"
- Removed hardcoded Grass installer detection (not universal)
- Updated README with edition comparison

## [1.1.0] - 2025-06-19

### Added

**Revert Feature:**
- Automatic backup before all risky changes
- Interactive revert menu
- Category-specific revert (Registry, Startup, Services, VisualEffects, WiFi)
- Backups stored in `%APPDATA%\ShadowScan\backups\`

### Changed

- Updated README with revert documentation
- Added revert examples to Quick Start section

## [1.0.0] - 2025-06-19

### Initial Release

**Cleanup Features:**
- Temp file cleanup (Windows Temp, CrashDumps, thumbnail cache)
- Downloads cleanup (old installers, duplicates)
- Universal orphan detection (50+ PUP/adware patterns + heuristic scanning)
- ProgramData, AppData, Program Files, Home directory scanning
- Leftover user profile folder detection

**Security Features:**
- Shadow user account detection and removal
- Suspicious process scanning with pattern matching
- Unknown/no-path process detection
- Running-from-temp detection

**Performance Features:**
- Startup item impact analysis
- Service analysis with safe-to-disable ratings
- Visual effects optimization (disable animations, transparency, shadows)
- WiFi optimization (old profiles, adapter settings)
- Browser bloat cleaning (Chrome, Firefox, Edge, Opera, Brave)

**System Features:**
- Corrupted system file repair (SFC + DISM)
- Registry cleanup (suspicious services, orphaned entries)
- DNS cache flush
- Telemetry disable
- Keyboard accessibility fixes (StickyKeys, ToggleKeys, FilterKeys)

**Developer Features:**
- npm cache cleanup
- pip cache cleanup
- VS Code cache cleanup
- NuGet cache cleanup
- JetBrains cache cleanup
- yarn/pnpm cache cleanup
- Docker size reporting

**User Experience:**
- Dry-run mode (preview changes before committing)
- Color-coded output (Green=OK, Yellow=Warning, Red=Critical)
- Batch file launcher for non-technical users
- 15 skip flags for granular control
- Comprehensive README with instructions

### Known Issues
- System file repair (SFC/DISM) requires Administrator privileges
- Docker cleanup requires manual `docker system prune` command
- Some ProgramData folders may require admin to delete
