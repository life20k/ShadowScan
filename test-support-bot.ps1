$questions = @(
    "is it safe",
    "how do i undo changes",
    "what does this tool do",
    "what features does it have",
    "can i undo changes",
    "how do i run it",
    "what does it clean",
    "is it free",
    "what is the pro version",
    "how long does it take",
    "does it delete my files",
    "what windows versions",
    "do i need admin rights"
)

$pass = 0
$fail = 0

foreach ($q in $questions) {
    $output = powershell -ExecutionPolicy Bypass -File "C:\Users\realp\OneDrive\Documents\Shadow User\support-bot.ps1" -Ask $q 2>&1
    $confLine = $output | Select-String "Confidence:"
    if ($confLine -match "Confidence: ([\d.]+)%") {
        $conf = [double]$matches[1]
        if ($conf -ge 70) {
            Write-Host "PASS $conf% - $q" -ForegroundColor Green
            $pass++
        } else {
            Write-Host "FAIL $conf% - $q" -ForegroundColor Red
            $fail++
        }
    } else {
        Write-Host "FAIL N/A - $q" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "Results: $pass passed, $fail failed out of $($questions.Count) total" -ForegroundColor Cyan
