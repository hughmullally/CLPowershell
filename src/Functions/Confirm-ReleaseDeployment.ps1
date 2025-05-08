<#
.SYNOPSIS
    Confirms the integrity of a release deployment.
.DESCRIPTION
    This function verifies that files deployed during the release process match their source files.
    It checks file existence, sizes, and optionally file contents by comparing source and destination folders.
    Handles cascading releases by checking multiple releases in order of version number.
.PARAMETER targetClient
    The target client name.
.PARAMETER releases
    Comma-separated list of releases to check (e.g., "9.4.0,9.4.2,9.4.2.5").
    Releases will be automatically sorted by version number.
.PARAMETER configPath
    Path to the configuration file.
.PARAMETER checkContents
    If true, performs a hash comparison of file contents.
.EXAMPLE
    Confirm-ReleaseDeployment -TargetClient "Drax" -Releases "9.4.0,9.4.2,9.4.2.5" -CheckContents $true
#>
function Confirm-ReleaseDeployment {
    param (
        [Parameter(Mandatory=$true)]
        [string] $targetClient,
        
        [Parameter(Mandatory=$true)]
        [string] $releases,
        
        [string] $configPath = ".\config.json",
        
        [bool] $checkContents = $false
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
        $logger.Information("Starting deployment confirmation for client: $targetClient, releases: $releases")

        # Create ReleaseService instance
        $releaseService = [ReleaseService]::new($rootFolder, $logger)

        # Get validation results
        $results = $releaseService.ConfirmReleaseDeployment($targetClient, $releases, $gitRootFolder, $config, $checkContents)

        # Output results
        $results | ForEach-Object {
            $status = switch ($_.Status) {
                "Success" { "OK" }
                "Error" { "ERROR" }
                "Warning" { "WARNING" }
                default { $_.Status }
            }
            Write-Host "$($_.File) - $status - $($_.Details)"
        }

        $logger.Information("Completed deployment confirmation for client: $targetClient")
        return $results
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