class ReleaseService {
    [string]$RootFolder
    [object]$Logger

    ReleaseService([string]$rootFolder, [object]$logger) {
        $this.RootFolder = $rootFolder
        $this.Logger = $logger
    }

    [Release] GetRelease([string]$version) {
        $release = [Release]::FromString($version)
        $parts = $version.Split(".")
        $firstPart = $parts[0].Trim()
        $secondPart = $parts[1].Trim()
        $release.RootFolder = "$($this.RootFolder)\V$firstPart.$secondPart"
        
        $this.Logger.Debug("Release root folder: $($release.RootFolder)")
        return $release
    }

    [Release] GetReleaseFolder([Release]$release) {
        if (-not (Test-Path $release.RootFolder)) {
            throw "Release root folder not found: $($release.RootFolder)"
        }

        $folders = Get-ChildItem -Path $release.RootFolder -Directory
        $version = $release.Version.Replace("V", "")

        foreach ($folder in $folders) {
            $folderRelease = $folder.Name.Split('V')[-1]
            if ($version -eq $folderRelease) {
                $release.ReleaseFolder = $folder.FullName
                $this.Logger.Debug("Found release folder: $($folder.FullName)")
                return $release
            }
        }

        throw "Release folder not found for version: $version"
    }
} 