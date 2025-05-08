#Requires -Version 5.1

class FileMapping {
    [string]$SourceFolder
    [string]$TargetFolder

    FileMapping([string]$sourceFolder, [string]$targetFolder) {
        $this.SourceFolder = $sourceFolder
        $this.TargetFolder = $targetFolder
    }

    [string] GetSourcePath([string]$basePath) {
        return Join-Path $basePath $this.SourceFolder
    }

    [string] GetTargetPath([string]$basePath) {
        return Join-Path $basePath $this.TargetFolder
    }
} 