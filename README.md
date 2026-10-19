# Watch-CMTraceLog

A colorized, live-following viewer for CMTrace-formatted logs — the log format used by ConfigMgr (SCCM) client logs, MECM, and Intune Management Extension logs.

## What it does

- Parses each CMTrace log line into a structured entry: timestamp, component, context, severity, thread, file, and message.
- Color-codes output by severity: **Information** = Gray, **Warning** = Yellow, **Error** = Red. Non-CMTrace lines pass through in dark gray.
- Word-wraps long messages to the console width, indenting continuation lines under the message column instead of letting the terminal hard-wrap mid-word. Skipped automatically when output is redirected.
- Lets you hide individual fields (`Timestamp`, `Component`, `Severity`, `Thread`, `Message`) from the displayed line, while still filtering on them via `-Type` or `-WhereObject`. The compact view (only Timestamp and Message) is the default; turn it off with `-Compact:$false`.
- Highlights regex matches live (`-Highlight`), optionally hiding non-matching entries (`-HighlightOnly`), so a `Select-String`-style search works while following the log.
- Joins log entries whose message contains line breaks (they span several physical lines in the file) and pretty-prints JSON embedded in messages by default (disable with `-FormatJson:$false`).
- After processing existing lines, keeps the file open and prints new entries as they're written (like `tail -f`).

## Usage

```powershell
# Follow a log from the start
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log'

# Only show the last 50 lines, then follow
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' -Tail 50

# Only show errors
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' -Type Error

# Multiple severities
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' -Tail 100 -Type Warning, Error

# Arbitrary filter against the parsed entry ($_.Component, $_.Severity, $_.Message, ...)
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' -WhereObject { $_.Component -eq 'AppEnforce' }
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' -WhereObject { $_.Message -match 'failed|error|exception' }

# Filter on a field while hiding it from the displayed line
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' -WhereObject { $_.Severity -eq 'Error' } -HideField Severity, Thread

# Highlight matches live, like Select-String (regex, case-insensitive)
.\Watch-CMTraceLog.ps1 -LogFile 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppActionProcessor.log' -Highlight $Parent, $Dep, 'effective intent', 'blocked on dependency'

# Same, but hide entries that don't match (filter + highlight)
.\Watch-CMTraceLog.ps1 -LogFile 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppActionProcessor.log' -Tail 80 -Highlight $Parent, $Dep, 'Found:' -HighlightOnly

# JSON payloads in messages are pretty-printed by default; show them as logged
.\Watch-CMTraceLog.ps1 -LogFile 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log' -FormatJson:$false

# Show every field (Component, Severity, Thread) instead of the default compact view
.\Watch-CMTraceLog.ps1 -LogFile 'C:\Windows\CCM\Logs\AppEnforce.log' -Compact:$false
```

Press `Ctrl+C` to stop monitoring.

## Parameters

| Parameter     | Required | Description |
|---------------|----------|-------------|
| `-LogFile`    | Yes      | Path to the CMTrace-formatted log file. Must exist when the script starts. |
| `-Type`       | No       | Severity filter: `All` (default), `Information`, `Warning`, `Error`. Accepts multiple values. |
| `-Tail`       | No       | Number of existing physical lines to process before following. Omit to process the entire existing log. Applied before parsing/filtering. |
| `-WhereObject`| No       | A scriptblock filter applied to every parsed entry (`$_`). Non-CMTrace lines are hidden when this is set. |
| `-HideField`  | No       | Fields to omit from the displayed line: `Timestamp`, `Component`, `Severity`, `Thread`, `Message`. Accepts multiple values. Hidden fields remain available for filtering via `-Type`/`-WhereObject`. Replaces the default compact view; cannot be combined with an explicit `-Compact`. |
| `-Highlight`  | No       | One or more regexes to highlight (black on yellow) in the message while following. Case-insensitive; works across word-wrapped lines. |
| `-HighlightOnly` | No    | Show only entries whose message matches a `-Highlight` pattern (like `Select-String`). Requires `-Highlight`. |
| `-FormatJson` | No (on)  | Pretty-print JSON objects/arrays found in messages (2-space indent, shown as logged); escaped JSON inside string values is expanded too. Use `-FormatJson:$false` to disable. Display only; filters see the original message. |
| `-Compact`    | No (on)  | Shorthand for `-HideField Component, Severity, Thread` — shows only Timestamp and Message. On by default; use `-Compact:$false` to show all fields. |

See the script's comment-based help (`Get-Help .\Watch-CMTraceLog.ps1 -Full`) for the complete parameter reference and more examples.

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+.

## Origin

Originally built as part of [ChTools](https://github.com/ChineaCh/ChTools), a portable Windows admin toolkit. Split out into its own repository to be usable and versioned independently.
