#Requires -Version 5.1
<#
.SYNOPSIS
    ShadowScan Pro - GUI Edition
.DESCRIPTION
    Professional PC cleanup and security tool with GUI interface.
.NOTES
    Author: Ben The Fix-It Guy
    Version: 2.0.0
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Script:Colors = @{
    Background = [System.Drawing.Color]::FromArgb(26, 26, 46)
    Surface    = [System.Drawing.Color]::FromArgb(22, 33, 62)
    Primary    = [System.Drawing.Color]::FromArgb(0, 255, 136)
    Accent     = [System.Drawing.Color]::FromArgb(0, 212, 255)
    Text       = [System.Drawing.Color]::FromArgb(255, 255, 255)
    TextDim    = [System.Drawing.Color]::FromArgb(150, 150, 170)
    Danger     = [System.Drawing.Color]::FromArgb(255, 71, 87)
    Warning    = [System.Drawing.Color]::FromArgb(255, 165, 2)
}

$Script:Form = New-Object System.Windows.Forms.Form
$Script:Form.Text = "ShadowScan Pro v2.0"
$Script:Form.Size = New-Object System.Drawing.Size(900, 700)
$Script:Form.StartPosition = "CenterScreen"
$Script:Form.FormBorderStyle = "FixedSingle"
$Script:Form.MaximizeBox = $false
$Script:Form.BackColor = $Script:Colors.Background
$Script:Form.ForeColor = $Script:Colors.Text
$Script:Form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$hdr = New-Object System.Windows.Forms.Panel
$hdr.Location = New-Object System.Drawing.Point(0, 0)
$hdr.Size = New-Object System.Drawing.Size(900, 80)
$hdr.BackColor = $Script:Colors.Surface
$Script:Form.Controls.Add($hdr)

$title = New-Object System.Windows.Forms.Label
$title.Text = "SHADOWSCAN PRO"
$title.Location = New-Object System.Drawing.Point(20, 8)
$title.Size = New-Object System.Drawing.Size(500, 40)
$title.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $Script:Colors.Primary
$hdr.Controls.Add($title)

$sub = New-Object System.Windows.Forms.Label
$sub.Text = "Scan for shadows. Remove the threats."
$sub.Location = New-Object System.Drawing.Point(22, 48)
$sub.Size = New-Object System.Drawing.Size(400, 25)
$sub.ForeColor = $Script:Colors.TextDim
$hdr.Controls.Add($sub)

$ver = New-Object System.Windows.Forms.Label
$ver.Text = "v2.0.0"
$ver.Location = New-Object System.Drawing.Point(820, 30)
$ver.Size = New-Object System.Drawing.Size(60, 25)
$ver.ForeColor = $Script:Colors.TextDim
$ver.TextAlign = "MiddleRight"
$hdr.Controls.Add($ver)

$fp = New-Object System.Windows.Forms.GroupBox
$fp.Text = " Select Features "
$fp.Location = New-Object System.Drawing.Point(20, 90)
$fp.Size = New-Object System.Drawing.Size(420, 420)
$fp.BackColor = $Script:Colors.Surface
$fp.ForeColor = $Script:Colors.Text
$fp.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Script:Form.Controls.Add($fp)

$Script:FeatureNames = @(
    "Temp File Cleanup",
    "Downloads Cleanup",
    "Orphaned Folder Detection",
    "Accessibility Fixes",
    "WiFi Optimization",
    "Shadow Account Removal",
    "Startup Cleanup",
    "Registry Cleanup",
    "System Optimization",
    "Process Scan",
    "System File Repair",
    "Startup Analyzer",
    "Service Analyzer",
    "Browser Cache Cleanup",
    "Visual Effects Optimizer",
    "Developer Cache Cleanup",
    "WinSxS Component Cleanup"
)

$Script:FeatureFlags = @(
    "-SkipTemp", "-SkipDownloads", "-SkipOrphans", "-SkipAccessibility",
    "-SkipWiFi", "-SkipShadowAccounts", "-SkipRegistry", "-SkipSystem",
    "-SkipProcessScan", "-SkipSystemRepair", "-SkipStartup", "-SkipServices",
    "-SkipBrowsers", "-SkipVisualEffects", "-SkipDevCleanup", "-SkipWinSxS"
)

$Script:CBs = [System.Collections.ArrayList]@()
$y = 25
for ($i = 0; $i -lt $Script:FeatureNames.Count; $i++) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = " $($Script:FeatureNames[$i])"
    $cb.Location = New-Object System.Drawing.Point(12, $y)
    $cb.Size = New-Object System.Drawing.Size(390, 22)
    $cb.Checked = $true
    $cb.ForeColor = $Script:Colors.Text
    $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $fp.Controls.Add($cb)
    $null = $Script:CBs.Add($cb)
    $y += 22
}

$selAll = New-Object System.Windows.Forms.Button
$selAll.Text = "Select All"
$selAll.Location = New-Object System.Drawing.Point(12, 400)
$selAll.Size = New-Object System.Drawing.Size(110, 30)
$selAll.BackColor = $Script:Colors.Accent
$selAll.ForeColor = $Script:Colors.Background
$selAll.FlatStyle = "Flat"
$selAll.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$fp.Controls.Add($selAll)

$desel = New-Object System.Windows.Forms.Button
$desel.Text = "Deselect All"
$desel.Location = New-Object System.Drawing.Point(130, 400)
$desel.Size = New-Object System.Drawing.Size(110, 30)
$desel.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 60)
$desel.ForeColor = $Script:Colors.TextDim
$desel.FlatStyle = "Flat"
$desel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$fp.Controls.Add($desel)

$ap = New-Object System.Windows.Forms.GroupBox
$ap.Text = " Actions "
$ap.Location = New-Object System.Drawing.Point(450, 90)
$ap.Size = New-Object System.Drawing.Size(420, 420)
$ap.BackColor = $Script:Colors.Surface
$ap.ForeColor = $Script:Colors.Text
$ap.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Script:Form.Controls.Add($ap)

$Script:ScanBtn = New-Object System.Windows.Forms.Button
$Script:ScanBtn.Text = "SCAN && CLEAN"
$Script:ScanBtn.Location = New-Object System.Drawing.Point(20, 30)
$Script:ScanBtn.Size = New-Object System.Drawing.Size(380, 55)
$Script:ScanBtn.BackColor = $Script:Colors.Primary
$Script:ScanBtn.ForeColor = $Script:Colors.Background
$Script:ScanBtn.FlatStyle = "Flat"
$Script:ScanBtn.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$ap.Controls.Add($Script:ScanBtn)

$Script:DryBtn = New-Object System.Windows.Forms.Button
$Script:DryBtn.Text = "Dry Run (Preview)"
$Script:DryBtn.Location = New-Object System.Drawing.Point(20, 95)
$Script:DryBtn.Size = New-Object System.Drawing.Size(380, 45)
$Script:DryBtn.BackColor = $Script:Colors.Accent
$Script:DryBtn.ForeColor = $Script:Colors.Background
$Script:DryBtn.FlatStyle = "Flat"
$Script:DryBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$ap.Controls.Add($Script:DryBtn)

$Script:RevBtn = New-Object System.Windows.Forms.Button
$Script:RevBtn.Text = "Revert Changes"
$Script:RevBtn.Location = New-Object System.Drawing.Point(20, 150)
$Script:RevBtn.Size = New-Object System.Drawing.Size(380, 45)
$Script:RevBtn.BackColor = $Script:Colors.Warning
$Script:RevBtn.ForeColor = $Script:Colors.Background
$Script:RevBtn.FlatStyle = "Flat"
$Script:RevBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$ap.Controls.Add($Script:RevBtn)

$Script:SupBtn = New-Object System.Windows.Forms.Button
$Script:SupBtn.Text = "Support"
$Script:SupBtn.Location = New-Object System.Drawing.Point(20, 205)
$Script:SupBtn.Size = New-Object System.Drawing.Size(380, 40)
$Script:SupBtn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 60)
$Script:SupBtn.ForeColor = $Script:Colors.TextDim
$Script:SupBtn.FlatStyle = "Flat"
$Script:SupBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$ap.Controls.Add($Script:SupBtn)

$Script:StatusLbl = New-Object System.Windows.Forms.Label
$Script:StatusLbl.Text = "Ready"
$Script:StatusLbl.Location = New-Object System.Drawing.Point(20, 265)
$Script:StatusLbl.Size = New-Object System.Drawing.Size(380, 30)
$Script:StatusLbl.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$Script:StatusLbl.ForeColor = $Script:Colors.Primary
$Script:StatusLbl.TextAlign = "MiddleCenter"
$ap.Controls.Add($Script:StatusLbl)

$Script:PBar = New-Object System.Windows.Forms.ProgressBar
$Script:PBar.Location = New-Object System.Drawing.Point(20, 305)
$Script:PBar.Size = New-Object System.Drawing.Size(380, 16)
$Script:PBar.Style = "Continuous"
$ap.Controls.Add($Script:PBar)

$lp = New-Object System.Windows.Forms.GroupBox
$lp.Text = " Output Log "
$lp.Location = New-Object System.Drawing.Point(20, 520)
$lp.Size = New-Object System.Drawing.Size(850, 150)
$lp.BackColor = $Script:Colors.Surface
$lp.ForeColor = $Script:Colors.Text
$lp.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Script:Form.Controls.Add($lp)

$Script:Log = New-Object System.Windows.Forms.TextBox
$Script:Log.Location = New-Object System.Drawing.Point(10, 22)
$Script:Log.Size = New-Object System.Drawing.Size(830, 118)
$Script:Log.Multiline = $true
$Script:Log.ScrollBars = "Vertical"
$Script:Log.BackColor = $Script:Colors.Background
$Script:Log.ForeColor = $Script:Colors.Primary
$Script:Log.Font = New-Object System.Drawing.Font("Consolas", 9)
$Script:Log.ReadOnly = $true
$Script:Log.Text = "ShadowScan Pro v2.0`r`nReady. Select features and click SCAN & CLEAN."
$lp.Controls.Add($Script:Log)

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format "HH:mm:ss"
    $Script:Log.AppendText("[$ts] $Msg`r`n")
    $Script:Log.ScrollToCaret()
}

function Set-Status {
    param([string]$Text, [System.Drawing.Color]$Clr)
    $Script:StatusLbl.Text = $Text
    $Script:StatusLbl.ForeColor = $Clr
}

function Get-SelectedFlags {
    $out = @()
    for ($i = 0; $i -lt $Script:CBs.Count; $i++) {
        if ($Script:CBs[$i].Checked) { $out += $Script:FeatureFlags[$i] }
    }
    return $out
}

$selAll.Add_Click({ foreach ($c in $Script:CBs) { $c.Checked = $true }; Write-Log "All features selected" })
$desel.Add_Click({ foreach ($c in $Script:CBs) { $c.Checked = $false }; Write-Log "All features deselected" })

$Script:ScanBtn.Add_Click({
    $flags = Get-SelectedFlags
    if ($flags.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one feature.", "No Features", "OK", "Warning")
        return
    }
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Run cleanup on $($flags.Count) features?`r`n`r`nAll changes are backed up. You can revert anytime.",
        "Confirm", "YesNo", "Question")
    if ($r -eq "No") { return }

    $Script:ScanBtn.Enabled = $false
    $Script:DryBtn.Enabled = $false
    Set-Status "Running..." $Script:Colors.Accent
    $Script:PBar.Value = 0
    Write-Log "Starting cleanup ($($flags.Count) features)..."

    $script = Join-Path $PSScriptRoot "ShadowScan.ps1"
    if (-not (Test-Path $script)) {
        Write-Log "ERROR: ShadowScan.ps1 not found"
        Set-Status "Error" $Script:Colors.Danger
        $Script:ScanBtn.Enabled = $true
        $Script:DryBtn.Enabled = $true
        return
    }

    try {
        $Script:PBar.Value = 20
        $out = & powershell -ExecutionPolicy Bypass -File $script -All @flags 2>&1
        $Script:PBar.Value = 80
        foreach ($line in $out) {
            $s = $line.ToString()
            if ($s -match "\[OK\]") { Write-Log $s }
            elseif ($s -match "\[!\]") { Write-Log "[!] $s" }
            elseif ($s -match "\[X\]") { Write-Log "[X] $s" }
            else { Write-Log $s }
        }
        $Script:PBar.Value = 100
        Set-Status "Complete!" $Script:Colors.Primary
        Write-Log "Done!"
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error" $Script:Colors.Danger
    }
    $Script:ScanBtn.Enabled = $true
    $Script:DryBtn.Enabled = $true
})

$Script:DryBtn.Add_Click({
    $flags = Get-SelectedFlags
    if ($flags.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one feature.", "No Features", "OK", "Warning")
        return
    }
    $Script:ScanBtn.Enabled = $false
    $Script:DryBtn.Enabled = $false
    Set-Status "Previewing..." $Script:Colors.Accent
    $Script:PBar.Value = 0
    Write-Log "DRY RUN ($($flags.Count) features) - No changes will be made"

    $script = Join-Path $PSScriptRoot "ShadowScan.ps1"
    if (-not (Test-Path $script)) {
        Write-Log "ERROR: ShadowScan.ps1 not found"
        Set-Status "Error" $Script:Colors.Danger
        $Script:ScanBtn.Enabled = $true
        $Script:DryBtn.Enabled = $true
        return
    }

    try {
        $Script:PBar.Value = 20
        $out = & powershell -ExecutionPolicy Bypass -File $script -All -DryRun @flags 2>&1
        $Script:PBar.Value = 80
        foreach ($line in $out) {
            $s = $line.ToString()
            if ($s -match "\[DRY-RUN\]") { Write-Log $s }
            elseif ($s -match "\[OK\]") { Write-Log $s }
            else { Write-Log $s }
        }
        $Script:PBar.Value = 100
        Set-Status "Preview Complete" $Script:Colors.Accent
        Write-Log "Dry run finished - no changes made"
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error" $Script:Colors.Danger
    }
    $Script:ScanBtn.Enabled = $true
    $Script:DryBtn.Enabled = $true
})

$Script:RevBtn.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Revert ALL changes made by ShadowScan?",
        "Confirm Revert", "YesNo", "Warning")
    if ($r -eq "No") { return }

    Set-Status "Reverting..." $Script:Colors.Warning
    Write-Log "Starting revert..."

    $script = Join-Path $PSScriptRoot "ShadowScan.ps1"
    if (-not (Test-Path $script)) {
        Write-Log "ERROR: ShadowScan.ps1 not found"
        Set-Status "Error" $Script:Colors.Danger
        return
    }

    try {
        $out = & powershell -ExecutionPolicy Bypass -File $script -Revert 2>&1
        foreach ($line in $out) { Write-Log $line.ToString() }
        Set-Status "Reverted!" $Script:Colors.Primary
        Write-Log "Revert complete"
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error" $Script:Colors.Danger
    }
})

$Script:SupBtn.Add_Click({
    $script = Join-Path $PSScriptRoot "support-bot.ps1"
    if (Test-Path $script) {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$script`" -Support"
    } else {
        [System.Windows.Forms.MessageBox]::Show("Support bot not found.", "Error", "OK", "Error")
    }
})

[void]$Script:Form.ShowDialog()
