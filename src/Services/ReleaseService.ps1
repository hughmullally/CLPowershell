#Requires -Version 5.1

class ReleaseService {
    [string]$RootFolder
    [object]$Logger

    ReleaseService([string]$rootFolder, [object]$logger) {
        $this.RootFolder = $rootFolder
        $this.Logger = $logger
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

    [void] ProcessRelease([string]$releaseRootFolder, [string]$release, [string]$client, [string]$gitRootFolder, [array]$folderMappings) {
        try {
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

<#
            if($cleanFolder) {
                $this.Logger.Information("Cleaning target folder: $targetRootFolder")
                # Get-ChildItem -Path $targetRootFolder -Recurse -File | Remove-Item -Force
            }
#>

            foreach ($mapping in $folderMappings) {
                $releaseFolderString = $releaseFolder.ReleaseFolder
                $sourceFolder = Join-Path $releaseFolderString $mapping.sourceFolder
                $targetFolder = Join-Path $targetRootFolder $mapping.targetFolder

                if (-not (Test-Path $sourceFolder)) {
                    $this.Logger.Warning("Source folder not found: $sourceFolder")
                    continue
                }

                if (-not (Test-Path $targetFolder)) {
                    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
                    $this.Logger.Information("Created target folder: $targetFolder")
                }

                # Copy files
                Get-ChildItem -Path $sourceFolder -File | ForEach-Object {
                    $targetFile = Join-Path $targetFolder $_.Name
                    Copy-Item -Path $_.FullName -Destination $targetFile -Force
                    $this.Logger.Information("Copied file: $($_.Name) to $targetFile")
                }
            }
        }
        catch {
            $this.Logger.Error("Error in ProcessRelease: $_")
            throw
        }
    }

    [array] ConfirmReleaseDeployment([string]$targetClient, [string]$releases, [string]$gitRootFolder, [hashtable]$config, [bool]$checkContents = $false) {
        try {
            $targetRootFolder = $this.GetTargetRootFolder($gitRootFolder, $targetClient)
            $results = @()
            $errors = 0
            $processedFiles = @{}

            # Process releases in version order (newest first)
            $releaseList = $releases.Split(',') | ForEach-Object { $_.Trim() }
            $sortedReleases = [Release]::SortByVersion([Release]::FromStringArray($releaseList))
            $this.Logger.Information("Processing releases in order: $($sortedReleases -join ', ')")

            foreach ($release in $sortedReleases) {
                $this.Logger.Information("Processing release: $release")
                
                $releaseObj = $this.GetRelease($release.Version)
                $releaseFolder = $this.GetReleaseFolder($releaseObj)

                if (-not $releaseFolder) {
                    $this.Logger.Warning("Source release folder not found for release: $release")
                    continue
                }

                # Process each folder mapping
                foreach ($mapping in $config.folderMappings) {
                    $sourceFolder = Join-Path $releaseFolder.FullName $mapping.sourceFolder
                    $targetFolder = Join-Path $targetRootFolder $mapping.targetFolder

                    if (-not (Test-Path $sourceFolder)) {
                        $this.Logger.Warning("Source folder not found: $sourceFolder")
                        continue
                    }

                    if (-not (Test-Path $targetFolder)) {
                        $this.Logger.Warning("Target folder not found: $targetFolder")
                        continue
                    }

                    # Get all files in source folder
                    $sourceFiles = Get-ChildItem -Path $sourceFolder -File -Recurse
                    $targetFiles = Get-ChildItem -Path $targetFolder -File -Recurse

                    foreach ($sourceFile in $sourceFiles) {
                        $relativePath = $sourceFile.FullName.Substring($sourceFolder.Length)
                        $targetFile = Join-Path $targetFolder $relativePath

                        if ($processedFiles.ContainsKey($relativePath)) {
                            continue
                        }

                        $result = [ValidationResult]::new($relativePath, $release.Version)

                        if (-not (Test-Path $targetFile)) {
                            $result.SetError("Target file not found")
                            $errors++
                        }
                        else {
                            $targetFileInfo = Get-Item $targetFile
                            if ($sourceFile.Length -ne $targetFileInfo.Length) {
                                $result.SetError("File size mismatch")
                                $errors++
                            }
                            elseif ($checkContents) {
                                $sourceHash = Get-FileHash -Path $sourceFile.FullName -Algorithm SHA256
                                $targetHash = Get-FileHash -Path $targetFile -Algorithm SHA256
                                if ($sourceHash.Hash -ne $targetHash.Hash) {
                                    $result.SetError("File content mismatch")
                                    $errors++
                                }
                            }
                        }

                        $results += $result
                        $processedFiles[$relativePath] = $true
                    }
                }
            }

            return $results
        }
        catch {
            $this.Logger.Error("Error in ConfirmReleaseDeployment: $_")
            throw
        }
    }
} 