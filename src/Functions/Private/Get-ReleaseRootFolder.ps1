function Get-ReleaseRootFolder {
    param (
        [string] $rootFolder,
        [string] $release,
        [object] $logger
    )

    $releaseFolder = Join-Path $rootFolder $release
    if (Test-Path $releaseFolder) {
        return $releaseFolder
    }

    $logger.Warning("Release folder not found: $releaseFolder")
    return $null
} 