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
        $logLevel = $LogLevel.Information
        if ($config.logging.logLevel) {
            $logLevel = $LogLevel.($config.logging.logLevel)
        }
        $logger = New-Logger -LogPath $config.logging.logPath -LogLevel $logLevel
        $logger.Information("Starting deployment confirmation for client: $targetClient, releases: $releases")

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
        $reportPath = Join-Path $gitRootFolder "$targetClient\release\deployment_confirmation_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $results | Export-Csv -Path $reportPath -NoTypeInformation

        $logger.Information("Deployment confirmation completed. Found $errors errors.")
        $logger.Information("Report generated at: $reportPath")

        return $results
    }
    catch {
        if ($logger) {
            $logger.Error("An error occurred during deployment confirmation: $_")
        } else {
            Write-Error "An error occurred before logger initialization: $_"
        }
        throw
    }
} 