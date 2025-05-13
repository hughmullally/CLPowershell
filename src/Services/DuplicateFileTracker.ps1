#Requires -Version 5.1

class DuplicateFileTracker {
    [object]$Logger
    [hashtable]$DuplicateFiles

    DuplicateFileTracker([object]$logger) {
        $this.Logger = $logger
        $this.DuplicateFiles = @{}
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

    [void] LogDuplicates() {
        $duplicates = $this.DuplicateFiles.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        if ($duplicates.Count -gt 0) {
            $this.Logger.Information("Found $($duplicates.Count) duplicate files:")
            foreach ($duplicate in $duplicates) {
                $this.Logger.Information("File: $($duplicate.Value.FileName)")
                $this.Logger.Information("  Count: $($duplicate.Value.Count)")
                $this.Logger.Information("  Locations:")
                foreach ($location in $duplicate.Value.Locations) {
                    $this.Logger.Information("    Source: $($location.SourceFolder)")
                    $this.Logger.Information("      Target: $($location.TargetFolder)")
                }
            }
        } else {
            $this.Logger.Information("No duplicate files found.")
        }
    }

    [hashtable] GetDuplicates() {
        return $this.DuplicateFiles
    }

    [void] Clear() {
        $this.DuplicateFiles = @{}
    }
} 