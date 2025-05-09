#Requires -Version 5.1

class FileTrackingService {
    [object]$Logger
    [hashtable]$FileReleaseTracker

    FileTrackingService([object]$logger) {
        $this.Logger = $logger
        $this.FileReleaseTracker = @{}
    }

    [void] LoadExistingFileReleases([string]$csvPath) {
        if (Test-Path $csvPath) {
            $this.Logger.Information("Loading existing file releases from: $csvPath")
            Import-Csv -Path $csvPath | ForEach-Object {
                $this.FileReleaseTracker[$_.File] = $_.Release
            }
        }
    }

    [void] SaveFileReleases([string]$csvPath) {
        $this.Logger.Information("Saving file releases to: $csvPath")
        $this.FileReleaseTracker.GetEnumerator() | 
            Select-Object @{Name='File'; Expression={$_.Key}}, @{Name='Release'; Expression={$_.Value}} |
            Export-Csv -Path $csvPath -NoTypeInformation
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