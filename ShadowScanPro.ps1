#Requires -Version 5.1
<#
.SYNOPSIS
    ShadowScan Pro - WPF GUI Edition
.DESCRIPTION
    Professional PC cleanup and security tool with modern WPF interface.
.NOTES
    Author: Ben The Fix-It Guy
    Version: 2.0.0
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ShadowScan Pro v2.0" Width="920" Height="720"
        WindowStartupLocation="CenterScreen"
        Background="#1a1a2e" Foreground="White"
        ResizeMode="NoResize" WindowStyle="None"
        AllowsTransparency="True" Opacity="0.98">

    <Window.Resources>
        <SolidColorBrush x:Key="BgBrush" Color="#1a1a2e"/>
        <SolidColorBrush x:Key="SurfaceBrush" Color="#16213e"/>
        <SolidColorBrush x:Key="PrimaryBrush" Color="#00ff88"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#00d4ff"/>
        <SolidColorBrush x:Key="TextBrush" Color="#ffffff"/>
        <SolidColorBrush x:Key="TextDimBrush" Color="#9696aa"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#ff4757"/>
        <SolidColorBrush x:Key="WarningBrush" Color="#ffa502"/>

        <Style x:Key="ModernButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="20,12"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"
                                            VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#1e2a4a"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#0f1a30"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource PrimaryBrush}"/>
            <Setter Property="Foreground" Value="#1a1a2e"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="20,16"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                CornerRadius="10"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"
                                            VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#00cc6e"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#009952"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="AccentButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground" Value="#1a1a2e"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="20,14"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"
                                            VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#00b8e6"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#0099cc"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="WarningButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource WarningBrush}"/>
            <Setter Property="Foreground" Value="#1a1a2e"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="20,14"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"
                                            VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#e69500"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#cc8500"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="CloseButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextDimBrush}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="8,4">
                            <ContentPresenter HorizontalAlignment="Center"
                                            VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background"
                                        Value="#ff4757"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="CheckBoxStyle" TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal">
                            <Border x:Name="box" Width="20" Height="20"
                                    CornerRadius="4" BorderThickness="2"
                                    BorderBrush="{StaticResource TextDimBrush}"
                                    Background="Transparent"
                                    VerticalAlignment="Center">
                                <TextBlock x:Name="check" Text="&#x2713;"
                                           Foreground="{StaticResource PrimaryBrush}"
                                           FontSize="14" FontWeight="Bold"
                                           HorizontalAlignment="Center"
                                           VerticalAlignment="Center"
                                           Visibility="Collapsed"/>
                            </Border>
                            <ContentPresenter Margin="10,0,0,0"
                                            VerticalAlignment="Center"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="box" Property="Background"
                                        Value="{StaticResource PrimaryBrush}"/>
                                <Setter TargetName="box" Property="BorderBrush"
                                        Value="{StaticResource PrimaryBrush}"/>
                                <Setter TargetName="check" Property="Visibility"
                                        Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="box" Property="BorderBrush"
                                        Value="{StaticResource AccentBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="GroupBoxStyle" TargetType="GroupBox">
            <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#2a2a4a"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="GroupBox">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Grid.Row="0" Background="{StaticResource SurfaceBrush}"
                                    CornerRadius="10,10,0,0" Padding="16,12,16,8">
                                <ContentPresenter ContentSource="Header"/>
                            </Border>
                            <Border Grid.Row="1" Background="{StaticResource SurfaceBrush}"
                                    CornerRadius="0,0,10,10" Padding="16">
                                <ContentPresenter/>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="{StaticResource BgBrush}" CornerRadius="12">
        <Border.Effect>
            <DropShadowEffect BlurRadius="20" ShadowDepth="0" Opacity="0.3"
                            Color="Black"/>
        </Border.Effect>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="70"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="160"/>
            </Grid.RowDefinitions>

            <!-- HEADER -->
            <Border Grid.Row="0" Background="{StaticResource SurfaceBrush}"
                    CornerRadius="12,12,0,0">
                <Grid>
                    <StackPanel VerticalAlignment="Center" Margin="24,0">
                        <TextBlock Text="SHADOWSCAN PRO"
                                   FontSize="26" FontWeight="Bold"
                                   Foreground="{StaticResource PrimaryBrush}"/>
                        <TextBlock Text="Scan for shadows. Remove the threats."
                                   FontSize="12" Foreground="{StaticResource TextDimBrush}"
                                   Margin="0,2,0,0"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right"
                                VerticalAlignment="Center" Margin="0,0,16,0">
                        <TextBlock Text="v2.0.0" Foreground="{StaticResource TextDimBrush}"
                                   FontSize="12" VerticalAlignment="Center" Margin="0,0,12,0"/>
                        <Button x:Name="CloseBtn" Style="{StaticResource CloseButton}"
                                Content="X" FontSize="16"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- MIDDLE -->
            <Grid Grid.Row="1" Margin="20,12,20,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="16"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- FEATURES -->
                <GroupBox Grid.Column="0" Header="SELECT FEATURES"
                          Style="{StaticResource GroupBoxStyle}">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel x:Name="FeatureStack" Margin="4,0"/>
                    </ScrollViewer>
                </GroupBox>

                <!-- ACTIONS -->
                <GroupBox Grid.Column="2" Header="ACTIONS"
                          Style="{StaticResource GroupBoxStyle}">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <Button x:Name="ScanBtn" Grid.Row="0"
                                Style="{StaticResource PrimaryButton}"
                                Content="SCAN && CLEAN" Margin="0,0,0,12"/>

                        <Button x:Name="DryBtn" Grid.Row="1"
                                Style="{StaticResource AccentButton}"
                                Content="Dry Run (Preview)" Margin="0,0,0,12"/>

                        <Button x:Name="RevertBtn" Grid.Row="2"
                                Style="{StaticResource WarningButton}"
                                Content="Revert Changes" Margin="0,0,0,12"/>

                        <Button x:Name="SupportBtn" Grid.Row="3"
                                Style="{StaticResource ModernButton}"
                                Content="Support" Margin="0,0,0,20"/>

                        <TextBlock x:Name="StatusText" Grid.Row="4"
                                   Text="Ready" FontSize="18" FontWeight="Bold"
                                   Foreground="{StaticResource PrimaryBrush}"
                                   HorizontalAlignment="Center" Margin="0,0,0,12"/>

                        <Border Grid.Row="5" Background="#0f1a30"
                                CornerRadius="6" Height="14" Margin="0,0,0,0">
                            <Border x:Name="ProgressFill" Background="{StaticResource PrimaryBrush}"
                                    CornerRadius="6" HorizontalAlignment="Left"
                                    Width="0" Height="14"/>
                        </Border>

                        <StackPanel Grid.Row="7" Orientation="Horizontal"
                                    HorizontalAlignment="Center" Margin="0,16,0,0">
                            <TextBlock Text="Made by " Foreground="{StaticResource TextDimBrush}"
                                       FontSize="11" VerticalAlignment="Center"/>
                            <TextBlock Text="Ben The Fix-It Guy"
                                       Foreground="{StaticResource AccentBrush}"
                                       FontSize="11" FontWeight="SemiBold"
                                       VerticalAlignment="Center"/>
                        </StackPanel>
                    </Grid>
                </GroupBox>
            </Grid>

            <!-- LOG -->
            <GroupBox Grid.Row="2" Header="OUTPUT LOG"
                      Style="{StaticResource GroupBoxStyle}" Margin="20,12,20,16">
                <TextBox x:Name="LogBox" Background="{StaticResource BgBrush}"
                         Foreground="{StaticResource PrimaryBrush}"
                         FontFamily="Consolas" FontSize="10"
                         IsReadOnly="True" TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"
                         BorderThickness="0" Padding="8"/>
            </GroupBox>
        </Grid>
    </Border>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [System.Windows.Markup.XamlReader]::Load($Reader)

$FeatureNames = @(
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

$FeatureFlags = @(
    "-SkipTemp", "-SkipDownloads", "-SkipOrphans", "-SkipAccessibility",
    "-SkipWiFi", "-SkipShadowAccounts", "-SkipRegistry", "-SkipSystem",
    "-SkipProcessScan", "-SkipSystemRepair", "-SkipStartup", "-SkipServices",
    "-SkipBrowsers", "-SkipVisualEffects", "-SkipDevCleanup", "-SkipWinSxS"
)

$FeatureStack = $Window.FindName("FeatureStack")
$Script:CheckBoxes = @()

# Select All / Deselect All
$btnPanel = New-Object System.Windows.Controls.StackPanel
$btnPanel.Orientation = "Horizontal"
$btnPanel.Margin = "0,8,0,0"

$selectAllBtn = New-Object System.Windows.Controls.Button
$selectAllBtn.Content = "Select All"
$selectAllBtn.Style = $Window.FindResource("AccentButton")
$selectAllBtn.FontSize = 11
$selectAllBtn.Padding = "12,6"
$selectAllBtn.Margin = "0,0,8,0"
$btnPanel.Children.Add($selectAllBtn) | Out-Null

$deselectBtn = New-Object System.Windows.Controls.Button
$deselectBtn.Content = "Deselect All"
$deselectBtn.Style = $Window.FindResource("ModernButton")
$deselectBtn.FontSize = 11
$deselectBtn.Padding = "12,6"
$btnPanel.Children.Add($deselectBtn) | Out-Null

$FeatureStack.Children.Add($btnPanel) | Out-Null

for ($i = 0; $i -lt $FeatureNames.Count; $i++) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $FeatureNames[$i]
    $cb.IsChecked = $true
    $cb.Style = $Window.FindResource("CheckBoxStyle")
    $cb.Margin = "4,6,4,2"
    $FeatureStack.Children.Add($cb) | Out-Null
    $Script:CheckBoxes += $cb
}

function Write-Log([string]$Msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $Window.FindName("LogBox")..AppendText("[$ts] $Msg`r`n")
    $Window.FindName("LogBox").ScrollToEnd()
}

function Set-Status([string]$Text, $Color) {
    $Window.FindName("StatusText").Text = $Text
    $Window.FindName("StatusText").Foreground = $Color
}

function Set-Progress([int]$Pct) {
    $bar = $Window.FindName("ProgressFill")
    $bar.Width = [Math]::Min(340, 340 * $Pct / 100)
}

function Get-Flags {
    $out = @()
    for ($i = 0; $i -lt $Script:CheckBoxes.Count; $i++) {
        if ($Script:CheckBoxes[$i].IsChecked -eq $true) {
            $out += $FeatureFlags[$i]
        }
    }
    return $out
}

$selectAllBtn.Add_Click({
    foreach ($cb in $Script:CheckBoxes) { $cb.IsChecked = $true }
    Write-Log "All features selected"
})

$deselectBtn.Add_Click({
    foreach ($cb in $Script:CheckBoxes) { $cb.IsChecked = $false }
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
        "Run cleanup on $($flags.Count) features?`r`n`r`nAll changes are backed up. You can revert anytime.",
        "Confirm", "YesNo", "Question")
    if ($r -eq "No") { return }

    $Window.FindName("ScanBtn").IsEnabled = $false
    $Window.FindName("DryBtn").IsEnabled = $false
    Set-Status "Running..." $Window.FindResource("AccentBrush")
    Set-Progress 0
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
        Set-Progress 20
        $out = & powershell -ExecutionPolicy Bypass -File $script -All @flags 2>&1
        Set-Progress 80
        foreach ($line in $out) { Write-Log $line.ToString() }
        Set-Progress 100
        Set-Status "Complete!" $Window.FindResource("PrimaryBrush")
        Write-Log "Done!"
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
        Set-Progress 20
        $out = & powershell -ExecutionPolicy Bypass -File $script -All -DryRun @flags 2>&1
        Set-Progress 80
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
    $script = Join-Path $PSScriptRoot "support-bot.ps1"
    if (Test-Path $script) {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$script`" -Support"
    } else {
        [System.Windows.MessageBox]::Show("Support bot not found.", "Error", "OK", "Error")
    }
})

Write-Log "ShadowScan Pro v2.0 ready"
Write-Log "Select features and click SCAN && CLEAN"

[void]$Window.ShowDialog()
