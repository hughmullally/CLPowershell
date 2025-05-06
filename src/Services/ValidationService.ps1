class ValidationService {
    [object]$Logger
    [bool]$CheckContents

    ValidationService([object]$logger, [bool]$checkContents) {
        $this.Logger = $logger
        $this.CheckContents = $checkContents
    }

    [ValidationResult] ValidateFile([string]$sourceFile, [string]$targetFile, [string]$release) {
        $result = [ValidationResult]::new($sourceFile, $release)

        if (-not (Test-Path $targetFile)) {
            $result.SetError("File not found in target")
            return $result
        }

        $sourceItem = Get-Item $sourceFile
        $targetItem = Get-Item $targetFile

        if ($sourceItem.Length -ne $targetItem.Length) {
            $result.SetError("File size mismatch. Source: $($sourceItem.Length) bytes, Target: $($targetItem.Length) bytes")
            return $result
        }

        if ($this.CheckContents) {
            $sourceHash = Get-FileHash -Path $sourceFile -Algorithm SHA256
            $targetHash = Get-FileHash -Path $targetFile -Algorithm SHA256
            
            if ($sourceHash.Hash -ne $targetHash.Hash) {
                $result.SetError("File content mismatch")
                return $result
            }
        }

        return $result
    }

    [ValidationResult[]] ValidateFolder([FileMapping]$mapping, [string]$sourceBase, [string]$targetBase, [string]$release) {
        $results = @()
        $sourceFolder = $mapping.GetSourcePath($sourceBase)
        $targetFolder = $mapping.GetTargetPath($targetBase)

        if (-not (Test-Path $sourceFolder)) {
            $this.Logger.Warning("Source folder not found: $sourceFolder")
            return $results
        }

        if (-not (Test-Path $targetFolder)) {
            $this.Logger.Warning("Target folder not found: $targetFolder")
            return $results
        }

        $sourceFiles = Get-ChildItem -Path $sourceFolder -File -Recurse
        $targetFiles = Get-ChildItem -Path $targetFolder -File -Recurse

        # Create lookup for target files
        $targetLookup = @{}
        foreach ($file in $targetFiles) {
            $relativePath = $file.FullName.Substring($targetFolder.Length)
            $targetLookup[$relativePath] = $file
        }

        # Validate each source file
        foreach ($sourceFile in $sourceFiles) {
            $relativePath = $sourceFile.FullName.Substring($sourceFolder.Length)
            if ($targetLookup.ContainsKey($relativePath)) {
                $result = $this.ValidateFile($sourceFile.FullName, $targetLookup[$relativePath].FullName, $release)
                $results += $result
            }
            else {
                $result = [ValidationResult]::new($relativePath, $release)
                $result.SetError("File not found in target")
                $results += $result
            }
        }

        # Check for extra files in target
        foreach ($targetFile in $targetFiles) {
            $relativePath = $targetFile.FullName.Substring($targetFolder.Length)
            $sourcePath = Join-Path $sourceFolder $relativePath
            
            if (-not (Test-Path $sourcePath)) {
                $result = [ValidationResult]::new($relativePath, "Unknown")
                $result.SetWarning("Extra file found in target that doesn't exist in source")
                $results += $result
            }
        }

        return $results
    }
} 