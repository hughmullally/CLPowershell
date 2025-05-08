function Get-Release([string]$version) {
    $release = [Release]::FromString($version)
    $parts = $version.Split(".")
    $firstPart = $parts[0].Trim()
    $secondPart = $parts[1].Trim()
    $release.RootFolder = "$($this.RootFolder)\V$firstPart.$secondPart"
    
    $this.Logger.Debug("Release root folder: $($release.RootFolder)")
    return $release
}
