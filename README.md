# Watch-CMTraceLog

A colorized, live-following viewer for CMTrace-formatted logs — the log format used by ConfigMgr (SCCM) client logs, MECM, and Intune Management Extension logs.

## What it does

- Parses each CMTrace log line into a structured entry: timestamp, component, context, severity, thread, file, and message.
- Color-codes output by severity: **Information** = Gray, **Warning** = Yellow, **Error** = Red. Non-CMTrace lines pass through in dark gray.
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
```

Press `Ctrl+C` to stop monitoring.

## Parameters

| Parameter     | Required | Description |
|---------------|----------|-------------|
| `-LogFile`    | Yes      | Path to the CMTrace-formatted log file. Must exist when the script starts. |
| `-Type`       | No       | Severity filter: `All` (default), `Information`, `Warning`, `Error`. Accepts multiple values. |
| `-Tail`       | No       | Number of existing physical lines to process before following. Omit to process the entire existing log. Applied before parsing/filtering. |
| `-WhereObject`| No       | A scriptblock filter applied to every parsed entry (`$_`). Non-CMTrace lines are hidden when this is set. |

See the script's comment-based help (`Get-Help .\Watch-CMTraceLog.ps1 -Full`) for the complete parameter reference and more examples.

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+.

## Origin

Originally built as part of [ChTools](https://github.com/ChineaCh/ChTools), a portable Windows admin toolkit. Split out into its own repository to be usable and versioned independently.
