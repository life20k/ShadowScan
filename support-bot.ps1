#Requires -Version 5.1
<#
.SYNOPSIS
    ShadowScan Self-Learning Support Bot
.DESCRIPTION
    Interactive support bot with fuzzy matching, feedback collection,
    and self-learning capabilities for ShadowScan.
.PARAMETER Support
    Shows the interactive support menu
.PARAMETER Ask
    Ask a direct question to the support bot
.PARAMETER SupportStats
    View learning statistics and metrics
.PARAMETER ExportUnanswered
    Export unanswered questions to a CSV file
.EXAMPLE
    .\support-bot.ps1 -Support
    .\support-bot.ps1 -Ask "How do I run a scan?"
    .\support-bot.ps1 -SupportStats
    .\support-bot.ps1 -ExportUnanswered
.NOTES
    Author: ShadowScan Team
    Version: 1.0.0
    Requires: PowerShell 5.1+
#>

param(
    [switch]$Support,
    [string]$Ask,
    [switch]$SupportStats,
    [switch]$ExportUnanswered
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:BotVersion = "1.0.0"
$Script:BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:KnowledgeBasePath = Join-Path $Script:BasePath "knowledge-base.json"
$Script:LearningDataPath = Join-Path $Script:BasePath "learning.json"
$Script:UnansweredPath = Join-Path $Script:BasePath "unanswered.json"
$Script:ExportPath = Join-Path $Script:BasePath "unanswered-export.csv"
$Script:MinConfidenceThreshold = 0.3
$Script:FeedbackPrompt = "Was this helpful? [y/n]: "
$Script:PatternLearningThreshold = 10

# ============================================================================
# STOP WORDS FOR KEYWORD EXTRACTION
# ============================================================================

$Script:StopWords = @(
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'is', 'it', 'this', 'that', 'are', 'was',
    'be', 'has', 'had', 'have', 'do', 'does', 'did', 'will', 'would',
    'could', 'should', 'may', 'might', 'can', 'i', 'me', 'my', 'we',
    'you', 'your', 'he', 'she', 'they', 'them', 'their', 'what', 'which',
    'who', 'how', 'when', 'where', 'why', 'not', 'no', 'so', 'if',
    'then', 'than', 'too', 'very', 'just', 'about', 'up', 'out', 'all'
)

# ============================================================================
# FUNCTION: Load-KnowledgeBase
# ============================================================================
function Load-KnowledgeBase {
    <#
    .SYNOPSIS
        Loads the knowledge base from JSON file
    .OUTPUTS
        PSCustomObject containing knowledge base data
    #>
    if (Test-Path $Script:KnowledgeBasePath) {
        try {
            $kb = Get-Content -Path $Script:KnowledgeBasePath -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Verbose "Knowledge base loaded ($($kb.patterns.Count) patterns)"
            return $kb
        }
        catch {
            Write-Warning "Failed to load knowledge base: $_"
            return $null
        }
    }
    else {
        Write-Warning "Knowledge base not found at $Script:KnowledgeBasePath"
        return $null
    }
}

# ============================================================================
# FUNCTION: Save-KnowledgeBase
# ============================================================================
function Save-KnowledgeBase {
    <#
    .SYNOPSIS
        Saves the knowledge base to JSON file
    .PARAMETER KnowledgeBase
        PSCustomObject to save
    #>
    param($KnowledgeBase)

    try {
        $KnowledgeBase | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:KnowledgeBasePath -Encoding UTF8
        Write-Verbose "Knowledge base saved"
    }
    catch {
        Write-Warning "Failed to save knowledge base: $_"
    }
}

# ============================================================================
# FUNCTION: Load-LearningData
# ============================================================================
function Load-LearningData {
    <#
    .SYNOPSIS
        Loads learning tracking data
    .OUTPUTS
        PSCustomObject containing learning metrics
    #>
    $defaultData = [PSCustomObject]@{
        totalQuestions     = 0
        answeredQuestions  = 0
        unansweredQuestions = 0
        averageConfidence  = 0.0
        topCategories      = @{}
        questionHistory    = @()
        lastUpdated        = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }

    if (Test-Path $Script:LearningDataPath) {
        try {
            $data = Get-Content -Path $Script:LearningDataPath -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Verbose "Learning data loaded"
            return $data
        }
        catch {
            Write-Warning "Failed to load learning data: $_. Using defaults."
            return $defaultData
        }
    }
    else {
        Save-LearningData -LearningData $defaultData
        return $defaultData
    }
}

# ============================================================================
# FUNCTION: Save-LearningData
# ============================================================================
function Save-LearningData {
    <#
    .SYNOPSIS
        Saves learning tracking data to JSON
    .PARAMETER LearningData
        PSCustomObject to save
    #>
    param($LearningData)

    try {
        $LearningData.lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        $LearningData | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:LearningDataPath -Encoding UTF8
        Write-Verbose "Learning data saved"
    }
    catch {
        Write-Warning "Failed to save learning data: $_"
    }
}

# ============================================================================
# FUNCTION: Get-NormalizedText
# ============================================================================
function Get-NormalizedText {
    <#
    .SYNOPSIS
        Normalizes text for comparison: lowercase, remove punctuation
    .PARAMETER Text
        Text to normalize
    #>
    param([string]$Text)

    $normalized = $Text.ToLower().Trim()
    $normalized = $normalized -replace '[^\w\s]', ''
    $normalized = $normalized -replace '\s+', ' '
    return $normalized
}

# ============================================================================
# FUNCTION: Get-Keywords
# ============================================================================
function Get-Keywords {
    <#
    .SYNOPSIS
        Extracts meaningful keywords by removing stop words
    .PARAMETER Text
        Text to extract keywords from
    #>
    param([string]$Text)

    $normalized = Get-NormalizedText -Text $Text
    $words = $normalized -split '\s+'
    $keywords = @($words | Where-Object { $_ -notin $Script:StopWords -and $_.Length -gt 1 })
    return $keywords
}

# ============================================================================
# FUNCTION: Get-FuzzyMatch
# ============================================================================
function Get-FuzzyMatch {
    <#
    .SYNOPSIS
        Performs fuzzy matching between query and knowledge base patterns
    .DESCRIPTION
        Calculates relevance score using:
        - Keyword overlap with question and stored keywords
        - Pattern matching against stored patterns
        - Word-level similarity (Levenshtein-inspired)
        - Helpfulness bonus from feedback history
    .PARAMETER Query
        User's question text
    .PARAMETER Patterns
        Array of knowledge base patterns to match against
    .OUTPUTS
        PSCustomObject with best match and confidence score
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        [Parameter(Mandatory)]
        [array]$Patterns
    )

    $queryNormalized = Get-NormalizedText -Text $Query
    $queryKeywords = Get-Keywords -Text $Query
    $bestMatch = $null
    $bestScore = 0

    foreach ($pattern in $Patterns) {
        $score = 0
        $maxScore = 0

        # Factor 1: Direct substring match in question (weight: 3)
        $maxScore += 3
        $patQuestion = Get-NormalizedText -Text $pattern.question
        if ($queryNormalized -match [regex]::Escape($patQuestion) -or
            $patQuestion -match [regex]::Escape($queryNormalized)) {
            $score += 3
        }
        elseif ($queryNormalized.Length -ge 5 -and $patQuestion.Length -ge 5) {
            $subLen = [Math]::Min(10, [Math]::Min($queryNormalized.Length, $patQuestion.Length))
            if ($queryNormalized.Substring(0, $subLen) -eq $patQuestion.Substring(0, $subLen)) {
                $score += 2
            }
        }

        # Factor 2: Keyword overlap (weight: 2.5)
        $maxScore += 2.5
        $patKeywords = @($pattern.keywords)
        if ($queryKeywords.Count -gt 0 -and $patKeywords.Count -gt 0) {
            $overlap = @($queryKeywords | Where-Object { $_ -in $patKeywords }).Count
            $keywordScore = [Math]::Min(2.5, ($overlap / [Math]::Max(1, $patKeywords.Count)) * 2.5)
            # Bonus for short queries with high overlap ratio
            if ($queryKeywords.Count -le 4 -and $overlap -ge 2) {
                $keywordScore = [Math]::Min(2.5, $keywordScore * 1.5)
            }
            $score += $keywordScore
        }

        # Factor 3: Normalized field match (weight: 2)
        $maxScore += 2
        if ($pattern.normalized) {
            if ($queryNormalized -eq $pattern.normalized) {
                $score += 2
            }
            elseif ($queryNormalized -like "*$($pattern.normalized.Substring(0, [Math]::Min(8, $pattern.normalized.Length)))*") {
                $score += 1.5
            }
        }

        # Factor 4: Word-level similarity (weight: 2)
        $maxScore += 2
        $queryWords = @($queryNormalized -split '\s+' | Where-Object { $_.Length -gt 1 })
        $patWords = @($patQuestion -split '\s+' | Where-Object { $_.Length -gt 1 })
        if ($queryWords.Count -gt 0 -and $patWords.Count -gt 0) {
            $totalSim = 0
            foreach ($qw in $queryWords) {
                $maxWordSim = 0
                foreach ($pw in $patWords) {
                    $len = [Math]::Max($qw.Length, $pw.Length)
                    if ($len -eq 0) { continue }
                    $matches = 0
                    $minLen = [Math]::Min($qw.Length, $pw.Length)
                    for ($i = 0; $i -lt $minLen; $i++) {
                        if ($qw[$i] -eq $pw[$i]) { $matches++ }
                    }
                    $sim = $matches / $len
                    # Exact match bonus
                    if ($qw -eq $pw) { $sim = 1.0 }
                    if ($sim -gt $maxWordSim) { $maxWordSim = $sim }
                }
                $totalSim += $maxWordSim
            }
            $score += ($totalSim / $queryWords.Count) * 2
        }

        # Factor 5: Helpfulness bonus (weight: 0.5)
        $maxScore += 0.5
        if ($pattern.times_helpful -gt 0) {
            $total = $pattern.times_asked
            if ($total -gt 0) {
                $helpRatio = $pattern.times_helpful / $total
                $score += $helpRatio * 0.5
            }
        }

        # Calculate final confidence
        $confidence = if ($maxScore -gt 0) { $score / $maxScore } else { 0 }

        if ($confidence -gt $bestScore) {
            $bestScore = $confidence
            $bestMatch = $pattern
        }
    }

    return [PSCustomObject]@{
        Pattern    = $bestMatch
        Confidence = [Math]::Round($bestScore, 4)
    }
}

# ============================================================================
# FUNCTION: Get-Answer
# ============================================================================
function Get-Answer {
    <#
    .SYNOPSIS
        Retrieves the best answer for a user question
    .PARAMETER Question
        User's question text
    .PARAMETER KnowledgeBase
        Knowledge base PSCustomObject
    .OUTPUTS
        PSCustomObject with answer, pattern, confidence, category
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Question,
        $KnowledgeBase
    )

    if (-not $KnowledgeBase -or -not $KnowledgeBase.patterns) {
        return [PSCustomObject]@{
            Answer     = "No knowledge base loaded. Please ensure knowledge-base.json exists."
            Pattern    = $null
            Confidence = 0
            Category   = "none"
        }
    }

    $patterns = @($KnowledgeBase.patterns)
    if ($patterns.Count -eq 0) {
        return [PSCustomObject]@{
            Answer     = "Knowledge base is empty."
            Pattern    = $null
            Confidence = 0
            Category   = "none"
        }
    }

    $match = Get-FuzzyMatch -Query $Question -Patterns $patterns

    return [PSCustomObject]@{
        Answer     = if ($match.Pattern) { $match.Pattern.answer } else { $null }
        Pattern    = $match.Pattern
        Confidence = $match.Confidence
        Category   = if ($match.Pattern) { $match.Pattern.category } else { "unknown" }
    }
}

# ============================================================================
# FUNCTION: Add-Feedback
# ============================================================================
function Add-Feedback {
    <#
    .SYNOPSIS
        Records user feedback for an answer
    .PARAMETER Pattern
        The knowledge base pattern that was shown
    .PARAMETER Helpful
        Boolean indicating if the answer was helpful
    .PARAMETER KnowledgeBase
        Reference to knowledge base for updating counts
    #>
    param(
        $Pattern,
        [bool]$Helpful,
        $KnowledgeBase
    )

    if (-not $Pattern -or -not $KnowledgeBase) { return }

    foreach ($p in $KnowledgeBase.patterns) {
        if ($p.id -eq $Pattern.id) {
            $p.times_asked++
            if ($Helpful) {
                $p.times_helpful++
            }
            # Update helpfulness score
            if ($p.times_asked -gt 0) {
                $p.helpfulness_score = [Math]::Round($p.times_helpful / $p.times_asked, 2)
            }
            $p.last_used = (Get-Date -Format "yyyy-MM-dd")
            break
        }
    }

    Save-KnowledgeBase -KnowledgeBase $KnowledgeBase
    Write-Verbose "Feedback recorded for pattern $($Pattern.id)"
}

# ============================================================================
# FUNCTION: Log-UnansweredQuestion
# ============================================================================
function Log-UnansweredQuestion {
    <#
    .SYNOPSIS
        Logs a question that could not be answered
    .PARAMETER Question
        The unanswered question text
    .PARAMETER Confidence
        The confidence score that was below threshold
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Question,
        [double]$Confidence = 0
    )

    $unanswered = [System.Collections.ArrayList]@()
    if (Test-Path $Script:UnansweredPath) {
        try {
            $raw = Get-Content -Path $Script:UnansweredPath -Raw -Encoding UTF8
            if ($raw) {
                $parsed = $raw | ConvertFrom-Json
                foreach ($item in $parsed) {
                    $null = $unanswered.Add([PSCustomObject]@{
                        question    = $item.question
                        normalized  = $item.normalized
                        keywords    = @($item.keywords)
                        timestamp   = $item.timestamp
                        confidence  = $item.confidence
                        occurrences = $item.occurrences
                        category    = $item.category
                    })
                }
            }
        }
        catch {
            $unanswered = [System.Collections.ArrayList]@()
        }
    }

    $entry = [PSCustomObject]@{
        question    = $Question
        normalized  = (Get-NormalizedText -Text $Question)
        keywords    = @(Get-Keywords -Text $Question)
        timestamp   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        confidence  = $Confidence
        occurrences = 1
        category    = "unclassified"
    }

    # Check if similar question already exists (merge duplicates)
    $existingIndex = -1
    $newKeywords = @(Get-Keywords -Text $Question)
    for ($i = 0; $i -lt $unanswered.Count; $i++) {
        $existingKw = @($unanswered[$i].keywords)
        if ($existingKw.Count -gt 0 -and $newKeywords.Count -gt 0) {
            $overlap = @($existingKw | Where-Object { $_ -in $newKeywords }).Count
            if ($overlap -ge [Math]::Max(1, [int]($newKeywords.Count * 0.5))) {
                $existingIndex = $i
                break
            }
        }
    }

    if ($existingIndex -ge 0) {
        $unanswered[$existingIndex].occurrences++
        $unanswered[$existingIndex].timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    else {
        $null = $unanswered.Add($entry)
    }

    $unanswered | ConvertTo-Json -Depth 5 | Set-Content -Path $Script:UnansweredPath -Encoding UTF8
    Write-Verbose "Unanswered question logged: $Question"
}

# ============================================================================
# FUNCTION: Update-LearningStats
# ============================================================================
function Update-LearningStats {
    <#
    .SYNOPSIS
        Updates learning statistics after a question is processed
    .PARAMETER Answered
        Whether the question was answered
    .PARAMETER Confidence
        The confidence score
    .PARAMETER Category
        The category of the answer
    .PARAMETER LearningData
        Reference to learning data
    #>
    param(
        [bool]$Answered,
        [double]$Confidence,
        [string]$Category,
        $LearningData
    )

    $LearningData.totalQuestions++

    if ($Answered) {
        $LearningData.answeredQuestions++
        $total = $LearningData.answeredQuestions
        $LearningData.averageConfidence = [Math]::Round(
            (($LearningData.averageConfidence * ($total - 1)) + $Confidence) / $total, 4
        )
    }
    else {
        $LearningData.unansweredQuestions++
    }

    # Track category usage
    if ($Category -and $Category -notin @("unknown", "none", "unclassified")) {
        if (-not $LearningData.topCategories) {
            $LearningData.topCategories = @{}
        }
        # Handle both hashtable and PSCustomObject
        $current = 0
        $props = $LearningData.topCategories.PSObject.Properties
        if ($props[$Category]) {
            $current = [int]$props[$Category].Value
        }
        if ($LearningData.topCategories -is [hashtable]) {
            $LearningData.topCategories[$Category] = $current + 1
        }
        else {
            $existing = $props[$Category]
            if ($existing) {
                $existing.Value = $current + 1
            }
            else {
                $LearningData.topCategories | Add-Member -NotePropertyName $Category -NotePropertyValue ($current + 1)
            }
        }
    }

    # Append to history (keep last 500)
    $hist = @($LearningData.questionHistory)
    $hist += [PSCustomObject]@{
        timestamp  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        answered   = $Answered
        confidence = $Confidence
        category   = $Category
    }
    if ($hist.Count -gt 500) {
        $hist = $hist[-500..-1]
    }
    $LearningData.questionHistory = $hist

    Save-LearningData -LearningData $LearningData
}

# ============================================================================
# FUNCTION: Show-SupportStats
# ============================================================================
function Show-SupportStats {
    <#
    .SYNOPSIS
        Displays learning statistics and metrics
    .PARAMETER LearningData
        Learning data PSCustomObject
    .PARAMETER KnowledgeBase
        Knowledge base PSCustomObject
    #>
    param(
        $LearningData,
        $KnowledgeBase
    )

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "   ShadowScan Support Bot - Learning Statistics" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""

    # Metrics
    Write-Host "  [Metrics]" -ForegroundColor Yellow
    Write-Host "  Total Questions:      $($LearningData.totalQuestions)"
    Write-Host "  Answered:             $($LearningData.answeredQuestions)"
    Write-Host "  Unanswered:           $($LearningData.unansweredQuestions)"
    $rate = if ($LearningData.totalQuestions -gt 0) {
        [Math]::Round(($LearningData.answeredQuestions / $LearningData.totalQuestions) * 100, 1)
    } else { 0 }
    Write-Host "  Answer Rate:          $rate%"
    Write-Host "  Avg Confidence:       $([Math]::Round($LearningData.averageConfidence * 100, 1))%"
    Write-Host ""

    # Knowledge Base
    Write-Host "  [Knowledge Base]" -ForegroundColor Yellow
    if ($KnowledgeBase -and $KnowledgeBase.patterns) {
        $patterns = @($KnowledgeBase.patterns)
        Write-Host "  Total Patterns: $($patterns.Count)"

        # Category breakdown
        $cats = @($patterns | Group-Object -Property category | Sort-Object Count -Descending)
        foreach ($c in $cats) {
            $avgHelp = if ($c.Count -gt 0) {
                $helpful = ($c.Group | Measure-Object -Property times_helpful -Sum).Sum
                $total = ($c.Group | Measure-Object -Property times_asked -Sum).Sum
                if ($total -gt 0) { "$([Math]::Round($helpful / $total * 100))%" } else { "N/A" }
            } else { "N/A" }
            Write-Host "  $($c.Name): $($c.Count) entries (helpfulness: $avgHelp)"
        }
    }
    else {
        Write-Host "  No knowledge base loaded"
    }
    Write-Host ""

    # Top Categories from learning
    if ($LearningData.topCategories) {
        $catProps = @($LearningData.topCategories.PSObject.Properties |
            Where-Object { $_.Name -notin @('IsReadOnly','IsFixedSize','IsSynchronized','Keys','Values','SyncRoot','Count') })
        if ($catProps.Count -gt 0) {
            Write-Host "  [Top Questioned Categories]" -ForegroundColor Yellow
            $sorted = $catProps | Sort-Object { try { [int]$_.Value } catch { 0 } } -Descending | Select-Object -First 5
            foreach ($entry in $sorted) {
                Write-Host "  $($entry.Key): $($entry.Value) questions"
            }
            Write-Host ""
        }
    }

    # Unanswered questions
    if (Test-Path $Script:UnansweredPath) {
        try {
            $raw = Get-Content -Path $Script:UnansweredPath -Raw -Encoding UTF8
            if ($raw) {
                $parsed = $raw | ConvertFrom-Json
                $unanswered = [System.Collections.ArrayList]@()
                foreach ($item in $parsed) {
                    $null = $unanswered.Add([PSCustomObject]@{
                        question    = $item.question
                        occurrences = if ($item.occurrences) { $item.occurrences } else { 1 }
                    })
                }
                $totalOcc = ($unanswered | Measure-Object -Property occurrences -Sum).Sum
                if (-not $totalOcc) { $totalOcc = 0 }
                Write-Host "  [Unanswered Questions]" -ForegroundColor Yellow
                Write-Host "  Unique: $($unanswered.Count)  |  Total Occurrences: $totalOcc"
                $top = @($unanswered | Sort-Object { $_.occurrences } -Descending | Select-Object -First 3)
                foreach ($q in $top) {
                    $preview = if ($q.question.Length -gt 40) { $q.question.Substring(0, 40) + "..." } else { $q.question }
                    Write-Host "    [$($q.occurrences)x] $preview"
                }
            }
        }
        catch { }
        Write-Host ""
    }

    Write-Host ("=" * 60) -ForegroundColor Cyan
}

# ============================================================================
# FUNCTION: Show-SupportMenu
# ============================================================================
function Show-SupportMenu {
    <#
    .SYNOPSIS
        Displays the interactive support menu and handles user interaction
    #>

    $kb = Load-KnowledgeBase
    $learningData = Load-LearningData

    if (-not $kb) {
        Write-Host "[!] Cannot start support bot: knowledge base not found." -ForegroundColor Red
        Write-Host "    Expected location: $Script:KnowledgeBasePath" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Green
    Write-Host "   ShadowScan Support Bot v$Script:BotVersion" -ForegroundColor Green
    Write-Host "   Self-Learning Interactive Help System" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Green
    Write-Host ""

    $running = $true
    while ($running) {
        Write-Host "  [Menu]" -ForegroundColor Yellow
        Write-Host "  1. Ask a question"
        Write-Host "  2. View FAQ"
        Write-Host "  3. Run diagnostics"
        Write-Host "  4. View learning stats"
        Write-Host "  5. Exit"
        Write-Host ""
        $choice = Read-Host "  Select option (1-5)"

        switch ($choice) {
            "1" {
                Write-Host ""
                $question = Read-Host "  Enter your question"
                if ([string]::IsNullOrWhiteSpace($question)) {
                    Write-Host "  [!] No question entered." -ForegroundColor Red
                    continue
                }

                $result = Get-Answer -Question $question -KnowledgeBase $kb

                if ($result.Confidence -ge $Script:MinConfidenceThreshold -and $result.Answer) {
                    Write-Host ""
                    Write-Host "  [Answer] (Confidence: $([Math]::Round($result.Confidence * 100, 1))%)" -ForegroundColor Green
                    Write-Host "  $($result.Answer)" -ForegroundColor White
                    Write-Host "  Category: $($result.Category)" -ForegroundColor DarkGray
                    Write-Host ""

                    $feedback = Read-Host $Script:FeedbackPrompt
                    [bool]$helpful = $feedback -match '^[yY]'
                    Add-Feedback -Pattern $result.Pattern -Helpful $helpful -KnowledgeBase $kb

                    if ($helpful) {
                        Write-Host "  [+] Thanks for the feedback!" -ForegroundColor Green
                    }
                    else {
                        Write-Host "  [-] Sorry it wasn't helpful. Logged for review." -ForegroundColor Yellow
                    }
                }
                else {
                    Write-Host ""
                    Write-Host "  [!] I'm not confident enough in my answer." -ForegroundColor Yellow
                    Write-Host "  Best match confidence: $([Math]::Round($result.Confidence * 100, 1))%" -ForegroundColor Yellow
                    Write-Host "  Your question has been logged for future learning." -ForegroundColor Yellow
                    Log-UnansweredQuestion -Question $question -Confidence $result.Confidence
                }

                Update-LearningStats -Answered ($result.Confidence -ge $Script:MinConfidenceThreshold) `
                    -Confidence $result.Confidence -Category $result.Category -LearningData $learningData
                Write-Host ""
            }
            "2" {
                Write-Host ""
                Write-Host "  [FAQ]" -ForegroundColor Cyan
                $patterns = @($kb.patterns | Group-Object -Property category)
                foreach ($catGroup in ($patterns | Sort-Object Name)) {
                    Write-Host ""
                    Write-Host "  --- $($catGroup.Name.ToUpper()) ---" -ForegroundColor Yellow
                    foreach ($entry in $catGroup.Group) {
                        Write-Host "  Q: $($entry.question)" -ForegroundColor White
                        Write-Host "  A: $($entry.answer)" -ForegroundColor Gray
                        $helpRate = if ($entry.times_asked -gt 0) {
                            "$([Math]::Round($entry.times_helpful / $entry.times_asked * 100))% ($($entry.times_helpful)/$($entry.times_asked))"
                        } else { "N/A" }
                        Write-Host "  Helpfulness: $helpRate" -ForegroundColor DarkGray
                        Write-Host ""
                    }
                }
            }
            "3" {
                Write-Host ""
                Write-Host "  [Diagnostics]" -ForegroundColor Cyan

                Write-Host "  Checking knowledge base..." -NoNewline
                if (Test-Path $Script:KnowledgeBasePath) {
                    $size = (Get-Item $Script:KnowledgeBasePath).Length
                    Write-Host " OK ($([Math]::Round($size / 1KB, 1)) KB, $($kb.patterns.Count) patterns)" -ForegroundColor Green
                }
                else {
                    Write-Host " MISSING" -ForegroundColor Red
                }

                Write-Host "  Checking learning data..." -NoNewline
                if (Test-Path $Script:LearningDataPath) {
                    $size = (Get-Item $Script:LearningDataPath).Length
                    Write-Host " OK ($([Math]::Round($size / 1KB, 1)) KB)" -ForegroundColor Green
                }
                else {
                    Write-Host " MISSING (will be created)" -ForegroundColor Yellow
                }

                Write-Host "  Checking unanswered log..." -NoNewline
                if (Test-Path $Script:UnansweredPath) {
                    try {
                        $count = @(Get-Content -Path $Script:UnansweredPath -Raw -Encoding UTF8 | ConvertFrom-Json).Count
                        Write-Host " OK ($count unique questions)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host " EMPTY" -ForegroundColor Yellow
                    }
                }
                else {
                    Write-Host " EMPTY" -ForegroundColor Yellow
                }

                Write-Host "  PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
                Write-Host "  Bot version: $Script:BotVersion" -ForegroundColor DarkGray
                Write-Host ""
            }
            "4" {
                Show-SupportStats -LearningData $learningData -KnowledgeBase $kb
            }
            "5" {
                $running = $false
                Write-Host ""
                Write-Host "  Goodbye!" -ForegroundColor Green
                Write-Host ""
            }
            default {
                Write-Host "  [!] Invalid option. Select 1-5." -ForegroundColor Red
            }
        }
    }
}

# ============================================================================
# FUNCTION: Export-UnansweredQuestions
# ============================================================================
function Export-UnansweredQuestions {
    <#
    .SYNOPSIS
        Exports unanswered questions to CSV for analysis
    #>

    if (-not (Test-Path $Script:UnansweredPath)) {
        Write-Host "[!] No unanswered questions recorded yet." -ForegroundColor Yellow
        return
    }

    try {
        $raw = Get-Content -Path $Script:UnansweredPath -Raw -Encoding UTF8
        if (-not $raw) {
            Write-Host "[!] No unanswered questions recorded yet." -ForegroundColor Yellow
            return
        }
        $unanswered = @($raw | ConvertFrom-Json)

        $csvData = $unanswered | ForEach-Object {
            [PSCustomObject]@{
                Question     = $_.question
                Occurrences  = $_.occurrences
                Confidence   = $_.confidence
                Category     = $_.category
                FirstAsked   = $_.timestamp
                Keywords     = ($_.keywords -join "; ")
            }
        }

        $csvData | Export-Csv -Path $Script:ExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "[+] Exported $($unanswered.Count) unanswered questions to:" -ForegroundColor Green
        Write-Host "    $Script:ExportPath" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[!] Export failed: $_" -ForegroundColor Red
    }
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

# Handle direct question mode
if ($Ask) {
    $kb = Load-KnowledgeBase
    $learningData = Load-LearningData

    if (-not $kb) {
        Write-Host "[!] Knowledge base not found at $Script:KnowledgeBasePath" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "  Question: $Ask" -ForegroundColor Cyan
    $result = Get-Answer -Question $Ask -KnowledgeBase $kb

    if ($result.Confidence -ge $Script:MinConfidenceThreshold -and $result.Answer) {
        Write-Host "  Answer (Confidence: $([Math]::Round($result.Confidence * 100, 1))%):" -ForegroundColor Green
        Write-Host "  $($result.Answer)" -ForegroundColor White
        Write-Host "  Category: $($result.Category)" -ForegroundColor DarkGray

        $feedback = Read-Host $Script:FeedbackPrompt
        $isHelpful = $false
        if ($feedback -match '^[yY]') { $isHelpful = $true }
        Add-Feedback -Pattern $result.Pattern -Helpful $isHelpful -KnowledgeBase $kb
    }
    else {
        Write-Host "  [!] No confident answer found (score: $([Math]::Round($result.Confidence * 100, 1))%)" -ForegroundColor Yellow
        Log-UnansweredQuestion -Question $Ask -Confidence $result.Confidence
    }

    Update-LearningStats -Answered ($result.Confidence -ge $Script:MinConfidenceThreshold) `
        -Confidence $result.Confidence -Category $result.Category -LearningData $learningData
    Write-Host ""
}

# Handle support menu
elseif ($Support) {
    Show-SupportMenu
}

# Handle stats view
elseif ($SupportStats) {
    $kb = Load-KnowledgeBase
    $learningData = Load-LearningData
    Show-SupportStats -LearningData $learningData -KnowledgeBase $kb
}

# Handle export
elseif ($ExportUnanswered) {
    Export-UnansweredQuestions
}

# No parameters: show help
else {
    Write-Host ""
    Write-Host "ShadowScan Support Bot v$Script:BotVersion" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\support-bot.ps1 -Support           # Interactive support menu"
    Write-Host "  .\support-bot.ps1 -Ask `"question`"   # Ask a direct question"
    Write-Host "  .\support-bot.ps1 -SupportStats      # View learning statistics"
    Write-Host "  .\support-bot.ps1 -ExportUnanswered  # Export unanswered questions"
    Write-Host ""
}
