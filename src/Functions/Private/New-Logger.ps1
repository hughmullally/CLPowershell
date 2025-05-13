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
        $this.LogLevel = $logLevel
        $this.LogPath = $this.CreateDatestampedLogPath($logPath)
    }

    hidden [string] CreateDatestampedLogPath([string] $baseLogPath) {
        $logDir = Split-Path $baseLogPath -Parent
        $logFileName = [System.IO.Path]::GetFileNameWithoutExtension($baseLogPath)
        $logExtension = [System.IO.Path]::GetExtension($baseLogPath)
        # $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $timestamp = Get-Date -Format "yyyy-MM-dd"
        $datestampedLogPath = Join-Path $logDir "${logFileName}_${timestamp}${logExtension}"

        # Ensure log directory exists
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        return $datestampedLogPath
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

    [void] WriteLog([string] $level, [string] $message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$level] $message"
        # Add color coding based on log level
        switch ( $level) {
            "ERROR" { Write-Host $logMessage -ForegroundColor Red }
            "WARN"  { Write-Host $logMessage -ForegroundColor Yellow }
#            "INFO"  { Write-Host $logMessage -ForegroundColor White }
#            "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
            "INFO"  { }
            "DEBUG" { }
        default { Write-Host $logMessage }
        }
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

    return [Logger]::new($LogPath, $LogLevel)
} 