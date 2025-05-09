<#
.SYNOPSIS
    Deploys release files to client-specific folders.
.DESCRIPTION
    This function processes one or more releases and deploys their files to the specified client's folder structure.
    It handles file copying, logging, and generates a deployment report.
.PARAMETER targetClient
    The target client name.
.PARAMETER release
    Comma-separated list of releases to process.
.PARAMETER configPath
    Path to the configuration file.
.EXAMPLE
    Deploy-Release -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
#>
function Deploy-Release {
    param (
        [Parameter(Mandatory=$true)]
        [string] $targetClient,
        
        [Parameter(Mandatory=$true)]
        [string] $release,
        
        [string] $configPath = ".\config.json"
    )

    
    $logger = $null
    try {
        $config = Get-Configuration -configPath $configPath
        $rootFolder = $config.defaultPaths.rootFolder
        $gitRootFolder = $config.defaultPaths.gitRootFolder

        # Initialize logger
        $logLevel = [LogLevel]::Information
        if ($config.logging.logLevel) {
            $logLevel = [LogLevel]::($config.logging.logLevel)
        }
        $logPath = $config.logging.logPath 
        $logger = New-Logger -LogPath $logPath -LogLevel $logLevel
        $logger.Information("Starting release deployment for client: $targetClient")

        # Create ReleaseService instance
        $releaseService = [ReleaseService]::new($rootFolder, $logger)

        # Validate all releases before processing
        $releases = $release.Split(',')
        foreach ($release in $releases) {
            Test-ReleaseFormat -Release $release
        }

        foreach ($release in $releases) {
            # Ensure release is prefixed with V
            if (-not $release.StartsWith('V')) {
                $release = "V" + $release.Trim()
            }
            $logger.Information("Processing Release: $release")
            
            $releaseObj = $releaseService.GetRelease($release)
            if (-not (Test-Path $releaseObj.RootFolder)) {
                $logger.Warning("Release root folder not found: $($releaseObj.RootFolder)")
                continue
            }
            
            $releaseService.ProcessRelease($releaseObj.RootFolder, $release, $targetClient, $gitRootFolder, $config.folderMappings)
        }
        rename-tracking-file -logPath $logPath
        $logger.Information("Generated deployment report at: $csvPath")
        $logger.Information("Completed release deployment for client: $targetClient")
    }
    catch {
        if ($logger) {
            $logger.Error("An error occurred: $_")
        } else {
            Write-Error "An error occurred before logger initialization: $_"
        }
        throw
    }
} 

function rename-tracking-file {
    param (
        [Parameter(Mandatory=$true)]
        [string] $logPath
    )
    $logFolder = Split-Path $logPath -Parent
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $existingTrackingFile = Join-Path $logFolder "file_releases.csv"
    $newTrackingFile = Join-Path $logFolder "file_releases_${timestamp}.csv"

    if (Test-Path $existingTrackingFile) {
        Rename-Item -Path $existingTrackingFile -NewName $newTrackingFile -Force
        $logger.Information("Renamed tracking file to: $newTrackingFile") 
    }

}
 # Deploy-Release -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
 