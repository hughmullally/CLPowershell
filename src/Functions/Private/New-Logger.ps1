enum LogLevel {
    Debug
    Information
    Warning
    Error
}

class Logger {
    [string] $LogPath
    [LogLevel] $LogLevel

    Logger([string] $logPath, [LogLevel] $logLevel) {
        $this.LogPath = $logPath
        $this.LogLevel = $logLevel
    }

    [void] Debug([string] $message) {
        if ($this.LogLevel -le [LogLevel]::Debug) {
            $this.WriteLog("DEBUG", $message)
        }
    }

    [void] Information([string] $message) {
        if ($this.LogLevel -le [LogLevel]::Information) {
            $this.WriteLog("INFO", $message)
        }
    }

    [void] Warning([string] $message) {
        if ($this.LogLevel -le [LogLevel]::Warning) {
            $this.WriteLog("WARN", $message)
        }
    }

    [void] Error([string] $message) {
        if ($this.LogLevel -le [LogLevel]::Error) {
            $this.WriteLog("ERROR", $message)
        }
    }

    hidden [void] WriteLog([string] $level, [string] $message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$level] $message"
        Add-Content -Path $this.LogPath -Value $logMessage
    }
}

function New-Logger {
    param (
        [Parameter(Mandatory=$true)]
        [string] $LogPath,
        
        [Parameter(Mandatory=$true)]
        [LogLevel] $LogLevel
    )

    # Ensure log directory exists
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    return [Logger]::new($LogPath, $LogLevel)
} 