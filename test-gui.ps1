$job = Start-Job -ScriptBlock {
    & 'C:\Users\realp\OneDrive\Documents\Shadow User\ShadowScan.ps1' -All -SkipDownloads -SkipOrphans -SkipAccessibility -SkipWiFi -SkipShadowAccounts -SkipRegistry -SkipSystem -SkipProcessScan -SkipSystemRepair -SkipStartup -SkipServices -SkipBrowsers -SkipVisualEffects -SkipDevCleanup -SkipWinSxS
}
Write-Host "Script started as job $($job.Id)..."
$completed = Wait-Job $job -Timeout 60
if ($completed) {
    Receive-Job $job | Select-Object -Last 10
    Write-Host "`nScript COMPLETED successfully!"
} else {
    Remove-Job $job -Force
    Write-Host "`nTIMEOUT - script took too long (>60 seconds)"
}
