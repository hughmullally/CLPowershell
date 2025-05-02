function GetReleaseRootFolder {
    param (
        [string] $rootFolder,
        [string] $release
    )

    $parts = $release.Split(".")
    $firstPart = $parts[0].Trim()
    $secondPart = $parts[1].Trim()
    $releaseRootFolder = "$rootFolder\V$firstPart.$secondPart"
    return $releaseRootFolder
}

function getReleaseFolder {
    param (
        [string] $releaseRootFolder,
        [string] $release
    )

    $folders = Get-ChildItem -Path $releaseRootFolder -Directory

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
        [string] $gitRootFolder
    )


    $folderMappings = @(
        @{ SourceFolder = '\Core Components\Database Scripts\1. Upgrade Release Script Files';TargetFolder = '01 Database Scripts\01 Upgrade Scripts' },
        @{ SourceFolder = "\Core Components\Loaders"; TargetFolder = "\04 Loaders\Standard Packages"},
        @{ SourceFolder = "\Core Components\RiskCubed Portal\RiskCubed"; TargetFolder = "\02 RiskCubedKit"},
        @{ SourceFolder = "\Core Components\RiskCubed Portal\RiskCubedAPI Kit"; TargetFolder = "\02 RiskCubedKit"},
        @{ SourceFolder = "\Credit Risk\Cube DB"; TargetFolder = "\03 Cubes"},
        @{ SourceFolder = "\Credit Risk\Reports\Cube Reports"; TargetFolder = "\05 Standard Reports\01 Cube Reports"},
        @{ SourceFolder = "\Credit Risk\DataMart Reports"; TargetFolder = "\05 Standard Reports\01 Cube Reports"},
        @{ SourceFolder = "\Credit Risk\Reports\DataMart Reports"; TargetFolder = "\05 Standard Reports\02 DataMart Reports"},
        @{ SourceFolder = "\Credit Risk\Reports\PowerBI"; TargetFolder = "\05 Standard Reports\03 PowerBI"},
        @{ SourceFolder = "\Credit Risk\Workflow XML"; TargetFolder = "\06 Standard Workflows"}
    )


    $release = $release.TrimStart()
    $releaseFolder = GetReleaseFolder -releaseRootFolder $releaseRootFolder -release $release 

    if ( $releaseFolder -eq "") {
        Write-Host "Release folder not found for release : $release" -ForegroundColor Red
        return
    }

    $targetRootFolder = get-target-root-folder $client -gitRootFolder $gitRootFolder

    foreach ($mapping in $folderMappings) {
        $sourceFolder = $mapping.SourceFolder
        Write-Host $sourceFolder
        $fullSourceFolder = "${releaseFolder}${SourceFolder}"
        $targetFolder = "$targetRootFolder\$($mapping.TargetFolder)"
        Write-Host "Processing Source: $fullSourceFolder -> Target: $targetFolder"
        
        if (Test-Path -Path $fullSourceFolder  -PathType Container) {
            # Get files from the source folder
            $files = Get-ChildItem -Path $fullSourceFolder -File
            
            # Copy each file to the target folder
            foreach ($file in $files) {
               Copy-Item -Path $file.FullName -Destination $TargetFolder -Force
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
.EXAMPLE
    CopyReleaseFilesToPSFolders -RootFolder "c:\releases" -TargetClient "Drax" -gitRootFolder "c:\Git" -Release "9.2.0, 9.2.4.0, 9.2.4.5"
#>
function CopyReleaseFilesToPSFolders {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string] $rootFolder,
        
        [Parameter(Mandatory=$true)]
        [string] $targetClient,
        
        [Parameter(Mandatory=$true)]
        [string] $release,
        
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string] $gitRootFolder
    )

    try {
        $releases = $release.Split(',')
        foreach ($release in $releases) {
            $release = "V" + $release.TrimStart()
            Write-Host "Processing Release: $release"
            
            $releaseRootFolder = GetReleaseRootFolder -rootFolder $rootFolder -release $release
            if (-not (Test-Path $releaseRootFolder)) {
                Write-Warning "Release root folder not found: $releaseRootFolder"
                continue
            }
            
            processRelease -releaseRootFolder $releaseRootFolder -release $release -client $targetClient -gitRootFolder $gitRootFolder
        }
    }
    catch {
        Write-Error "An error occurred: $_"
        throw
    }
}

CopyReleaseFilesToPSFolders -RootFolder "c:\releases" -TargetClient "Drax" -gitRootFolder "c:\Git" -Release "9.2.0, 9.2.4.0, 9.2.4.5"