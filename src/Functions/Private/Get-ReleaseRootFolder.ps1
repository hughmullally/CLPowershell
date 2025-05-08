function Get-ReleaseRootFolder {
    param (
        [string] $rootFolder,
        [string] $release,
        [object] $logger
    )

    # Remove the last part of the release version
    $releaseParts = $release.Split('.')
    if ($releaseParts.Count -gt 1) {
        $releaseRoot = $releaseParts[0..($releaseParts.Count-2)] -join '.'
        $releaseFolder = Join-Path $rootFolder $releaseRoot
        if (Test-Path $releaseFolder) {
            return $releaseFolder
        }
        $logger.Warning("Release root folder not found: $releaseFolder")
    }

    $logger.Warning("Release folder not found: $releaseFolder")
    return $null
} 