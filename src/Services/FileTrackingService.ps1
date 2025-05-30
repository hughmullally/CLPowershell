#Requires -Version 5.1

# Table of files to exclude from tracking


class FileTrackingService {
    [object]$Logger
    [hashtable]$FileReleaseTracker
    [string]$CsvPath
    
    FileTrackingService([object]$logger, $gitRootFolder, $Client, [string]$csvFileName ) {
        $this.Logger = $logger
        $this.FileReleaseTracker = @{}
        $clientReleaseFolder = Join-Path $gitRootFolder "ClientReleases"
        $clientFolder = Join-Path $clientReleaseFolder $client
        $releaseFolder = Join-Path $clientFolder "Release"

        $this.CsvPath = Join-Path $releaseFolder $csvFileName
    }

    [void] LoadExistingFileReleases() {
        if (Test-Path $this.csvPath) {
            $this.Logger.Information("Loading existing file releases from: $this.csvPath")
            Import-Csv -Path $this.csvPath | ForEach-Object {
                $this.FileReleaseTracker[$_.File] = @{
                    Release = $_.Release
                    SourceFolder = $_.SourceFolder
                    TargetFolder = $_.TargetFolder
                }
            }
        }
    }

    [void] SaveFileReleases() {
        $this.Logger.Information("Saving file releases to: $this.CsvPath")
        $sortedTracker = $this.FileReleaseTracker.GetEnumerator() | Sort-Object Key
        $csvData = foreach ($entry in $sortedTracker) {
            $file = $entry.Key
            $release = $entry.Value.Release
            $sourceFolder = $entry.Value.SourceFolder
            $targetFolder = $entry.Value.TargetFolder
            [PSCustomObject]@{
                File = $file
                Release = $release
                SourceFolder = $sourceFolder
                TargetFolder = $targetFolder
            }
        }
        $csvData | Export-Csv -Path $this.csvPath -NoTypeInformation
    }

    [void] CompleteFileTracking() {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $csvFolder = Split-Path $this.CsvPath -Parent
        $csvFileName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $this.CsvPath -Leaf))
        $newCsvFileName = "${csvFileName}_${timestamp}.csv"
        $newCsvPath = Join-Path $csvFolder $newCsvFileName
        
        if (Test-Path $this.CsvPath) {
            Copy-Item -Path $this.CsvPath -Destination $newCsvPath -Force
            $this.Logger.Information("Copied tracking file to: $newCsvPath")
        }
    }

    [void] TrackFile([string]$fileName, [string]$release, [string]$sourceFolder, [string]$targetFolder) {
        [hashtable] $ExcludedFiles = @{
            "Microsoft.Data.SqlClient.dll" = $true
            "System.Data.SqlClient.dll" = $true
            "System.Runtime.Caching.dll" = $true
            "System.Security.Cryptography.ProtectedData.dll" = $true
            "System.Text.Encodings.Web.dll" = $true
            "sni.dll" = $true
        }
        
        $fileNameOnly = Split-Path $fileName -Leaf
        $this.Logger.Information("FileNameOnly: $fileNameOnly")
        if (-not $ExcludedFiles.ContainsKey($fileNameOnly)) {
            $this.FileReleaseTracker[$fileName] = @{
                Release = $release
                SourceFolder = $sourceFolder
                TargetFolder = $targetFolder
            }
            $this.Logger.Information("Tracked file: $fileName from release: $release (source: $sourceFolder, target: $targetFolder)")
        }
        else {
            $this.Logger.Information("Excluded file: $fileName from release: $release (source: $sourceFolder, target: $targetFolder)")
        }
    }

    [string] GetFileRelease([string]$fileName) {
        if ($this.FileReleaseTracker.ContainsKey($fileName)) {
            return $this.FileReleaseTracker[$fileName]
        }
        return $null
    }

    [hashtable] GetAllFileReleases() {
        return $this.FileReleaseTracker
    }
} 