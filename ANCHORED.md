# Anchored Summary

## Goal
Build and launch ShadowScan on GitHub - a universal PowerShell PC cleanup and security tool with 17 features, self-learning support bot, and auto-revert system.

## Product
**ShadowScan** by Ben The Fix-It Guy
- CLI edition: Free (MIT License)
- Pro edition: $19 one-time purchase (proprietary, GUI + extras)
- Tagline: "Scan for shadows. Remove the threats."

## Completed
- [x] Built ShadowScan.ps1 v1.4.0 (2,322 lines, 17 features)
- [x] Feature selection menu (select individual, multiple, or all)
- [x] Interactive Downloads cleanup (user chooses what to delete)
- [x] Auto-backup system with revert (Registry, Startup, Services, VisualEffects, WiFi)
- [x] Self-learning support bot with fuzzy matching (55+ Q&A)
- [x] WinSxS safe cleanup (DISM /StartComponentCleanup only, no /resetbase)
- [x] Run-Cleanup.bat launcher (6 options)
- [x] README.md with How It Works guide, WiFi tips, support bot docs
- [x] CHANGELOG.md (v1.0.0 through v1.4.0)
- [x] LICENSE (MIT)
- [x] Git initialized, committed, pushed to GitHub
- [x] GitHub repo: https://github.com/life20k/ShadowScan
- [x] Repo topics added: windows, cleanup, security, powershell, etc.

## Next Steps
1. Test support bot locally
2. Build Pro version with GUI wrapper (WinForms/WPF)
3. Set up Gumroad/LemonSqueezy for Pro sales
4. Add more Q&A to support bot over time

## Critical Context
- Git user: Ben (life20k@users.noreply.github.com)
- Script displays version in banner: "ShadowScan v1.4.0"

## Files
| File | Description |
|------|-------------|
| `ShadowScan.ps1` | Main script (17 features + support bot) |
| `Run-Cleanup.bat` | Double-click launcher |
| `README.md` | Full documentation |
| `CHANGELOG.md` | Version history |
| `LICENSE` | MIT License |
| `knowledge-base.json` | Support bot Q&A (55+ patterns) |
| `support-bot.ps1` | Standalone bot script |
| `learning.json` | Bot learning data |
| `unanswered.json` | Unanswered questions log |
