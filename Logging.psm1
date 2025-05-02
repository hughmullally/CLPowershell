# Logging Module
$LogLevel = @{
    Debug = 0
    Information = 1
    Warning = 2
    Error = 3
}

function New-Logger {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogPath,
        
        [Parameter(Mandatory=$true)]
        [int]$LogLevel,
        
        [bool]$ConsoleOutput = $true
    )

    # Create log directory if it doesn't exist
    if (-not (Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    }
    
    # Create log file with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd"
    $LogFile = Join-Path $LogPath "CopyReleaseToPSFolders_$timestamp.log"

    # Create logger object
    $logger = @{
        LogPath = $LogPath
        LogLevel = $LogLevel
        LogFile = $LogFile
        ConsoleOutput = $ConsoleOutput
    }

    # Add logging methods
    $logger | Add-Member -MemberType ScriptMethod -Name Log -Value {
        param([string]$message, [int]$level)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $levelName = ($LogLevel.GetEnumerator() | Where-Object { $_.Value -eq $level }).Name
        $logMessage = "[$timestamp] [$levelName] $message"
        
        # Only log if the message level is equal to or higher than the configured level
        if ($level -ge $this.LogLevel) {
            if ($this.ConsoleOutput) {
                switch ($level) {
                    ($LogLevel.Error) { Write-Host $logMessage -ForegroundColor Red }
                    ($LogLevel.Warning) { Write-Host $logMessage -ForegroundColor Yellow }
                    ($LogLevel.Information) { Write-Host $logMessage -ForegroundColor Green }
                    default { Write-Host $logMessage }
                }
            }
            
            # Write to log file
            Add-Content -Path $this.LogFile -Value $logMessage
        }
    }

    $logger | Add-Member -MemberType ScriptMethod -Name Debug -Value {
        param([string]$message)
        $this.Log($message, $LogLevel.Debug)
    }

    $logger | Add-Member -MemberType ScriptMethod -Name Information -Value {
        param([string]$message)
        $this.Log($message, $LogLevel.Information)
    }

    $logger | Add-Member -MemberType ScriptMethod -Name Warning -Value {
        param([string]$message)
        $this.Log($message, $LogLevel.Warning)
    }

    $logger | Add-Member -MemberType ScriptMethod -Name Error -Value {
        param([string]$message)
        $this.Log($message, $LogLevel.Error)
    }

    return $logger
}

# Export the functions and variables
Export-ModuleMember -Function New-Logger -Variable LogLevel 