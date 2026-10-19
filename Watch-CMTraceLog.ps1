<#
.SYNOPSIS
    Displays and follows a CMTrace-formatted log file.

.DESCRIPTION
    Reads a CMTrace-formatted log file, parses each entry, and displays it
    in a readable, color-coded format.

    Long messages are word-wrapped to the console width, with continuation
    lines indented to align under the message column instead of the
    terminal hard-wrapping mid-word at column 0. Wrapping is skipped when
    output is redirected (piped or captured to a file).

    After processing the existing lines, the script continues monitoring the
    file and displays new entries as they are written.

    CMTrace severity colors:

        Information = Gray
        Warning     = Yellow
        Error       = Red

.PARAMETER LogFile
    Specifies the path to the CMTrace-formatted log file.

    The file must exist when the script starts.

.PARAMETER Type
    Specifies the CMTrace severity types to display.

    Supported values:

        All
        Information
        Warning
        Error

    Multiple severity types can be provided by separating them with commas.

    The default value is All.

.PARAMETER Tail
    Specifies the number of existing physical lines to process when the
    script starts.

    After processing those lines, the script continues monitoring the file
    for new entries.

    If Tail is omitted, the entire existing log is processed.

    Tail is applied before parsing and filtering. For example, using
    "-Tail 100 -Type Error" examines the last 100 physical lines and displays
    only errors found within those lines.

.PARAMETER WhereObject
    Specifies an optional Where-Object filter script to apply to every parsed
    CMTrace entry.

    The current parsed entry is available through $_ and contains:

        Timestamp
        Date
        Time
        Component
        Context
        Type
        Severity
        Thread
        File
        Message

    Non-CMTrace lines are not displayed when WhereObject is specified.

.PARAMETER HideField
    Specifies which fields to omit from the displayed line.

    Supported values:

        Timestamp
        Component
        Severity
        Thread
        Message

    Multiple fields can be provided by separating them with commas.

    Hiding a field only affects what is displayed; filtering (via -Type or
    -WhereObject) is always applied first, against the full parsed entry, so
    a hidden field can still be filtered on. For example, "-WhereObject {
    $_.Severity -eq 'Error' } -HideField Severity" filters on severity while
    hiding the Severity field from the output.

    Any combination of fields can be hidden. The remaining, visible fields
    keep their normal left-to-right order (Timestamp, Component, Severity,
    Thread, Message).

.PARAMETER Compact
    Displays only the Timestamp and Message fields, hiding Component,
    Severity, and Thread.

    This is a shorthand equivalent to "-HideField Component, Severity,
    Thread". As with -HideField, this only affects what is displayed;
    filtering via -Type or -WhereObject still applies to the full parsed
    entry.

    Cannot be combined with -HideField.

.PARAMETER Highlight
    Specifies one or more regular expressions to highlight in the displayed
    message as entries are written. Matches are shown in black on a yellow
    background, similar to how Select-String highlights matches in
    PowerShell 7. Matching is case-insensitive.

    Highlighting works while following the log, and across word-wrapped
    lines. Non-CMTrace lines are highlighted too.

    Highlight only changes how matches are displayed. Combine it with
    -HighlightOnly to also hide entries that do not match.

.PARAMETER HighlightOnly
    Displays only the entries whose message matches at least one of the
    -Highlight patterns, like piping the log through Select-String. For
    non-CMTrace lines the whole line is matched. This is applied after
    -Type and -WhereObject.

    Requires -Highlight.

.PARAMETER FormatJson
    Pretty-prints JSON found inside log messages (objects and arrays), with
    one property per line and two-space indentation. Text around the JSON is
    kept; JSON that starts mid-line is moved to its own line.

    The JSON is re-indented token for token, so values such as
    "\/Date(...)\/" and escaped nested JSON strings are shown exactly as
    logged. Text that only looks like JSON, such as "[Win32App]", is left
    alone.

    This only affects what is displayed. -WhereObject and -HighlightOnly
    match against the original message, so a -Highlight pattern that
    includes JSON punctuation (for example '"AppId":"x"') may filter but not
    highlight; plain words and GUIDs work as expected.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log'

    Processes the entire existing log and follows new entries.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -Tail 50

    Processes the last 50 physical lines and follows new entries.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -Type Error

    Displays only error entries.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -Tail 100 `
        -Type Warning, Error

    Examines the last 100 lines and displays warnings and errors.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -WhereObject { $_.Component -eq 'AppEnforce' }

    Displays entries generated by the AppEnforce component.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -WhereObject { $_.Message -match 'failed|error|exception' }

    Displays entries whose message matches the supplied regular expression.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -Tail 500 `
        -WhereObject {
            $_.Severity -in 'Warning', 'Error' -and
            $_.Message -match 'install'
        }

    Displays warning and error entries containing "install" from the last
    500 lines and from new entries written afterward.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -WhereObject { $_.Severity -eq 'Error' } `
        -HideField Severity, Thread

    Filters on error severity while hiding the Severity and Thread fields
    from the displayed line.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' `
        -Compact

    Displays only the Timestamp and Message fields.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppActionProcessor.log' `
        -Highlight $Parent, $Dep, 'effective intent', 'enforceability', 'Found:', 'blocked on dependency' `
        -HighlightOnly `
        -Tail 80

    Live-follows the log, showing only entries that match one of the
    patterns, with each match highlighted.

.EXAMPLE
    .\Watch-CMTraceLog.ps1 `
        -LogFile 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log' `
        -FormatJson `
        -Highlight 'ReportingCacheManager'

    Pretty-prints JSON payloads in messages while highlighting matches.

.INPUTS
    None.

    This script does not accept pipeline input.

.OUTPUTS
    None.

    Parsed entries are written directly to the host using severity-based
    colors.

.NOTES
    Press Ctrl+C to stop monitoring the log.

    A log entry whose message contains line breaks spans several physical
    lines in the file. Such entries are joined and shown as one entry. Tail
    counts physical lines, so it can start in the middle of a multi-line
    entry; the partial entry is then shown as plain lines.

    CMTrace type mapping:

        1 = Information
        2 = Warning
        3 = Error
#>

[CmdletBinding()]
param (
    [Parameter(
        Mandatory,
        Position = 0,
        HelpMessage = 'Enter the path to a CMTrace-formatted log file.'
    )]
    [ValidateNotNullOrEmpty()]
    [string]$LogFile,

    [Parameter()]
    [ValidateSet('All', 'Information', 'Warning', 'Error')]
    [string[]]$Type = 'All',

    [Parameter()]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$Tail,

    [Parameter()]
    [scriptblock]$WhereObject,

    [Parameter()]
    [ValidateSet('Timestamp', 'Component', 'Severity', 'Thread', 'Message')]
    [string[]]$HideField = @(),

    [Parameter()]
    [switch]$Compact,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$Highlight,

    [Parameter()]
    [switch]$HighlightOnly,

    [Parameter()]
    [switch]$FormatJson
)

if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    throw "Log file not found: $LogFile"
}

if ($Compact -and $PSBoundParameters.ContainsKey('HideField')) {
    throw 'Specify either -Compact or -HideField, not both.'
}

if ($HighlightOnly -and -not $PSBoundParameters.ContainsKey('Highlight')) {
    throw '-HighlightOnly requires -Highlight.'
}

# Combine all -Highlight patterns into a single case-insensitive regex.
$highlightRegex = $null

if ($PSBoundParameters.ContainsKey('Highlight')) {
    try {
        $highlightRegex = [regex]::new(
            (($Highlight | ForEach-Object { "(?:$_)" }) -join '|'),
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    } catch {
        throw "Invalid -Highlight pattern: $($_.Exception.Message)"
    }
}

# -Compact is shorthand for hiding every field except Timestamp and Message.
$effectiveHideField = if ($Compact) { @('Component', 'Severity', 'Thread') } else { $HideField }

# Map CMTrace numeric types to readable severity names.
$typeMapping = @{
    '1' = 'Information'
    '2' = 'Warning'
    '3' = 'Error'
}

# Expected CMTrace line format:
# <![LOG[Message]LOG]!><time="..." date="..." component="..." ...>
$cmTracePattern = @'
(?s)^<!\[LOG\[(?<Message>.*?)\]LOG\]!><time="(?<Time>[^"]*)" date="(?<Date>[^"]*)" component="(?<Component>[^"]*)" context="(?<Context>[^"]*)" type="(?<Type>[^"]*)" thread="(?<Thread>[^"]*)" file="(?<File>[^"]*)">$
'@

$getContentParameters = @{
    LiteralPath = $LogFile
    Wait        = $true
}

if ($PSBoundParameters.ContainsKey('Tail')) {
    $getContentParameters.Tail = $Tail
}

# Returns the current console width, or 0 when output is redirected (piped
# or captured) and wrapping should be skipped.
function Get-ConsoleWidth {
    if ([Console]::IsOutputRedirected) {
        return 0
    }

    try {
        $width = $Host.UI.RawUI.WindowSize.Width
    } catch {
        return 0
    }

    if (-not $width -or $width -le 0) {
        return 0
    }

    return $width
}

# Returns the non-empty regex matches in $Text, or nothing when no regex is set.
function Get-HighlightHit {
    param (
        [string]$Text,
        [regex]$Regex
    )

    if ($null -eq $Regex) {
        return
    }

    $Regex.Matches($Text) | Where-Object { $_.Length -gt 0 }
}

# Writes one line, painting the parts covered by $Hits with the highlight
# colors. $Offset is where $Text starts within the string the hits were
# matched against, so a line can be one slice of a wrapped message.
function Write-HighlightedLine {
    param (
        [string]$Prefix,
        [string]$Text,
        [int]$Offset,
        [object[]]$Hits,
        [string]$Color
    )

    Write-Host $Prefix -NoNewline -ForegroundColor $Color

    $position = 0
    $end = $Offset + $Text.Length

    foreach ($hit in $Hits) {
        $from = [Math]::Max($hit.Index, $Offset)
        $to = [Math]::Min($hit.Index + $hit.Length, $end)

        if ($to -le $from) {
            continue
        }

        $local = $from - $Offset

        if ($local -gt $position) {
            Write-Host $Text.Substring($position, $local - $position) -NoNewline -ForegroundColor $Color
        }

        Write-Host $Text.Substring($local, $to - $from) -NoNewline -ForegroundColor Black -BackgroundColor Yellow
        $position = $local + ($to - $from)
    }

    Write-Host $Text.Substring($position) -ForegroundColor $Color
}

# Trims the leading whitespace of every line and trailing blank space, so a
# multi-line message lines up under the message column.
function Format-MessageLines {
    param (
        [string]$Message
    )

    $lines = $Message -split '\r?\n' | ForEach-Object { $_.TrimStart() }

    return (($lines -join "`n")).TrimEnd()
}

# Returns the index of the bracket that closes the JSON value opened at
# $Start, skipping over string contents, or -1 if it is never closed.
function Find-JsonEnd {
    param (
        [string]$Text,
        [int]$Start
    )

    $closers = [System.Collections.Generic.Stack[char]]::new()
    $inString = $false
    $escaped = $false

    for ($i = $Start; $i -lt $Text.Length; $i++) {
        $c = $Text[$i]

        if ($inString) {
            if ($escaped) {
                $escaped = $false
            } elseif ($c -eq [char]'\') {
                $escaped = $true
            } elseif ($c -eq [char]'"') {
                $inString = $false
            }

            continue
        }

        if ($c -eq [char]'"') {
            $inString = $true
        } elseif ($c -eq [char]'{') {
            $closers.Push([char]'}')
        } elseif ($c -eq [char]'[') {
            $closers.Push([char]']')
        } elseif ($c -eq [char]'}' -or $c -eq [char]']') {
            if ($closers.Count -eq 0 -or $closers.Pop() -ne $c) {
                return -1
            }

            if ($closers.Count -eq 0) {
                return $i
            }
        }
    }

    return -1
}

# Re-indents a JSON document token for token (two spaces per level) without
# parsing values, so the text is shown exactly as it was logged.
function Format-JsonText {
    param (
        [string]$Json
    )

    $sb = [System.Text.StringBuilder]::new()
    $depth = 0
    $inString = $false
    $escaped = $false

    for ($i = 0; $i -lt $Json.Length; $i++) {
        $c = $Json[$i]

        if ($inString) {
            $null = $sb.Append($c)

            if ($escaped) {
                $escaped = $false
            } elseif ($c -eq [char]'\') {
                $escaped = $true
            } elseif ($c -eq [char]'"') {
                $inString = $false
            }

            continue
        }

        if ($c -eq [char]'"') {
            $inString = $true
            $null = $sb.Append($c)
        } elseif ($c -eq [char]'{' -or $c -eq [char]'[') {
            $close = if ($c -eq [char]'{') { [char]'}' } else { [char]']' }
            $next = $i + 1

            while ($next -lt $Json.Length -and [char]::IsWhiteSpace($Json[$next])) {
                $next++
            }

            if ($next -lt $Json.Length -and $Json[$next] -eq $close) {
                # Empty object or array stays on one line.
                $null = $sb.Append($c).Append($close)
                $i = $next
            } else {
                $depth++
                $null = $sb.Append($c).Append("`n").Append(' ' * (2 * $depth))
            }
        } elseif ($c -eq [char]'}' -or $c -eq [char]']') {
            $depth--
            $null = $sb.Append("`n").Append(' ' * (2 * $depth)).Append($c)
        } elseif ($c -eq [char]',') {
            $null = $sb.Append(',').Append("`n").Append(' ' * (2 * $depth))
        } elseif ($c -eq [char]':') {
            $null = $sb.Append(': ')
        } elseif (-not [char]::IsWhiteSpace($c)) {
            $null = $sb.Append($c)
        }
    }

    return $sb.ToString()
}

# Pretty-prints every JSON object or array embedded in a message, leaving
# the surrounding text alone.
function Format-MessageJson {
    param (
        [string]$Message
    )

    $sb = [System.Text.StringBuilder]::new()
    $position = 0
    $i = 0

    while ($i -lt $Message.Length) {
        $c = $Message[$i]

        if ($c -ne [char]'{' -and $c -ne [char]'[') {
            $i++
            continue
        }

        $end = Find-JsonEnd -Text $Message -Start $i

        if ($end -lt 0) {
            $i++
            continue
        }

        $candidate = $Message.Substring($i, $end - $i + 1)

        # Only objects/arrays that open with a key, string, or nested
        # structure; skips things like "[Win32App]", "[1]" and "{}".
        $isJson = $candidate -match '^[\[{]\s*["{\[]'

        if ($isJson) {
            try {
                $null = ConvertFrom-Json -InputObject $candidate -ErrorAction Stop
            } catch {
                $isJson = $false
            }
        }

        if (-not $isJson) {
            $i++
            continue
        }

        $before = $Message.Substring($position, $i - $position)
        $lineStart = $before.LastIndexOf("`n") + 1

        if ($before.Substring($lineStart).Trim().Length -eq 0) {
            $before = $before.Substring(0, $lineStart)
        } else {
            $before = $before.TrimEnd() + "`n"
        }

        $null = $sb.Append($before).Append((Format-JsonText -Json $candidate))
        $position = $end + 1

        # Text that follows the JSON on the same line starts a new line.
        $lineEnd = $Message.IndexOf("`n", $position)
        $rest = if ($lineEnd -ge 0) { $Message.Substring($position, $lineEnd - $position) } else { $Message.Substring($position) }

        if ($rest.Trim().Length -gt 0) {
            $null = $sb.Append("`n")

            while ($position -lt $Message.Length -and ($Message[$position] -eq ' ' -or $Message[$position] -eq "`t")) {
                $position++
            }
        }

        $i = $position
    }

    $null = $sb.Append($Message.Substring($position))

    return $sb.ToString()
}

# Writes a log line that is not a parsed CMTrace entry (raw text), honoring
# the same visibility rules the main loop applies to such lines.
function Write-PlainLine {
    param (
        [string]$Text
    )

    if (-not $showPlainLines) {
        return
    }

    if ($HighlightOnly -and -not $highlightRegex.IsMatch($Text)) {
        return
    }

    Write-WrappedHostLine -Prefix '' -Message $Text -Color DarkGray -Width 0 -Regex $highlightRegex
}

# Writes a prefixed message. Long lines are word-wrapped so continuation
# lines align under the message column instead of column 0, and messages
# with line breaks keep them (indented under the prefix). Leading whitespace
# of a line, such as JSON indentation, is kept on its wrapped continuations.
# Matches of $Regex, if given, are highlighted.
function Write-WrappedHostLine {
    param (
        [string]$Prefix,
        [string]$Message,
        [string]$Color,
        [int]$Width,
        [regex]$Regex
    )

    $minAvailableWidth = 20
    $available = $Width - $Prefix.Length
    $wrap = $Width -gt 0 -and $available -ge $minAvailableWidth

    # One segment per displayed line. Indent is display-only; Sep is the
    # single character that follows the line in the text matches are found
    # in (a space after a wrap point, a newline after a real line break), so
    # a match can span a wrap point.
    $segments = [System.Collections.Generic.List[object]]::new()

    foreach ($logicalLine in ($Message -split "`n")) {
        if (-not $wrap) {
            $segments.Add([pscustomobject]@{ Indent = ''; Text = $logicalLine; Sep = "`n" })
            continue
        }

        $lead = [regex]::Match($logicalLine, '^\s*').Value

        if ($lead.Length -gt $available - $minAvailableWidth) {
            $lead = ''
        }

        $maxWidth = $available - $lead.Length
        $words = $logicalLine.TrimStart() -split '\s+' | Where-Object { $_.Length -gt 0 }
        $lines = [System.Collections.Generic.List[string]]::new()
        $current = ''

        foreach ($word in $words) {
            $candidate = if ($current.Length -eq 0) { $word } else { "$current $word" }

            if ($candidate.Length -gt $maxWidth -and $current.Length -gt 0) {
                $lines.Add($current)
                $current = $word
            } else {
                $current = $candidate
            }
        }

        if ($current.Length -gt 0 -or $lines.Count -eq 0) {
            $lines.Add($current)
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $segments.Add([pscustomobject]@{
                Indent = if ($i -eq 0) { '' } else { $lead }
                Text   = if ($i -eq 0) { $lead + $lines[$i] } else { $lines[$i] }
                Sep    = if ($i -lt $lines.Count - 1) { ' ' } else { "`n" }
            })
        }
    }

    $fullText = -join ($segments | ForEach-Object { $_.Text + $_.Sep })
    $hits = @(Get-HighlightHit -Text $fullText -Regex $Regex)
    $continuation = ' ' * $Prefix.Length
    $offset = 0

    for ($i = 0; $i -lt $segments.Count; $i++) {
        $basePrefix = if ($i -eq 0) { $Prefix } else { $continuation }
        $linePrefix = $basePrefix + $segments[$i].Indent
        Write-HighlightedLine -Prefix $linePrefix -Text $segments[$i].Text -Offset $offset -Hits $hits -Color $Color
        $offset += $segments[$i].Text.Length + 1
    }
}

# Raw (non-CMTrace) lines are hidden when filtering by severity or by a
# custom filter.
$showPlainLines = $Type -contains 'All' -and -not $PSBoundParameters.ContainsKey('WhereObject')

# A message with line breaks spans several physical lines; the lines read so
# far are held here until the closing "]LOG]!><...>" line arrives.
$script:pendingEntry = $null

Get-Content @getContentParameters | ForEach-Object {
    $line = $_

    if ($null -ne $script:pendingEntry) {
        if ($line.StartsWith('<![LOG[')) {
            # A new entry began, so the pending one was never completed.
            Write-PlainLine -Text $script:pendingEntry
            $script:pendingEntry = $null
        } else {
            $line = $script:pendingEntry + "`n" + $line
            $script:pendingEntry = $null
        }
    }

    if ($line.StartsWith('<![LOG[') -and $line -notmatch $cmTracePattern) {
        $script:pendingEntry = $line
        return
    }

    # Handle lines that are not in CMTrace format.
    if ($line -notmatch $cmTracePattern) {
        Write-PlainLine -Text $line
        return
    }

    $severity = $typeMapping[$Matches.Type]

    if (-not $severity) {
        $severity = 'Unknown'
    }

    # Apply the severity filter.
    if (
        $Type -notcontains 'All' -and
        $Type -notcontains $severity
    ) {
        return
    }

    # Create a structured object for filtering and display.
    $entry = [pscustomobject]@{
        Timestamp = '{0} {1}' -f $Matches.Date, $Matches.Time
        Date      = $Matches.Date
        Time      = $Matches.Time
        Component = $Matches.Component
        Context   = $Matches.Context
        Type      = $Matches.Type
        Severity  = $severity
        Thread    = $Matches.Thread
        File      = $Matches.File
        Message   = $Matches.Message
    }

    # Apply the custom Where-Object clause.
    if ($PSBoundParameters.ContainsKey('WhereObject')) {
        $filterResult = $entry |
            Where-Object -FilterScript $WhereObject

        if (-not $filterResult) {
            return
        }
    }

    # Apply the highlight-only filter against the message.
    if ($HighlightOnly -and -not $highlightRegex.IsMatch($entry.Message)) {
        return
    }

    # Build the displayed line last, so hiding a field never affects
    # filtering above, which always sees the full parsed entry.
    $visibleFields = [System.Collections.Generic.List[string]]::new()

    if ($effectiveHideField -notcontains 'Timestamp') {
        $visibleFields.Add("[$($entry.Timestamp)]")
    }

    if ($effectiveHideField -notcontains 'Component') {
        $visibleFields.Add("[$($entry.Component)]")
    }

    if ($effectiveHideField -notcontains 'Severity') {
        $visibleFields.Add("[$($entry.Severity)]")
    }

    if ($effectiveHideField -notcontains 'Thread') {
        $visibleFields.Add("[Thread:$($entry.Thread)]")
    }

    $prefix = if ($visibleFields.Count -gt 0) { ($visibleFields -join ' ') + ' ' } else { '' }
    $message = ''

    if ($effectiveHideField -notcontains 'Message') {
        $message = Format-MessageLines -Message $entry.Message

        if ($FormatJson) {
            $message = Format-MessageJson -Message $message
        }
    }

    $color = switch ($entry.Severity) {
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Unknown' { 'DarkGray' }
        default   { 'Gray' }
    }

    Write-WrappedHostLine -Prefix $prefix -Message $message -Color $color -Width (Get-ConsoleWidth) -Regex $highlightRegex
}
