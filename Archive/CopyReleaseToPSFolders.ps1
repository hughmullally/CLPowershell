# Import the modules
$modulePath = Join-Path $PSScriptRoot "Logging.psm1"
Import-Module $modulePath -Force
$validationPath = Join-Path $PSScriptRoot "Validation.psm1"
Import-Module $validationPath -Force

# Global variable to track files and their releases
$script:fileReleaseTracker = @{}

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
        Test-Configuration -Config $config
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

    try {
        Test-ReleaseFormat -Release $release | Out-Null
        Test-FolderPermissions -Path $rootFolder -Permission 'Read' | Out-Null

        $parts = $release.Split(".")
        $firstPart = $parts[0].Trim()
        $secondPart = $parts[1].Trim()
        $releaseRootFolder = "$rootFolder\V$firstPart.$secondPart"
        $logger.Debug("Release root folder: $releaseRootFolder")
        return $releaseRootFolder
    }
    catch {
        $logger.Error("Error in GetReleaseRootFolder: $_")
        throw
    }
}

function getReleaseFolder {
    param (
        [string] $releaseRootFolder,
        [string] $release,
        $logger
    )

    try {
        Test-FolderPermissions -Path $releaseRootFolder -Permission 'Read' | Out-Null

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
    catch {
        $logger.Error("Error in getReleaseFolder: $_")
        throw
    }
}

function get-target-root-folder {
    param (
        [string] $gitRootFolder,
        [string] $client,
        $logger
    )

    try {
        Test-FolderPermissions -Path $gitRootFolder -Permission 'Write' | Out-Null

        $targetFolder = "$gitRootFolder\$client\release"
        $logger.Debug("Target root folder: $targetFolder")
        return $targetFolder
    }
    catch {
        $logger.Error("Error in get-target-root-folder: $_")
        throw
    }
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

    try {
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
                        Test-FileSize -Path $file.FullName -MaxSizeMB 100 | Out-Null
                        $relativePath = $file.FullName.Substring($releaseFolder.Length)
                        $targetFilePath = Join-Path $targetFolder $file.Name
                        
                        # Track the file and its release
                        $script:fileReleaseTracker[$targetFilePath] = $release
                        
                        Copy-Item -Path $file.FullName -Destination $targetFolder -Force | Out-Null
                        $logger.Information("Copied file: $($file.Name) to $targetFolder")
                    }
                    catch {
                        $logger.Error("Failed to copy file $($file.Name): $_")
                        # Continue with next file instead of failing the entire process
                        continue
                    }
                }
            }
            else {
                $logger.Warning("Skipping folder for release $release : $fullSourceFolder")
            }
        }
    }
    catch {
        $logger.Error("Error in processRelease: $_")
        throw
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

        # Reset the file tracker
        $script:fileReleaseTracker = @{}

        # Validate all releases before processing
        $releases = $release.Split(',')
        foreach ($release in $releases) {
            Test-ReleaseFormat -Release $release
        }

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

        # Generate CSV report
        $csvPath = Join-Path $gitRootFolder "$targetClient\release\file_releases.csv"
        $fileReleaseTracker.GetEnumerator() | 
            Select-Object @{Name='File'; Expression={$_.Key}}, @{Name='Release'; Expression={$_.Value}} |
            Export-Csv -Path $csvPath -NoTypeInformation
        
        $logger.Information("Generated file release report at: $csvPath")
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


# Get release number from user
function test-get-release-number {
    release = Read-Host "Enter release number (e.g., 9.2.0 or 9.2.4.0)"
    $release = $release.Trim()  # Trim any leading/trailing spaces

    # Validate release format
    try {
        Test-ReleaseFormat -Release $release
    } catch {
        Write-Error $_.Exception.Message
        exit 1
    }

}

# Example usage
# CopyReleaseFilesToPSFolders -TargetClient "Drax" -Release "9.2.0, 9.2.4.0, 9.2.4.5"

<#
.SYNOPSIS
    Sorts release versions in descending order (newest first).
.DESCRIPTION
    Takes a list of release versions and sorts them in descending order,
    properly handling version numbers like 9.4.0, 9.4.2, 9.4.2.5.
.PARAMETER releases
    Array of release versions to sort.
.EXAMPLE
    Sort-ReleaseVersions -Releases @("9.4.0", "9.4.2", "9.4.2.5")
#>
function Sort-ReleaseVersions {
    param (
        [Parameter(Mandatory=$true)]
        [string[]] $releases
    )

    return $releases | ForEach-Object {
        # Convert version string to array of integers for proper comparison
        $versionParts = $_ -replace '^V', '' -split '\.'
        [PSCustomObject]@{
            Original = $_
            Version = [version]::new($versionParts -join '.')
        }
    } | Sort-Object -Property Version -Descending | ForEach-Object { $_.Original }
}

<#
.SYNOPSIS
    Tests the integrity of copied release files.
.DESCRIPTION
    This function verifies that files copied during the release process match their source files.
    It checks file existence, sizes, and optionally file contents by comparing source and destination folders directly.
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
    Test-ReleaseCopyIntegrity -TargetClient "Drax" -Releases "9.4.0,9.4.2,9.4.2.5" -CheckContents $true
#>
function Test-ReleaseCopyIntegrity {
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
        $logLevel = $LogLevel.Information
        if ($config.logging.logLevel) {
            $logLevel = $LogLevel.($config.logging.logLevel)
        }
        $logger = New-Logger -LogPath $config.logging.logPath -LogLevel $logLevel
        $logger.Information("Starting integrity check for client: $targetClient, releases: $releases")

        # Get target root folder
        $targetRootFolder = get-target-root-folder -gitRootFolder $gitRootFolder -client $targetClient -logger $logger

        $results = @()
        $errors = 0
        $processedFiles = @{}  # Track which files we've already checked

        # Process releases in version order (newest first)
        $releaseList = $releases.Split(',') | ForEach-Object { $_.Trim() }
        $sortedReleases = Sort-ReleaseVersions -Releases $releaseList
        $logger.Information("Processing releases in order: $($sortedReleases -join ', ')")

        foreach ($release in $sortedReleases) {
            $logger.Information("Processing release: $release")
            
            # Get source folders
        $releaseRootFolder = GetReleaseRootFolder -rootFolder $rootFolder -release $release -logger $logger
            $releaseFolder = GetReleaseFolder -releaseRootFolder $releaseRootFolder -release $release -logger $logger

            if (-not $releaseFolder) {
                $logger.Warning("Source release folder not found for release: $release")
                continue
            }

            # Process each folder mapping
            foreach ($mapping in $config.folderMappings) {
                $sourceFolder = Join-Path $releaseFolder.FullName $mapping.sourceFolder
                $targetFolder = Join-Path $targetRootFolder $mapping.targetFolder

                if (-not (Test-Path $sourceFolder)) {
                    $logger.Warning("Source folder not found: $sourceFolder")
                    continue
                }

                if (-not (Test-Path $targetFolder)) {
                    $logger.Warning("Target folder not found: $targetFolder")
                    continue
                }

                # Get all files in source folder
                $sourceFiles = Get-ChildItem -Path $sourceFolder -File -Recurse
                $targetFiles = Get-ChildItem -Path $targetFolder -File -Recurse

                # Create a hashtable of target files for quick lookup
                $targetFileLookup = @{}
                foreach ($file in $targetFiles) {
                    $relativePath = $file.FullName.Substring($targetFolder.Length)
                    $targetFileLookup[$relativePath] = $file
                }

                # Check each source file
                foreach ($sourceFile in $sourceFiles) {
                    $relativePath = $sourceFile.FullName.Substring($sourceFolder.Length)
                    
                    # Skip if we've already processed this file in a newer release
                    if ($processedFiles.ContainsKey($relativePath)) {
                        $logger.Debug("Skipping file $relativePath as it was already found in a newer release")
                        continue
                    }

                    $result = [PSCustomObject]@{
                        File = $relativePath
                        Release = $release
                        Status = "OK"
                        Details = ""
                    }

                    # Check if file exists in target
                    if (-not $targetFileLookup.ContainsKey($relativePath)) {
                        $result.Status = "ERROR"
                        $result.Details = "File not found in target"
                        $errors++
                        $results += $result
                        continue
                    }

                    $targetFile = $targetFileLookup[$relativePath]

                    # Compare file sizes
                    if ($sourceFile.Length -ne $targetFile.Length) {
                        $result.Status = "ERROR"
                        $result.Details = "File size mismatch. Source: $($sourceFile.Length) bytes, Target: $($targetFile.Length) bytes"
                        $errors++
                        $results += $result
                        continue
                    }

                    # Optionally compare file contents
                    if ($checkContents) {
                        $sourceHash = Get-FileHash -Path $sourceFile.FullName -Algorithm SHA256
                        $targetHash = Get-FileHash -Path $targetFile.FullName -Algorithm SHA256
                        
                        if ($sourceHash.Hash -ne $targetHash.Hash) {
                            $result.Status = "ERROR"
                            $result.Details = "File content mismatch"
                            $errors++
                            $results += $result
                            continue
                        }
                    }

                    $results += $result
                    $processedFiles[$relativePath] = $true
                }
            }
        }

        # Check for extra files in target that shouldn't be there
        foreach ($mapping in $config.folderMappings) {
            $targetFolder = Join-Path $targetRootFolder $mapping.targetFolder
            if (Test-Path $targetFolder) {
                $targetFiles = Get-ChildItem -Path $targetFolder -File -Recurse
                foreach ($targetFile in $targetFiles) {
                    $relativePath = $targetFile.FullName.Substring($targetFolder.Length)
                    if (-not $processedFiles.ContainsKey($relativePath)) {
                        $result = [PSCustomObject]@{
                            File = $relativePath
                            Release = "Unknown"
                            Status = "WARNING"
                            Details = "Extra file found in target that doesn't exist in any source release"
                        }
                        $results += $result
                    }
                }
            }
        }

        # Generate report
        $reportPath = Join-Path $gitRootFolder "$targetClient\release\integrity_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $results | Export-Csv -Path $reportPath -NoTypeInformation

        $logger.Information("Integrity check completed. Found $errors errors.")
        $logger.Information("Report generated at: $reportPath")

        return $results
    }
    catch {
        if ($logger) {
            $logger.Error("An error occurred during integrity check: $_")
        } else {
            Write-Error "An error occurred before logger initialization: $_"
        }
        throw
    }
}

# Example usage
# Test-ReleaseCopyIntegrity -TargetClient "Drax" -Releases "9.2.0,9.2.4.0,9.2.4.5" -CheckContents $true
