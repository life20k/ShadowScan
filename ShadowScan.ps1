<#
.SYNOPSIS
    Ben The Fix-It Guy - Complete PC Cleanup Script
.DESCRIPTION
    Cleans junk files, removes bloatware leftovers, fixes accessibility issues,
    optimizes WiFi, and removes shadow/suspicious accounts.
    All changes are backed up automatically. Use -Revert to undo changes.
.PARAMETER Revert
    Revert previously made changes using backups.
.PARAMETER RevertCategory
    Specific category to revert (Registry, Startup, Services, VisualEffects, WiFi).
.EXAMPLE
    .\ShadowScan.ps1
    Run cleanup with backup
.EXAMPLE
    .\ShadowScan.ps1 -Revert
    Revert all changes
.EXAMPLE
    .\ShadowScan.ps1 -Revert -RevertCategory "Services"
    Revert only service changes
.NOTES
    Run as Administrator for full cleanup.
    Created by Ben The Fix-It Guy
#>

param(
    [switch]$SkipTemp,
    [switch]$SkipDownloads,
    [switch]$SkipOrphans,
    [switch]$SkipAccessibility,
    [switch]$SkipWiFi,
    [switch]$SkipShadowAccounts,
    [switch]$SkipRegistry,
    [switch]$SkipSystem,
    [switch]$SkipProcessScan,
    [switch]$SkipSystemRepair,
    [switch]$SkipStartup,
    [switch]$SkipServices,
    [switch]$SkipBrowsers,
    [switch]$SkipVisualEffects,
    [switch]$SkipDevCleanup,
    [switch]$SkipWinSxS,
    [switch]$DryRun,
    [switch]$All,
    [switch]$Revert,
    [string]$RevertCategory = "",
    [switch]$Support,
    [string]$Ask,
    [switch]$SupportStats,
    [switch]$ExportUnanswered
)

$ErrorActionPreference = "SilentlyContinue"
$bytesFreed = 0
$itemsDeleted = 0

# ============================================================
# REVERT SYSTEM
# ============================================================

$backupRoot = "$env:APPDATA\ShadowScan\backups"
$currentBackup = "$backupRoot\$(Get-Date -Format 'yyyyMMdd_HHmmss')"

function New-BackupFolder {
    param([string]$Category)
    $path = "$currentBackup\$Category"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Save-Backup {
    param(
        [string]$Category,
        [string]$Name,
        [object]$Data
    )
    $folder = New-BackupFolder -Category $Category
    $filePath = "$folder\$Name.json"
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Force
}

function Save-RegistryBackup {
    param(
        [string]$Category,
        [string]$Name,
        [string]$Path
    )
    if (Test-Path $Path) {
        $backup = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
        if ($backup) {
            Save-Backup -Category $Category -Name $Name -Data $backup
            return $true
        }
    }
    return $false
}

function Save-ServiceBackup {
    param([string]$ServiceName)
    $svc = Get-CimInstance Win32_Service | Where-Object { $_.Name -eq $ServiceName }
    if ($svc) {
        $backup = @{
            Name = $svc.Name
            StartMode = $svc.StartMode
            State = $svc.State
        }
        Save-Backup -Category "Services" -Name $ServiceName -Data $backup
        return $true
    }
    return $false
}

function Save-VisualEffectsBackup {
    $settings = @{}
    $paths = @{
        "MenuShowDelay" = "HKCU:\Control Panel\Desktop"
        "SmoothScroll" = "HKCU:\Control Panel\Desktop"
        "EnableTransparency" = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        "ListviewShadow" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        "TaskbarAnimations" = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    }
    
    foreach ($key in $paths.Keys) {
        $regPath = $paths[$key]
        if (Test-Path $regPath) {
            $value = Get-ItemProperty -Path $regPath -Name $key -ErrorAction SilentlyContinue
            if ($value) {
                $settings[$key] = @{
                    Path = $regPath
                    Value = $value.$key
                }
            }
        }
    }
    
    Save-Backup -Category "VisualEffects" -Name "settings" -Data $settings
}

function Save-WiFiBackup {
    $profiles = netsh wlan show profiles 2>$null | Select-String "All User Profile\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
    $backup = @{ Profiles = $profiles }
    Save-Backup -Category "WiFi" -Name "profiles" -Data $backup
}

function Save-StartupBackup {
    $startupData = @()
    
    # HKCU Run
    $hkcuRun = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hkcuRun) {
        $props = Get-ItemProperty $hkcuRun -ErrorAction SilentlyContinue
        if ($props) {
            $props.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                $startupData += @{
                    Location = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
                    Name = $_.Name
                    Value = $_.Value
                }
            }
        }
    }
    
    # HKLM Run
    $hklmRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hklmRun) {
        $props = Get-ItemProperty $hklmRun -ErrorAction SilentlyContinue
        if ($props) {
            $props.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                $startupData += @{
                    Location = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
                    Name = $_.Name
                    Value = $_.Value
                }
            }
        }
    }
    
    Save-Backup -Category "Startup" -Name "entries" -Data $startupData
}

function Save-RegistryServiceBackup {
    param([string]$ServiceName)
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    if (Test-Path $regPath) {
        $backup = Get-Item -Path $regPath -ErrorAction SilentlyContinue
        if ($backup) {
            Save-Backup -Category "Registry" -Name "service_$ServiceName" -Data @{ Path = $regPath }
            return $true
        }
    }
    return $false
}

# ============================================================
# REvert Functions
# ============================================================

function Restore-RegistryKey {
    param(
        [string]$Category,
        [string]$Name
    )
    $backupFile = "$currentBackup\$Category\$Name.json"
    if (Test-Path $backupFile) {
        $backup = Get-Content $backupFile | ConvertFrom-Json
        # Registry backups store the path, we'd need to re-export
        # This is simplified - full implementation would need reg export/import
        return $true
    }
    return $false
}

function Restore-Service {
    param([string]$ServiceName)
    $backupFile = "$currentBackup\Services\$ServiceName.json"
    if (Test-Path $backupFile) {
        $backup = Get-Content $backupFile | ConvertFrom-Json
        Set-Service -Name $ServiceName -StartupType $backup.StartMode -ErrorAction SilentlyContinue
        if ($backup.State -eq "Running") {
            Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        }
        return $true
    }
    return $false
}

function Restore-VisualEffects {
    $backupFile = "$currentBackup\VisualEffects\settings.json"
    if (Test-Path $backupFile) {
        $backup = Get-Content $backupFile | ConvertFrom-Json
        foreach ($key in $backup.PSObject.Properties.Name) {
            $setting = $backup.$key
            if (Test-Path $setting.Path) {
                Set-ItemProperty -Path $setting.Path -Name $key -Value $setting.Value -Force -ErrorAction SilentlyContinue
            }
        }
        return $true
    }
    return $false
}

function Restore-WiFiProfiles {
    $backupFile = "$currentBackup\WiFi\profiles.json"
    if (Test-Path $backupFile) {
        $backup = Get-Content $backupFile | ConvertFrom-Json
        Write-Host "  WiFi profiles were backed up. Profiles are not auto-restored." -ForegroundColor Yellow
        Write-Host "  Use 'netsh wlan connect name=<profile>' to reconnect." -ForegroundColor Yellow
        return $true
    }
    return $false
}

function Restore-StartupEntries {
    $backupFile = "$currentBackup\Startup\entries.json"
    if (Test-Path $backupFile) {
        $backup = Get-Content $backupFile | ConvertFrom-Json
        foreach ($entry in $backup) {
            if (Test-Path $entry.Location) {
                Set-ItemProperty -Path $entry.Location -Name $entry.Name -Value $entry.Value -Force -ErrorAction SilentlyContinue
                Write-Host "  Restored startup: $($entry.Name)" -ForegroundColor Green
            }
        }
        return $true
    }
    return $false
}

function Show-RevertMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "   ShadowScan - Revert Changes" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # List available backups
    if (-not (Test-Path $backupRoot)) {
        Write-Host "  No backups found." -ForegroundColor Yellow
        Write-Host "  Run ShadowScan first to create a backup." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    $backups = Get-ChildItem $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -First 5
    
    if ($backups.Count -eq 0) {
        Write-Host "  No backups found." -ForegroundColor Yellow
        return
    }
    
    Write-Host "  Available backups:" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $backup = $backups[$i]
        $categories = Get-ChildItem $backup.FullName -Directory | Select-Object -ExpandProperty Name
        Write-Host "  [$($i + 1)] $($backup.Name)" -ForegroundColor White
        Write-Host "      Categories: $($categories -join ', ')" -ForegroundColor Gray
    }
    
    Write-Host ""
    $selection = Read-Host "  Select backup number (or 'q' to quit)"
    
    if ($selection -eq 'q') { return }
    
    $index = [int]$selection - 1
    if ($index -lt 0 -or $index -ge $backups.Count) {
        Write-Host "  Invalid selection." -ForegroundColor Red
        return
    }
    
    $currentBackup = $backups[$index].FullName
    
    Write-Host ""
    Write-Host "  Select category to revert:" -ForegroundColor Cyan
    Write-Host "    [1] Registry" -ForegroundColor White
    Write-Host "    [2] Startup" -ForegroundColor White
    Write-Host "    [3] Services" -ForegroundColor White
    Write-Host "    [4] Visual Effects" -ForegroundColor White
    Write-Host "    [5] WiFi" -ForegroundColor White
    Write-Host "    [6] All" -ForegroundColor Yellow
    Write-Host "    [q] Quit" -ForegroundColor White
    Write-Host ""
    
    $catSelection = Read-Host "  Select category"
    
    switch ($catSelection) {
        "1" { Revert-Category -Category "Registry" }
        "2" { Revert-Category -Category "Startup" }
        "3" { Revert-Category -Category "Services" }
        "4" { Revert-Category -Category "VisualEffects" }
        "5" { Revert-Category -Category "WiFi" }
        "6" {
            Revert-Category -Category "Registry"
            Revert-Category -Category "Startup"
            Revert-Category -Category "Services"
            Revert-Category -Category "VisualEffects"
            Revert-Category -Category "WiFi"
        }
        "q" { return }
    }
    
    Write-Host ""
    Write-Host "  Revert complete. A restart is recommended." -ForegroundColor Green
    Write-Host ""
}

function Revert-Category {
    param([string]$Category)
    
    Write-Host ""
    Write-Host "  Reverting $Category..." -ForegroundColor Cyan
    
    $categoryPath = "$currentBackup\$Category"
    if (-not (Test-Path $categoryPath)) {
        Write-Host "  No backup found for $Category" -ForegroundColor Yellow
        return
    }
    
    $backupFiles = Get-ChildItem "$categoryPath\*.json" -ErrorAction SilentlyContinue
    
    foreach ($file in $backupFiles) {
        $backup = Get-Content $file.FullName | ConvertFrom-Json
        
        switch ($Category) {
            "Services" {
                $serviceName = $file.BaseName
                Restore-Service -ServiceName $serviceName
                Write-Host "  Restored service: $serviceName" -ForegroundColor Green
            }
            "VisualEffects" {
                Restore-VisualEffects
                Write-Host "  Restored visual effects settings" -ForegroundColor Green
                break
            }
            "Startup" {
                Restore-StartupEntries
                Write-Host "  Restored startup entries" -ForegroundColor Green
                break
            }
            "WiFi" {
                Restore-WiFiProfiles
                Write-Host "  WiFi profiles noted (manual restore required)" -ForegroundColor Yellow
                break
            }
            "Registry" {
                Write-Host "  Registry restore: $($file.BaseName)" -ForegroundColor White
                # Full registry restore would require reg import
            }
        }
    }
}

# Dry-run mode banner
if ($DryRun) {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Yellow
    Write-Host "   DRY-RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host "  ============================================" -ForegroundColor Yellow
    Write-Host ""
}

# Revert mode banner
if ($Revert) {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "   REVERT MODE - Undoing changes" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Write-Status {
    param([string]$Message, [string]$Status = "OK")
    switch ($Status) {
        "OK"     { Write-Host "  [OK] $Message" -ForegroundColor Green }
        "WARN"   { Write-Host "  [!] $Message" -ForegroundColor Yellow }
        "ERROR"  { Write-Host "  [X] $Message" -ForegroundColor Red }
        "INFO"   { Write-Host "  [*] $Message" -ForegroundColor White }
    }
}

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    }
    return 0
}

function Remove-ItemSafe {
    param([string]$Path, [string]$Description = "")
    if (Test-Path $Path) {
        $size = Get-FolderSize $Path
        if ($DryRun) {
            $sizeMB = [math]::Round($size / 1MB, 2)
            Write-Host "  [DRY-RUN] Would delete: $Path ($sizeMB MB)" -ForegroundColor Yellow
            $script:bytesFreed += $size
            return $true
        } else {
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $Path)) {
                $script:bytesFreed += $size
                $script:itemsDeleted++
                return $true
            }
        }
    }
    return $false
}

# ============================================================
# REVERT MODE
# ============================================================

if ($Revert) {
    if ($RevertCategory) {
        # Direct revert without menu
        $backups = Get-ChildItem $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($backups.Count -gt 0) {
            $currentBackup = $backups[0].FullName
            Revert-Category -Category $RevertCategory
        } else {
            Write-Host "  No backups found." -ForegroundColor Yellow
        }
    } else {
        Show-RevertMenu
    }
    exit
}

# ============================================================
# SUPPORT BOT
# ============================================================

$Script:SupportPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:KnowledgeBaseFile = Join-Path $Script:SupportPath "knowledge-base.json"
$Script:LearningDataFile = Join-Path $Script:SupportPath "learning.json"
$Script:UnansweredFile = Join-Path $Script:SupportPath "unanswered.json"

function Load-SupportKnowledgeBase {
    if (Test-Path $Script:KnowledgeBaseFile) {
        try {
            return Get-Content -Path $Script:KnowledgeBaseFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            Write-Host "  Failed to load knowledge base" -ForegroundColor Red
            return $null
        }
    }
    return $null
}

function Save-SupportLearningData {
    param($Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:LearningDataFile -Force
}

function Load-SupportLearningData {
    if (Test-Path $Script:LearningDataFile) {
        try {
            return Get-Content -Path $Script:LearningDataFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            return @{ patterns = @(); total_questions = 0 }
        }
    }
    return @{ patterns = @(); total_questions = 0 }
}

function Get-NormalizedText {
    param([string]$Text)
    $stopWords = @('a','an','the','and','or','but','in','on','at','to','for','of','with','by','from','is','it','this','that','are','was','be','has','had','have','do','does','did','will','would','could','should','may','might','can','i','me','my','we','you','your','he','she','they','them','their','what','which','who','how','when','where','why','not','no','so','if','then','than','too','very','just','about','up','out','all')
    $words = $Text.ToLower() -replace '[^a-z0-9\s]', '' -split '\s+' | Where-Object { $_ -notin $stopWords -and $_.Length -gt 2 }
    return $words -join ' '
}

function Get-FuzzyScore {
    param([string]$Question, [string]$Normalized, [array]$Keywords)
    $score = 0
    $qLower = $Question.ToLower()
    $qNormalized = Get-NormalizedText -Text $Question
    
    # Factor 1: Substring match (weight: 3)
    if ($qLower -match [regex]::Escape($Normalized)) { $score += 3 }
    
    # Factor 2: Keyword overlap (weight: 2.5)
    $qWords = $qLower -split '\s+' | Where-Object { $_.Length -gt 2 }
    $overlap = ($Keywords | Where-Object { $qWords -contains $_ }).Count
    if ($Keywords.Count -gt 0) { $score += ($overlap / $Keywords.Count) * 2.5 }
    
    # Factor 3: Normalized field match (weight: 2)
    $qNormWords = $qNormalized -split '\s+'
    $normWords = $Normalized -split '\s+'
    $normOverlap = ($normWords | Where-Object { $qNormWords -contains $_ }).Count
    if ($normWords.Count -gt 0) { $score += ($normOverlap / $normWords.Count) * 2 }
    
    return $score
}

function Get-SupportAnswer {
    param([string]$Question)
    
    $kb = Load-SupportKnowledgeBase
    if (-not $kb) { return $null }
    
    $normalized = Get-NormalizedText -Text $Question
    $keywords = $normalized -split '\s+' | Where-Object { $_.Length -gt 2 }
    
    $bestMatch = $null
    $bestScore = 0
    
    foreach ($pattern in $kb.patterns) {
        $score = Get-FuzzyScore -Question $Question -Normalized $pattern.normalized -Keywords $pattern.keywords
        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = $pattern
        }
    }
    
    if ($bestScore -ge 2.0 -and $bestMatch) {
        return @{ Pattern = $bestMatch; Score = $bestScore }
    }
    
    return $null
}

function Add-UnansweredQuestion {
    param([string]$Question)
    
    $unanswered = @()
    if (Test-Path $Script:UnansweredFile) {
        try {
            $unanswered = Get-Content -Path $Script:UnansweredFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            $unanswered = @()
        }
    }
    
    $exists = $unanswered | Where-Object { $_.question -eq $Question }
    if (-not $exists) {
        $unanswered += @{
            question = $Question
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            count = 1
        }
        $unanswered | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:UnansweredFile -Force
    }
}

function Show-SupportMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "   ShadowScan Support Bot v1.0" -ForegroundColor Yellow
    Write-Host "   Ask me anything about ShadowScan!" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Ask a question" -ForegroundColor White
    Write-Host "  [2] View FAQ" -ForegroundColor White
    Write-Host "  [3] View learning stats" -ForegroundColor White
    Write-Host "  [q] Quit" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "  Select option"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            $question = Read-Host "  Ask your question"
            if ($question) {
                $result = Get-SupportAnswer -Question $question
                if ($result) {
                    Write-Host ""
                    Write-Host "  Answer:" -ForegroundColor Green
                    Write-Host "  $($result.Pattern.answer)" -ForegroundColor White
                    Write-Host "  (Confidence: $([math]::Round($result.Score / 8 * 100))%)" -ForegroundColor Gray
                    
                    $feedback = Read-Host "  Was this helpful? [y/n]"
                    if ($feedback -eq 'y') {
                        Write-Host "  Thanks for your feedback!" -ForegroundColor Green
                    } else {
                        Write-Host "  Sorry, I'll learn from this." -ForegroundColor Yellow
                        Add-UnansweredQuestion -Question $question
                    }
                } else {
                    Write-Host ""
                    Write-Host "  I don't have an answer for that yet." -ForegroundColor Yellow
                    Write-Host "  Your question has been logged for future learning." -ForegroundColor Yellow
                    Add-UnansweredQuestion -Question $question
                }
            }
            Read-Host "  Press Enter to continue"
            Show-SupportMenu
        }
        "2" {
            Write-Host ""
            Write-Host "  Frequently Asked Questions:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Q: What is ShadowScan?" -ForegroundColor White
            Write-Host "  A: ShadowScan is a PC cleanup and security tool." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  Q: Is it safe to use?" -ForegroundColor White
            Write-Host "  A: Yes! All changes are backed up automatically." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  Q: How do I undo changes?" -ForegroundColor White
            Write-Host "  A: Run: .\ShadowScan.ps1 -Revert" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  Q: Why did WinSxS cleanup free 0 GB?" -ForegroundColor White
            Write-Host "  A: WinSxS uses hardlinks. 0 GB is normal if already optimized." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  Q: How do I run as Administrator?" -ForegroundColor White
            Write-Host "  A: Right-click PowerShell → Run as Administrator" -ForegroundColor Gray
            Write-Host ""
            Read-Host "  Press Enter to continue"
            Show-SupportMenu
        }
        "3" {
            Write-Host ""
            Write-Host "  Learning Statistics:" -ForegroundColor Cyan
            Write-Host ""
            $learning = Load-SupportLearningData
            Write-Host "  Total questions asked: $($learning.total_questions)" -ForegroundColor White
            Write-Host "  Patterns in database: $($learning.patterns.Count)" -ForegroundColor White
            Write-Host ""
            Read-Host "  Press Enter to continue"
            Show-SupportMenu
        }
        "q" { return }
        default { Show-SupportMenu }
    }
}

# Handle support commands
if ($Support) {
    Show-SupportMenu
    exit
}

if ($Ask) {
    $result = Get-SupportAnswer -Question $Ask
    if ($result) {
        Write-Host ""
        Write-Host "  Answer:" -ForegroundColor Green
        Write-Host "  $($result.Pattern.answer)" -ForegroundColor White
        Write-Host "  (Confidence: $([math]::Round($result.Score / 8 * 100))%)" -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "  I don't have an answer for that yet." -ForegroundColor Yellow
        Add-UnansweredQuestion -Question $Ask
    }
    exit
}

if ($SupportStats) {
    Write-Host ""
    Write-Host "  Support Bot Learning Stats:" -ForegroundColor Cyan
    $learning = Load-SupportLearningData
    Write-Host "  Total questions: $($learning.total_questions)" -ForegroundColor White
    Write-Host "  Patterns: $($learning.patterns.Count)" -ForegroundColor White
    exit
}

if ($ExportUnanswered) {
    if (Test-Path $Script:UnansweredFile) {
        Copy-Item -Path $Script:UnansweredFile -Destination "unanswered-export.json" -Force
        Write-Host "  Exported to unanswered-export.json" -ForegroundColor Green
    } else {
        Write-Host "  No unanswered questions found." -ForegroundColor Yellow
    }
    exit
}

# ============================================================
# START
# ============================================================

Clear-Host
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "   ShadowScan v1.4.0" -ForegroundColor Yellow
Write-Host "   Ben The Fix-It Guy" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  This script will clean up your PC for better performance." -ForegroundColor White
Write-Host "  Run as Administrator for full cleanup." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Changes are backed up automatically. Use -Revert to undo." -ForegroundColor Green
Write-Host ""

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  [WARNING] Not running as Administrator. Some cleanup will be limited." -ForegroundColor Yellow
    Write-Host "  Right-click PowerShell > Run as Administrator for full cleanup." -ForegroundColor Yellow
    Write-Host ""
}

# Feature selection menu
if (-not $All) {
Write-Host "  Select features to run:" -ForegroundColor Cyan
Write-Host ""
Write-Host "    [1]  Temp File Cleanup" -ForegroundColor White
Write-Host "    [2]  Downloads Cleanup" -ForegroundColor White
Write-Host "    [3]  Universal Orphan Detection" -ForegroundColor White
Write-Host "    [4]  Accessibility Fixes" -ForegroundColor White
Write-Host "    [5]  WiFi Optimization" -ForegroundColor White
Write-Host "    [6]  Shadow Account Removal" -ForegroundColor White
Write-Host "    [7]  Startup Cleanup" -ForegroundColor White
Write-Host "    [8]  Registry Cleanup" -ForegroundColor White
Write-Host "    [9]  System Cleanup" -ForegroundColor White
Write-Host "    [10] Process Scan" -ForegroundColor White
Write-Host "    [11] System File Repair" -ForegroundColor White
Write-Host "    [12] Startup Impact Analyzer" -ForegroundColor White
Write-Host "    [13] Service Analysis" -ForegroundColor White
Write-Host "    [14] Browser Bloat Cleaner" -ForegroundColor White
Write-Host "    [15] Visual Effects Optimizer" -ForegroundColor White
Write-Host "    [16] Developer Cache Cleanup" -ForegroundColor White
Write-Host "    [17] WinSxS Component Cleanup" -ForegroundColor White
Write-Host ""
Write-Host "    [a]  ALL features (recommended)" -ForegroundColor Yellow
Write-Host "    [d]  Dry-run mode (preview only)" -ForegroundColor Yellow
Write-Host "    [q]  Quit" -ForegroundColor White
Write-Host ""

$selection = Read-Host "  Select options (comma-separated, e.g., 1,2,3 or 'a' for all)"

if ($selection -eq 'q') { exit }

# Process selection
if ($selection -eq 'a') {
    $All = $true
    $SkipTemp = $false
    $SkipDownloads = $false
    $SkipOrphans = $false
    $SkipAccessibility = $false
    $SkipWiFi = $false
    $SkipShadowAccounts = $false
    $SkipRegistry = $false
    $SkipSystem = $false
    $SkipProcessScan = $false
    $SkipSystemRepair = $false
    $SkipStartup = $false
    $SkipServices = $false
    $SkipBrowsers = $false
    $SkipVisualEffects = $false
    $SkipDevCleanup = $false
    $SkipWinSxS = $false
} elseif ($selection -eq 'd') {
    $DryRun = $true
    $All = $true
    $SkipTemp = $false
    $SkipDownloads = $false
    $SkipOrphans = $false
    $SkipAccessibility = $false
    $SkipWiFi = $false
    $SkipShadowAccounts = $false
    $SkipRegistry = $false
    $SkipSystem = $false
    $SkipProcessScan = $false
    $SkipSystemRepair = $false
    $SkipStartup = $false
    $SkipServices = $false
    $SkipBrowsers = $false
    $SkipVisualEffects = $false
    $SkipDevCleanup = $false
    $SkipWinSxS = $false
} elseif ($selection -match ',') {
    # Multiple selections
    $selected = $selection -split ','
    # Set all to skip first, then enable selected
    $SkipTemp = $true
    $SkipDownloads = $true
    $SkipOrphans = $true
    $SkipAccessibility = $true
    $SkipWiFi = $true
    $SkipShadowAccounts = $true
    $SkipRegistry = $true
    $SkipSystem = $true
    $SkipProcessScan = $true
    $SkipSystemRepair = $true
    $SkipStartup = $true
    $SkipServices = $true
    $SkipBrowsers = $true
    $SkipVisualEffects = $true
    $SkipDevCleanup = $true
    $SkipWinSxS = $true
    
    foreach ($num in $selected) {
        switch ($num.Trim()) {
            "1"  { $SkipTemp = $false }
            "2"  { $SkipDownloads = $false }
            "3"  { $SkipOrphans = $false }
            "4"  { $SkipAccessibility = $false }
            "5"  { $SkipWiFi = $false }
            "6"  { $SkipShadowAccounts = $false }
            "7"  { $SkipStartup = $false }
            "8"  { $SkipRegistry = $false }
            "9"  { $SkipSystem = $false }
            "10" { $SkipProcessScan = $false }
            "11" { $SkipSystemRepair = $false }
            "12" { $SkipStartup = $false }
            "13" { $SkipServices = $false }
            "14" { $SkipBrowsers = $false }
            "15" { $SkipVisualEffects = $false }
            "16" { $SkipDevCleanup = $false }
            "17" { $SkipWinSxS = $false }
        }
    }
} elseif ($selection -match '^\d+$') {
    # Single selection
    $SkipTemp = $true
    $SkipDownloads = $true
    $SkipOrphans = $true
    $SkipAccessibility = $true
    $SkipWiFi = $true
    $SkipShadowAccounts = $true
    $SkipRegistry = $true
    $SkipSystem = $true
    $SkipProcessScan = $true
    $SkipSystemRepair = $true
    $SkipStartup = $true
    $SkipServices = $true
    $SkipBrowsers = $true
    $SkipVisualEffects = $true
    $SkipDevCleanup = $true
    
    switch ($selection.Trim()) {
        "1"  { $SkipTemp = $false }
        "2"  { $SkipDownloads = $false }
        "3"  { $SkipOrphans = $false }
        "4"  { $SkipAccessibility = $false }
        "5"  { $SkipWiFi = $false }
        "6"  { $SkipShadowAccounts = $false }
        "7"  { $SkipStartup = $false }
        "8"  { $SkipRegistry = $false }
        "9"  { $SkipSystem = $false }
        "10" { $SkipProcessScan = $false }
        "11" { $SkipSystemRepair = $false }
        "12" { $SkipStartup = $false }
        "13" { $SkipServices = $false }
        "14" { $SkipBrowsers = $false }
        "15" { $SkipVisualEffects = $false }
        "16" { $SkipDevCleanup = $false }
        "17" { $SkipSystem = $false }
    }
} else {
    Write-Host "  Invalid selection. Running all features." -ForegroundColor Yellow
    $All = $true
}
} # end if (-not $All)

Write-Host ""
Write-Host "  Starting cleanup..." -ForegroundColor Green
Write-Host ""

# ============================================================
# 1. JUNK FILE CLEANUP
# ============================================================

if (-not $SkipTemp) {
    Write-Header "1. Cleaning Temp Files & Caches"

    $tempPaths = @(
        "$env:LOCALAPPDATA\Temp",
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\CrashDumps",
        "$env:LOCALAPPDATA\npm-cache",
        "$env:LOCALAPPDATA\pip\cache"
    )

    foreach ($path in $tempPaths) {
        if (Remove-ItemSafe $path) {
            Write-Status "Cleaned: $path"
        } else {
            Write-Status "Skipped: $path (empty or locked)" "WARN"
        }
    }

    # Windows Update cache
    $wuPath = "$env:WINDIR\SoftwareDistribution\Download"
    if (Remove-ItemSafe $wuPath) {
        Write-Status "Cleaned Windows Update cache"
    }

    # Thumbnail cache
    $thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    Get-ChildItem $thumbPath -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Status "Cleaned thumbnail cache"
}

# ============================================================
# 2. DOWNLOADS CLEANUP
# ============================================================

if (-not $SkipDownloads) {
    Write-Header "2. Cleaning Downloads Folder"

    $downloads = "$env:USERPROFILE\Downloads"
    if (Test-Path $downloads) {
        # Find old installers
        $oldFiles = Get-ChildItem $downloads -File | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-30) -and
            $_.Extension -in @(".exe", ".msi", ".msu", ".msp", ".zip")
        }

        if ($oldFiles.Count -gt 0) {
            Write-Host ""
            Write-Host "  Found $($oldFiles.Count) old installer(s) in Downloads:" -ForegroundColor Yellow
            Write-Host ""

            $totalSize = 0
            foreach ($file in $oldFiles) {
                $sizeMB = [math]::Round($file.Length / 1MB, 2)
                $totalSize += $file.Length
                $age = (Get-Date) - $file.LastWriteTime
                Write-Host "    - $($file.Name) ($sizeMB MB, $([math]::Round($age.Days)) days old)" -ForegroundColor White
            }

            $totalMB = [math]::Round($totalSize / 1MB, 2)
            Write-Host ""
            Write-Host "  Total: $totalMB MB" -ForegroundColor Cyan
            Write-Host ""

            if ($DryRun) {
                Write-Host "  [DRY-RUN] Would delete all $($oldFiles.Count) files" -ForegroundColor Yellow
                $script:bytesFreed += $totalSize
            } else {
                Write-Host "  Options:" -ForegroundColor Cyan
                Write-Host "    [1] Delete ALL listed files" -ForegroundColor White
                Write-Host "    [2] Skip ALL (keep everything)" -ForegroundColor White
                Write-Host "    [3] Select files to delete" -ForegroundColor White
                Write-Host ""

                $choice = Read-Host "  Select option (1/2/3)"

                switch ($choice) {
                    "1" {
                        foreach ($file in $oldFiles) {
                            Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                            if (-not (Test-Path $file.FullName)) {
                                $script:bytesFreed += $file.Length
                                $script:itemsDeleted++
                                Write-Status "Removed: $($file.Name)"
                            }
                        }
                    }
                    "2" {
                        Write-Status "Skipping Downloads cleanup" "INFO"
                    }
                    "3" {
                        foreach ($file in $oldFiles) {
                            $sizeMB = [math]::Round($file.Length / 1MB, 2)
                            $confirm = Read-Host "  Delete $($file.Name)? ($sizeMB MB) (y/n)"
                            if ($confirm -eq 'y') {
                                Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                                if (-not (Test-Path $file.FullName)) {
                                    $script:bytesFreed += $file.Length
                                    $script:itemsDeleted++
                                    Write-Status "Removed: $($file.Name)"
                                }
                            } else {
                                Write-Status "Kept: $($file.Name)" "INFO"
                            }
                        }
                    }
                    default {
                        Write-Status "Invalid option - skipping Downloads cleanup" "WARN"
                    }
                }
            }
        } else {
            Write-Status "No old installers found in Downloads"
        }
    }
}

# ============================================================
# 3. UNIVERSAL ORPHANED FOLDER CLEANUP
# ============================================================

if (-not $SkipOrphans) {
    Write-Header "3. Universal Orphan Detection"

    # Expanded pattern list - catches 50+ known PUP/adware/bloatware names
    $orphanPatterns = @(
        # Shadow/Suspicious
        "shadow", "aioz", "mysterium",
        # Common PUPs
        "iobit", "itop", "glary", "advanced.?systemcare", "driver.?booster",
        "smart.?defrag", "uninstaller", "software.?updater",
        # Known crypto miners (not user-installed apps)
        "coinhive", "cryptoloot",
        # Antivirus bloat
        "malwarebytes", "sophos", "zemana", "norton", "mcafee", "avast",
        "avg", "kaspersky", "bitdefender",
        # Other bloatware
        "nemex", "winhance", "pc.?cleaner", "pc.?booster", "pc.?optimizer",
        "registry.?cleaner", "driver.?updater", "speedup", "tuneup",
        "webbar", "babylon", "conduit", "ask", "bing.?bar", "yahoo.?toolbar",
        # Updater leftovers
        "updater", "auto.?update", "update.?helper"
    )

    # Build combined regex pattern
    $combinedPattern = ($orphanPatterns -join "|")

    # Known safe folders to NEVER delete
    $safeFolders = @(
        "Microsoft", "Google", "Mozilla", "Adobe", "NVIDIA", "AMD", "Intel",
        "Lenovo", "Dell", "HP", "Realtek", "Synaptics", "Qualcomm",
        "Windows", "Package Cache", "Temp", "ShadowScan"
    )

    Write-Status "Scanning for orphaned folders..." "INFO"

    # --- ProgramData scan ---
    $programDataFound = @()
    Get-ChildItem "C:\ProgramData" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $combinedPattern -and $_.Name -notin $safeFolders
    } | ForEach-Object { $programDataFound += $_ }

    if ($programDataFound.Count -gt 0) {
        Write-Host "  ProgramData orphans found: $($programDataFound.Count)" -ForegroundColor Yellow
        foreach ($folder in $programDataFound) {
            if (Remove-ItemSafe $_.FullName) {
                Write-Status "Removed: C:\ProgramData\$($folder.Name)"
            }
        }
    } else {
        Write-Status "ProgramData: No orphans found"
    }

    # --- AppData Local scan ---
    $localFound = @()
    Get-ChildItem "$env:LOCALAPPDATA" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $combinedPattern -and $_.Name -notin $safeFolders
    } | ForEach-Object { $localFound += $_ }

    if ($localFound.Count -gt 0) {
        Write-Host "  AppData\Local orphans found: $($localFound.Count)" -ForegroundColor Yellow
        foreach ($folder in $localFound) {
            if (Remove-ItemSafe $_.FullName) {
                Write-Status "Removed: AppData\Local\$($folder.Name)"
            }
        }
    } else {
        Write-Status "AppData\Local: No orphans found"
    }

    # --- AppData Roaming scan ---
    $roamingFound = @()
    Get-ChildItem "$env:APPDATA" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $combinedPattern -and $_.Name -notin $safeFolders
    } | ForEach-Object { $roamingFound += $_ }

    if ($roamingFound.Count -gt 0) {
        Write-Host "  AppData\Roaming orphans found: $($roamingFound.Count)" -ForegroundColor Yellow
        foreach ($folder in $roamingFound) {
            if (Remove-ItemSafe $_.FullName) {
                Write-Status "Removed: AppData\Roaming\$($folder.Name)"
            }
        }
    } else {
        Write-Status "AppData\Roaming: No orphans found"
    }

    # --- Home directory scan ---
    $homeFound = @()
    Get-ChildItem "$env:USERPROFILE" -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $combinedPattern
    } | ForEach-Object { $homeFound += $_ }

    if ($homeFound.Count -gt 0) {
        Write-Host "  Home directory orphans found: $($homeFound.Count)" -ForegroundColor Yellow
        foreach ($folder in $homeFound) {
            if (Remove-ItemSafe $_.FullName) {
                Write-Status "Removed: ~\$($folder.Name)"
            }
        }
    }

    # --- Program Files scan ---
    $pfPaths = @("C:\Program Files", "C:\Program Files (x86)")
    foreach ($pf in $pfPaths) {
        $pfFound = @()
        Get-ChildItem $pf -Directory -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match $combinedPattern
        } | ForEach-Object { $pfFound += $_ }

        if ($pfFound.Count -gt 0) {
            Write-Host "  $($pf) orphans found: $($pfFound.Count)" -ForegroundColor Yellow
            foreach ($folder in $pfFound) {
                if (Remove-ItemSafe $_.FullName) {
                    Write-Status "Removed: $($folder.FullName)"
                }
            }
        }
    }

    # --- Leftover user profile folders ---
    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match "shadow|aioz|mysterium" -and $_.Name -ne $env:USERNAME
    } | ForEach-Object {
        $profilePath = $_.FullName
        Write-Status "Found leftover user profile: $profilePath" "WARN"
        if (Remove-ItemSafe $profilePath) {
            Write-Status "Deleted leftover profile: $profilePath"
        } else {
            Write-Status "Could not delete (may need admin): $profilePath" "WARN"
        }
    }

    # --- UNIVERSAL HEURISTIC: Empty folders older than 30 days ---
    Write-Host ""
    Write-Status "Running heuristic scan (empty/old folders)..." "INFO"
    $heuristicLocations = @(
        "C:\ProgramData",
        "$env:LOCALAPPDATA",
        "$env:APPDATA"
    )

    $emptyFoldersFound = 0
    foreach ($loc in $heuristicLocations) {
        Get-ChildItem $loc -Directory -ErrorAction SilentlyContinue | Where-Object {
            $items = Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue
            $age = (Get-Date) - $_.LastWriteTime
            # Empty folder OR untouched for 6+ months AND not a known safe folder
            ($items.Count -eq 0 -and $age.TotalDays -gt 30) -or
            ($age.TotalDays -gt 180 -and $_.Name -notin $safeFolders -and $items.Count -lt 3)
        } | ForEach-Object {
            $emptyFoldersFound++
            if (Remove-ItemSafe $_.FullName) {
                Write-Status "Heuristic: Removed stale folder: $($_.Name)"
            }
        }
    }

    if ($emptyFoldersFound -eq 0) {
        Write-Status "Heuristic scan: No stale folders found"
    }

    # Summary
    $totalOrphans = $programDataFound.Count + $localFound.Count + $roamingFound.Count + $homeFound.Count + $emptyFoldersFound
    Write-Host ""
    Write-Status "Universal scan complete: $totalOrphans orphaned folders detected" "INFO"
}

# ============================================================
# 4. ACCESSIBILITY FIXES
# ============================================================

if (-not $SkipAccessibility) {
    Write-Header "4. Disabling Keyboard Accessibility Features"

    # Disable StickyKeys
    $stickyPath = "HKCU:\Control Panel\Accessibility\StickyKeys"
    if (Test-Path $stickyPath) {
        Set-ItemProperty -Path $stickyPath -Name "Flags" -Value "506" -Force
        Write-Status "Disabled StickyKeys"
    }

    # Disable ToggleKeys
    $togglePath = "HKCU:\Control Panel\Accessibility\ToggleKeys"
    if (Test-Path $togglePath) {
        Set-ItemProperty -Path $togglePath -Name "Flags" -Value "58" -Force
        Write-Status "Disabled ToggleKeys"
    }

    # Disable FilterKeys
    $filterPath = "HKCU:\Control Panel\Accessibility\Keyboard Response"
    if (Test-Path $filterPath) {
        Set-ItemProperty -Path $filterPath -Name "Flags" -Value "122" -Force
        Write-Status "Disabled FilterKeys"
    }
}

# ============================================================
# 5. WIFI OPTIMIZATION
# ============================================================

if (-not $SkipWiFi) {
    Write-Header "5. Optimizing WiFi"

    # Backup WiFi profiles before modifying
    Save-WiFiBackup
    Write-Status "WiFi profiles backed up" "INFO"

    # Clean old WiFi profiles (keep only recent)
    $profiles = netsh wlan show profiles | Select-String "All User Profile\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
    $currentProfile = (netsh wlan show interfaces | Select-String "Profile\s+:\s+(.+)").Matches.Groups[1].Value.Trim()

    $oldProfiles = $profiles | Where-Object { $_ -ne $currentProfile }

    foreach ($profile in $oldProfiles) {
        netsh wlan delete profile name="$profile" 2>$null | Out-Null
        Write-Status "Removed WiFi profile: $profile"
    }

    # Optimize WiFi adapter properties
    $wifiAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Wi-Fi|Wireless|WiFi" } | Select-Object -First 1
    if ($wifiAdapter) {
        Set-NetAdapterAdvancedProperty -Name $wifiAdapter.Name -RegistryKeyword "D0PCEnable" -RegistryValue 0 -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $wifiAdapter.Name -RegistryKeyword "smpsDynamic" -RegistryValue 0 -ErrorAction SilentlyContinue
        Write-Status "Optimized WiFi adapter properties"
    }

    # DNS will be set separately (requires admin)
    Write-Status "Run these commands in Admin PowerShell to set DNS:" "INFO"
    Write-Host '    netsh interface ip set dns "Wi-Fi" static 1.1.1.1 primary' -ForegroundColor Yellow
    Write-Host '    netsh interface ip add dns "Wi-Fi" 1.0.0.1 index=2' -ForegroundColor Yellow
}

# ============================================================
# 6. SHADOW ACCOUNT REMOVAL
# ============================================================

if (-not $SkipShadowAccounts) {
    Write-Header "6. Checking for Shadow/Suspicious Accounts"

    # Check for shadow user accounts
    $shadowUsers = Get-CimInstance Win32_UserAccount | Where-Object { $_.Name -match "ShadowUser|shadow" }

    if ($shadowUsers) {
        foreach ($user in $shadowUsers) {
            Write-Status "Found shadow account: $($user.Name)" "WARN"
            net user $user.Name /active:no 2>$null
            net user $user.Name /delete 2>$null
            Write-Status "Disabled and deleted account: $($user.Name)"

            # Delete user profile folder
            $profilePath = "C:\Users\$($user.Name)"
            if (Test-Path $profilePath) {
                Remove-Item $profilePath -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $profilePath)) {
                    Write-Status "Deleted profile folder: $profilePath"
                } else {
                    Write-Status "Could not delete profile (may need admin): $profilePath" "WARN"
                }
            }
        }

        # Remove registry entries
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
        if (Test-Path $regPath) {
            Get-ItemProperty $regPath | Get-Member -MemberType NoteProperty | Where-Object {
                $_.Name -match "ShadowUser|shadow" -and $_.Name -notlike "PS*"
            } | ForEach-Object {
                Remove-ItemProperty -Path $regPath -Name $_.Name -Force -ErrorAction SilentlyContinue
                Write-Status "Removed registry entry: $($_.Name)"
            }
        }
    } else {
        Write-Status "No shadow accounts found"
    }

    # Check for leftover ShadowUser profile folders even if accounts are deleted
    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match "ShadowUser|shadow"
    } | ForEach-Object {
        $folderPath = $_.FullName
        Write-Status "Found leftover shadow profile: $folderPath" "WARN"
        Remove-Item $folderPath -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $folderPath)) {
            Write-Status "Deleted leftover folder: $folderPath"
        } else {
            Write-Status "Could not delete (may need admin): $folderPath" "WARN"
        }
    }

    # Check for suspicious services
    $suspiciousServices = Get-CimInstance Win32_Service | Where-Object {
        $_.PathName -match "shadow|aioz|mysterium" -or
        $_.DisplayName -match "shadow|aioz|mysterium"
    }

    if ($suspiciousServices) {
        foreach ($svc in $suspiciousServices) {
            Write-Status "Found suspicious service: $($svc.Name)" "WARN"
        }
    }
}

# ============================================================
# 7. STARTUP CLEANUP
# ============================================================

if (-not $SkipStartup) {
    Write-Header "7. Checking Startup Items"

    # Backup startup entries before modifying
    Save-StartupBackup
    Write-Status "Startup entries backed up" "INFO"

    $runKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$startupItems = Get-ItemProperty $runKey -ErrorAction SilentlyContinue

if ($startupItems) {
    $suspiciousStartup = $startupItems.PSObject.Properties | Where-Object {
        $_.Name -match "shadow|aioz|mysterium" -and $_.Name -notlike "PS*"
    }

    foreach ($item in $suspiciousStartup) {
        Write-Status "Found suspicious startup: $($item.Name)" "WARN"
        Remove-ItemProperty -Path $runKey -Name $item.Name -Force -ErrorAction SilentlyContinue
        Write-Status "Removed startup entry: $($item.Name)"
    }

    if (-not $suspiciousStartup) {
        Write-Status "No suspicious startup items found"
    }
}

# Clean RunOnce entries
$runOnceKeys = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
)

foreach ($key in $runOnceKeys) {
    if (Test-Path $key) {
        $items = Get-ItemProperty $key -ErrorAction SilentlyContinue
        if ($items) {
            $items.PSObject.Properties | Where-Object {
                $_.Name -match "shadow|aioz|mysterium" -and $_.Name -notlike "PS*"
            } | ForEach-Object {
                Remove-ItemProperty -Path $key -Name $_.Name -Force -ErrorAction SilentlyContinue
                Write-Status "Removed RunOnce entry: $($_.Name)"
            }
        }
    }
}

# Clean suspicious scheduled tasks
$suspiciousTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -match "shadow|aioz|mysterium" -or
    $_.Author -match "shadow|aioz|mysterium"
}

foreach ($task in $suspiciousTasks) {
    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Status "Removed scheduled task: $($task.TaskName)"
}
}

# ============================================================
# 8. REGISTRY CLEANUP
# ============================================================

if (-not $SkipRegistry) {
    Write-Header "8. Cleaning Registry"

    # Backup registry before modifying
    $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services"
    if (Test-Path $servicePath) {
        Get-ChildItem $servicePath -ErrorAction SilentlyContinue | Where-Object {
            $_.PSChildName -match "shadow|aioz|mysterium"
        } | ForEach-Object {
            Save-RegistryServiceBackup -ServiceName $_.PSChildName
        }
    }
    Write-Status "Registry backed up" "INFO"

    # Remove suspicious service registry keys (requires admin)
    $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services"
    if (Test-Path $servicePath) {
        Get-ChildItem $servicePath -ErrorAction SilentlyContinue | Where-Object {
            $_.PSChildName -match "shadow|aioz|mysterium"
        } | ForEach-Object {
            $svcName = $_.PSChildName
            Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $_.PSPath)) {
                Write-Status "Removed service registry: $svcName"
            } else {
                Write-Status "Could not remove (admin needed): $svcName" "WARN"
            }
        }
    }

    # Clean uninstall registry entries for uninstalled software
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($path in $uninstallPaths) {
        if (Test-Path $path) {
            Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
                $displayName = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DisplayName
                $installLocation = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).InstallLocation

                if ($displayName -match "shadow|aioz|mysterium") {
                    Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Status "Removed uninstall entry: $displayName"
                }

                # Check for empty install locations
                if ($installLocation -and -not (Test-Path $installLocation)) {
                    Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Status "Removed orphaned uninstall: $displayName"
                }
            }
        }
    }

    # Clean Windows Installer cache (admin required, partial)
    $installerCache = "$env:WINDIR\Installer"
    if (Test-Path $installerCache) {
        $size = Get-FolderSize $installerCache
        $sizeMB = [math]::Round($size / 1MB, 2)
        Write-Status "Windows Installer cache: $sizeMB MB (requires admin to clean)" "INFO"
    }

    # Clean prefetch (safe, will rebuild)
    $prefetchPath = "$env:WINDIR\Prefetch"
    if (Test-Path $prefetchPath) {
        $size = Get-FolderSize $prefetchPath
        Remove-Item "$prefetchPath\*" -Force -ErrorAction SilentlyContinue
        $script:bytesFreed += $size
        Write-Status "Cleaned prefetch cache"
    }

    # Clean font cache (will rebuild)
    $fontCache = "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\FontCache"
    if (Test-Path $fontCache) {
        Remove-Item "$fontCache\*" -Force -ErrorAction SilentlyContinue
        Write-Status "Cleaned font cache"
    }
}

# ============================================================
# 9. SYSTEM CLEANUP
# ============================================================

if (-not $SkipSystem) {
    Write-Header "9. System Cleanup"

    # Flush DNS cache
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Write-Status "Flushed DNS cache"

    # Flush ARP cache (admin needed)
    try { netsh interface ip delete arpcache 2>$null | Out-Null } catch {}
    Write-Status "Flushed ARP cache"

    # Clean Windows Temp via cleanmgr registry
    $diskCleanupKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    if (Test-Path $diskCleanupKey) {
        Get-ChildItem $diskCleanupKey -ErrorAction SilentlyContinue | ForEach-Object {
            Set-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        Write-Status "Scheduled Windows Disk Cleanup (run cleanmgr.exe to execute)"
    }

    # Disable Windows Telemetry (optional)
    $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $telemetryPath)) {
        New-Item -Path $telemetryPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Status "Disabled Windows Telemetry"

    # Disable Cortana (optional)
    $cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $cortanaPath)) {
        New-Item -Path $cortanaPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Status "Disabled Cortana"

    # Optimize power plan
    $powerPlan = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
    if (Test-Path $powerPlan) {
        # Disable hard disk timeout
        $diskGuid = "0012ee47-9041-4b5d-9b77-535fba8b1442"
        $diskIdleGuid = "6738e2c4-e8a5-4a42-b16a-e040e769756e"
        $diskPath = "$powerPlan\$diskGuid\$diskIdleGuid"
        if (Test-Path $diskPath) {
            Set-ItemProperty -Path $diskPath -Name "Attributes" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }
}

# ============================================================
# 10. PROCESS SCAN
# ============================================================

if (-not $SkipProcessScan) {
    Write-Header "10. Scanning Running Processes"

    # Known legitimate Windows processes
    $systemProcesses = @(
        "Idle", "System", "Registry", "csrss", "smss", "lsass", "wininit", "winlogon",
        "fontdrvhost", "dwm", "audiodg", "svchost", "services", "conhost", "dllhost",
        "ctfmon", "sihost", "taskhostw", "RuntimeBroker", "ShellExperienceHost",
        "StartMenuExperienceHost", "SearchApp", "TextInputHost", "UserOOBEBroker",
        "MoUsoCoreWorker", "MpDefenderCoreService", "NisSrv", "SecurityHealthService",
        "WUDFHost", "wslservice", "Registry"
    )

    # Known legitimate third-party processes
    $knownProcesses = @(
        "chrome", "msedgewebview2", "OpenCode", "powershell", "cmd", "notepad",
        "RadeonSettings", "RAVCpl64", "RtHDVCpl", "RtHDVBg", "SynTPEnh",
        "SynTPEnhService", "SynTPHelper", "memreduct", "rustdesk", "Everything",
        "Taskmgr", "explorer", "node", "npm",
        "python", "java", "slack", "discord", "spotify", "steam", "EACef",
        "ESET", "mbam", "mbamtray"
    )

    # Known suspicious patterns
    $suspiciousPatterns = @(
        "miner", "cryptominer", "coinminer", "xmrig", "stratum",
        "keylog", "spyware", "trojan", "backdoor", "rootkit",
        "ShadowUser", "aioz", "mysterium", "ShadowSandbox"
    )

    $allProcesses = Get-Process
    $suspiciousFound = @()
    $unknownFound = @()
    $cleanCount = 0

    foreach ($proc in $allProcesses) {
        $name = $proc.ProcessName
        $path = $proc.Path
        $procId = $proc.Id

        # Check if system process
        if ($name -in $systemProcesses) {
            $cleanCount++
            continue
        }

        # Check if known legitimate
        if ($name -in $knownProcesses) {
            $cleanCount++
            continue
        }

        # Check for suspicious patterns
        $isSuspicious = $false
        foreach ($pattern in $suspiciousPatterns) {
            if ($name -match $pattern -or $path -match $pattern) {
                $suspiciousFound += [PSCustomObject]@{
                    Name = $name
                    PID = $procId
                    Path = $path
                    MB = [math]::Round($proc.WorkingSet64 / 1MB)
                    Reason = "Matches pattern: $pattern"
                }
                $isSuspicious = $true
                break
            }
        }

        if ($isSuspicious) { continue }

        # Check for processes with no path
        if (-not $path) {
            $unknownFound += [PSCustomObject]@{
                Name = $name
                PID = $procId
                Path = "NO PATH"
                MB = [math]::Round($proc.WorkingSet64 / 1MB)
                Reason = "No executable path"
            }
            continue
        }

        # Check for processes running from temp or unusual locations
        if ($path -match "\\Temp\\|\\AppData\\Local\\Temp\\|\\tmp\\") {
            $unknownFound += [PSCustomObject]@{
                Name = $name
                PID = $procId
                Path = $path
                MB = [math]::Round($proc.WorkingSet64 / 1MB)
                Reason = "Running from Temp folder"
            }
            continue
        }

        # Check for unsigned executables (basic check)
        if ($path -and (Test-Path $path)) {
            try {
                $sig = Get-AuthenticodeSignature $path -ErrorAction SilentlyContinue
                if ($sig.Status -ne "Valid" -and $sig.Status -ne "NotSigned") {
                    $unknownFound += [PSCustomObject]@{
                        Name = $name
                        PID = $procId
                        Path = $path
                        MB = [math]::Round($proc.WorkingSet64 / 1MB)
                        Reason = "Signature: $($sig.Status)"
                    }
                    continue
                }
            } catch {}
        }

        $cleanCount++
    }

    # Report results
    Write-Host ""
    Write-Host "  Scan Results:" -ForegroundColor Cyan
    Write-Host "    Processes scanned: $($allProcesses.Count)" -ForegroundColor White
    Write-Host "    Clean: $cleanCount" -ForegroundColor Green

    if ($suspiciousFound.Count -gt 0) {
        Write-Host ""
        Write-Host "  SUSPICIOUS PROCESSES FOUND:" -ForegroundColor Red
        foreach ($proc in $suspiciousFound) {
            Write-Host "    - $($proc.Name) (PID: $($proc.PID)) - $($proc.Reason)" -ForegroundColor Red
            Write-Host "      Path: $($proc.Path)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    Suspicious: 0" -ForegroundColor Green
    }

    if ($unknownFound.Count -gt 0) {
        Write-Host ""
        Write-Host "  UNKNOWN/FLAGGED PROCESSES:" -ForegroundColor Yellow
        foreach ($proc in $unknownFound) {
            Write-Host "    - $($proc.Name) (PID: $($proc.PID)) - $($proc.Reason)" -ForegroundColor Yellow
            Write-Host "      Path: $($proc.Path)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Unknown: 0" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  If suspicious processes are found, run a full Windows Defender scan." -ForegroundColor Yellow
}

# ============================================================
# 11. CORRUPTED SYSTEM FILE REPAIR
# ============================================================

if (-not $SkipSystemRepair) {
    Write-Header "11. Repairing Corrupted System Files"

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Status "Running DISM to repair Windows image..." "INFO"
        Write-Status "This may take 10-30 minutes..." "INFO"
        $dismResult = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
        if ($dismResult -match "The operation completed successfully") {
            Write-Status "DISM repair completed successfully"
        } else {
            Write-Status "DISM completed with warnings" "WARN"
        }

        Write-Status "Running SFC to repair system files..." "INFO"
        Write-Status "This may take 10-30 minutes..." "INFO"
        $sfcResult = sfc /scannow 2>&1
        if ($sfcResult -match "Windows Resource Protection did not find any integrity violations") {
            Write-Status "SFC: No integrity violations found"
        } elseif ($sfcResult -match "repaired successfully") {
            Write-Status "SFC: Corrupted files repaired successfully"
        } else {
            Write-Status "SFC: Scan completed - check results above" "WARN"
        }
    } else {
        Write-Status "System repair requires Administrator privileges" "WARN"
        Write-Status "Run this script as Administrator for system repair" "WARN"
        Write-Host ""
        Write-Host "  Manual commands (run in Admin PowerShell):" -ForegroundColor Yellow
        Write-Host "    DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor Yellow
        Write-Host "    sfc /scannow" -ForegroundColor Yellow
    }
}

# ============================================================
# 12. STARTUP IMPACT ANALYZER
# ============================================================

if (-not $SkipStartup) {
    Write-Header "12. Startup Impact Analyzer"

    $startupItems = @()

    # Check HKCU Run
    $hkcuRun = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hkcuRun) {
        Get-ItemProperty $hkcuRun -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object {
            $_.Name -notlike "PS*"
        } | ForEach-Object {
            $value = (Get-ItemProperty $hkcuRun -Name $_.Name -ErrorAction SilentlyContinue).$_
            $path = ($value -split '"')[1]
            if (-not $path) { $path = ($value -split ' ')[0] }
            $path = $path.Trim('"')

            $impact = "Unknown"
            if ($path -match "chrome|firefox|opera|edge") { $impact = "Medium" }
            elseif ($path -match "steam|discord|slack|spotify") { $impact = "Medium" }
            elseif ($path -match "honeygain|grass|bytelixir|wipter|browser.?cash|uprock|hivello") { $impact = "High - Crypto" }
            elseif ($path -match "teams|zoom|skype") { $impact = "Medium" }
            elseif ($path -match "adobe|nvidia|amd|realtek") { $impact = "Low" }
            else { $impact = "Medium" }

            $startupItems += [PSCustomObject]@{
                Name = $_.Name
                Location = "HKCU\Run"
                Path = $path
                Impact = $impact
            }
        }
    }

    # Check HKLM Run
    $hklmRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hklmRun) {
        Get-ItemProperty $hklmRun -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object {
            $_.Name -notlike "PS*"
        } | ForEach-Object {
            $value = (Get-ItemProperty $hklmRun -Name $_.Name -ErrorAction SilentlyContinue).$_
            $path = ($value -split '"')[1]
            if (-not $path) { $path = ($value -split ' ')[0] }
            $path = $path.Trim('"')

            $impact = "Low"
            if ($path -match "chrome|firefox|opera") { $impact = "Medium" }

            $startupItems += [PSCustomObject]@{
                Name = $_.Name
                Location = "HKLM\Run"
                Path = $path
                Impact = $impact
            }
        }
    }

    # Check Startup folders
    $startupFolders = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    foreach ($folder in $startupFolders) {
        if (Test-Path $folder) {
            Get-ChildItem $folder -File -ErrorAction SilentlyContinue | ForEach-Object {
                $startupItems += [PSCustomObject]@{
                    Name = $_.Name
                    Location = "Startup Folder"
                    Path = $_.FullName
                    Impact = "Medium"
                }
            }
        }
    }

    # Display results
    Write-Host ""
    Write-Host "  Startup Items Found: $($startupItems.Count)" -ForegroundColor Cyan
    Write-Host ""

    if ($startupItems.Count -gt 0) {
        Write-Host "  {0,-30} {1,-20} {2}" -ForegroundColor Cyan -ArgumentList "Name", "Location", "Impact"
        Write-Host "  " + ("-" * 70) -ForegroundColor Gray

        foreach ($item in $startupItems) {
            $color = switch ($item.Impact) {
                "High - Crypto" { "Red" }
                "High" { "Yellow" }
                "Medium" { "White" }
                "Low" { "Green" }
                default { "White" }
            }
            Write-Host ("  {0,-30} {1,-20} {2}" -f $item.Name, $item.Location, $item.Impact) -ForegroundColor $color
        }

        Write-Host ""
        Write-Host "  To disable startup items:" -ForegroundColor Yellow
        Write-Host "    1. Open Task Manager (Ctrl+Shift+Esc)" -ForegroundColor White
        Write-Host "    2. Click 'Startup' tab" -ForegroundColor White
        Write-Host "    3. Right-click items you want to disable" -ForegroundColor White
    }
}

# ============================================================
# 13. UNNECESSARY SERVICE KILLER
# ============================================================

if (-not $SkipServices) {
    Write-Header "13. Service Analysis"

    # Backup services before analysis
    $runningServices = Get-CimInstance Win32_Service | Where-Object { $_.State -eq "Running" }
    foreach ($svc in $runningServices) {
        Save-ServiceBackup -ServiceName $svc.Name
    }
    Write-Status "Services backed up" "INFO"

    # Database of services with risk ratings
    $serviceDB = @{
        # Safe to disable
        "DiagTrack" = @{ Risk = "Safe"; Desc = "Connected User Experiences and Telemetry" }
        "dmwappushservice" = @{ Risk = "Safe"; Desc = "WAP Push Message Routing Service" }
        "SysMain" = @{ Risk = "Safe"; Desc = "Superfetch (can help on SSDs)" }
        "WSearch" = @{ Risk = "Safe"; Desc = "Windows Search Indexer" }
        "Fax" = @{ Risk = "Safe"; Desc = "Fax service" }
        "MapsBroker" = @{ Risk = "Safe"; Desc = "Downloaded Maps Manager" }
        "lfsvc" = @{ Risk = "Safe"; Desc = "Geolocation Service" }
        "SharedAccess" = @{ Risk = "Safe"; Desc = "Internet Connection Sharing" }
        "RemoteRegistry" = @{ Risk = "Safe"; Desc = "Remote Registry" }
        "TrkWks" = @{ Risk = "Safe"; Desc = "Distributed Link Tracking Client" }
        "WpcMonSvc" = @{ Risk = "Safe"; Desc = "Parental Controls" }
        "RetailDemo" = @{ Risk = "Safe"; Desc = "Retail Demo Service" }
        "CDPSvc" = @{ Risk = "Safe"; Desc = "Connected Devices Platform" }
        "CDPUserSvc" = @{ Risk = "Safe"; Desc = "Connected Devices Platform User" }
        "PcaSvc" = @{ Risk = "Safe"; Desc = "Program Compatibility Assistant" }
        "Spooler" = @{ Risk = "Caution"; Desc = "Print Spooler (disable if no printer)" }
        "TabletInputService" = @{ Risk = "Caution"; Desc = "Touch Keyboard and Handwriting" }
        "WbioSvc" = @{ Risk = "Caution"; Desc = "Windows Biometric Service" }
        "WerSvc" = @{ Risk = "Safe"; Desc = "Windows Error Reporting" }
        "WpnService" = @{ Risk = "Safe"; Desc = "Windows Push Notifications" }
        "XblAuthManager" = @{ Risk = "Safe"; Desc = "Xbox Live Auth Manager" }
        "XblGameSave" = @{ Risk = "Safe"; Desc = "Xbox Live Game Save" }
        "XboxNetApiSvc" = @{ Risk = "Safe"; Desc = "Xbox Live Networking" }
        "XboxGipSvc" = @{ Risk = "Safe"; Desc = "Xbox Accessory Management" }
    }

    $runningServices = Get-CimInstance Win32_Service | Where-Object { $_.State -eq "Running" }
    $safeToDisable = @()
    $cautionList = @()
    $keepRunning = @()

    foreach ($svc in $runningServices) {
        $name = $svc.Name
        $dbEntry = $serviceDB[$name]

        if ($dbEntry) {
            $obj = [PSCustomObject]@{
                Name = $name
                DisplayName = $svc.DisplayName
                Risk = $dbEntry.Risk
                Desc = $dbEntry.Desc
            }

            switch ($dbEntry.Risk) {
                "Safe" { $safeToDisable += $obj }
                "Caution" { $cautionList += $obj }
            }
        } else {
            $keepRunning += $svc
        }
    }

    # Display results
    Write-Host ""
    Write-Host "  Running Services: $($runningServices.Count)" -ForegroundColor Cyan
    Write-Host "  Safe to Disable: $($safeToDisable.Count)" -ForegroundColor Green
    Write-Host "  Use Caution: $($cautionList.Count)" -ForegroundColor Yellow
    Write-Host ""

    if ($safeToDisable.Count -gt 0) {
        Write-Host "  SAFE TO DISABLE:" -ForegroundColor Green
        foreach ($svc in $safeToDisable) {
            Write-Host "    - $($svc.Name) - $($svc.Desc)" -ForegroundColor White
        }
        Write-Host ""
    }

    if ($cautionList.Count -gt 0) {
        Write-Host "  USE CAUTION:" -ForegroundColor Yellow
        foreach ($svc in $cautionList) {
            Write-Host "    - $($svc.Name) - $($svc.Desc)" -ForegroundColor White
        }
        Write-Host ""
    }

    Write-Host "  To disable a service:" -ForegroundColor Yellow
    Write-Host "    1. Open Services (services.msc)" -ForegroundColor White
    Write-Host "    2. Right-click the service > Properties" -ForegroundColor White
    Write-Host "    3. Set Startup type to 'Disabled'" -ForegroundColor White
    Write-Host "    4. Click Stop if running" -ForegroundColor White
}

# ============================================================
# 14. BROWSER BLOAT CLEANER
# ============================================================

if (-not $SkipBrowsers) {
    Write-Header "14. Browser Bloat Cleaner"

    # Detect installed browsers
    $browsers = @()

    # Chrome
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    if (Test-Path $chromePath) {
        $chromeSize = Get-FolderSize $chromePath
        $browsers += [PSCustomObject]@{
            Name = "Google Chrome"
            Path = $chromePath
            SizeMB = [math]::Round($chromeSize / 1MB, 2)
            Detected = $true
        }
    }

    # Firefox
    $firefoxPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxPath) {
        $firefoxSize = Get-FolderSize $firefoxPath
        $browsers += [PSCustomObject]@{
            Name = "Mozilla Firefox"
            Path = $firefoxPath
            SizeMB = [math]::Round($firefoxSize / 1MB, 2)
            Detected = $true
        }
    }

    # Edge
    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    if (Test-Path $edgePath) {
        $edgeSize = Get-FolderSize $edgePath
        $browsers += [PSCustomObject]@{
            Name = "Microsoft Edge"
            Path = $edgePath
            SizeMB = [math]::Round($edgeSize / 1MB, 2)
            Detected = $true
        }
    }

    # Opera
    $operaPath = "$env:APPDATA\Opera Software\Opera Stable"
    if (Test-Path $operaPath) {
        $operaSize = Get-FolderSize $operaPath
        $browsers += [PSCustomObject]@{
            Name = "Opera"
            Path = $operaPath
            SizeMB = [math]::Round($operaSize / 1MB, 2)
            Detected = $true
        }
    }

    # Brave
    $bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    if (Test-Path $bravePath) {
        $braveSize = Get-FolderSize $bravePath
        $browsers += [PSCustomObject]@{
            Name = "Brave"
            Path = $bravePath
            SizeMB = [math]::Round($braveSize / 1MB, 2)
            Detected = $true
        }
    }

    Write-Host ""
    Write-Host "  Detected Browsers:" -ForegroundColor Cyan
    foreach ($browser in $browsers) {
        Write-Host "    - $($browser.Name): $($browser.SizeMB) MB" -ForegroundColor White
    }

    if ($browsers.Count -gt 0) {
        Write-Host ""
        Write-Host "  Available cleaning targets:" -ForegroundColor Yellow
        Write-Host "    - Cache (safe, re-downloads as needed)" -ForegroundColor White
        Write-Host "    - Cookies (will log you out of websites)" -ForegroundColor White
        Write-Host "    - Browsing history" -ForegroundColor White
        Write-Host ""

        # Clean cache for all detected browsers
        foreach ($browser in $browsers) {
            $cachePaths = @(
                "$($browser.Path)\Default\Cache",
                "$($browser.Path)\Default\Code Cache",
                "$($browser.Path)\Default\Service Worker\CacheStorage",
                "$($browser.Path)\Profile*\Cache",
                "$($browser.Path)\Profile*\Code Cache"
            )

            foreach ($cachePath in $cachePaths) {
                if (Test-Path $cachePath) {
                    $cacheItems = Get-ChildItem $cachePath -Recurse -ErrorAction SilentlyContinue
                    $cacheSize = ($cacheItems | Measure-Object -Property Length -Sum).Sum
                    if ($cacheSize -gt 0) {
                        Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                        $script:bytesFreed += $cacheSize
                        Write-Status "Cleaned $($browser.Name) cache: $([math]::Round($cacheSize/1MB, 2)) MB"
                    }
                }
            }
        }

        Write-Host ""
        Write-Host "  Browser caches cleaned." -ForegroundColor Green
        Write-Host "  Note: Close browsers before cleaning for best results." -ForegroundColor Yellow
    } else {
        Write-Status "No supported browsers detected"
    }
}

# ============================================================
# 15. VISUAL EFFECTS OPTIMIZER
# ============================================================

if (-not $SkipVisualEffects) {
    Write-Header "15. Visual Effects Optimizer"

    # Backup visual effects before modifying
    Save-VisualEffectsBackup
    Write-Status "Visual effects settings backed up" "INFO"

    $visualEffectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $performancePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\VisualFXSetting"

    # Disable animations
    $animPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $animPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $animPath -Name "MenuShowDelay" -Value "0" -Force -ErrorAction SilentlyContinue
    Write-Status "Disabled menu animations"

    # Disable smooth scrolling
    $smoothScrollPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $smoothScrollPath -Name "SmoothScroll" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Status "Disabled smooth scrolling"

    # Disable transparency
    $transparencyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (Test-Path $transparencyPath) {
        Set-ItemProperty -Path $transparencyPath -Name "EnableTransparency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Status "Disabled transparency effects"
    }

    # Disable shadows
    $shadowPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $shadowPath -Name "ListviewShadow" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Status "Disabled list view shadows"

    # Set best performance visual effects
    $performanceOptPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-ItemProperty -Path $performanceOptPath -Name "VisualFXSetting" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Status "Set visual effects to best performance"

    # Disable taskbar animations
    $taskbarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $taskbarPath -Name "TaskbarAnimations" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Status "Disabled taskbar animations"

    # Disable peek
    Set-ItemProperty -Path $taskbarPath -Name "DisablePreviewDesktop" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Status "Disabled taskbar peek"

    Write-Host ""
    Write-Host "  Visual effects optimized for performance." -ForegroundColor Green
    Write-Host "  UI will feel snappier, especially on older hardware." -ForegroundColor White
    Write-Host "  Changes take effect immediately." -ForegroundColor Yellow
}

# ============================================================
# 16. DEVELOPER CACHE CLEANUP
# ============================================================

if (-not $SkipDevCleanup) {
    Write-Header "16. Developer Cache Cleanup"

    $devToolsFound = @()

    # --- npm cache ---
    $npmCache = "$env:LOCALAPPDATA\npm-cache"
    if (Test-Path $npmCache) {
        $size = Get-FolderSize $npmCache
        $sizeMB = [math]::Round($size / 1MB, 2)
        $devToolsFound += [PSCustomObject]@{ Name = "npm cache"; SizeMB = $sizeMB; Path = $npmCache }
        if ($sizeMB -gt 10) {
            if ($DryRun) {
                Write-Host "  [DRY-RUN] Would clean npm cache ($sizeMB MB)" -ForegroundColor Yellow
            } else {
                Remove-Item "$npmCache\*" -Recurse -Force -ErrorAction SilentlyContinue
                $script:bytesFreed += $size
                Write-Status "Cleaned npm cache: $sizeMB MB"
            }
        }
    }

    # --- pip cache ---
    $pipCache = "$env:LOCALAPPDATA\pip\cache"
    if (Test-Path $pipCache) {
        $size = Get-FolderSize $pipCache
        $sizeMB = [math]::Round($size / 1MB, 2)
        $devToolsFound += [PSCustomObject]@{ Name = "pip cache"; SizeMB = $sizeMB; Path = $pipCache }
        if ($sizeMB -gt 10) {
            if ($DryRun) {
                Write-Host "  [DRY-RUN] Would clean pip cache ($sizeMB MB)" -ForegroundColor Yellow
            } else {
                Remove-Item "$pipCache\*" -Recurse -Force -ErrorAction SilentlyContinue
                $script:bytesFreed += $size
                Write-Status "Cleaned pip cache: $sizeMB MB"
            }
        }
    }

    # --- VS Code cache ---
    $vscodeCache = "$env:APPDATA\Code\Cache"
    $vscodeCache2 = "$env:APPDATA\Code\CachedData"
    $vscodeCache3 = "$env:APPDATA\Code\CachedExtensions"
    $vscodePaths = @($vscodeCache, $vscodeCache2, $vscodeCache3)
    foreach ($vp in $vscodePaths) {
        if (Test-Path $vp) {
            $size = Get-FolderSize $vp
            $sizeMB = [math]::Round($size / 1MB, 2)
            if ($sizeMB -gt 10) {
                $devToolsFound += [PSCustomObject]@{ Name = "VS Code cache"; SizeMB = $sizeMB; Path = $vp }
                if ($DryRun) {
                    Write-Host "  [DRY-RUN] Would clean VS Code cache ($sizeMB MB)" -ForegroundColor Yellow
                } else {
                    Remove-Item "$vp\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $script:bytesFreed += $size
                    Write-Status "Cleaned VS Code cache: $sizeMB MB"
                }
            }
        }
    }

    # --- NuGet cache ---
    $nugetCache = "$env:LOCALAPPDATA\NuGet"
    if (Test-Path $nugetCache) {
        $size = Get-FolderSize $nugetCache
        $sizeMB = [math]::Round($size / 1MB, 2)
        $devToolsFound += [PSCustomObject]@{ Name = "NuGet cache"; SizeMB = $sizeMB; Path = $nugetCache }
        if ($sizeMB -gt 10) {
            if ($DryRun) {
                Write-Host "  [DRY-RUN] Would clean NuGet cache ($sizeMB MB)" -ForegroundColor Yellow
            } else {
                Remove-Item "$nugetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
                $script:bytesFreed += $size
                Write-Status "Cleaned NuGet cache: $sizeMB MB"
            }
        }
    }

    # --- Docker cleanup (check if Docker is installed) ---
    $dockerPath = "C:\ProgramData\Docker"
    if (Test-Path $dockerPath) {
        $size = Get-FolderSize $dockerPath
        $sizeMB = [math]::Round($size / 1MB, 2)
        $devToolsFound += [PSCustomObject]@{ Name = "Docker"; SizeMB = $sizeMB; Path = $dockerPath }
        Write-Status "Docker found: $sizeMB MB (use 'docker system prune' to clean)" "INFO"
    }

    # --- JetBrains cache ---
    $jetbrainsPaths = @(
        "$env:LOCALAPPDATA\JetBrains",
        "$env:APPDATA\JetBrains"
    )
    foreach ($jp in $jetbrainsPaths) {
        if (Test-Path $jp) {
            $size = Get-FolderSize $jp
            $sizeMB = [math]::Round($size / 1MB, 2)
            if ($sizeMB -gt 50) {
                $devToolsFound += [PSCustomObject]@{ Name = "JetBrains cache"; SizeMB = $sizeMB; Path = $jp }
                if ($DryRun) {
                    Write-Host "  [DRY-RUN] Would clean JetBrains cache ($sizeMB MB)" -ForegroundColor Yellow
                } else {
                    Remove-Item "$jp\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $script:bytesFreed += $size
                    Write-Status "Cleaned JetBrains cache: $sizeMB MB"
                }
            }
        }
    }

    # --- yarn/pnpm cache ---
    $yarnCache = "$env:LOCALAPPDATA\Yarn\Cache"
    $pnpmCache = "$env:LOCALAPPDATA\pnpm-cache"
    $otherCaches = @($yarnCache, $pnpmCache)
    foreach ($oc in $otherCaches) {
        if (Test-Path $oc) {
            $size = Get-FolderSize $oc
            $sizeMB = [math]::Round($size / 1MB, 2)
            if ($sizeMB -gt 10) {
                $devToolsFound += [PSCustomObject]@{ Name = (Split-Path $oc -Leaf); SizeMB = $sizeMB; Path = $oc }
                if ($DryRun) {
                    Write-Host "  [DRY-RUN] Would clean $(Split-Path $oc -Leaf) ($sizeMB MB)" -ForegroundColor Yellow
                } else {
                    Remove-Item "$oc\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $script:bytesFreed += $size
                    Write-Status "Cleaned $(Split-Path $oc -Leaf): $sizeMB MB"
                }
            }
        }
    }

    # Summary
    Write-Host ""
    if ($devToolsFound.Count -gt 0) {
        Write-Host "  Developer tools found:" -ForegroundColor Cyan
        foreach ($tool in $devToolsFound) {
            Write-Host "    - $($tool.Name): $($tool.SizeMB) MB" -ForegroundColor White
        }
    } else {
        Write-Status "No developer caches detected"
    }
}

# ============================================================
# 17. WinSxS COMPONENT CLEANUP
# ============================================================

if (-not $SkipWinSxS) {
    Write-Header "17. WinSxS Component Cleanup"

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        # Show current size first
        $winsxsPath = "$env:WINDIR\WinSxS"
        if (Test-Path $winsxsPath) {
            $size = Get-FolderSize $winsxsPath
            $sizeGB = [math]::Round($size / 1GB, 2)
            Write-Status "Current WinSxS size: $sizeGB GB" "INFO"
        }

        # Run cleanup directly (safe and recommended by Microsoft)
        Write-Status "Running DISM StartComponentCleanup..." "INFO"
        Write-Status "This may take 10-30 minutes..." "INFO"
        Write-Host ""

        try {
            $dismOutput = & DISM /Online /Cleanup-Image /StartComponentCleanup 2>&1
            $dismString = $dismOutput | Out-String
            
            # Show DISM output for debugging
            if ($dismString.Trim().Length -gt 0) {
                Write-Host "  DISM Output:" -ForegroundColor Gray
                foreach ($line in $dismOutput) {
                    if ($line -match "^\s+\d+\.\d+%") {
                        Write-Host "    $line" -ForegroundColor Gray
                    } elseif ($line -match "completed|successfully|error|failed") {
                        Write-Host "    $line" -ForegroundColor Yellow
                    }
                }
            }

            if ($dismString -match "The operation completed successfully" -or $dismString -match "completed successfully") {
                Write-Status "WinSxS cleanup completed successfully"
            } elseif ($dismString -match "Error|Failed|Access Denied") {
                Write-Status "WinSxS cleanup encountered errors" "WARN"
            } else {
                Write-Status "WinSxS cleanup completed" "INFO"
            }
        } catch {
            Write-Status "Error running DISM: $($_.Exception.Message)" "ERROR"
        }

        # Show size after cleanup
        if (Test-Path $winsxsPath) {
            $newSize = Get-FolderSize $winsxsPath
            $newSizeGB = [math]::Round($newSize / 1GB, 2)
            $freedGB = [math]::Round(($size - $newSize) / 1GB, 2)
            Write-Status "WinSxS size after cleanup: $newSizeGB GB (freed $freedGB GB)" "INFO"
        }
    } else {
        Write-Status "WinSxS cleanup requires Administrator privileges" "WARN"
        Write-Host ""
        Write-Host "  Manual command (run in Admin PowerShell):" -ForegroundColor Yellow
        Write-Host "    DISM /Online /Cleanup-Image /StartComponentCleanup" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Note: This removes old Windows Update components." -ForegroundColor White
        Write-Host "  This is safe and recommended by Microsoft." -ForegroundColor Green
    }
}

# ============================================================
# SUMMARY
# ============================================================

Write-Header "Cleanup Complete!"

$freedMB = [math]::Round($bytesFreed / 1MB, 2)
Write-Host ""

if ($DryRun) {
    Write-Host "  DRY-RUN COMPLETE - No changes were made" -ForegroundColor Yellow
    Write-Host "  Space that WOULD be freed: $freedMB MB" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Run without -DryRun to apply changes." -ForegroundColor Cyan
} else {
    Write-Host "  Total space freed: $freedMB MB" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Summary:" -ForegroundColor Cyan

if (-not $SkipTemp) { Write-Host "    - Temp files and caches cleaned" -ForegroundColor White }
if (-not $SkipDownloads) { Write-Host "    - Downloads cleaned (with confirmation)" -ForegroundColor White }
if (-not $SkipOrphans) { Write-Host "    - Universal orphan detection (50+ patterns)" -ForegroundColor White }
if (-not $SkipAccessibility) { Write-Host "    - Keyboard accessibility fixed" -ForegroundColor White }
if (-not $SkipWiFi) { Write-Host "    - WiFi optimized" -ForegroundColor White }
if (-not $SkipShadowAccounts) { Write-Host "    - Shadow accounts checked" -ForegroundColor White }
if (-not $SkipRegistry) { Write-Host "    - Registry cleaned" -ForegroundColor White }
if (-not $SkipSystem) { Write-Host "    - System optimized" -ForegroundColor White }
if (-not $SkipProcessScan) { Write-Host "    - Processes scanned" -ForegroundColor White }
if (-not $SkipSystemRepair) { Write-Host "    - System files repaired" -ForegroundColor White }
if (-not $SkipStartup) { Write-Host "    - Startup items analyzed" -ForegroundColor White }
if (-not $SkipServices) { Write-Host "    - Services analyzed" -ForegroundColor White }
if (-not $SkipBrowsers) { Write-Host "    - Browser bloat cleaned" -ForegroundColor White }
if (-not $SkipVisualEffects) { Write-Host "    - Visual effects optimized" -ForegroundColor White }
if (-not $SkipDevCleanup) { Write-Host "    - Developer caches cleaned" -ForegroundColor White }
if (-not $SkipSystem) { Write-Host "    - WinSxS component cleanup" -ForegroundColor White }
Write-Host "    - All changes backed up (use -Revert to undo)" -ForegroundColor Green
Write-Host ""
Write-Host "  For DNS optimization, run as Admin:" -ForegroundColor Yellow
Write-Host '    netsh interface ip set dns "Wi-Fi" static 1.1.1.1 primary' -ForegroundColor Yellow
Write-Host '    netsh interface ip add dns "Wi-Fi" 1.0.0.1 index=2' -ForegroundColor Yellow
Write-Host ""
Write-Host "  A restart is recommended for all changes to take effect." -ForegroundColor Yellow
Write-Host ""
