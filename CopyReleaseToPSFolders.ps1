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
        [string] $release
    )

    $parts = $release.Split(".")
    $firstPart = $parts[0].Trim()
    $secondPart = $parts[1].Trim()
    $releaseRootFolder = "$rootFolder\$firstPart.$secondPart"
    return $releaseRootFolder
}

function getReleaseFolder {
    param (
        [string] $releaseRootFolder,
        [string] $release
    )

    $folders = Get-ChildItem -Path $releaseRootFolder -Directory
    $release = $release.Replace("V", "")

    $releaseFolder = ""
    foreach ($folder in $folders) {
        $folderRelease =  $folder.Name.Split('V')[-1]      
        if ($release -eq $folderRelease) {
            $releaseFolder = $folder
            break;
        }
    }
    return $releaseFolder
}

function get-target-root-folder {
    param (
        [string] $gitRootFolder,
        [string] $client
    )

    return "$gitRootFolder\\$client\\release"
}

function processRelease {
    param (
        [string] $releaseRootFolder,
        [string] $release,
        [string] $client,
        [string] $gitRootFolder,
        [object] $folderMappings
    )

    $release = $release.TrimStart()
    $releaseFolder = GetReleaseFolder -releaseRootFolder $releaseRootFolder -release $release 

    if ( $releaseFolder -eq "") {
        Write-Host "Release folder not found for release : $release" -ForegroundColor Red
        return
    }

    $targetRootFolder = get-target-root-folder $client -gitRootFolder $gitRootFolder

    foreach ($mapping in $folderMappings) {
        $sourceFolder = $mapping.sourceFolder
        Write-Host $sourceFolder
        $fullSourceFolder = "${releaseFolder}${sourceFolder}"
        $targetFolder = "$targetRootFolder\$($mapping.targetFolder)"
        Write-Host "Processing Source: $fullSourceFolder -> Target: $targetFolder"
        
        if (Test-Path -Path $fullSourceFolder  -PathType Container) {
            # Get files from the source folder
            $files = Get-ChildItem -Path $fullSourceFolder -File
            
            # Copy each file to the target folder
            foreach ($file in $files) {
               Copy-Item -Path $file.FullName -Destination $targetFolder -Force
               Write-Host "Copying `n    $file`n    to $targetFolder"
            }
        }
        else {
            Write-Host "Skipping folder for release $release : $fullSourceFolder" -ForegroundColor Red
        }
    }
}

<#
.SYNOPSIS
    Copies release files to client-specific folders.
.DESCRIPTION
    This function processes one or more releases and copies their files to the specified client's folder structure.
.PARAMETER rootFolder
    The root folder containing the releases.
.PARAMETER targetClient
    The target client name.
.PARAMETER release
    Comma-separated list of releases to process.
.PARAMETER gitRootFolder
    The root folder of the git repository.
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

    try {
        $config = Get-Configuration -configPath $configPath
        $rootFolder = $config.defaultPaths.rootFolder
        $gitRootFolder = $config.defaultPaths.gitRootFolder

        $releases = $release.Split(',')
        foreach ($release in $releases) {
            $release = "V" + $release.TrimStart()
            Write-Host "Processing Release: $release"
            
            $releaseRootFolder = GetReleaseRootFolder -rootFolder $rootFolder -release $release
            if (-not (Test-Path $releaseRootFolder)) {
                Write-Warning "Release root folder not found: $releaseRootFolder"
                continue
            }
            
            processRelease -releaseRootFolder $releaseRootFolder -release $release -client $targetClient -gitRootFolder $gitRootFolder -folderMappings $config.folderMappings
        }
    }
    catch {
        Write-Error "An error occurred: $_"
        throw
    }
}

# Example usage
CopyReleaseFilesToPSFolders -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"