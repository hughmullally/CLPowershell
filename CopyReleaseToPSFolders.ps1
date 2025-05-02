# Import the logging module
$modulePath = Join-Path $PSScriptRoot "Logging.psm1"
Import-Module $modulePath -Force

# Load configuration
function Get-Configuration {
    param (
        [string] $configPath = ".\config.json"
    )

    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found at: $configPath"
    }

    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        throw "Error loading configuration: $_"
    }
}

function GetReleaseRootFolder {
    param (
        [string] $rootFolder,
        [string] $release,
        $logger
    )

    $parts = $release.Split(".")
    $firstPart = $parts[0].Trim()
    $secondPart = $parts[1].Trim()
    $releaseRootFolder = "$rootFolder\$firstPart.$secondPart"
    $logger.Debug("Release root folder: $releaseRootFolder")
    return $releaseRootFolder
}

function getReleaseFolder {
    param (
        [string] $releaseRootFolder,
        [string] $release,
        $logger
    )

    $folders = Get-ChildItem -Path $releaseRootFolder -Directory
    $release = $release.Replace("V", "")

    $releaseFolder = ""
    foreach ($folder in $folders) {
        $folderRelease =  $folder.Name.Split('V')[-1]      
        if ($release -eq $folderRelease) {
            $releaseFolder = $folder
            $logger.Debug("Found release folder: $($folder.FullName)")
            break;
        }
    }
    return $releaseFolder
}

function get-target-root-folder {
    param (
        [string] $gitRootFolder,
        [string] $client,
        $logger
    )

    $targetFolder = "$gitRootFolder\\$client\\release"
    $logger.Debug("Target root folder: $targetFolder")
    return $targetFolder
}

function processRelease {
    param (
        [string] $releaseRootFolder,
        [string] $release,
        [string] $client,
        [string] $gitRootFolder,
        [object] $folderMappings,
        $logger
    )

    $release = $release.TrimStart()
    $releaseFolder = GetReleaseFolder -releaseRootFolder $releaseRootFolder -release $release -logger $logger

    if ( $releaseFolder -eq "") {
        $logger.Error("Release folder not found for release: $release")
        return
    }

    $targetRootFolder = get-target-root-folder $client -gitRootFolder $gitRootFolder -logger $logger

    foreach ($mapping in $folderMappings) {
        $sourceFolder = $mapping.sourceFolder
        $logger.Debug("Processing mapping: $sourceFolder")
        $fullSourceFolder = "${releaseFolder}${sourceFolder}"
        $targetFolder = "$targetRootFolder\$($mapping.targetFolder)"
        $logger.Information("Processing Source: $fullSourceFolder -> Target: $targetFolder")
        
        if (Test-Path -Path $fullSourceFolder  -PathType Container) {
            # Get files from the source folder
            $files = Get-ChildItem -Path $fullSourceFolder -File
            
            # Copy each file to the target folder
            foreach ($file in $files) {
                try {
                    Copy-Item -Path $file.FullName -Destination $targetFolder -Force
                    $logger.Information("Copied file: $($file.Name) to $targetFolder")
                }
                catch {
                    $logger.Error("Failed to copy file $($file.Name): $_")
                }
            }
        }
        else {
            $logger.Warning("Skipping folder for release $release : $fullSourceFolder")
        }
    }
}

<#
.SYNOPSIS
    Copies release files to client-specific folders.
.DESCRIPTION
    This function processes one or more releases and copies their files to the specified client's folder structure.
.PARAMETER targetClient
    The target client name.
.PARAMETER release
    Comma-separated list of releases to process.
.PARAMETER configPath
    Path to the configuration file.
.EXAMPLE
    CopyReleaseFilesToPSFolders -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
#>
function CopyReleaseFilesToPSFolders {
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
        $logLevel = $LogLevel.Information
        if ($config.logging.logLevel) {
            $logLevel = $LogLevel.($config.logging.logLevel)
        }
        $logger = New-Logger -LogPath $config.logging.logPath -LogLevel $logLevel
        $logger.Information("Starting CopyReleaseFilesToPSFolders for client: $targetClient")

        $releases = $release.Split(',')
        foreach ($release in $releases) {
            $release = "V" + $release.TrimStart()
            $logger.Information("Processing Release: $release")
            
            $releaseRootFolder = GetReleaseRootFolder -rootFolder $rootFolder -release $release -logger $logger
            if (-not (Test-Path $releaseRootFolder)) {
                $logger.Warning("Release root folder not found: $releaseRootFolder")
                continue
            }
            
            processRelease -releaseRootFolder $releaseRootFolder -release $release -client $targetClient -gitRootFolder $gitRootFolder -folderMappings $config.folderMappings -logger $logger
        }

        $logger.Information("Completed CopyReleaseFilesToPSFolders for client: $targetClient")
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

# Example usage
CopyReleaseFilesToPSFolders -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"