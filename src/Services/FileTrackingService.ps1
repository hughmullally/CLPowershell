#Requires -Version 5.1

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
                $this.FileReleaseTracker[$_.File] = $_.Release
            }
        }
    }

    [void] SaveFileReleases() {
        $this.Logger.Information("Saving file releases to: $this.CsvPath")
        $this.FileReleaseTracker.GetEnumerator() | 
            Select-Object @{Name='File'; Expression={$_.Key}}, @{Name='Release'; Expression={$_.Value}} |
            Export-Csv -Path $this.csvPath -NoTypeInformation
    }

    [void] CompleteFileTracking() {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $csvFolder = Split-Path $this.CsvPath -Parent
        $csvFileName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $this.CsvPath -Leaf))
        $newCsvFileName = "${csvFileName}_${timestamp}.csv"
        $newCsvPath = Join-Path $csvFolder $newCsvFileName
        
        if (Test-Path $this.CsvPath) {
            Rename-Item -Path $this.CsvPath -NewName $newCsvPath -Force
            $this.Logger.Information("Renamed tracking file to: $newCsvPath")
        }
    }

    [void] TrackFile([string]$fileName, [string]$release) {
        $this.FileReleaseTracker[$fileName] = $release
        $this.Logger.Debug("Tracked file: $fileName from release: $release")
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