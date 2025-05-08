function Get-ReleaseFolder {
    param (
        [Parameter(Mandatory=$true)]
        [string] $releaseRootFolder,
        
        [Parameter(Mandatory=$true)]
        [string] $release,
        
        [Parameter(Mandatory=$true)]
        [object] $logger
    )

    if (-not (Test-Path $releaseRootFolder)) {
        throw "Release root folder not found: $releaseRootFolder"
    }

    $folders = Get-ChildItem -Path $releaseRootFolder -Directory
    $version = $release.Replace("V", "")

    foreach ($folder in $folders) {
        $folderRelease = $folder.Name.Split('V')[-1]
        if ($version -eq $folderRelease) {
            $logger.Debug("Found release folder: $($folder.FullName)")
            return $folder.FullName
        }
    }

    throw "Release folder not found for version: $version"
}