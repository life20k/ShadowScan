# ShadowScan

**Scan for shadows. Remove the threats.**

The only tool that cleans your PC AND checks for security threats.

## Editions

| Edition | Price | What You Get |
|---------|-------|--------------|
| **CLI (Free)** | $0 | 17 cleanup features, security scanning, dry-run, revert |
| **Pro (Download)** | $19 one-time | Everything in CLI + GUI, scheduled scans, auto-updates, reports |

Optional **Maintenance Plan**: $9/year for updates and priority support.

## Features

| Category | What It Does |
|----------|--------------|
| **Shadow Detection** | Finds hidden user accounts, suspicious processes, orphaned folders |
| **Deep Cleanup** | Removes temp files, browser bloat, developer caches |
| **Downloads Cleanup** | Interactive - shows files, lets you choose what to delete |
| **Security Scan** | Pattern matching for 50+ known PUPs, adware, and crypto miners |
| **Performance Boost** | Startup analysis, service optimization, visual effects tuning |
| **System Repair** | SFC + DISM corrupted file repair |
| **WinSxS Cleanup** | Safe DISM component cleanup (reclaim 1-3 GB) |
| **Universal** | Works on ANY Windows PC - smart heuristics, not hardcoded lists |
| **Auto-Backup** | All changes backed up automatically - revert anytime |

## How It Works (Feature-by-Feature Guide)

This section explains what each feature does and what the output means.

### [1] Temp File Cleanup

**What it does:** Deletes temporary files Windows no longer needs.

| Location | What's There |
|----------|--------------|
| `%TEMP%` | App temp files, safe to delete |
| `C:\Windows\Temp` | System temp files, safe to delete |
| CrashDumps | Crash reports, safe to delete |
| npm-cache | Node.js cache, rebuilds as needed |
| pip-cache | Python cache, rebuilds as needed |

**Output examples:**
```
[OK] Cleaned: C:\Users\You\AppData\Local\Temp
[!] Skipped: C:\Windows\Temp (empty or locked)
```

**Why "Skipped" is normal:** Some files are in use by Windows. This is safe - it just means those files are busy.

---

### [2] Downloads Cleanup

**What it does:** Shows old installers (>30 days) and lets YOU decide what to delete.

**Output example:**
```
Found 3 old installer(s) in Downloads:

  - old_setup.exe (125 MB, 45 days old)
  - installer.msi (200 MB, 38 days old)
  - update.zip (125 MB, 32 days old)

Total: 450 MB

Options:
  [1] Delete ALL listed files
  [2] Skip ALL (keep everything)
  [3] Select files to delete
```

**Why this matters:** You control what gets deleted. Nothing is removed without your permission.

---

### [3] Universal Orphan Detection

**What it does:** Scans for leftover folders from uninstalled programs.

**Where it looks:**
- `C:\ProgramData`
- `%LOCALAPPDATA%`
- `%APPDATA%`
- `C:\Users` (home folders)
- `C:\Program Files`

**Output examples:**
```
[OK] Removed: C:\ProgramData\IObit
[OK] Heuristic: Removed stale folder: OldSoftware
[INFO] Universal scan complete: 5 orphaned folders detected
```

**Why "0 orphaned folders" is good:** Your PC is clean! No leftover junk found.

---

### [4] Accessibility Fixes

**What it does:** Disables annoying keyboard features that cause phantom keystrokes.

| Feature | What It Does | Why Disable |
|---------|--------------|-------------|
| StickyKeys | Press Shift 5 times to activate | Annoying popups |
| ToggleKeys | Beep on Caps Lock | Annoying sounds |
| FilterKeys | Ignore brief keystrokes | Slows down typing |

**Output example:**
```
[OK] Disabled StickyKeys
[OK] Disabled ToggleKeys
[OK] Disabled FilterKeys
```

---

### [5] WiFi Optimization

**What it does:** Cleans up old WiFi networks and optimizes your adapter.

**Output example:**
```
[OK] Removed WiFi profile: OldNetwork1
[OK] Removed WiFi profile: OldNetwork2
[OK] Optimized WiFi adapter properties
[INFO] Run these commands in Admin PowerShell to set DNS:
    netsh interface ip set dns "Wi-Fi" static 1.1.1.1 primary
```

**What this means:** Old WiFi networks you no longer use are removed. Your adapter is tuned for better performance.

---

### [6] Shadow Account Removal

**What it does:** Finds and removes hidden user accounts (malware often creates these).

**Output examples:**
```
[OK] No shadow accounts found
```
or
```
[!] Found shadow account: ShadowUser_1604
[OK] Disabled and deleted account: ShadowUser_1604
[OK] Deleted profile folder: C:\Users\ShadowUser_1604
```

**Why this matters:** Hidden accounts are a security risk. This removes them.

---

### [7] Startup Cleanup

**What it does:** Checks which programs start automatically with Windows.

**Output example:**
```
[OK] Startup entries backed up
[OK] No suspicious startup items found
```

**What to do with results:** Open Task Manager (Ctrl+Shift+Esc) → Startup tab to disable items you don't need.

---

### [8] Registry Cleanup

**What it does:** Removes leftover registry entries from uninstalled programs.

**Output examples:**
```
[OK] Removed service registry: ShadowSandbox
[OK] Removed uninstall entry: OldSoftware
[INFO] Windows Installer cache: 2.5 GB (requires admin to clean)
```

**Why some things need admin:** Windows protects certain registry keys. Running as Administrator gives full access.

---

### [9] System Cleanup

**What it does:** Optimizes Windows settings for better performance.

**What it does:**
- Flushes DNS cache (faster internet lookups)
- Disables Windows Telemetry (privacy)
- Disables Cortana (if you don't use it)
- Optimizes power settings

**Output example:**
```
[OK] Flushed DNS cache
[OK] Disabled Windows Telemetry
[OK] Disabled Cortana
```

---

### [10] Process Scan

**What it does:** Checks all running programs for suspicious activity.

**What it looks for:**
- Known malware patterns
- Programs running from temp folders
- Unsigned executables
- Unknown processes

**Output examples:**
```
Scan Results:
  Processes scanned: 85
  Clean: 82
  Suspicious: 0
  Unknown: 3

  UNKNOWN/FLAGGED PROCESSES:
    - unknown_app.exe (PID: 1234) - Running from Temp folder
```

**What to do with suspicious findings:** Run a full Windows Defender scan.

---

### [11] System File Repair

**What it does:** Repairs corrupted Windows system files.

**Commands used:**
- `DISM /Online /Cleanup-Image /RestoreHealth` - Repairs Windows image
- `sfc /scannow` - Repairs system files

**Output example:**
```
[INFO] Running DISM to repair Windows image...
[INFO] This may take 10-30 minutes...
[OK] DISM repair completed successfully
[INFO] Running SFC to repair system files...
[OK] SFC: No integrity violations found
```

**Why this takes long:** Windows checks every system file. This is thorough but slow.

---

### [12] Startup Impact Analyzer

**What it does:** Shows which startup programs slow down your boot time.

**Output example:**
```
Startup Items Found: 8

Name                           Location             Impact
----------------------------------------------------------------------
Chrome                         HKCU\Run            Medium
Steam                          HKCU\Run            Medium
OneDrive                       HKLM\Run            Low
```

**What the colors mean:**
- **Red (High)** - Slows boot significantly
- **Yellow (Medium)** - Moderate impact
- **Green (Low)** - Minimal impact

---

### [13] Service Analysis

**What it does:** Shows which Windows services can be safely disabled.

**Output example:**
```
Running Services: 45
Safe to Disable: 12
Use Caution: 3

SAFE TO DISABLE:
  - DiagTrack - Connected User Experiences and Telemetry
  - Fax - Fax service
  - MapsBroker - Downloaded Maps Manager
```

**What to do:** Open `services.msc` → Right-click service → Properties → Set Startup type to Disabled.

---

### [14] Browser Bloat Cleaner

**What it does:** Cleans browser cache to free space.

**Output example:**
```
Detected Browsers:
  - Google Chrome: 847.5 MB
  - Mozilla Firefox: 234.2 MB

[OK] Cleaned Google Chrome cache: 847.5 MB
[OK] Cleaned Mozilla Firefox cache: 234.2 MB
```

**Note:** Close browsers before cleaning for best results. Cache rebuilds as you browse.

---

### [15] Visual Effects Optimizer

**What it does:** Disables visual effects to make Windows feel faster.

**What it disables:**
- Menu animations
- Smooth scrolling
- Transparency effects
- Window shadows
- Taskbar animations

**Output example:**
```
[OK] Disabled menu animations
[OK] Disabled smooth scrolling
[OK] Disabled transparency effects
[OK] Set visual effects to best performance
```

**What you'll notice:** Windows feels snappier, especially on older hardware.

---

### [16] Developer Cache Cleanup

**What it does:** Cleans caches from development tools.

| Tool | Cache Location |
|------|----------------|
| npm | `%LOCALAPPDATA%\npm-cache` |
| pip | `%LOCALAPPDATA%\pip\cache` |
| VS Code | `%APPDATA%\Code\Cache` |
| NuGet | `%LOCALAPPDATA%\NuGet` |
| JetBrains | `%LOCALAPPDATA%\JetBrains` |

**Output example:**
```
Developer tools found:
  - npm cache: 1.2 GB
  - VS Code cache: 450 MB

[OK] Cleaned npm cache: 1.2 GB
[OK] Cleaned VS Code cache: 450 MB
```

---

### [17] WinSxS Component Cleanup

**What it does:** Removes old Windows Update components.

**Output example:**
```
[INFO] Current WinSxS size: 10.97 GB
[INFO] Running DISM StartComponentCleanup...
[INFO] This may take 10-30 minutes...
[OK] WinSxS cleanup completed successfully
[INFO] WinSxS size after cleanup: 10.97 GB (freed 0 GB)
```

**Why "0 GB freed" is normal:**
- WinSxS uses **hardlinks** (files appear to take space but are shared)
- If your PC is already optimized, there's nothing to remove
- 10-12 GB is a normal, healthy WinSxS size

**To check if cleanup is needed:**
```powershell
DISM /Online /Cleanup-Image /AnalyzeComponentStore
```
If it says "Cleanup Recommended: No", your WinSxS is already clean.

---

## Understanding the Output

| Symbol | Meaning |
|--------|---------|
| `[OK]` | Action completed successfully |
| `[!]` | Warning - check this |
| `[X]` | Error - something failed |
| `[INFO]` | Informational message |
| `[DRY-RUN]` | Would happen (preview mode) |

## Quick Start

### Option 1: Double-Click (Easiest)
1. Copy the folder to the target PC
2. Right-click `Run-Cleanup.bat`
3. Select **Run as Administrator**
4. Pick option 1 for full cleanup

### Option 2: PowerShell
```powershell
# Preview what will be cleaned (no changes made)
.\ShadowScan.ps1 -All -DryRun

# Run full cleanup
.\ShadowScan.ps1 -All

# Skip specific features
.\ShadowScan.ps1 -All -SkipDevCleanup -SkipWiFi

# Revert all changes
.\ShadowScan.ps1 -Revert

# Revert specific category
.\ShadowScan.ps1 -Revert -RevertCategory "Services"
```

## What ShadowScan Finds

### Security Threats
- Hidden/shadow user accounts
- Suspicious processes (crypto miners, keyloggers, trojans)
- Running-from-temp detection
- Unsigned executables

### System Bloat
- 50+ known PUP/adware folder patterns
- Empty/stale folders (heuristic scan)
- Orphaned ProgramData, AppData, Program Files
- Leftover user profiles

### Performance Issues
- High-impact startup items
- Unnecessary running services
- Browser cache bloat
- Developer cache accumulation (npm, pip, VS Code, Docker)

### System Health
- Corrupted Windows system files
- Broken registry entries
- Visual effects slowing down UI
- WiFi misconfigurations
- WinSxS component store bloat

## Command Line Options

| Flag | Description |
|------|-------------|
| `-DryRun` | Preview changes without deleting anything |
| `-All` | Run all features |
| `-Revert` | Revert previously made changes |
| `-RevertCategory` | Specific category to revert (Registry, Startup, Services, VisualEffects, WiFi) |
| `-SkipTemp` | Skip temp file cleanup |
| `-SkipDownloads` | Skip downloads cleanup |
| `-SkipOrphans` | Skip orphaned folder cleanup |
| `-SkipAccessibility` | Skip accessibility fixes |
| `-SkipWiFi` | Skip WiFi optimization |
| `-SkipShadowAccounts` | Skip shadow account removal |
| `-SkipRegistry` | Skip registry cleanup |
| `-SkipSystem` | Skip system optimization |
| `-SkipProcessScan` | Skip process scanning |
| `-SkipSystemRepair` | Skip SFC/DISM repair |
| `-SkipStartup` | Skip startup analysis |
| `-SkipServices` | Skip service analysis |
| `-SkipBrowsers` | Skip browser bloat cleaning |
| `-SkipVisualEffects` | Skip visual effects optimization |
| `-SkipDevCleanup` | Skip developer cache cleanup |

## Support Bot

ShadowScan includes a self-learning support bot that gets smarter with every question.

### Commands

| Command | Description |
|---------|-------------|
| `.\ShadowScan.ps1 -Support` | Interactive support menu |
| `.\ShadowScan.ps1 -Ask "question"` | Ask a direct question |
| `.\ShadowScan.ps1 -SupportStats` | View learning statistics |
| `.\ShadowScan.ps1 -ExportUnanswered` | Export unanswered questions |

### How It Works

1. **Ask a question** - Type naturally (e.g., "how do I undo changes")
2. **Bot finds answer** - Uses fuzzy matching to find best response
3. **Rate the answer** - Tell us if it was helpful
4. **Bot learns** - Improves based on your feedback

### Example Session

```
PS> .\ShadowScan.ps1 -Support

  ShadowScan Support Bot v1.0
  Ask me anything about ShadowScan!

  [1] Ask a question
  [2] View FAQ
  [3] View learning stats
  [q] Quit

  Select option: 1

  Ask your question: how do i undo changes

  Answer:
  Run: .\ShadowScan.ps1 -Revert
  (Confidence: 85%)

  Was this helpful? [y/n]: y

  Thanks for your feedback!
```

### Learning Stats

The bot tracks:
- Total questions asked
- Most helpful answers
- Unanswered questions
- Helpfulness scores

## Example Output

```
ShadowScan v1.2.0
Scan for shadows. Remove the threats.

[OK] Cleaned: C:\Users\...\AppData\Local\Temp
[OK] Found 3 old installers in Downloads (450 MB)
  [1] Delete ALL listed files
  [2] Skip ALL (keep everything)
  [3] Select files to delete
  Select option: 1
[OK] Removed: old_setup.exe
[OK] Removed: installer.msi
[OK] Removed: update.zip
[OK] Heuristic: Removed stale folder: OldSoftware
[OK] Disabled StickyKeys
[OK] Cleaned Chrome cache: 847 MB
[OK] Cleaned npm cache: 1.2 GB
[OK] WinSxS cleanup: Reclaimed 2.1 GB

Total space freed: 4.8 GB
```

## Revert Feature

ShadowScan automatically backs up all changes before making them. If something goes wrong, you can revert:

```powershell
# Interactive revert menu
.\ShadowScan.ps1 -Revert

# Revert only service changes
.\ShadowScan.ps1 -Revert -RevertCategory "Services"

# Revert only startup changes
.\ShadowScan.ps1 -Revert -RevertCategory "Startup"

# Revert only visual effects
.\ShadowScan.ps1 -Revert -RevertCategory "VisualEffects"
```

### What Gets Backed Up

| Category | What's Saved |
|----------|--------------|
| **Registry** | Service keys, uninstall entries |
| **Startup** | HKCU/HKLM Run entries, RunOnce |
| **Services** | Service states and startup types |
| **Visual Effects** | Animation, transparency, shadow settings |
| **WiFi** | Old profiles (before deletion) |

### What Doesn't Get Backed Up

- Temp files (safe to delete, rebuilds automatically)
- Downloads (user chose to clean them)
- Browser cache (rebuilds over time)
- Orphan folders (safe to delete)

Backups are stored in: `%APPDATA%\ShadowScan\backups\`

## WiFi Optimization Guide

ShadowScan optimizes your WiFi adapter settings, but router settings are equally important.

### Router Settings for Maximum Speed

| Setting | Optimal Value | Why |
|---------|---------------|-----|
| **Channel Width** | **80MHz** (or 160MHz) | Wider = faster |
| **Channel (5GHz)** | 36, 40, 44, or 48 | Less interference |
| **Channel (2.4GHz)** | 1, 6, or 11 | Non-overlapping |
| **Mode** | 802.11ac/ax | Latest WiFi standard |
| **Security** | WPA2 or WPA3 | Most secure + fastest |

### Channel Width Impact

| Width | Max Speed | Best For |
|-------|-----------|----------|
| 20MHz | ~86 Mbps | Long range, crowded areas |
| 40MHz | ~200 Mbps | Moderate speed |
| **80MHz** | **~400-600 Mbps** | **Best balance** |
| 160MHz | ~800+ Mbps | Maximum speed (short range) |

### How to Change Router Settings

1. Open browser, go to `192.168.1.1` or `192.168.0.1`
2. Login (check router label for credentials)
3. Find **Wireless Settings** or **WiFi Settings**
4. Set **Channel Width** to 80MHz
5. Set **Channel** to 36, 40, 44, or 48
6. Set **Mode** to 802.11ac or 802.11ax
7. Save and reboot router

### Quick Wins

- **Restart router** - Clears memory, fixes many issues
- **Move closer** - Signal strength = speed
- **Update firmware** - Check manufacturer website
- **Reduce interference** - Keep away from microwaves, cordless phones
- **Use 5GHz** - Faster, less crowded than 2.4GHz

### Test Your Speed

After changing settings, test at:
- [speedtest.net](https://www.speedtest.net)
- [fast.com](https://www.fast.com)

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Admin rights recommended

## Licensing

| Edition | License | Commercial Use |
|---------|---------|----------------|
| **CLI (Free)** | MIT | Yes - free to use, modify, distribute |
| **Pro (Paid)** | Proprietary | Personal use only - no redistribution |

## Author

Created by Ben The Fix-It Guy

---

**Scan for shadows. Remove the threats.**
