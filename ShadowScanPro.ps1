#Requires -Version 5.1
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$xamlPath = Join-Path $PSScriptRoot "gui.xaml"
[xml]$xaml = Get-Content $xamlPath -Raw
$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [System.Windows.Markup.XamlReader]::Load($reader)

$FeatureNames = @(
    "Temp File Cleanup", "Downloads Cleanup", "Orphaned Folder Detection",
    "Accessibility Fixes", "WiFi Optimization", "Shadow Account Removal",
    "Startup Cleanup", "Registry Cleanup", "System Optimization",
    "Process Scan", "System File Repair", "Startup Analyzer",
    "Service Analyzer", "Browser Cache Cleanup", "Visual Effects Optimizer",
    "Developer Cache Cleanup", "WinSxS Component Cleanup"
)

$FeatureFlags = @(
    "-SkipTemp", "-SkipDownloads", "-SkipOrphans", "-SkipAccessibility",
    "-SkipWiFi", "-SkipShadowAccounts", "-SkipRegistry", "-SkipSystem",
    "-SkipProcessScan", "-SkipSystemRepair", "-SkipStartup", "-SkipServices",
    "-SkipBrowsers", "-SkipVisualEffects", "-SkipDevCleanup", "-SkipWinSxS"
)

$FeatureStack = $Window.FindName("FeatureStack")
$Script:CBs = @()

$btnPanel = New-Object System.Windows.Controls.StackPanel
$btnPanel.Orientation = "Horizontal"
$btnPanel.Margin = New-Object System.Windows.Thickness(0,8,0,4)

$allBtn = New-Object System.Windows.Controls.Button
$allBtn.Content = "Select All"
$allBtn.Style = $Window.FindResource("AccentButton")
$allBtn.FontSize = 11
$allBtn.Padding = New-Object System.Windows.Thickness(12,6,12,6)
$allBtn.Margin = New-Object System.Windows.Thickness(0,0,8,0)
$btnPanel.Children.Add($allBtn) | Out-Null

$noneBtn = New-Object System.Windows.Controls.Button
$noneBtn.Content = "Deselect All"
$noneBtn.Style = $Window.FindResource("DarkButton")
$noneBtn.FontSize = 11
$noneBtn.Padding = New-Object System.Windows.Thickness(12,6,12,6)
$btnPanel.Children.Add($noneBtn) | Out-Null

$FeatureStack.Children.Add($btnPanel) | Out-Null

for ($i = 0; $i -lt $FeatureNames.Count; $i++) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $FeatureNames[$i]
    $cb.IsChecked = $true
    $cb.Style = $Window.FindResource("FeatureCheckBox")
    $cb.Margin = New-Object System.Windows.Thickness(4,4,4,2)
    $FeatureStack.Children.Add($cb) | Out-Null
    $Script:CBs += $cb
}

$LogBox = $Window.FindName("LogBox")
$StatusText = $Window.FindName("StatusText")
$ProgressFill = $Window.FindName("ProgressFill")

function Write-Log([string]$Msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $LogBox.AppendText("[$ts] $Msg`r`n")
    $LogBox.ScrollToEnd()
}

function Set-Status([string]$Text, $Clr) {
    $StatusText.Text = $Text
    $StatusText.Foreground = $Clr
}

function Set-Progress([int]$Pct) {
    $ProgressFill.Width = [Math]::Max(0, [Math]::Min(380, 380 * $Pct / 100))
}

function Get-Flags {
    $out = @()
    for ($i = 0; $i -lt $Script:CBs.Count; $i++) {
        if ($Script:CBs[$i].IsChecked -eq $false) { $out += $FeatureFlags[$i] }
    }
    return $out
}

$allBtn.Add_Click({
    foreach ($c in $Script:CBs) { $c.IsChecked = $true }
    Write-Log "All features selected"
})

$noneBtn.Add_Click({
    foreach ($c in $Script:CBs) { $c.IsChecked = $false }
    Write-Log "All features deselected"
})

$Window.FindName("CloseBtn").Add_Click({ $Window.Close() })

$Window.FindName("ScanBtn").Add_Click({
    $flags = Get-Flags
    if ($flags.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Select at least one feature.", "No Features", "OK", "Warning")
        return
    }
    $r = [System.Windows.MessageBox]::Show(
        "Run cleanup on $($flags.Count) features?`r`nAll changes are backed up. You can revert anytime.",
        "Confirm", "YesNo", "Question")
    if ($r -eq "No") { return }

    $Window.FindName("ScanBtn").IsEnabled = $false
    $Window.FindName("DryBtn").IsEnabled = $false
    Set-Status "Running..." $Window.FindResource("AccentBrush")
    Set-Progress 0
    $LogBox.Clear()
    Write-Log "Starting cleanup ($($flags.Count) features)..."

    $script = Join-Path $PSScriptRoot "ShadowScan.ps1"
    if (-not (Test-Path $script)) {
        Write-Log "ERROR: ShadowScan.ps1 not found"
        Set-Status "Error" $Window.FindResource("DangerBrush")
        $Window.FindName("ScanBtn").IsEnabled = $true
        $Window.FindName("DryBtn").IsEnabled = $true
        return
    }

    try {
        Set-Progress 10
        $out = & powershell -ExecutionPolicy Bypass -File $script -All @flags 2>&1
        Set-Progress 90
        foreach ($line in $out) { Write-Log $line.ToString() }
        Set-Progress 100
        Set-Status "Complete!" $Window.FindResource("PrimaryBrush")
        Write-Log "Cleanup complete!"
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error" $Window.FindResource("DangerBrush")
    }
    $Window.FindName("ScanBtn").IsEnabled = $true
    $Window.FindName("DryBtn").IsEnabled = $true
})

$Window.FindName("DryBtn").Add_Click({
    $flags = Get-Flags
    if ($flags.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Select at least one feature.", "No Features", "OK", "Warning")
        return
    }
    $Window.FindName("ScanBtn").IsEnabled = $false
    $Window.FindName("DryBtn").IsEnabled = $false
    Set-Status "Previewing..." $Window.FindResource("AccentBrush")
    Set-Progress 0
    $LogBox.Clear()
    Write-Log "DRY RUN ($($flags.Count) features) - No changes"

    $script = Join-Path $PSScriptRoot "ShadowScan.ps1"
    if (-not (Test-Path $script)) {
        Write-Log "ERROR: ShadowScan.ps1 not found"
        Set-Status "Error" $Window.FindResource("DangerBrush")
        $Window.FindName("ScanBtn").IsEnabled = $true
        $Window.FindName("DryBtn").IsEnabled = $true
        return
    }

    try {
        Set-Progress 10
        $out = & powershell -ExecutionPolicy Bypass -File $script -All -DryRun @flags 2>&1
        Set-Progress 90
        foreach ($line in $out) { Write-Log $line.ToString() }
        Set-Progress 100
        Set-Status "Preview Complete" $Window.FindResource("AccentBrush")
        Write-Log "Dry run finished"
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error" $Window.FindResource("DangerBrush")
    }
    $Window.FindName("ScanBtn").IsEnabled = $true
    $Window.FindName("DryBtn").IsEnabled = $true
})

$Window.FindName("RevertBtn").Add_Click({
    $r = [System.Windows.MessageBox]::Show(
        "Revert ALL changes?", "Confirm Revert", "YesNo", "Warning")
    if ($r -eq "No") { return }

    Set-Status "Reverting..." $Window.FindResource("WarningBrush")
    Write-Log "Starting revert..."

    $script = Join-Path $PSScriptRoot "ShadowScan.ps1"
    if (-not (Test-Path $script)) {
        Write-Log "ERROR: ShadowScan.ps1 not found"
        Set-Status "Error" $Window.FindResource("DangerBrush")
        return
    }

    try {
        $out = & powershell -ExecutionPolicy Bypass -File $script -Revert 2>&1
        foreach ($line in $out) { Write-Log $line.ToString() }
        Set-Status "Reverted!" $Window.FindResource("PrimaryBrush")
        Write-Log "Revert complete"
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error" $Window.FindResource("DangerBrush")
    }
})

$Window.FindName("SupportBtn").Add_Click({
    $bot = Join-Path $PSScriptRoot "support-bot.ps1"
    if (Test-Path $bot) {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$bot`" -Support"
    } else {
        [System.Windows.MessageBox]::Show("Support bot not found.", "Error", "OK", "Error")
    }
})

Write-Log "ShadowScan Pro v2.0 ready"
Write-Log "Select features and click SCAN and CLEAN"

[void]$Window.ShowDialog()
