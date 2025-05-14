#Requires -Version 5.1

class DuplicateFileTracker {
    [object]$Logger
    [hashtable]$DuplicateFiles
    [string]$CsvPath

    DuplicateFileTracker([object]$logger) {
        $this.Logger = $logger
        $this.DuplicateFiles = @{}
        $this.CsvPath = ""
    }

    [void] SetCSVFile([string]$csvPath) {
        $this.CsvPath = $csvPath
    }

    [void] TrackFile([string]$fileName, [string]$sourceFolder, [string]$targetFolder) {
        $key = "$fileName"
        if ($this.DuplicateFiles.ContainsKey($key)) {
            $this.DuplicateFiles[$key].Count++
            $this.DuplicateFiles[$key].Locations += @{
                SourceFolder = $sourceFolder
                TargetFolder = $targetFolder
            }
            $this.Logger.Warning("Duplicate file found: $fileName (Count: $($this.DuplicateFiles[$key].Count))")
        } else {
            $this.DuplicateFiles[$key] = @{
                FileName = $fileName
                Count = 1
                Locations = @(
                    @{
                        SourceFolder = $sourceFolder
                        TargetFolder = $targetFolder
                    }
                )
            }
        }
     }

    [void] LogDuplicates([string]$release) {
        $duplicates = $this.DuplicateFiles.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        if ($duplicates.Count -gt 0) {
            $this.Logger.Information("Release $($Release) Found $($duplicates.Count) duplicate files:")
            
            # Create CSV data
            $csvData = @()
            foreach ($duplicate in $duplicates) {
                $this.Logger.Information("File: $($duplicate.Value.FileName)")
                $this.Logger.Information("  Count: $($duplicate.Value.Count)")
                $this.Logger.Information("  Locations:")
                
                foreach ($location in $duplicate.Value.Locations) {
                    $this.Logger.Information("    Source: $($location.SourceFolder)")
                    $this.Logger.Information("      Target: $($location.TargetFolder)")
                    
                    # Add entry to CSV data
                    $csvData += [PSCustomObject]@{
                        Release = $release
                        FileName = $duplicate.Value.FileName
                        Count = $duplicate.Value.Count
                        SourceFolder = $location.SourceFolder
                        TargetFolder = $location.TargetFolder
                        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    }
                }
            }
            
            # Ensure the directory exists
            $csvDir = Split-Path $this.CsvPath -Parent
            if (-not (Test-Path $csvDir)) {
                New-Item -ItemType Directory -Path $csvDir -Force | Out-Null
            }
            
            # Append to CSV file
            if( $this.csvPath -ne "") {
                $csvData | Export-Csv -Path $this.CsvPath -NoTypeInformation -Append
                $this.Logger.Information("Duplicate files logged to: $($this.CsvPath)")
            }
        } else {
            $this.Logger.Information("Release $($Release) No duplicate files found.")
        }
    }

    [hashtable] GetDuplicates() {
        return $this.DuplicateFiles
    }

    [void] Clear() {
        $this.DuplicateFiles = @{}
    }
} 