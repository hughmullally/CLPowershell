class Release {
    [string]$Version
    [string]$RootFolder
    [string]$ReleaseFolder

    Release([string]$version) {
        $this.Version = $version
    }

    [string] ToString() {
        return $this.Version
    }

    static [Release] FromString([string]$versionString) {
        return [Release]::new($versionString.Trim())
    }

    static [Release[]] FromStringArray([string[]]$versionStrings) {
        return $versionStrings | ForEach-Object { [Release]::FromString($_) }
    }

    static [Release[]] SortByVersion([Release[]]$releases) {
        return $releases | Sort-Object -Property {
            $versionParts = $_.Version -replace '^V', '' -split '\.'
            [version]::new($versionParts -join '.')
        } -Descending
    }
} 