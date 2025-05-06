function processRelease {
    param (
        [string] $releaseRootFolder,
        [string] $release,
        [string] $client,
        [string] $gitRootFolder,
        [hashtable] $folderMappings,
        [object] $logger
    )

    $logger.Information("Processing release folder: $releaseRootFolder")

    # Process each folder mapping
    foreach ($mapping in $folderMappings.GetEnumerator()) {
        $sourceFolder = Join-Path $releaseRootFolder $mapping.Key
        if (-not (Test-Path $sourceFolder)) {
            $logger.Warning("Source folder not found: $sourceFolder")
            continue
        }

        $targetFolder = Join-Path $gitRootFolder "$client\release\$($mapping.Value)"
        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
            $logger.Information("Created target folder: $targetFolder")
        }

        # Copy files
        Get-ChildItem -Path $sourceFolder -File | ForEach-Object {
            $targetFile = Join-Path $targetFolder $_.Name
            Copy-Item -Path $_.FullName -Destination $targetFile -Force
            $script:fileReleaseTracker[$_.Name] = $release
            $logger.Information("Copied file: $($_.Name) to $targetFile")
        }
    }
} 