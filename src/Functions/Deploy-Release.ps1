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
        $logger = New-Logger -LogPath $config.logging.logPath -LogLevel $logLevel
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

        # Generate CSV report
        $csvPath = Join-Path $gitRootFolder "$targetClient\release\file_releases.csv"
        $fileReleaseTracker.GetEnumerator() | 
            Select-Object @{Name='File'; Expression={$_.Key}}, @{Name='Release'; Expression={$_.Value}} |
            Export-Csv -Path $csvPath -NoTypeInformation
        
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

 # Deploy-Release -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
 