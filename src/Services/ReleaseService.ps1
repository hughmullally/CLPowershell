#Requires -Version 5.1

class ReleaseService {
    [string]$RootFolder
    [object]$Logger
    [DuplicateFileTracker]$DuplicateTracker

    ReleaseService([string]$rootFolder, [object]$logger, [string]$client) {
        $this.RootFolder = $rootFolder
        $this.Logger = $logger
        $this.DuplicateTracker = [DuplicateFileTracker]::new($logger)
        
        # Replace client name in log path if it exists in the logger
        if ($logger.LogPath) {
            $logger.LogPath = $this.ReplaceClientInLogPath($logger.LogPath, $client)
        }
    }

    [string] ReplaceClientInLogPath([string]$logPath, [string]$client) {
        return $logPath -replace '{client}', $client
    }

    [Release] GetRelease([string]$version) {
        $release = [Release]::FromString($version)
        $parts = $version.Split(".")
        $firstPart = $parts[0].Trim()
        $secondPart = $parts[1].Trim()
        $release.RootFolder = "$($this.RootFolder)\$firstPart.$secondPart"
        
        $this.Logger.Debug("Release root folder: $($release.RootFolder)")
        return $release
    }

    [Release] GetReleaseFolder([Release]$release) {
        if (-not (Test-Path $release.RootFolder)) {
            throw "Release root folder not found: $($release.RootFolder)"
        }

        $folders = Get-ChildItem -Path $release.RootFolder -Directory
        $version = $release.Version.Replace("V", "")

        foreach ($folder in $folders) {
            $folderRelease = $folder.Name.Split('V')[-1]
            if ($version -eq $folderRelease) {
                $release.ReleaseFolder = $folder.FullName
                $this.Logger.Debug("Found release folder: $($folder.FullName)")
                return $release
            }
        }

        throw "Release folder not found for version: $version"
    }

    [string] GetTargetRootFolder([string]$gitRootFolder, [string]$client) {
        try {
            $targetFolder = "$gitRootFolder\ClientReleases\$client\release"
            $this.Logger.Debug("Target root folder: $targetFolder")
            return $targetFolder
        }
        catch {
            $this.Logger.Error("Error in GetTargetRootFolder: $_")
            throw
        }
    }

    hidden [void] CopyFiles(
        [string]$sourceFolder,
        [string]$targetFolder,
        [string]$release,
        [string]$sourceFolderName,
        [string]$targetFolderName,
        [FileTrackingService]$fileTracker
    ) {
        # Copy files from root folder
        Get-ChildItem -Path $sourceFolder -File | ForEach-Object {
            $targetFile = Join-Path $targetFolder $_.Name
            Copy-Item -Path $_.FullName -Destination $targetFile -Force
            $key = "$targetFolderName\$($_.Name)"
            $fileTracker.TrackFile($key, $release, $sourceFolderName, $targetFolderName)
            $this.DuplicateTracker.TrackFile($key, $sourceFolderName, $targetFolderName)
            $this.Logger.Information("Copied file: $($_.FullName) to $targetFile")
        }
    }

    [void] CopyFilesAndSubfoldersFromSourceToTarget(
        [string]$sourceFolder,
        [string]$targetFolder,
        [string]$release,
        [string]$sourceFolderName,
        [string]$targetFolderName,
        [FileTrackingService]$fileTracker
    ) {
        if (-not (Test-Path $sourceFolder)) {
            $this.Logger.Warning("Source folder not found: $sourceFolder")
            return
        }
        else {
            $this.Logger.Information("Source folder found: $sourceFolder")
        }

        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
            $this.Logger.Information("Created target folder: $targetFolder")
        }

        # Copy files from current folder
        $this.CopyFiles($sourceFolder, $targetFolder, $release, $sourceFolderName, $targetFolderName, $fileTracker)

        # Process subfolders recursively
        Get-ChildItem -Path $sourceFolder -Directory | ForEach-Object {
            $sourceSubFolder = $_.FullName
            $relativePath = $_.Name
            $targetSubFolder = Join-Path $targetFolder $relativePath

            # Create target subfolder if it doesn't exist
            if (-not (Test-Path $targetSubFolder)) {
                New-Item -ItemType Directory -Path $targetSubFolder -Force | Out-Null
                $this.Logger.Information("Created target subfolder: $targetSubFolder")
            }

            # Recursively copy files from subfolder
            $this.CopyFilesAndSubfoldersFromSourceToTarget(
                $sourceSubFolder,
                $targetSubFolder,
                $release,
                (Join-Path $sourceFolderName $relativePath),
                (Join-Path $targetFolderName $relativePath),
                $fileTracker
            )
        }
    }

    [void] CopyFilesFromSourceToTarget(
        [string]$sourceFolder,
        [string]$targetFolder,
        [string]$release,
        [string]$sourceFolderName,
        [string]$targetFolderName,
        [FileTrackingService]$fileTracker
    ) {
        if (-not (Test-Path $sourceFolder)) {
            $this.Logger.Warning("Source folder not found: $sourceFolder")
            return
        }
        else {
            $this.Logger.Information("Source folder found: $sourceFolder")
        }

        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
            $this.Logger.Information("Created target folder: $targetFolder")
        }

        # Copy files from current folder
        $this.CopyFiles($sourceFolder, $targetFolder, $release, $sourceFolderName, $targetFolderName, $fileTracker)
    }

    [void] ProcessRelease(
        [string]$releaseRootFolder,
        [string]$release,
        [string]$client,
        [string]$gitRootFolder,
        [array]$folderMappings,
        [FileTrackingService]$fileTracker
    ) {
        try {
            $this.DuplicateTracker.Clear()
            $csvPath = $this.GetTargetRootFolder($gitRootFolder, $client) + $($release) + "_DuplicateFiles.csv"
            $this.DuplicateTracker.SetCSVFile($csvPath)
            $this.Logger.Information("Processing release folder: $releaseRootFolder")
            $releaseObj = $this.GetRelease($release)
            $releaseFolder = $this.GetReleaseFolder($releaseObj)

            if (-not $releaseFolder) {
                $this.Logger.Warning("Release folder not found for release: $release")
                return
            }

            $targetRootFolder = $this.GetTargetRootFolder($gitRootFolder, $client)
            if (-not $targetRootFolder) {
                $this.Logger.Warning("Target root folder not found for client: $client")
                return
            }

            # Load existing file releases
            $fileTracker.LoadExistingFileReleases()

            foreach ($mapping in $folderMappings) {
                $releaseFolderString = $releaseFolder.ReleaseFolder
                $sourceFolder = Join-Path $releaseFolderString $mapping.sourceFolder
                $targetFolder = Join-Path $targetRootFolder $mapping.targetFolder
                $recurse = $mapping.recurse
                
                if (-not $recurse) {
                    $this.CopyFilesFromSourceToTarget(
                        $sourceFolder,
                        $targetFolder,
                        $release,
                        $mapping.sourceFolder,
                        $mapping.targetFolder,
                        $fileTracker
                    )
                }
                else {
                    $this.CopyFilesAndSubfoldersFromSourceToTarget(
                        $sourceFolder,
                        $targetFolder,
                        $release,
                        $mapping.sourceFolder,
                        $mapping.targetFolder,
                        $fileTracker
                    )
                }
            }

            # Save updated file releases
            $fileTracker.SaveFileReleases()
            $this.DuplicateTracker.LogDuplicates($release)
            
        }
        catch {
            $this.Logger.Error("Error in ProcessRelease: $_")
            throw
        }
    }

    hidden [void] ValidateFiles(
        [string]$sourceFolder,
        [string]$targetFolder,
        [string]$release,
        [string]$sourceFolderName,
        [string]$targetFolderName,
        [FileTrackingService]$fileTracker,
        [hashtable]$processedFiles,
        [array]$results,
        [ref]$errors,
        [bool]$checkContents
    ) {
        # Get all files in source folder
        $sourceFiles = Get-ChildItem -Path $sourceFolder -File
        $targetFiles = Get-ChildItem -Path $targetFolder -File

        foreach ($sourceFile in $sourceFiles) {
            $relativePath = $sourceFile.FullName.Substring($sourceFolder.Length)
            $targetFile = Join-Path $targetFolder $relativePath
            $this.Logger.Information("Relative: $relativePath")

            if ($processedFiles.ContainsKey($relativePath)) {
                continue
            }

            $result = [ValidationResult]::new($relativePath, $release)

            if (-not (Test-Path $targetFile)) {
                $result.SetError("Target file not found")
                $errors.Value++
            }
            else {
                $targetFileInfo = Get-Item $targetFile
                if ($sourceFile.Length -ne $targetFileInfo.Length) {
                    $result.SetError("File size mismatch")
                    $errors.Value++
                }
                elseif ($checkContents) {
                    $sourceHash = Get-FileHash -Path $sourceFile.FullName -Algorithm SHA256
                    $targetHash = Get-FileHash -Path $targetFile -Algorithm SHA256
                    if ($sourceHash.Hash -ne $targetHash.Hash) {
                        $result.SetError("File content mismatch")
                        $errors.Value++
                    }
                }
            }

            # Track the file with its release version
            $fileTracker.TrackFile("$targetFolderName\$($sourceFile.Name)", $release, $sourceFolderName, $targetFolderName)
            $this.Logger.Information("Release $release - $($sourceFile.Name) matches")
            
            $results += $result
            $processedFiles[$relativePath] = $true
        }
    }

    [array] ConfirmReleaseDeployment([string]$targetClient, [string]$releases, [string]$gitRootFolder, $config, [bool]$checkContents = $false) {
        try {
            $targetRootFolder = $this.GetTargetRootFolder($gitRootFolder, $targetClient)
            $results = @()
            $errors = 0
            $processedFiles = @{}

            # Load existing file releases
            $fileTracker = [FileTrackingService]::new($this.Logger, $gitRootFolder, $targetClient, "confirm-release-tracker.csv")
            $fileTracker.LoadExistingFileReleases()

            # Process releases in version order (newest first)
            $releaseList = $releases.Split(',') | ForEach-Object { $_.Trim() }
            $sortedReleases = [Release]::SortByVersion([Release]::FromStringArray($releaseList))
            $this.Logger.Information("Processing releases in order: $($sortedReleases -join ', ')")

            foreach ($release in $sortedReleases) {
                if (-not $release.Version.StartsWith('V')) {
                    $release.Version = "V" + $release.Version.Trim()
                }

                $this.Logger.Information("Processing release: $release")
                
                $releaseObj = $this.GetRelease($release.Version)
                $releaseFolder = $this.GetReleaseFolder($releaseObj)

                if (-not $releaseFolder) {
                    $this.Logger.Warning("Source release folder not found for release: $release")
                    continue
                }

                # Process each folder mapping
                foreach ($mapping in $config.folderMappings) {
                    $sourceFolder = Join-Path $releaseFolder.ReleaseFolder $mapping.sourceFolder
                    $targetFolder = Join-Path $targetRootFolder $mapping.targetFolder
                    $recurse = $mapping.recurse

                    if (-not (Test-Path $sourceFolder)) {
                        $this.Logger.Warning("Source folder not found: $sourceFolder")
                        continue
                    }
                    else {
                        $this.Logger.Information("Source folder found: $sourceFolder")
                    }

                    if (-not (Test-Path $targetFolder)) {
                        $this.Logger.Warning("Target folder not found: $targetFolder")
                        continue
                    }

                    if (-not $recurse) {
                        # Validate files in current folder only
                        $this.ValidateFiles(
                            $sourceFolder,
                            $targetFolder,
                            $release.Version,
                            $mapping.sourceFolder,
                            $mapping.targetFolder,
                            $fileTracker,
                            $processedFiles,
                            $results,
                            [ref]$errors,
                            $checkContents
                        )
                    }
                    else {
                        # Process all files recursively
                        $this.ValidateFilesRecursively(
                            $sourceFolder,
                            $targetFolder,
                            $release.Version,
                            $mapping.sourceFolder,
                            $mapping.targetFolder,
                            $fileTracker,
                            $processedFiles,
                            $results,
                            [ref]$errors,
                            $checkContents
                        )
                    }
                }
                # Save the updated file releases to CSV
                $fileTracker.SaveFileReleases()
            }
            $fileTracker.CompleteFileTracking()

            return $results
        }
        catch {
            $this.Logger.Error("Error in ConfirmReleaseDeployment: $_")
            throw
        }
    }

    hidden [void] ValidateFilesRecursively(
        [string]$sourceFolder,
        [string]$targetFolder,
        [string]$release,
        [string]$sourceFolderName,
        [string]$targetFolderName,
        [FileTrackingService]$fileTracker,
        [hashtable]$processedFiles,
        [array]$results,
        [ref]$errors,
        [bool]$checkContents
    ) {
        # Validate files in current folder
        $this.ValidateFiles(
            $sourceFolder,
            $targetFolder,
            $release,
            $sourceFolderName,
            $targetFolderName,
            $fileTracker,
            $processedFiles,
            $results,
            $errors,
            $checkContents
        )

        # Process subfolders recursively
        Get-ChildItem -Path $sourceFolder -Directory | ForEach-Object {
            $sourceSubFolder = $_.FullName
            $relativePath = $_.Name
            $targetSubFolder = Join-Path $targetFolder $relativePath

            if (-not (Test-Path $targetSubFolder)) {
                $this.Logger.Warning("Target subfolder not found: $targetSubFolder")
                return
            }

            # Recursively validate files in subfolder
            $this.ValidateFilesRecursively(
                $sourceSubFolder,
                $targetSubFolder,
                $release,
                (Join-Path $sourceFolderName $relativePath),
                (Join-Path $targetFolderName $relativePath),
                $fileTracker,
                $processedFiles,
                $results,
                $errors,
                $checkContents
            )
        }
    }

    [void] ProcessAllReleases([string]$targetClient, [string]$releases, [string]$gitRootFolder, $config) {
        try {
            $this.Logger.Information("Starting release deployment for client: $targetClient")
            $releaseTracker = [FileTrackingService]::new($this.Logger, $gitRootFolder, $targetClient, "deploy-release-tracker.csv")
            $duplicateCsv = $this.GetTargetRootFolder($gitRootFolder, $targetClient) + "\DuplicateFiles.csv"

            # Validate all releases before processing
            $releaseList = $releases.Split(',')
            foreach ($release in $releaseList) {
                Test-ReleaseFormat -Release $release
            }

            foreach ($release in $releaseList) {
                # Ensure release is prefixed with V
                if (-not $release.StartsWith('V')) {
                    $release = "V" + $release.Trim()
                }
                $this.Logger.Information("Processing Release: $release")
                
                $releaseObj = $this.GetRelease($release)
                if (-not (Test-Path $releaseObj.RootFolder)) {
                    $this.Logger.Warning("Release root folder not found: $($releaseObj.RootFolder)")
                    continue
                }
                
                $this.ProcessRelease($releaseObj.RootFolder, 
                                        $release, 
                                        $targetClient, 
                                        $gitRootFolder, 
                                        $config.folderMappings, 
                                        $releaseTracker)

            }
            $releaseTracker.CompleteFileTracking()
            $this.Logger.Information("Completed release deployment for client: $targetClient")
        }
        catch {
            $this.Logger.Error("Error in ProcessAllReleases: $_")
            throw
        }
    }
} 